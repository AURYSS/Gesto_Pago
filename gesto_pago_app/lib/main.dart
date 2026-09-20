import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/providers/app_providers.dart';
import 'features/auth/application/session_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();
  // Vincula los puentes de red una sola vez: evita las referencias circulares
  // estáticas entre ApiClient y AuthRepository/SessionController.
  container.read(tokenRefresherBridgeProvider).bind(
        () => container.read(authRepositoryProvider),
      );
  container.read(sessionExpiredBridgeProvider).bind(
        () => container.read(sessionControllerProvider.notifier).onSessionExpired(),
      );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const GestoPagoApp(),
    ),
  );
}