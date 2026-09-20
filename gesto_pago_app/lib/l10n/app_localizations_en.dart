// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Gesto Pago';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonSave => 'Save';

  @override
  String get commonClose => 'Close';

  @override
  String get commonBack => 'Back';

  @override
  String get commonDone => 'Done';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNetwork =>
      'Unable to reach the server. Check your connection.';

  @override
  String get errorTimeout =>
      'The server took too long to respond. Please try again.';

  @override
  String get errorUnauthorized =>
      'Your session has expired. Please log in again.';

  @override
  String get errorForbidden =>
      'You don\'t have permission to perform this action.';

  @override
  String get errorNotFound => 'The requested information was not found.';

  @override
  String get errorRateLimit => 'Too many attempts. Please try again shortly.';

  @override
  String get errorServer => 'Server error. Please try again later.';

  @override
  String get splashTagline => 'Pay your services in one place';

  @override
  String get splashRestoring => 'Restoring your session...';

  @override
  String get loginTitle => 'Welcome back';

  @override
  String get loginSubtitle => 'Sign in to pay your services';

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginEmailRequired => 'Enter your email';

  @override
  String get loginEmailInvalid => 'Invalid email';

  @override
  String get loginPasswordRequired => 'Enter your password';

  @override
  String get loginButton => 'Sign in';

  @override
  String get loginInvalidCredentials => 'Invalid email or password.';

  @override
  String get loginGenericError => 'Unable to sign in. Please try again.';

  @override
  String get loginNoAccount => 'Don\'t have an account?';

  @override
  String get loginCreateAccount => 'Create account';

  @override
  String get registerTitle => 'Create account';

  @override
  String get registerSubtitle => 'Register to get started';

  @override
  String get registerNameLabel => 'Full name';

  @override
  String get registerEmailLabel => 'Email';

  @override
  String get registerPasswordLabel => 'Password';

  @override
  String get registerConfirmPasswordLabel => 'Confirm password';

  @override
  String get registerNameRequired => 'Enter your name';

  @override
  String get registerPasswordTooShort => 'Use at least 6 characters';

  @override
  String get registerButton => 'Create account';

  @override
  String get registerPasswordMismatch => 'Passwords do not match.';

  @override
  String get registerAlreadyHaveAccount => 'Already have an account?';

  @override
  String get registerSignIn => 'Sign in';

  @override
  String get registerGenericError =>
      'Unable to create the account. Please try again.';

  @override
  String get homeWelcome => 'What would you like to pay today?';

  @override
  String homeGreeting(Object nombre) {
    return 'Hi, $nombre!';
  }

  @override
  String get navInicio => 'Home';

  @override
  String get navHistorial => 'History';

  @override
  String get navPerfil => 'Profile';

  @override
  String get homeCatalog => 'Services';

  @override
  String get homeProfile => 'Profile';

  @override
  String get catalogTitle => 'Services';

  @override
  String get catalogAll => 'All';

  @override
  String get catalogSearchHint => 'Search services...';

  @override
  String get catalogEmpty => 'No services available.';

  @override
  String get catalogPrice => 'Price';

  @override
  String get catalogCommission => 'Commission';

  @override
  String get catalogDetails => 'Service details';

  @override
  String get catalogReferenceTypeA => 'Mobile number';

  @override
  String get catalogReferenceTypeB => 'Customer / contract number';

  @override
  String get catalogReferenceTypeC => 'Barcode / reference';

  @override
  String get catalogReferenceDefault => 'Reference';

  @override
  String get catalogDigitoVerificador => 'Check digit';

  @override
  String get catalogHelp => 'Help';

  @override
  String get catalogError => 'Unable to load the catalog.';

  @override
  String get pagoReferenceLabel => 'Reference';

  @override
  String get pagoReferenceHint => 'e.g. 6241234567';

  @override
  String get pagoReferenceRequired => 'Enter the reference';

  @override
  String get pagoServicioNoDisponible => 'This service is not available.';

  @override
  String get pagoAmountLabel => 'Amount to pay';

  @override
  String get pagoAmountHint => '0.00';

  @override
  String get pagoServiceLabel => 'Service';

  @override
  String get pagoVerifyReference => 'Verify reference';

  @override
  String get pagoVerifying => 'Verifying reference...';

  @override
  String get pagoVerifyValid => 'Valid reference';

  @override
  String pagoValidReferenceMessage(Object saldo) {
    return 'Valid reference. Balance: $saldo.';
  }

  @override
  String get pagoVerifyInvalid => 'Invalid reference. Check it and try again.';

  @override
  String get pagoVerifyError => 'Unable to verify the reference.';

  @override
  String get pagoInvalidAmount => 'Enter a valid amount.';

  @override
  String get pagoConfirmTitle => 'Confirm payment';

  @override
  String pagoConfirmMessage(Object amount, Object reference, Object service) {
    return 'You are about to pay $service reference $reference for $amount. Confirm that the data is correct.';
  }

  @override
  String get pagoConfirmService => 'Service';

  @override
  String get pagoConfirmReference => 'Reference';

  @override
  String get pagoConfirmAmount => 'Amount';

  @override
  String get pagoConfirmButton => 'Pay now';

  @override
  String get pagoEnviado =>
      'Payment sent. Waiting for provider confirmation...';

  @override
  String get pagoProcessing =>
      'Processing payment... You will be able to check the result at any time from your history.';

  @override
  String get pagoCheckingResult => 'Checking result with the provider...';

  @override
  String get pagoSuccess => 'Payment completed successfully';

  @override
  String get pagoAuthorization => 'Authorization';

  @override
  String get pagoTransactionId => 'Transaction';

  @override
  String get pagoFailed => 'The payment was not completed';

  @override
  String get pagoPending =>
      'Payment in process. We will confirm it with the provider.';

  @override
  String get pagoReceipt => 'Receipt';

  @override
  String get pagoSeeHistory => 'View history';

  @override
  String get pagoDoNotDoubleSubmit => 'Please wait, do not close the app.';

  @override
  String get comprobanteTitle => 'Payment receipt';

  @override
  String get comprobanteFecha => 'Date';

  @override
  String get comprobanteEstado => 'Status';

  @override
  String get comprobanteVolverInicio => 'Back to home';

  @override
  String get historialTitle => 'Payment history';

  @override
  String get historialEmpty => 'No payments yet.';

  @override
  String get historialError => 'Unable to load history.';

  @override
  String get historialFecha => 'Date';

  @override
  String get historialVerComprobante => 'View receipt';

  @override
  String get historialStateApproved => 'Approved';

  @override
  String get historialStateFailed => 'Failed';

  @override
  String get historialStateProcessing => 'In process';

  @override
  String get historialStatePending => 'Pending';

  @override
  String get perfilTitle => 'Profile';

  @override
  String get perfilName => 'Name';

  @override
  String get perfilEmail => 'Email';

  @override
  String get perfilEdit => 'Edit profile data';

  @override
  String get perfilPersonaName => 'Name';

  @override
  String get perfilPersonaPaternal => 'Paternal last name';

  @override
  String get perfilPersonaMaternal => 'Maternal last name';

  @override
  String get perfilSaveSuccess => 'Profile data saved correctly.';

  @override
  String get perfilTheme => 'Appearance';

  @override
  String get perfilThemeSystem => 'System';

  @override
  String get perfilThemeLight => 'Light';

  @override
  String get perfilThemeDark => 'Dark';

  @override
  String get perfilLogout => 'Sign out';

  @override
  String get perfilLogoutConfirm => 'Sign out?';

  @override
  String get perfilLogoutConfirmMessage =>
      'You will need your password to sign back in.';
}
