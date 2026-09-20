import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/gp_money.dart';
import '../../../core/format/message_de_error.dart';
import '../../../core/theme/gp_colors.dart';
import '../../../core/theme/gp_theme.dart';
import '../../../core/widgets/money_text.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalogo/application/catalogo_controller.dart';
import '../../catalogo/domain/catalogo_producto.dart';
import '../application/pago_controller.dart';

/// Captura los datos del pago, verifica contra el proveedor y lo ejecuta.
class PagoScreen extends ConsumerStatefulWidget {
  const PagoScreen({super.key, required this.idServicio, required this.idProducto});

  final int idServicio;
  final int idProducto;

  @override
  ConsumerState<PagoScreen> createState() => _PagoScreenState();
}

class _PagoScreenState extends ConsumerState<PagoScreen> {
  final _referenciaController = TextEditingController();
  final _montoController = TextEditingController();

  @override
  void dispose() {
    _referenciaController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  CatalogoProducto? _producto(BuildContext context) {
    final catalogo = ref.watch(catalogoControllerProvider).value;
    if (catalogo == null) {
      return null;
    }
    for (final p in catalogo) {
      if (p.idServicio == widget.idServicio && p.idProducto == widget.idProducto) {
        return p;
      }
    }
    return null;
  }

  Future<void> _verificar() async {
    final l = AppLocalizations.of(context);
    final producto = _producto(context);
    if (producto == null) {
      return;
    }
    final referencia = _referenciaController.text.trim();
    if (referencia.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.pagoReferenceRequired)),
      );
      return;
    }
    await ref.read(pagoControllerProvider.notifier).verificarReferencia(
          producto: producto,
          referencia: referencia,
        );
    final estado = ref.read(pagoControllerProvider);
    if (estado.verificacion?.valida == true && estado.verificacion?.monto != null) {
      if (_montoController.text.trim().isEmpty) {
        _montoController.text = GpMoney.sanitizarEntrada(estado.verificacion!.monto!);
      }
    }
  }

  Future<void> _pagar() async {
    final l = AppLocalizations.of(context);
    final producto = _producto(context);
    if (producto == null) {
      return;
    }
    final referencia = _referenciaController.text.trim();
    if (referencia.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.pagoReferenceRequired)),
      );
      return;
    }

    final monto = producto.esPagoServicio ? _montoController.text.trim() : producto.precio;
    if (monto.isEmpty || (double.tryParse(monto) ?? 0) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.pagoInvalidAmount)),
      );
      return;
    }

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.pagoConfirmTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.pagoConfirmMessage(
                producto.producto,
                referencia,
                GpMoney.format(monto),
              ),
            ),
            const SizedBox(height: 8),
            _Fila(label: l.pagoConfirmService, valor: producto.servicio),
            _Fila(label: l.pagoConfirmReference, valor: referencia),
            _Fila(label: l.pagoConfirmAmount, valor: GpMoney.format(monto)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.pagoConfirmButton),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) {
      return;
    }

    // Pantalla de proceso no cerrable: el envío no debe interrumpirse.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ProcesandoDialog(),
    );

    await ref.read(pagoControllerProvider.notifier).pagar(
          producto: producto,
          referencia: referencia,
          monto: monto,
        );

    if (mounted) {
      Navigator.of(context).pop();
    }
    final estado = ref.read(pagoControllerProvider);
    if (estado.transaccion != null && mounted) {
      context.go('/comprobante/${estado.transaccion!.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final catalogo = ref.watch(catalogoControllerProvider);
    final estado = ref.watch(pagoControllerProvider);
    final producto = _producto(context);

    if (catalogo.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l.pagoConfirmTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (producto == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.pagoConfirmTitle)),
        body: Center(child: Text(l.pagoServicioNoDisponible)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.pagoConfirmTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(GpSpacing.page),
          children: [
            _ProductoHeader(producto: producto),
            const SizedBox(height: 24),
            Text(l.pagoServiceLabel, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            TextField(
              controller: _referenciaController,
              enabled: !estado.estaOcupado,
              keyboardType: TextInputType.number,
              onSubmitted: (_) => _verificar(),
              decoration: InputDecoration(
                labelText: l.pagoReferenceLabel,
                hintText: l.pagoReferenceHint,
              ),
            ),
            const SizedBox(height: 16),
            if (producto.esPagoServicio) ...[
              TextField(
                controller: _montoController,
                enabled: !estado.estaOcupado,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l.pagoAmountLabel,
                  hintText: l.pagoAmountHint,
                  prefixText: r'$ ',
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: estado.estaOcupado ? null : _verificar,
                icon: estado.verificando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.verified_user_outlined),
                label: Text(l.pagoVerifyReference),
              ),
            ],
            _EstadoVerificacion(estado: estado),
            if (estado.error != null) ...[
              const SizedBox(height: 16),
              _ErrorBanner(mensaje: messageDeError(context, estado.error!)),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(GpSpacing.page, 8, GpSpacing.page, 16),
          child: FilledButton.icon(
            onPressed: estado.estaOcupado ? null : _pagar,
            icon: const Icon(Icons.lock_outline),
            label: Text(l.pagoConfirmButton),
          ),
        ),
      ),
    );
  }
}

class _ProductoHeader extends StatelessWidget {
  const _ProductoHeader({required this.producto});

  final CatalogoProducto producto;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(GpSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(GpRadii.tarjeta),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: GpColors.verde.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.payments_outlined, color: scheme.primary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(producto.producto, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(producto.servicio, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                producto.esPrecioFinal ? l.catalogPrice : l.catalogCommission,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              MoneyText(
                monto: producto.precio,
                style: Theme.of(context).textTheme.titleMedium,
                negritas: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EstadoVerificacion extends ConsumerWidget {
  const _EstadoVerificacion({required this.estado});

  final PagoFlowState estado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final verificacion = estado.verificacion;
    if (verificacion == null) {
      return const SizedBox.shrink();
    }
    final valida = verificacion.valida;
    final colorFondo = valida ? GpColors.exitoClaro : GpColors.errorClaro;
    final colorTexto = valida ? GpColors.exito : GpColors.error;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(GpSpacing.md),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(GpRadii.campo),
      ),
      child: Row(
        children: [
          Icon(
            valida ? Icons.check_circle : Icons.cancel,
            color: colorTexto,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              valida
                  ? (l.pagoValidReferenceMessage(verificacion.monto ?? '-'))
                  : l.pagoVerifyInvalid,
              style: TextStyle(color: colorTexto, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProcesandoDialog extends StatelessWidget {
  const _ProcesandoDialog();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(l.pagoEnviado, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            l.pagoDoNotDoubleSubmit,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({required this.label, required this.valor});

  final String label;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Flexible(
            child: Text(valor, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: scheme.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(mensaje, style: TextStyle(color: scheme.error)),
          ),
        ],
      ),
    );
  }
}