import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/gp_colors.dart';
import '../../auth/application/session_controller.dart';
import '../../../../l10n/app_localizations.dart';

/// Pantalla de arranque: restaura la sesión persistida mientras se muestra
/// la marca. El router redirige según el resultado del restore.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sessionControllerProvider.notifier).restore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: GpColors.verde,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(Icons.payments_outlined, size: 52, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              l.appTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l.splashTagline,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l.splashRestoring, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}