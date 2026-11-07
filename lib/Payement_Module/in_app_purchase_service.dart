import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class IosPackageOffer {
  const IosPackageOffer({
    required this.storePackage,
    required this.packageDocumentId,
    required this.displayName,
    required this.dailyProfiles,
    required this.duration,
    required this.order,
    this.description = '',
  });

  final Package storePackage;
  final String packageDocumentId;
  final String displayName;
  final int dailyProfiles;
  final String duration;
  final int order;
  final String description;

  String get packageIdentifier => storePackage.identifier;
  String get productId => storePackage.storeProduct.identifier;
}

class InAppPurchaseService {
  InAppPurchaseService._();

  static final InAppPurchaseService instance = InAppPurchaseService._();

  static const String entitlementId = 'nikah_blessing_pro';
  static const String _dartDefineApiKey = String.fromEnvironment(
    'REVENUECAT_IOS_API_KEY',
  );
  final ValueNotifier<bool> iosEntitlementActive = ValueNotifier(false);
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  String? _configuredUserId;
  bool _isConfigured = false;
  bool _listenerRegistered = false;
  Object? lastSyncError;
  String? _resolvedApiKey;

  Future<String> _resolveApiKey() async {
    if (_resolvedApiKey != null) return _resolvedApiKey!;
    final dartDefineApiKey = _dartDefineApiKey.trim();
    if (dartDefineApiKey.isNotEmpty) {
      return _resolvedApiKey = dartDefineApiKey;
    }

    try {
      final environment = await rootBundle.loadString('assets/revenuecat.env');
      for (final line in environment.split('\n')) {
        final entry = line.trim();
        if (entry.isEmpty || entry.startsWith('#')) continue;
        final separator = entry.indexOf('=');
        if (separator < 0 ||
            entry.substring(0, separator).trim() != 'REVENUECAT_IOS_API_KEY') {
          continue;
        }
        var value = entry.substring(separator + 1).trim();
        if (value.length >= 2 &&
            ((value.startsWith('"') && value.endsWith('"')) ||
                (value.startsWith("'") && value.endsWith("'")))) {
          value = value.substring(1, value.length - 1).trim();
        }
        return _resolvedApiKey = value;
      }
    } on FlutterError {
      // The local environment asset is optional when using --dart-define.
    }
    return _resolvedApiKey = '';
  }

  String? _apiKeyConfigurationError(String apiKey) {
    final normalizedApiKey = apiKey.trim();
    if (normalizedApiKey.isEmpty) {
      return 'REVENUECAT_IOS_API_KEY is missing.';
    }
    if (!normalizedApiKey.startsWith('appl_') &&
        !normalizedApiKey.startsWith('apph_')) {
      return 'REVENUECAT_IOS_API_KEY must be a RevenueCat public API key.';
    }
    return null;
  }

  void _ensureIos() {
    if (!Platform.isIOS) {
      throw UnsupportedError('RevenueCat purchases are available on iOS only.');
    }
  }

  Future<void> configureAtStartup() async {
    if (!Platform.isIOS) return;
    final apiKey = await _resolveApiKey();
    final apiKeyError = _apiKeyConfigurationError(apiKey);
    if (apiKeyError != null) {
      lastSyncError = StateError(apiKeyError);
      debugPrint('RevenueCat is not configured: $apiKeyError');
      return;
    }

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      await Purchases.configure(
        PurchasesConfiguration(apiKey.trim())..appUserID = userId,
      );
      _isConfigured = true;
      _configuredUserId = userId;
      unawaited(_logOfferingsAtStartup());
    } catch (error, stackTrace) {
      lastSyncError = error;
      debugPrint('Unable to configure RevenueCat at app startup: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _logOfferingsAtStartup() async {
    try {
      final offerings = await Purchases.getOfferings();
      debugPrint(
        'RevenueCat startup getOfferings returned '
        '${offerings.all.length} offerings: ${offerings.all.keys.toList()}; '
        'current=${offerings.current?.identifier ?? 'none'}.',
      );
      for (final offering in offerings.all.values) {
        final products = offering.availablePackages
            .map((package) =>
                '${package.identifier} -> ${package.storeProduct.identifier}')
            .toList();
        debugPrint(
          'RevenueCat startup offering "${offering.identifier}" returned '
          '${products.length} packages: $products.',
        );
      }
    } catch (error, stackTrace) {
      debugPrint('RevenueCat startup getOfferings failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> initialize() async {
    _ensureIos();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Sign in before loading Premium subscriptions.');
    }
    final apiKey = await _resolveApiKey();
    final apiKeyError = _apiKeyConfigurationError(apiKey);
    if (apiKeyError != null) {
      throw StateError(
        'RevenueCat is not configured: $apiKeyError',
      );
    }

    await _configureForUser(user.uid, apiKey);
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

  Future<void> _configureForUser(String userId, String apiKey) async {
    if (_isConfigured && _configuredUserId == userId) return;
    if (!_isConfigured) {
      await Purchases.configure(
        PurchasesConfiguration(apiKey.trim())..appUserID = userId,
      );
      _isConfigured = true;
    } else {
      await Purchases.logIn(userId);
      iosEntitlementActive.value = await _syncCustomerInfo();
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
    if (FirebaseAuth.instance.currentUser == null) {
      throw StateError('Sign in before refreshing Premium access.');
    }

    late final CustomerInfo customerInfo;
    try {
      customerInfo = await Purchases.getCustomerInfo();
    } catch (error) {
      lastSyncError = error;
      if (fallback != null) {
        customerInfo = fallback;
      } else {
        iosEntitlementActive.value = false;
        rethrow;
      }
    }
    debugPrint(
      'RevenueCat customer entitlements: '
      'active=${customerInfo.entitlements.active.keys.toList()}, '
      'all=${customerInfo.entitlements.all.values.map((entitlement) => '${entitlement.identifier} (active=${entitlement.isActive}, '
          'product=${entitlement.productIdentifier}, store=${entitlement.store})').toList()}.',
    );
    try {
      iosEntitlementActive.value = await _syncCustomerInfo();
      return customerInfo;
    } catch (error) {
      lastSyncError = error;
      iosEntitlementActive.value = false;
      rethrow;
    }
  }

  Future<List<IosPackageOffer>> loadPackages() async {
    await initialize();
    late final Offerings offerings;
    try {
      offerings = await Purchases.getOfferings();
    } catch (error, stackTrace) {
      debugPrint('RevenueCat getOfferings failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
    debugPrint(
      'RevenueCat getOfferings returned ${offerings.all.length} offerings: '
      '${offerings.all.keys.toList()}; '
      'current=${offerings.current?.identifier ?? 'none'}.',
    );
    final defaultOffering = offerings.all['default'];
    if (defaultOffering == null) {
      debugPrint(
        'RevenueCat "default" offering is absent. '
        'Available offering IDs: ${offerings.all.keys.toList()}.',
      );
      throw StateError(
        'The RevenueCat "default" offering is unavailable.',
      );
    }
    final offeringProducts = defaultOffering.availablePackages
        .map((package) =>
            '${package.identifier} -> ${package.storeProduct.identifier}')
        .toList();
    debugPrint(
      'RevenueCat "default" offering returned '
      '${offeringProducts.length} packages: $offeringProducts.',
    );

    final packageSnapshot =
        await FirebaseFirestore.instance.collection('packages').get();
    debugPrint(
      'Firestore iOS subscription configuration: '
      '${packageSnapshot.docs.map((document) {
        final data = document.data();
        return '${document.id} (active=${data['isActive'] != false}, '
            'product=${data['ios_product_id']}, '
            'RevenueCat package=${data['revenuecat_package_id']})';
      }).toList()}.',
    );
    final selectedPackages = <IosPackageOffer>[];
    final unmatchedFirestoreProducts = <String>[];
    final skippedFirestorePackages = <String>[];
    for (final document in packageSnapshot.docs) {
      final packageData = document.data();
      if (packageData['isActive'] == false) continue;

      final productId = packageData['ios_product_id']?.toString().trim() ?? '';
      final revenueCatPackageId =
          packageData['revenuecat_package_id']?.toString().trim() ?? '';
      final displayName = packageData['name']?.toString().trim() ?? '';
      final parsedDailyProfiles = _parseInt(packageData['DailyProfiles']);
      final duration = packageData['days']?.toString().trim() ?? '';
      final parsedOrder = _parseInt(packageData['order']);
      final isRehmatYearly = document.id == 'Yearly Package' ||
          displayName.toLowerCase() == 'rehmat package';

      if (isRehmatYearly) {
        final invalidFields = <String>[
          if (productId.isEmpty) 'ios_product_id',
          if (displayName.isEmpty) 'name',
          if (parsedDailyProfiles == null || parsedDailyProfiles < 0)
            'DailyProfiles',
          if (duration.isEmpty) 'days',
          if (parsedOrder == null) 'order',
        ];
        debugPrint(
          'Firestore Rehmat yearly package document "${document.id}": '
          'ios_product_id=${packageData['ios_product_id']}, '
          'name=${packageData['name']}, '
          'price=${packageData['price']}, '
          'DailyProfiles=${packageData['DailyProfiles']}, '
          'ChatCredit=${packageData['ChatCredit']}, '
          'days=${packageData['days']}. '
          'Missing/invalid fields causing package configuration failure: '
          '${invalidFields.isEmpty ? 'none' : invalidFields.join(', ')}. '
          'price and ChatCredit are diagnostic only and are not required '
          'for iOS display.',
        );
      }

      if (productId.isEmpty) {
        skippedFirestorePackages.add(document.id);
        debugPrint(
          'Skipping iOS package "${document.id}": Firestore ios_product_id '
          'is missing or empty.',
        );
        continue;
      }

      if (!isRehmatYearly &&
          (displayName.isEmpty ||
              parsedDailyProfiles == null ||
              parsedDailyProfiles < 0 ||
              duration.isEmpty ||
              parsedOrder == null)) {
        throw StateError(
          'The iOS package "${document.id}" is missing required Firestore configuration.',
        );
      }
      final matches = defaultOffering.availablePackages.where(
        (storePackage) => storePackage.storeProduct.identifier == productId,
      );
      if (matches.length > 1) {
        throw StateError(
          'The RevenueCat "default" offering contains multiple packages for '
          'Firestore ios_product_id "$productId" (${document.id}).',
        );
      }
      if (matches.isEmpty) {
        unmatchedFirestoreProducts.add(
          '${document.id} (Firestore product=$productId, '
          'RevenueCat package=$revenueCatPackageId)',
        );
        continue;
      }

      final packageOrder = defaultOffering.availablePackages.indexWhere(
            (storePackage) => storePackage.storeProduct.identifier == productId,
          ) +
          1;
      debugPrint(
        'Matched Firestore package "${document.id}": ios_product_id=$productId '
        'to RevenueCat package=${matches.single.identifier}, '
        'storeProduct.identifier=${matches.single.storeProduct.identifier}.',
      );
      selectedPackages.add(IosPackageOffer(
        storePackage: matches.single,
        packageDocumentId: document.id,
        displayName: displayName.isEmpty ? document.id : displayName,
        dailyProfiles: parsedDailyProfiles ?? 0,
        duration: duration.isEmpty ? 'UNKNOWN' : duration,
        order: parsedOrder ?? packageOrder,
        description: packageData['description']?.toString().trim() ?? '',
      ));
    }
    selectedPackages.sort(
      (left, right) => left.order.compareTo(right.order),
    );

    if (packageSnapshot.docs.isEmpty) {
      throw StateError(
        'Firestore has no iOS subscription package configuration.',
      );
    }
    if (unmatchedFirestoreProducts.isNotEmpty) {
      debugPrint(
        'Firestore iOS products not matched in RevenueCat "default": '
        '$unmatchedFirestoreProducts. RevenueCat "default" offering packages were '
        '$offeringProducts.',
      );
    }
    if (selectedPackages.isEmpty) {
      throw StateError(
        'No active Firestore iOS packages with a non-empty ios_product_id '
        'matched the RevenueCat "default" offering. '
        'Unmatched: ${unmatchedFirestoreProducts.join('; ')}. '
        'Skipped because ios_product_id was empty: '
        '${skippedFirestorePackages.join(', ')}. '
        'RevenueCat packages: $offeringProducts.',
      );
    }
    return selectedPackages;
  }

  int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double && value.isFinite && value == value.roundToDouble()) {
      return value.toInt();
    }
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  Future<CustomerInfo> purchase(IosPackageOffer offer) async {
    _ensureIos();
    await initialize();
    final currentDocument = await FirebaseFirestore.instance
        .collection('packages')
        .doc(offer.packageDocumentId)
        .get();
    final currentData = currentDocument.data();
    final currentProductId =
        currentData?['ios_product_id']?.toString().trim() ?? '';
    if (!currentDocument.exists ||
        currentData?['isActive'] == false ||
        currentProductId != offer.productId) {
      throw StateError('This subscription is not available for purchase.');
    }

    final result = await Purchases.purchase(
      PurchaseParams.package(offer.storePackage),
    );
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

  Future<void> presentCodeRedemptionSheet() async {
    _ensureIos();
    await initialize();
    await Purchases.presentCodeRedemptionSheet();
  }

  Future<CustomerInfo> restorePurchases() async {
    _ensureIos();
    await initialize();
    final result = await Purchases.restorePurchases();
    return refreshCustomerInfo(fallback: result);
  }

  Future<void> _handleCustomerInfoUpdate(CustomerInfo _) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;
      iosEntitlementActive.value = await _syncCustomerInfo();
      lastSyncError = null;
    } catch (error, stackTrace) {
      lastSyncError = error;
      iosEntitlementActive.value = false;
      debugPrint('Unable to synchronize RevenueCat entitlement: $error');
      FlutterError.reportError(FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'RevenueCat entitlement synchronization',
      ));
    }
  }

  Future<bool> _syncCustomerInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Sign in before synchronizing Premium access.');
    }

    final result = await _functions
        .httpsCallable('syncRevenueCatSubscription')
        .call<Map<String, dynamic>>();
    final isPremium = result.data['isPremium'];
    if (isPremium is! bool) {
      throw StateError(
        'The subscription service returned an invalid Premium status. Please try again.',
      );
    }
    lastSyncError = null;
    return isPremium;
  }
}
