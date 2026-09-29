import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'controllers/app_controller.dart';
import 'controllers/paywall_controller.dart';
import 'services/ai_service.dart';
import 'services/repository.dart';
import 'services/revenuecat_service.dart';

final repositoryProvider = Provider<Repository>(
  (ref) => throw UnimplementedError(),
);

final aiServiceProvider = Provider<AiService>(
  (ref) => throw UnimplementedError(),
);

final revenueCatServiceProvider = Provider<RevenueCatService>(
  (ref) => throw UnimplementedError(),
);

final appControllerProvider = ChangeNotifierProvider<AppController>((ref) {
  final controller = AppController(
    repository: ref.watch(repositoryProvider),
    aiService: ref.watch(aiServiceProvider),
  );
  return controller;
});

final paywallControllerProvider = ChangeNotifierProvider<PaywallController>((
  ref,
) {
  final controller = PaywallController(
    revenueCat: ref.watch(revenueCatServiceProvider),
    appController: ref.watch(appControllerProvider),
  );
  controller.init();
  return controller;
});
