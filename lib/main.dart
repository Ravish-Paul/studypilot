import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'providers.dart';
import 'services/ai_service.dart';
import 'services/repository.dart';
import 'services/revenuecat_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  await Hive.initFlutter();
  final repository = Repository();
  await repository.init();

  final aiService = AiService(
    apiKey: dotenv.env['OPENROUTER_API_KEY'],
    model: dotenv.env['OPENROUTER_MODEL'] ?? 'openai/gpt-4o-mini',
  );

  final revenueCat = RevenueCatService(
    apiKey: dotenv.env['REVENUECAT_GOOGLE_API_KEY'],
  );
  await revenueCat.init();

  runApp(
    ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(repository),
        aiServiceProvider.overrideWithValue(aiService),
        revenueCatServiceProvider.overrideWithValue(revenueCat),
      ],
      child: const StudyPilotApp(),
    ),
  );
}
