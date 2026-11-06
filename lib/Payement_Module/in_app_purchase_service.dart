import 'dart:async';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InAppPurchaseService {
  InAppPurchaseService._();

  static final InAppPurchaseService instance = InAppPurchaseService._();

  static const String monthlyProductId = 'nikahblessing_monthly';
  static const String threeMonthProductId = 'nikahblessing_3month';
  static const String yearlyProductId = 'nikahblessing_yearly';
  static const String entitlementId = 'premium';
  static const String monthlyPackageName = 'Premium';
  static const String yearlyPackageName = 'Premium';
  static const String _apiKey =
      String.fromEnvironment('REVENUECAT_IOS_API_KEY');

  final ValueNotifier<bool> iosEntitlementActive = ValueNotifier(false);
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  String? _configuredUserId;
  bool _listenerRegistered = false;
  Object? lastSyncError;
  String? _currentAppUserId;

  void _ensureIos() {
    if (!Platform.isIOS) {
      throw UnsupportedError('RevenueCat purchases are available on iOS only.');
    }
  }

  Future<void> initialize() async {
    _ensureIos();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Sign in before loading Premium subscriptions.');
    }
    if (_apiKey.trim().isEmpty) {
      throw StateError(
        'RevenueCat is not configured. Add REVENUECAT_IOS_API_KEY to the build environment.',
      );
    }

    if (_currentAppUserId != user.uid) {
      _currentAppUserId = user.uid;
      await _loadCachedEntitlement(user.uid);
    }

    await _configureForUser(user.uid);
    _registerCustomerInfoListener();
    try {
      await refreshCustomerInfo();
    } catch (error) {
      lastSyncError = error;
      debugPrint('Unable to refresh RevenueCat customer information: $error');
    }
  }

  Future<void> refreshEntitlement() async {
    if (!Platform.isIOS) return;
    if (FirebaseAuth.instance.currentUser == null) {
      _currentAppUserId = null;
      iosEntitlementActive.value = false;
      return;
    }
    try {
      await initialize();
    } catch (error, stackTrace) {
      lastSyncError = error;
      debugPrint('Unable to refresh iOS Premium entitlement: $error');
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'RevenueCat entitlement refresh',
        ),
      );
    }
  }

  Future<void> loadCachedEntitlement() async {
    if (!Platform.isIOS) return;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _currentAppUserId = null;
      iosEntitlementActive.value = false;
      return;
    }
    if (_currentAppUserId == userId) return;
    _currentAppUserId = userId;
    await _loadCachedEntitlement(userId);
  }

  Future<void> _configureForUser(String userId) async {
    if (_configuredUserId == userId) return;
    if (_configuredUserId == null) {
      await Purchases.configure(
        PurchasesConfiguration(_apiKey.trim())..appUserID = userId,
      );
    } else {
      final result = await Purchases.logIn(userId);
      await _applyCustomerInfo(result.customerInfo, userId);
    }
    _configuredUserId = userId;
  }

  void _registerCustomerInfoListener() {
    if (_listenerRegistered) return;
    Purchases.addCustomerInfoUpdateListener(_handleCustomerInfoUpdate);
    _listenerRegistered = true;
  }

  Future<CustomerInfo> refreshCustomerInfo({
    CustomerInfo? fallback,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw StateError('Sign in before refreshing Premium access.');
    }

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      await _applyCustomerInfo(customerInfo, userId);
      unawaited(
        _syncCustomerInfo(customerInfo).catchError((Object error) {
          lastSyncError = error;
        }),
      );
      return customerInfo;
    } catch (error) {
      lastSyncError = error;
      if (fallback != null) {
        await _applyCustomerInfo(fallback, userId);
        unawaited(
          _syncCustomerInfo(fallback).catchError((Object syncError) {
            lastSyncError = syncError;
          }),
        );
        return fallback;
      }
      rethrow;
    }
  }

  Future<void> _loadCachedEntitlement(String userId) async {
    iosEntitlementActive.value = false;
    try {
      final preferences = await SharedPreferences.getInstance();
      final cachedStatus =
          preferences.getBool(_entitlementPreferenceKey(userId));
      iosEntitlementActive.value = cachedStatus ?? false;
    } catch (error) {
      lastSyncError = error;
      debugPrint('Unable to load cached Premium entitlement: $error');
    }
  }

  String _entitlementPreferenceKey(String userId) =>
      'revenuecat_premium_entitlement_$userId';

  Future<void> _applyCustomerInfo(
    CustomerInfo customerInfo,
    String userId,
  ) async {
    final isActive =
        customerInfo.entitlements.active.containsKey(entitlementId);
    iosEntitlementActive.value = isActive;
    await _saveCachedEntitlement(userId, isActive);
  }

  Future<void> _saveCachedEntitlement(String userId, bool isActive) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_entitlementPreferenceKey(userId), isActive);
    } catch (error) {
      lastSyncError = error;
      debugPrint('Unable to cache Premium entitlement: $error');
    }
  }

  Future<List<Package>> loadPackages() async {
    await initialize();
    final offerings = await Purchases.getOfferings();
    final current = offerings.current;
    if (current == null) {
      throw StateError(
        'Premium plans are temporarily unavailable. Please try again later.',
      );
    }

    final availablePackages = current.availablePackages.toList();
    for (final package in [
      current.monthly,
      current.threeMonth,
      current.annual,
    ]) {
      if (package != null &&
          !availablePackages
              .any((item) => item.identifier == package.identifier)) {
        availablePackages.add(package);
      }
    }

    Package? findPackage(String productId, PackageType packageType) {
      for (final package in availablePackages) {
        if (package.storeProduct.identifier == productId) return package;
      }
      for (final package in availablePackages) {
        if (package.packageType == packageType) return package;
      }
      return null;
    }

    final selectedPackages = <Package>[];
    for (final match in [
      findPackage(monthlyProductId, PackageType.monthly),
      findPackage(threeMonthProductId, PackageType.threeMonth),
      findPackage(yearlyProductId, PackageType.annual),
    ]) {
      if (match != null &&
          !selectedPackages
              .any((item) => item.identifier == match.identifier)) {
        selectedPackages.add(match);
      }
    }

    if (selectedPackages.isEmpty) {
      throw StateError(
        'Premium plans are temporarily unavailable. Please try again later.',
      );
    }
    return selectedPackages;
  }

  Future<CustomerInfo> purchase(Package package) async {
    _ensureIos();
    await initialize();
    final productId = package.storeProduct.identifier;
    final supportedProductIds = {
      monthlyProductId,
      threeMonthProductId,
      yearlyProductId,
    };
    final supportedPackageTypes = {
      PackageType.monthly,
      PackageType.threeMonth,
      PackageType.annual,
    };
    if (!supportedProductIds.contains(productId) &&
        !supportedPackageTypes.contains(package.packageType)) {
      throw StateError('This subscription is not available for purchase.');
    }

    final result = await Purchases.purchase(PurchaseParams.package(package));
    final customerInfo = await refreshCustomerInfo(
      fallback: result.customerInfo,
    );
    if (!iosEntitlementActive.value) {
      throw StateError(
        'The store completed the purchase but did not activate Premium.',
      );
    }
    return customerInfo;
  }

  Future<CustomerInfo> restorePurchases() async {
    _ensureIos();
    await initialize();
    final result = await Purchases.restorePurchases();
    return refreshCustomerInfo(fallback: result);
  }

  Future<void> _handleCustomerInfoUpdate(CustomerInfo customerInfo) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;
      await _applyCustomerInfo(customerInfo, userId);
      await _syncCustomerInfo(customerInfo);
      lastSyncError = null;
    } catch (error, stackTrace) {
      lastSyncError = error;
      debugPrint('Unable to synchronize RevenueCat entitlement: $error');
      FlutterError.reportError(FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'RevenueCat entitlement synchronization',
      ));
    }
  }

  Future<void> _syncCustomerInfo(CustomerInfo customerInfo) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Sign in before synchronizing Premium access.');
    }
    final isActive =
        customerInfo.entitlements.active.containsKey(entitlementId);

    final result = await _functions
        .httpsCallable('syncRevenueCatSubscription')
        .call<Map<String, dynamic>>();
    if (result.data['isPremium'] is! bool ||
        result.data['isPremium'] != isActive) {
      throw StateError(
        'RevenueCat and the subscription service returned different Premium status. Please try again.',
      );
    }
    lastSyncError = null;
  }
}
