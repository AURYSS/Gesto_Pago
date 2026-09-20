# Gesto Pago — Progreso y reanudación

Estado guardado el 19-sep-2026. Ambos proyectos están versionados en git
y listos para apagar la máquina. Esta nota sirve para retomar la sesión.

## Repos
- Backend:  `/Volumes/RespaldoMacbook/UTNG/GP/api-gesto-pago` (rama `feature/auth-jwt`)
  - `085c51e` feat(auth): registro de usuarios POST /auth/register
  - `b254956` feat(pagos): modulo de pagos GestoPago (verificar referencia, enviar y confirmar transaccion)
  - `e08768f` feat(auth): autenticacion JWT, roles, rate limiting y sincronizacion de catalogo (previo)
- App Flutter: `/Volumes/RespaldoMacbook/UTNG/GP/gesto_pago_app`
  - `2f3edf5` feat(app): Gesto Pago completo — auth, catalogo, pagos, historial, perfil, l10n y tests

## Hecho y verificado (todo en verde)
- Backend: `sh gradlew compileJava` OK; 37 unit tests OK con:
  `sh gradlew test --tests "com.proyecto.servicios.service.Impl.*" --tests "com.proyecto.servicios.config.security.*" --tests "com.proyecto.servicios.service.security.*"`
- Flutter: `flutter analyze` 0 issues; `flutter test` 15/15;
  `flutter build apk --debug` generó `build/app/outputs/flutter-apk/app-debug.apk`.

## Pendiente (próxima sesión)
- E2E real requiere levantar infra con docker compose (Postgres :5434, Redis :6379).
- Icono de app / splash nativo / pulido Android.
- El catálogo llega del backend (GestoPago getProductList). Probar login→catálogo→pago→comprobante.

## Comandos útiles
- Backend (desde `api-gesto-pago`): `sh gradlew compileJava`, `sh gradlew test --tests ...` (el wrapper no es ejecutable; usar `sh gradlew`).
- Flutter (desde `gesto_pago_app`): `flutter gen-l10n`, `flutter analyze`, `flutter test`, `flutter build apk --debug`.

## Claves del diseño implementado
- El subject del JWT es el **email**; PagosController resuelve email→`usuario_id`.
- Idempotencia por usuario: `UNIQUE(usuario_id, idempotency_key)`; upc = clave (3–15) o SHA-256 truncado; reintento tras FALLIDA reutiliza la fila; advisory lock serializa concurrentes.
- Envío: sendTx fallo de red → EN_PROCESO (confirmable tras `gestopago.confirm-wait-seconds`, default 62); confirm 06/01 → APROBADA, 70 → FALLIDA; códigos 01/06 → APROBADA, 82 → EN_PROCESO, resto FALLIDA.
- Flutter: `TokenRefresherBridge` (enlace en `main.dart`) rompe el ciclo `apiClientProvider`↔`authRepositoryProvider`.
- TipoFront: 1 = precio final (recargas, monto del catálogo); 2 = pago de servicio (monto editable, verificar referencia antes).