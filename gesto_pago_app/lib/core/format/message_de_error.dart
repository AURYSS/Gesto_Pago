import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../network/app_exception.dart';

/// Traduce un [AppException] a un mensaje humano localizado.
String messageDeError(BuildContext context, AppException error) {
  final l = AppLocalizations.of(context);
  switch (error) {
    case NetworkException():
      return l.errorNetwork;
    case TimeoutException():
      return l.errorTimeout;
    case UnauthorizedException():
      return l.errorUnauthorized;
    case ForbiddenException():
      return l.errorForbidden;
    case NotFoundException():
      return l.errorNotFound;
    case RateLimitException():
      return l.errorRateLimit;
    case ServerException():
      return l.errorServer;
    default:
      final texto = error.message.trim();
      return texto.isEmpty ? l.errorGeneric : texto;
  }
}