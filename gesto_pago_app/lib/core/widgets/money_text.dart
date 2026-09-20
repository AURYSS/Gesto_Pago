import 'package:flutter/material.dart';

import '../format/gp_money.dart';

/// Texto monetario con el símbolo $ y notación es_MX.
class MoneyText extends StatelessWidget {
  const MoneyText({
    super.key,
    required this.monto,
    this.style,
    this.negritas = false,
  });

  final String monto;
  final TextStyle? style;
  final bool negritas;

  @override
  Widget build(BuildContext context) {
    final baseStyle =
        style ?? (Theme.of(context).textTheme.bodyLarge ?? const TextStyle());
    return Text(
      GpMoney.format(monto),
      style: negritas
          ? baseStyle.copyWith(fontWeight: FontWeight.w700)
          : baseStyle,
    );
  }
}