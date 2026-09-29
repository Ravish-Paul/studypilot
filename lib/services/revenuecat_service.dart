import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

class PurchaseOutcome {
  final bool success;
  final bool cancelled;
  final String? message;

  PurchaseOutcome({
    required this.success,
    this.cancelled = false,
    this.message,
  });
}

class RevenueCatService {
  final String? apiKey;
  bool configured = false;

  static const entitlementId = 'pro';

  RevenueCatService({this.apiKey});

  bool get _platformSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  bool get isConfigured => configured;

  Future<void> init() async {
    if (apiKey == null || apiKey!.trim().isEmpty) return;
    if (!_platformSupported) return;
    try {
      await Purchases.configure(PurchasesConfiguration(apiKey!.trim()));
      configured = true;
    } catch (_) {
      configured = false;
    }
  }

  Future<List<Package>> fetchPackages() async {
    if (!configured) return [];
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current?.availablePackages ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<PurchaseOutcome> purchasePackage(Package package) async {
    if (!configured) {
      return PurchaseOutcome(
        success: false,
        message: 'RevenueCat is not configured',
      );
    }
    try {
      final result = await Purchases.purchase(
        PurchaseParams.package(package),
      );
      return PurchaseOutcome(success: hasProAccess(result.customerInfo));
    } on PlatformException catch (e) {
      final cancelled = e.code == 'purchaseCancelledError' ||
          (e.details?['readableErrorCode'] ?? '') == 'PURCHASE_CANCELLED_ERROR';
      return PurchaseOutcome(
        success: false,
        cancelled: cancelled,
        message: e.message,
      );
    } catch (e) {
      return PurchaseOutcome(success: false, message: e.toString());
    }
  }

  Future<bool> restorePurchases() async {
    if (!configured) return false;
    try {
      final info = await Purchases.restorePurchases();
      return hasProAccess(info);
    } catch (_) {
      return false;
    }
  }

  Future<PaywallResult?> presentNativePaywall() async {
    if (!configured) return null;
    try {
      return await RevenueCatUI.presentPaywallIfNeeded(
        entitlementId,
        displayCloseButton: true,
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> presentCustomerCenter({
    void Function(CustomerInfo info)? onRestoreCompleted,
    void Function(PurchasesError error)? onRestoreFailed,
  }) async {
    if (!configured) return false;
    try {
      await RevenueCatUI.presentCustomerCenter(
        onRestoreCompleted: onRestoreCompleted,
        onRestoreFailed: onRestoreFailed,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<CustomerInfo?> fetchCustomerInfo() async {
    if (!configured) return null;
    try {
      return await Purchases.getCustomerInfo();
    } catch (_) {
      return null;
    }
  }

  EntitlementInfo? proEntitlement(CustomerInfo info) =>
      info.entitlements.active[entitlementId];

  Future<bool> checkCurrentAccess() async {
    if (!configured) return false;
    try {
      final info = await Purchases.getCustomerInfo();
      return hasProAccess(info);
    } catch (_) {
      return false;
    }
  }

  bool hasProAccess(CustomerInfo info) =>
      info.entitlements.active[entitlementId] != null;

  bool hasProAccessOf(CustomerInfo? info) =>
      info != null && hasProAccess(info);

  void Function(CustomerInfo info)? _customerInfoListener;

  void listenForUpdates(void Function(bool isPro) onUpdate) {
    if (!configured) return;
    stopListening();
    _customerInfoListener = (info) => onUpdate(hasProAccess(info));
    Purchases.addCustomerInfoUpdateListener(_customerInfoListener!);
  }

  void stopListening() {
    final listener = _customerInfoListener;
    if (listener == null) return;
    Purchases.removeCustomerInfoUpdateListener(listener);
    _customerInfoListener = null;
  }
}
