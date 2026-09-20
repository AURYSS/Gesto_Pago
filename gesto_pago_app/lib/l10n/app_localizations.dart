import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Gesto Pago'**
  String get appTitle;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get commonLoading;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Unable to reach the server. Check your connection.'**
  String get errorNetwork;

  /// No description provided for @errorTimeout.
  ///
  /// In en, this message translates to:
  /// **'The server took too long to respond. Please try again.'**
  String get errorTimeout;

  /// No description provided for @errorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please log in again.'**
  String get errorUnauthorized;

  /// No description provided for @errorForbidden.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to perform this action.'**
  String get errorForbidden;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'The requested information was not found.'**
  String get errorNotFound;

  /// No description provided for @errorRateLimit.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again shortly.'**
  String get errorRateLimit;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get errorServer;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Pay your services in one place'**
  String get splashTagline;

  /// No description provided for @splashRestoring.
  ///
  /// In en, this message translates to:
  /// **'Restoring your session...'**
  String get splashRestoring;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to pay your services'**
  String get loginSubtitle;

  /// No description provided for @loginEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginEmailLabel;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordLabel;

  /// No description provided for @loginEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get loginEmailRequired;

  /// No description provided for @loginEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get loginEmailInvalid;

  /// No description provided for @loginPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get loginPasswordRequired;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginButton;

  /// No description provided for @loginInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get loginInvalidCredentials;

  /// No description provided for @loginGenericError.
  ///
  /// In en, this message translates to:
  /// **'Unable to sign in. Please try again.'**
  String get loginGenericError;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get loginNoAccount;

  /// No description provided for @loginCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get loginCreateAccount;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Register to get started'**
  String get registerSubtitle;

  /// No description provided for @registerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get registerNameLabel;

  /// No description provided for @registerEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get registerEmailLabel;

  /// No description provided for @registerPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get registerPasswordLabel;

  /// No description provided for @registerConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get registerConfirmPasswordLabel;

  /// No description provided for @registerNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get registerNameRequired;

  /// No description provided for @registerPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 6 characters'**
  String get registerPasswordTooShort;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerButton;

  /// No description provided for @registerPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get registerPasswordMismatch;

  /// No description provided for @registerAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get registerAlreadyHaveAccount;

  /// No description provided for @registerSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get registerSignIn;

  /// No description provided for @registerGenericError.
  ///
  /// In en, this message translates to:
  /// **'Unable to create the account. Please try again.'**
  String get registerGenericError;

  /// No description provided for @homeWelcome.
  ///
  /// In en, this message translates to:
  /// **'What would you like to pay today?'**
  String get homeWelcome;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi, {nombre}!'**
  String homeGreeting(Object nombre);

  /// No description provided for @navInicio.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navInicio;

  /// No description provided for @navHistorial.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistorial;

  /// No description provided for @navPerfil.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navPerfil;

  /// No description provided for @homeCatalog.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get homeCatalog;

  /// No description provided for @homeProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get homeProfile;

  /// No description provided for @catalogTitle.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get catalogTitle;

  /// No description provided for @catalogAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get catalogAll;

  /// No description provided for @catalogSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search services...'**
  String get catalogSearchHint;

  /// No description provided for @catalogEmpty.
  ///
  /// In en, this message translates to:
  /// **'No services available.'**
  String get catalogEmpty;

  /// No description provided for @catalogPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get catalogPrice;

  /// No description provided for @catalogCommission.
  ///
  /// In en, this message translates to:
  /// **'Commission'**
  String get catalogCommission;

  /// No description provided for @catalogDetails.
  ///
  /// In en, this message translates to:
  /// **'Service details'**
  String get catalogDetails;

  /// No description provided for @catalogReferenceTypeA.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get catalogReferenceTypeA;

  /// No description provided for @catalogReferenceTypeB.
  ///
  /// In en, this message translates to:
  /// **'Customer / contract number'**
  String get catalogReferenceTypeB;

  /// No description provided for @catalogReferenceTypeC.
  ///
  /// In en, this message translates to:
  /// **'Barcode / reference'**
  String get catalogReferenceTypeC;

  /// No description provided for @catalogReferenceDefault.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get catalogReferenceDefault;

  /// No description provided for @catalogDigitoVerificador.
  ///
  /// In en, this message translates to:
  /// **'Check digit'**
  String get catalogDigitoVerificador;

  /// No description provided for @catalogHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get catalogHelp;

  /// No description provided for @catalogError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load the catalog.'**
  String get catalogError;

  /// No description provided for @pagoReferenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get pagoReferenceLabel;

  /// No description provided for @pagoReferenceHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 6241234567'**
  String get pagoReferenceHint;

  /// No description provided for @pagoReferenceRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the reference'**
  String get pagoReferenceRequired;

  /// No description provided for @pagoServicioNoDisponible.
  ///
  /// In en, this message translates to:
  /// **'This service is not available.'**
  String get pagoServicioNoDisponible;

  /// No description provided for @pagoAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount to pay'**
  String get pagoAmountLabel;

  /// No description provided for @pagoAmountHint.
  ///
  /// In en, this message translates to:
  /// **'0.00'**
  String get pagoAmountHint;

  /// No description provided for @pagoServiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get pagoServiceLabel;

  /// No description provided for @pagoVerifyReference.
  ///
  /// In en, this message translates to:
  /// **'Verify reference'**
  String get pagoVerifyReference;

  /// No description provided for @pagoVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying reference...'**
  String get pagoVerifying;

  /// No description provided for @pagoVerifyValid.
  ///
  /// In en, this message translates to:
  /// **'Valid reference'**
  String get pagoVerifyValid;

  /// No description provided for @pagoValidReferenceMessage.
  ///
  /// In en, this message translates to:
  /// **'Valid reference. Balance: {saldo}.'**
  String pagoValidReferenceMessage(Object saldo);

  /// No description provided for @pagoVerifyInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid reference. Check it and try again.'**
  String get pagoVerifyInvalid;

  /// No description provided for @pagoVerifyError.
  ///
  /// In en, this message translates to:
  /// **'Unable to verify the reference.'**
  String get pagoVerifyError;

  /// No description provided for @pagoInvalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount.'**
  String get pagoInvalidAmount;

  /// No description provided for @pagoConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm payment'**
  String get pagoConfirmTitle;

  /// No description provided for @pagoConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'You are about to pay {service} reference {reference} for {amount}. Confirm that the data is correct.'**
  String pagoConfirmMessage(Object amount, Object reference, Object service);

  /// No description provided for @pagoConfirmService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get pagoConfirmService;

  /// No description provided for @pagoConfirmReference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get pagoConfirmReference;

  /// No description provided for @pagoConfirmAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get pagoConfirmAmount;

  /// No description provided for @pagoConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Pay now'**
  String get pagoConfirmButton;

  /// No description provided for @pagoEnviado.
  ///
  /// In en, this message translates to:
  /// **'Payment sent. Waiting for provider confirmation...'**
  String get pagoEnviado;

  /// No description provided for @pagoProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing payment... You will be able to check the result at any time from your history.'**
  String get pagoProcessing;

  /// No description provided for @pagoCheckingResult.
  ///
  /// In en, this message translates to:
  /// **'Checking result with the provider...'**
  String get pagoCheckingResult;

  /// No description provided for @pagoSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment completed successfully'**
  String get pagoSuccess;

  /// No description provided for @pagoAuthorization.
  ///
  /// In en, this message translates to:
  /// **'Authorization'**
  String get pagoAuthorization;

  /// No description provided for @pagoTransactionId.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get pagoTransactionId;

  /// No description provided for @pagoFailed.
  ///
  /// In en, this message translates to:
  /// **'The payment was not completed'**
  String get pagoFailed;

  /// No description provided for @pagoPending.
  ///
  /// In en, this message translates to:
  /// **'Payment in process. We will confirm it with the provider.'**
  String get pagoPending;

  /// No description provided for @pagoReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get pagoReceipt;

  /// No description provided for @pagoSeeHistory.
  ///
  /// In en, this message translates to:
  /// **'View history'**
  String get pagoSeeHistory;

  /// No description provided for @pagoDoNotDoubleSubmit.
  ///
  /// In en, this message translates to:
  /// **'Please wait, do not close the app.'**
  String get pagoDoNotDoubleSubmit;

  /// No description provided for @comprobanteTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment receipt'**
  String get comprobanteTitle;

  /// No description provided for @comprobanteFecha.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get comprobanteFecha;

  /// No description provided for @comprobanteEstado.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get comprobanteEstado;

  /// No description provided for @comprobanteVolverInicio.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get comprobanteVolverInicio;

  /// No description provided for @historialTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment history'**
  String get historialTitle;

  /// No description provided for @historialEmpty.
  ///
  /// In en, this message translates to:
  /// **'No payments yet.'**
  String get historialEmpty;

  /// No description provided for @historialError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load history.'**
  String get historialError;

  /// No description provided for @historialFecha.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get historialFecha;

  /// No description provided for @historialVerComprobante.
  ///
  /// In en, this message translates to:
  /// **'View receipt'**
  String get historialVerComprobante;

  /// No description provided for @historialStateApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get historialStateApproved;

  /// No description provided for @historialStateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get historialStateFailed;

  /// No description provided for @historialStateProcessing.
  ///
  /// In en, this message translates to:
  /// **'In process'**
  String get historialStateProcessing;

  /// No description provided for @historialStatePending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get historialStatePending;

  /// No description provided for @perfilTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get perfilTitle;

  /// No description provided for @perfilName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get perfilName;

  /// No description provided for @perfilEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get perfilEmail;

  /// No description provided for @perfilEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit profile data'**
  String get perfilEdit;

  /// No description provided for @perfilPersonaName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get perfilPersonaName;

  /// No description provided for @perfilPersonaPaternal.
  ///
  /// In en, this message translates to:
  /// **'Paternal last name'**
  String get perfilPersonaPaternal;

  /// No description provided for @perfilPersonaMaternal.
  ///
  /// In en, this message translates to:
  /// **'Maternal last name'**
  String get perfilPersonaMaternal;

  /// No description provided for @perfilSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile data saved correctly.'**
  String get perfilSaveSuccess;

  /// No description provided for @perfilTheme.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get perfilTheme;

  /// No description provided for @perfilThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get perfilThemeSystem;

  /// No description provided for @perfilThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get perfilThemeLight;

  /// No description provided for @perfilThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get perfilThemeDark;

  /// No description provided for @perfilLogout.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get perfilLogout;

  /// No description provided for @perfilLogoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get perfilLogoutConfirm;

  /// No description provided for @perfilLogoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'You will need your password to sign back in.'**
  String get perfilLogoutConfirmMessage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
