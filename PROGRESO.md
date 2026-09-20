# Gesto Pago — Progreso y reanudación

Estado guardado el 19-sep-2026 (noche). Ambos proyectos están versionados en git
y listos para apagar la máquina. Esta nota sirve para retomar la sesión.

## Repos
- Backend:  `/Volumes/RespaldoMacbook/UTNG/GP/api-gesto-pago` (rama `feature/auth-jwt`)
  - `085c51e` feat(auth): registro de usuarios POST /auth/register
  - `b254956` feat(pagos): modulo de pagos GestoPago (verificar referencia, enviar y confirmar transaccion)
  - `e08768f` feat(auth): autenticacion JWT, roles, rate limiting y sincronizacion de catalogo (previo)
- App Flutter: `/Volumes/RespaldoMacbook/UTNG/GP/gesto_pago_app`
  - `2f3edf5` feat(app): Gesto Pago completo — auth, catalogo, pagos, historial, perfil, l10n y tests
- **Repo único (para subir a GitHub):** `/Volumes/RespaldoMacbook/UTNG/GestoPago_v2`
  - Contiene `gesto_pago_app/` + `api-gesto-pago/` + `PROGRESO.md` en UN solo git (`main`).
  - Commit inicial `7e3789d` (296 archivos, solo código sin artefactos). Falta crear repo en GitHub y `git remote add origin <URL>` + `git push -u origin main`.
  - El `.env` con credenciales está copiado localmente pero **gitignored**.

## Última sesión (19-sep-2026): login E2E funcionando en Chrome
- **Login ya funciona de punta a punta** en web: `CHROME_EXECUTABLE="/Volumes/RespaldoMacbook/Google Chrome.app/Contents/MacOS/Google Chrome" flutter run -d chrome --web-port=3000` (Chrome vive en el disco externo; `--web-port=3000` coincide con el origen CORS permitido `http://localhost:3000`). API en `sh gradlew bootRun` (IntelliJ, :8080). Usuario: `admin@prueba.com`.
- **Causa raíz de los errores genéricos:** Dio 5.11 envuelve en `DioException` (con original en `.error`) todo lo que lanzan los interceptores → ninguna `AppException` llegaba a los catches. Fix: `ApiClient.unwrap()` centraliza el desempaquetado y los 4 `*_remote` relanzan `throw ApiClient.unwrap(e)`. Test `test/core/network/unwrap_error_test.dart`.
- **Bug de providers duplicados:** en `session_controller`, `catalogo_controller` y `pago_controller` había `authRepositoryProvider`/`catalogoRepositoryProvider`/`pagosRepositoryProvider` locales que lanzaban `UnimplementedError` y tapaban los reales de `app_providers.dart` → pantallas en blanco o "error inesperado". Eliminados los duplicados.
- **Ciclo Riverpod roto:** `apiClientProvider` ya no depende de `sessionControllerProvider`; `SessionExpiredBridge` + `SessionExpiredBridgeProvider` (enlazado en `main.dart`) entrega `onSessionExpired`, igual que `TokenRefresherBridge`.
- **Inicio/perfil:** `catalogo` ya se resuelve; `_TarjetaSeccion` de perfil ahora envuelve sus hijos en `Material(color: transparent)` para silenciar la aserción "ListTile background color or ink splashes may be invisible".
- Extras previos de la sesión: `restore()` de splash con try/catch + tests; `ConfigDB` con `?` scan de repos/entities `pago`.

## Hecho y verificado (todo en verde)
- Backend: `sh gradlew compileJava` OK; 37 unit tests OK con:
  `sh gradlew test --tests "com.proyecto.servicios.service.Impl.*" --tests "com.proyecto.servicios.config.security.*" --tests "com.proyecto.servicios.service.security.*"`
- Flutter: `flutter analyze` 0 issues; `flutter test` 22/22 (con el test nuevo de unwrap);
  `flutter build apk --debug` generó `build/app/outputs/flutter-apk/app-debug.apk` (previo).

## Pendiente (próxima sesión)
- E2E real requiere levantar infra con docker compose (Postgres :5434, Redis :6379).
- Icono de app / splash nativo / pulido Android.
- Probar el flujo completo login→catálogo→pago→comprobante (catálogo llega del backend GestoPago getProductList).
- En web/iOS el almacenamiento seguro se comporta distinto; verificar persistencia de sesión entre recargas.

## Comandos útiles
- Backend (desde `api-gesto-pago`): `sh gradlew compileJava`, `sh gradlew test --tests ...` (el wrapper no es ejecutable; usar `sh gradlew`).
- Flutter (desde `gesto_pago_app`): `flutter gen-l10n`, `flutter analyze`, `flutter test`, `flutter build apk --debug`.
- Web (app + API en la misma Mac): API `sh gradlew bootRun`; app `CHROME_EXECUTABLE="..." flutter run -d chrome --web-port=3000`.
- Android emulador: `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080`.

## Claves del diseño implementado
- El subject del JWT es el **email**; PagosController resuelve email→`usuario_id`.
- Idempotencia por usuario: `UNIQUE(usuario_id, idempotency_key)`; upc = clave (3–15) o SHA-256 truncado; reintento tras FALLIDA reutiliza la fila; advisory lock serializa concurrentes.
- Envío: sendTx fallo de red → EN_PROCESO (confirmable tras `gestopago.confirm-wait-seconds`, default 62); confirm 06/01 → APROBADA, 70 → FALLIDA; códigos 01/06 → APROBADA, 82 → EN_PROCESO, resto FALLIDA.
- Flutter: `TokenRefresherBridge` y `SessionExpiredBridge` (enlazados en `main.dart`) rompen los ciclos `apiClientProvider`↔`authRepositoryProvider`/`SessionController`.
- Los providers de repositorio se definen UNA sola vez en `lib/core/providers/app_providers.dart` (no duplicarlos en cada feature).
- TipoFront: 1 = precio final (recargas, monto del catálogo); 2 = pago de servicio (monto editable, verificar referencia antes).