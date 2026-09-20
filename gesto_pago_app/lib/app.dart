import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/app_providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/gp_theme.dart';
import 'l10n/app_localizations.dart';

/// Raíz de la aplicación: identidad visual, idiomas y navegación.
class GestoPagoApp extends ConsumerWidget {
  const GestoPagoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Gesto Pago',
      debugShowCheckedModeBanner: false,
      theme: GpTheme.light(),
      darkTheme: GpTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    );
  }
}