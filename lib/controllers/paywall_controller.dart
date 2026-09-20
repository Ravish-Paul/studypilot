import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../services/revenuecat_service.dart';
import 'app_controller.dart';

class PaywallController extends ChangeNotifier {
  final RevenueCatService revenueCat;
  final AppController appController;

  List<Package> packages = [];
  bool loadingPackages = false;
  bool restoring = false;
  String? message;

  PaywallController({required this.revenueCat, required this.appController});

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
      await appController.setPro(isPro);
      notifyListeners();
    });
    final hasAccess = await revenueCat.checkCurrentAccess();
    if (hasAccess && !appController.state.isPro) {
      await appController.setPro(true);
    }
    await loadPackages();
  }

  Future<void> loadPackages() async {
    loadingPackages = true;
    message = null;
    notifyListeners();
    try {
      packages = await revenueCat.fetchPackages();
    } finally {
      loadingPackages = false;
      notifyListeners();
    }
  }

  Future<bool> purchase(Package package) async {
    message = null;
    notifyListeners();
    final outcome = await revenueCat.purchasePackage(package);
    if (outcome.success) {
      await appController.setPro(true);
    } else if (!outcome.cancelled) {
      message = outcome.message ?? 'Purchase failed';
    }
    notifyListeners();
    return outcome.success;
  }

  Future<bool> restore() async {
    restoring = true;
    message = null;
    notifyListeners();
    try {
      final restored = await revenueCat.restorePurchases();
      if (restored) {
        await appController.setPro(true);
        message = null;
      } else {
        message = 'No purchases to restore';
      }
      return restored;
    } finally {
      restoring = false;
      notifyListeners();
    }
  }

  Future<void> demoUnlock() async {
    await appController.setPro(true);
    notifyListeners();
  }
}
