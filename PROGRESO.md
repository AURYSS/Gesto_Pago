# Gesto Pago — Progreso y reanudación

Estado guardado el 26-sep-2026. Ambos proyectos están versionados en git
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

## Sesión (26-sep-2026): migración de catálogos y pagos pendientes a BD
- **Backend:**
  - `V7__create_catalogo_marcas.sql`: tablas `catalogo_categorias` y `catalogo_marcas` con semilla de 6 categorías y 51 marcas con logo/color oficial.
  - `CatalogoController`: endpoint `GET /catalogo/marcas` servido vía `CatalogoMarcaConsultaImpl` (JdbcTemplate). Test unitario `CatalogoMarcaConsultaImplTest`.
  - `PagosServiceImpl.pendientes`: consulta transacciones reales del usuario (`PENDIENTE`, `EN_PROCESO`, `FALLIDA`) ordenadas por fecha descendente.
  - `PagosController`: nuevo endpoint `GET /pagos/pendientes` autenticado por JWT. Test ampliado en `PagosServiceImplTest`.
- **Flutter:**
  - `CatalogoMarca`, `CatalogoCategoria` y agregación `CatalogoMarcas` en el dominio con resolución dinámica de marcas, logos y colores oficiales.
  - Eliminado catálogo estático `gp_marcas.dart` y mapas estáticos en `GpAssets`. `GpCategoria` reemplazado por datos dinámicos.
  - `MarcasController` y `PendientesController` implementados como `AsyncNotifier` reactivos con soporte de `refresh()`.
  - `BrandMark` y `ServiceCard` reciben directamente los assets/colores desde el modelo de datos.
  - `PendingPaymentItem` muestra insignias de estado real (`EstadoTransaccionBadge`) y botones de acción dinámicos (Confirmar, Reintentar, Pagar).
  - l10n actualizado y regenerado (eliminadas claves obsoletas de vencimiento).
  - Fixture `marcas_catalogo.json` y tests unitarios verificando resolución de marcas y existencia de todos los logos en disco.

## Hecho y verificado (todo en verde)
- Backend: `sh gradlew compileJava` OK; suite completa de tests de service en verde con:
  `sh gradlew test --tests "com.proyecto.servicios.service.Impl.*"`
- Flutter: `flutter analyze` 0 issues; `flutter test` 102/102 tests en verde.

## Pendiente (próxima sesión)
- E2E real requiere levantar infra con docker compose (Postgres :5434, Redis :6379).
- Icono de app / splash nativo / pulido Android.
- Probar el flujo completo login→catálogo→pago→comprobante con transacciones pendientes en vivo.
- En web/iOS el almacenamiento seguro se comporta distinto; verificar persistencia de sesión entre recargas.

## Comandos útiles
- Backend (desde `api-gesto-pago`): `sh gradlew compileJava`, `sh gradlew test --tests ...` (el wrapper no es ejecutable; usar `sh gradlew`).
- Flutter (desde `gesto_pago_app`): `flutter gen-l10n`, `flutter analyze`, `flutter test`, `flutter build apk --debug`.
- Web (app + API en la misma Mac): API `sh gradlew bootRun`; app `CHROME_EXECUTABLE="..." flutter run -d chrome --web-port=3000`.
- Android emulador: `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080`.

## Claves del diseño implementado
- El subject del JWT es el **email**; PagosController resuelve email→`usuario_id`.
- Catálogo de marcas y categorías reside en Postgres (`catalogo_marcas`, `catalogo_categorias`) y se expone en `GET /catalogo/marcas`.
- Pagos pendientes salen de `transacciones` reales del usuario (`GET /pagos/pendientes`), mapeadas a `PagoPendiente` con flags `puedeConfirmar` y `puedeReintentar`.
- Idempotencia por usuario: `UNIQUE(usuario_id, idempotency_key)`; upc = clave (3–15) o SHA-256 truncado; reintento tras FALLIDA reutiliza la fila; advisory lock serializa concurrentes.
- Envío: sendTx fallo de red → EN_PROCESO (confirmable tras `gestopago.confirm-wait-seconds`, default 62); confirm 06/01 → APROBADA, 70 → FALLIDA; códigos 01/06 → APROBADA, 82 → EN_PROCESO, resto FALLIDA.
- Flutter: `TokenRefresherBridge` y `SessionExpiredBridge` (enlazados en `main.dart`) rompen los ciclos `apiClientProvider`↔`authRepositoryProvider`/`SessionController`.
- Los providers de repositorio se definen UNA sola vez en `lib/core/providers/app_providers.dart` (no duplicarlos en cada feature).
- TipoFront: 1 = precio final (recargas, monto del catálogo); 2 = pago de servicio (monto editable, verificar referencia antes).