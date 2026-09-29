import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../services/revenuecat_service.dart';
import 'app_controller.dart';

class PaywallController extends ChangeNotifier {
  final RevenueCatService revenueCat;
  final AppController appController;

  List<Package> packages = [];
  bool loadingPackages = false;
  bool restoring = false;
  String? message;
  CustomerInfo? customerInfo;

  bool _disposed = false;

  PaywallController({required this.revenueCat, required this.appController});

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    revenueCat.stopListening();
    super.dispose();
  }

  bool get demoMode => !revenueCat.isConfigured;

  bool get isPro => appController.state.isPro;

  Package? get monthlyPackage {
    for (final p in packages) {
      if (p.packageType == PackageType.monthly) return p;
    }
    return null;
  }

  Package? get lifetimePackage {
    for (final p in packages) {
      if (p.packageType == PackageType.lifetime) return p;
    }
    return null;
  }

  Future<void> init() async {
    revenueCat.listenForUpdates((isPro) async {
      final info = await revenueCat.fetchCustomerInfo();
      if (_disposed) return;
      customerInfo = info;
      await appController.setPro(isPro);
      if (_disposed) return;
      _safeNotify();
    });
    customerInfo = await revenueCat.fetchCustomerInfo();
    if (_disposed) return;
    final hasAccess = revenueCat.hasProAccessOf(customerInfo);
    if (hasAccess && !appController.state.isPro) {
      await appController.setPro(true);
    }
    if (_disposed) return;
    await loadPackages();
  }

  Future<bool> presentNativePaywall() async {
    message = null;
    final result = await revenueCat.presentNativePaywall();
    if (result == PaywallResult.purchased ||
        result == PaywallResult.restored) {
      customerInfo = await revenueCat.fetchCustomerInfo();
      await appController.setPro(true);
      _safeNotify();
      return true;
    }
    if (result == PaywallResult.error) {
      message = 'Paywall failed to load';
      _safeNotify();
    }
    return false;
  }

  Future<bool> openCustomerCenter() async {
    final opened = await revenueCat.presentCustomerCenter(
      onRestoreCompleted: (info) async {
        customerInfo = info;
        await appController.setPro(revenueCat.hasProAccessOf(info));
        _safeNotify();
      },
      onRestoreFailed: (error) {
        message = error.message;
        _safeNotify();
      },
    );
    return opened;
  }

  Future<void> loadPackages() async {
    if (loadingPackages) return;
    loadingPackages = true;
    message = null;
    _safeNotify();
    try {
      packages = await revenueCat.fetchPackages();
    } finally {
      loadingPackages = false;
      _safeNotify();
    }
  }

  Future<bool> purchase(Package package) async {
    message = null;
    _safeNotify();
    final outcome = await revenueCat.purchasePackage(package);
    if (outcome.success) {
      customerInfo = await revenueCat.fetchCustomerInfo();
      await appController.setPro(true);
    } else if (!outcome.cancelled) {
      message = outcome.message ?? 'Purchase failed';
    }
    _safeNotify();
    return outcome.success;
  }

  Future<bool> restore() async {
    restoring = true;
    message = null;
    _safeNotify();
    try {
      final restored = await revenueCat.restorePurchases();
      if (restored) {
        customerInfo = await revenueCat.fetchCustomerInfo();
        await appController.setPro(true);
        message = null;
      } else {
        message = 'No purchases to restore';
      }
      return restored;
    } finally {
      restoring = false;
      _safeNotify();
    }
  }

  Future<void> demoUnlock() async {
    await appController.setPro(true);
    _safeNotify();
  }
}
