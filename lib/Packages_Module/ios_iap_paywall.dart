import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nikah_blessing/FirebaseOperation/payment_visibility_service.dart';
import 'package:nikah_blessing/Payement_Module/in_app_purchase_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nikah_blessing/theme/app_colors.dart';

class IosIapPaywall extends StatefulWidget {
  final String? entryMessage;

  const IosIapPaywall({super.key, this.entryMessage});

  @override
  State<IosIapPaywall> createState() => _IosIapPaywallState();
}

class _IosIapPaywallState extends State<IosIapPaywall> {
  static final Uri _termsUrl = Uri.parse(
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
  );
  static final Uri _privacyUrl =
      Uri.parse('https://nikahblessing.com/nkb-app/privacypolicy');
  final InAppPurchaseService _purchaseService = InAppPurchaseService.instance;

  List<IosPackageOffer> _packages = [];
  bool _isLoading = true;
  bool _isBusy = false;
  bool _isPremium = false;
  String? _errorMessage;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _purchaseService.iosEntitlementActive.addListener(_onEntitlementChanged);
    _loadPackages();
  }

  @override
  void dispose() {
    _purchaseService.iosEntitlementActive.removeListener(_onEntitlementChanged);
    super.dispose();
  }

  void _onEntitlementChanged() {
    if (!mounted) return;
    if (_purchaseService.iosEntitlementActive.value) {
      setState(() => _isPremium = true);
    } else {
      _refreshExistingEntitlement();
    }
  }

  Future<void> _refreshExistingEntitlement() async {
    try {
      final isPremium =
          await PaymentVisibilityService.arePremiumFeaturesUnlocked();
      if (mounted) setState(() => _isPremium = isPremium);
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage =
            'Unable to refresh Premium status: ${_readableError(error)}');
      }
    }
  }

  Future<void> _loadPackages() async {
    if (!Platform.isIOS) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Subscriptions are available on iOS only.';
      });
      return;
    }

    try {
      final packages = await _purchaseService.loadPackages();
      final existingPremium =
          await PaymentVisibilityService.arePremiumFeaturesUnlocked();
      if (!mounted) return;
      setState(() {
        _packages = packages;
        _isPremium =
            existingPremium || _purchaseService.iosEntitlementActive.value;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      var existingPremium = _purchaseService.iosEntitlementActive.value;
      var statusErrorMessage = '';
      try {
        existingPremium = existingPremium ||
            await PaymentVisibilityService.arePremiumFeaturesUnlocked();
      } catch (statusError) {
        statusErrorMessage =
            ' Account status could not be refreshed: $statusError';
      }
      if (!mounted) return;
      setState(() {
        _isPremium =
            existingPremium || _purchaseService.iosEntitlementActive.value;
        _isLoading = false;
        _errorMessage = '${_readableError(error)}$statusErrorMessage';
      });
    }
  }

  Future<void> _purchase(IosPackageOffer package) async {
    setState(() {
      _isBusy = true;
      _errorMessage = null;
      _statusMessage = 'Waiting for App Store confirmation…';
    });

    try {
      await _purchaseService.purchase(package);
      if (!mounted) return;
      setState(() {
        _isPremium = _purchaseService.iosEntitlementActive.value;
        _statusMessage = _isPremium
            ? 'Premium is active on your account.'
            : 'The purchase is still being processed.';
      });
    } catch (error) {
      if (!mounted) return;
      final hasEntitlement = _purchaseService.iosEntitlementActive.value;
      final purchaseError = error is PlatformException
          ? PurchasesErrorHelper.getErrorCode(error)
          : null;
      final wasCancelled =
          purchaseError == PurchasesErrorCode.purchaseCancelledError;
      final isPending = purchaseError == PurchasesErrorCode.paymentPendingError;
      setState(() {
        _isPremium = hasEntitlement;
        _statusMessage = hasEntitlement
            ? 'Purchase confirmed. Account synchronization will retry when your connection is available.'
            : isPending
                ? 'Your purchase is pending approval by the App Store.'
                : null;
        if (!hasEntitlement && !wasCancelled && !isPending) {
          _errorMessage = _readableError(error);
        }
      });
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _isBusy = true;
      _errorMessage = null;
      _statusMessage = 'Checking your App Store purchases…';
    });

    try {
      final customerInfo = await _purchaseService.restorePurchases();
      if (!mounted) return;
      final restored = customerInfo.entitlements.active.containsKey(
        InAppPurchaseService.entitlementId,
      );
      setState(() {
        _isPremium = restored;
        _statusMessage = restored
            ? 'Your Premium subscription has been restored.'
            : 'No active Premium subscription was found for this Apple account.';
      });
    } catch (error) {
      if (!mounted) return;
      final restored = _purchaseService.iosEntitlementActive.value;
      setState(() {
        _isPremium = restored;
        _statusMessage = restored
            ? 'Subscription restored. Account synchronization will retry when your connection is available.'
            : null;
        if (!restored) _errorMessage = _readableError(error);
      });
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  String _readableError(Object error) {
    if (error is PlatformException) {
      switch (PurchasesErrorHelper.getErrorCode(error)) {
        case PurchasesErrorCode.purchaseCancelledError:
          return 'Purchase cancelled. No payment was made.';
        case PurchasesErrorCode.networkError:
          return 'Unable to reach the App Store. Check your internet connection and try again.';
        case PurchasesErrorCode.productNotAvailableForPurchaseError:
          return 'This subscription is not available for purchase right now.';
        case PurchasesErrorCode.paymentPendingError:
          return 'Your purchase is pending approval by the App Store.';
        default:
          return error.message ??
              'The App Store could not complete this request.';
      }
    }
    if (error is StateError) return error.message;
    return 'Unable to load or process subscriptions. Check your connection and try again.';
  }

  String? _savingsText() {
    final monthly = _packageForOrder(1)?.storePackage.storeProduct.price;
    final yearly = _packageForOrder(2)?.storePackage.storeProduct.price;
    if (monthly == null || yearly == null || monthly <= 0) return null;

    final savings = ((monthly * 12 - yearly) / (monthly * 12) * 100).round();
    if (savings <= 0) return null;
    return 'Save $savings% compared with 12 monthly payments';
  }

  IosPackageOffer? _packageForOrder(int order) {
    for (final package in _packages) {
      if (package.order == order) return package;
    }
    return null;
  }

  String _renewalPeriod(StoreProduct product) {
    final match = RegExp(r'^P(\d+)([DWMY])$')
        .firstMatch(product.subscriptionPeriod ?? '');
    if (match == null) return '';
    final count = int.parse(match.group(1)!);
    final unit = _periodUnitLabel(
      switch (match.group(2)) {
        'D' => PeriodUnit.day,
        'W' => PeriodUnit.week,
        'M' => PeriodUnit.month,
        'Y' => PeriodUnit.year,
        _ => PeriodUnit.unknown,
      },
      count,
    );
    if (unit == null) return '';
    if (count == 1) return 'per ${unit.substring(2)}';
    return 'every $unit';
  }

  String _billingInterval(StoreProduct product) {
    final period = _periodLabel(product.subscriptionPeriod);
    if (period == null) return 'One-time purchase';
    final match = RegExp(r'^1 (day|week|month|year)$').firstMatch(period);
    if (match == null) return 'Billed every $period';
    return 'Billed ${switch (match.group(1)) {
      'day' => 'daily',
      'week' => 'weekly',
      'month' => 'monthly',
      'year' => 'yearly',
      _ => period,
    }}';
  }

  bool _isLifetime(IosPackageOffer package) =>
      package.duration.toUpperCase() == 'LIFETIME';

  String? _introductoryOfferText(StoreProduct product) {
    final introductoryPrice = product.introductoryPrice;
    final period = _periodLabel(product.subscriptionPeriod);
    final trialPeriods = introductoryPrice == null
        ? 0
        : introductoryPrice.periodNumberOfUnits * introductoryPrice.cycles;
    if (introductoryPrice == null ||
        introductoryPrice.price != 0 ||
        trialPeriods <= 0 ||
        introductoryPrice.periodUnit == PeriodUnit.unknown ||
        period == null) {
      return null;
    }

    final trialLength = _periodUnitLabel(
      introductoryPrice.periodUnit,
      trialPeriods,
    );
    if (trialLength == null) return null;
    return '$trialLength free, then ${product.priceString}/$period';
  }

  String? _periodLabel(String? subscriptionPeriod) {
    if (subscriptionPeriod == null) return null;
    final match = RegExp(r'^P(\d+)([DWMY])$').firstMatch(subscriptionPeriod);
    if (match == null) return null;
    final count = int.tryParse(match.group(1)!);
    if (count == null || count <= 0) return null;
    final unit = switch (match.group(2)) {
      'D' => PeriodUnit.day,
      'W' => PeriodUnit.week,
      'M' => PeriodUnit.month,
      'Y' => PeriodUnit.year,
      _ => PeriodUnit.unknown,
    };
    return _periodUnitLabel(unit, count);
  }

  String? _periodUnitLabel(PeriodUnit unit, int count) {
    final name = switch (unit) {
      PeriodUnit.day => 'day',
      PeriodUnit.week => 'week',
      PeriodUnit.month => 'month',
      PeriodUnit.year => 'year',
      PeriodUnit.unknown => null,
    };
    if (name == null) return null;
    return '$count $name${count == 1 ? '' : 's'}';
  }

  Future<void> _openLegalLink(Uri uri, String name) async {
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        setState(() => _errorMessage = 'Could not open the $name link.');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = 'Could not open the $name link: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Close',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.close),
        ),
        title: const Text('Nikah Blessing Premium'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (widget.entryMessage?.trim().isNotEmpty == true) ...[
            _messageCard(widget.entryMessage!, isError: false),
            const SizedBox(height: 16),
          ],
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: AppColors.logoGradient,
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.workspace_premium_rounded,
                    color: Colors.white, size: 42),
                SizedBox(height: 16),
                Text(
                  'More ways to connect',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Choose a Premium plan to access more proposals, messaging, and search filters.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Card(
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BenefitRow(text: 'More proposals'),
                  _BenefitRow(text: 'Messaging'),
                  _BenefitRow(text: 'Search filters'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            for (final package in _packages)
              _planCard(
                package: package,
                bestValue: package.order == 2,
                savings: package.order == 2 ? _savingsText() : null,
                isLifetime: _isLifetime(package),
              ),
            if (_packages.isEmpty && _errorMessage == null) ...[
              _messageCard(
                'Premium plans are temporarily unavailable. Please try again later.',
                isError: true,
              ),
              TextButton(
                onPressed: _isBusy
                    ? null
                    : () {
                        setState(() {
                          _isLoading = true;
                          _errorMessage = null;
                        });
                        _loadPackages();
                      },
                child: const Text('Retry'),
              ),
            ],
            if (_isPremium)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Premium is active for this account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (_errorMessage != null) ...[
              _messageCard(_errorMessage!, isError: true),
              TextButton(
                onPressed: _isBusy
                    ? null
                    : () {
                        setState(() {
                          _isLoading = true;
                          _errorMessage = null;
                        });
                        _loadPackages();
                      },
                child: const Text('Retry'),
              ),
            ],
          ],
          if (_statusMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _statusMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
          const SizedBox(height: 8),
          if (_isBusy)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          const Text(
            'Subscriptions renew automatically until cancelled. One-time purchases do not renew. Cancel subscriptions anytime in App Store settings.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: kBrandPrimary),
            ),
            onPressed: _isBusy ? null : _restorePurchases,
            child: const Text('Restore Purchases'),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              TextButton(
                onPressed: () => _openLegalLink(_termsUrl, 'Terms of Use'),
                child: const Text('Terms of Use (EULA)'),
              ),
              TextButton(
                onPressed: () => _openLegalLink(_privacyUrl, 'Privacy Policy'),
                child: const Text('Privacy Policy'),
              ),
            ],
          ),
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _planCard({
    required IosPackageOffer package,
    bool bestValue = false,
    String? savings,
    bool isLifetime = false,
  }) {
    final product = package.storePackage.storeProduct;
    final renewalPeriod = _renewalPeriod(product);
    final interval = _billingInterval(product);
    final introductoryOfferText = _introductoryOfferText(product);
    final packageDescription = package.description.isNotEmpty
        ? package.description
        : product.description;
    final durationText = isLifetime
        ? 'Lifetime access'
        : package.duration == 'UNKNOWN'
            ? 'Duration unavailable'
            : '${package.duration} days access';
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: kBrandPrimary,
          width: bestValue ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    package.displayName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (bestValue)
                  const Chip(
                    label: Text('Best value'),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(color: kBrandPrimary),
                  ),
              ],
            ),
            if (packageDescription.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                packageDescription,
                style: const TextStyle(color: Colors.black54),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              '${package.dailyProfiles} daily profiles · $durationText',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Text(
              '${product.priceString} · $interval',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (introductoryOfferText != null) ...[
              const SizedBox(height: 4),
              Text(
                introductoryOfferText,
                style: const TextStyle(color: Colors.black87),
              ),
            ],
            if (savings != null) ...[
              const SizedBox(height: 4),
              Text(savings, style: const TextStyle(color: Colors.black87)),
            ],
            const SizedBox(height: 4),
            Text(
              isLifetime
                  ? '${product.priceString} one-time purchase.'
                  : '${product.priceString} $renewalPeriod. Renews automatically. Cancel anytime in App Store settings.',
              style: const TextStyle(color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: kBrandGradient,
                  ),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    onPressed: _isBusy || _isLoading || _isPremium
                        ? null
                        : () => _purchase(package),
                    child: _isBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isPremium ? 'Premium is active' : 'Continue'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _messageCard(String message, {required bool isError}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? Colors.red.shade50 : AppColors.lightPurpleTint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isError ? Colors.red.shade700 : AppColors.textDark,
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final String text;

  const _BenefitRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle,
              color: AppColors.primaryPink, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}
