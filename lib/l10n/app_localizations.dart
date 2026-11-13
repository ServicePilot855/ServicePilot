import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_km.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('km')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'ServicePilot'**
  String get appName;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get commonOr;

  /// Screen-reader label for a button that is busy.
  ///
  /// In en, this message translates to:
  /// **'{label}, loading'**
  String commonLoading(String label);

  /// Screen-reader label for the step indicator.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String commonStepOf(int step, int total);

  /// Short visible step count beside the step indicator.
  ///
  /// In en, this message translates to:
  /// **'{step} of {total}'**
  String commonStepCount(int step, int total);

  /// No description provided for @commonShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get commonShowPassword;

  /// No description provided for @commonHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get commonHidePassword;

  /// No description provided for @commonLogInLink.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get commonLogInLink;

  /// No description provided for @commonAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get commonAlreadyHaveAccount;

  /// No description provided for @commonBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get commonBackToLogin;

  /// No description provided for @commonYourDetails.
  ///
  /// In en, this message translates to:
  /// **'Your details'**
  String get commonYourDetails;

  /// No description provided for @commonSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get commonSecurity;

  /// No description provided for @commonFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get commonFullNameLabel;

  /// No description provided for @commonEmailAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get commonEmailAddressLabel;

  /// No description provided for @commonPhoneCambodiaLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number (Cambodia)'**
  String get commonPhoneCambodiaLabel;

  /// No description provided for @commonPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get commonPasswordLabel;

  /// No description provided for @commonConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get commonConfirmPasswordLabel;

  /// No description provided for @commonPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Min. 8 characters'**
  String get commonPasswordHint;

  /// No description provided for @commonRepeatPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Repeat your password'**
  String get commonRepeatPasswordHint;

  /// No description provided for @commonFullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get commonFullNameRequired;

  /// No description provided for @commonEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get commonEmailRequired;

  /// No description provided for @commonEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get commonEmailInvalid;

  /// No description provided for @commonPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get commonPhoneRequired;

  /// No description provided for @commonPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Cambodian phone (+855...)'**
  String get commonPhoneInvalid;

  /// No description provided for @commonPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get commonPasswordRequired;

  /// No description provided for @commonPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Must be at least 8 characters'**
  String get commonPasswordMinLength;

  /// No description provided for @commonPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get commonPasswordsDoNotMatch;

  /// No description provided for @commonInvalidLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Invalid or Expired Link'**
  String get commonInvalidLinkTitle;

  /// No description provided for @roleHomeowner.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get roleHomeowner;

  /// No description provided for @roleIndependentProvider.
  ///
  /// In en, this message translates to:
  /// **'Independent Technician'**
  String get roleIndependentProvider;

  /// No description provided for @roleCompany.
  ///
  /// In en, this message translates to:
  /// **'Service Company'**
  String get roleCompany;

  /// No description provided for @roleCompanyTechnician.
  ///
  /// In en, this message translates to:
  /// **'Company Technician'**
  String get roleCompanyTechnician;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Platform Admin'**
  String get roleAdmin;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Home repairs, booked in one place.'**
  String get splashTagline;

  /// No description provided for @splashFootnote.
  ///
  /// In en, this message translates to:
  /// **'Student prototype · Phnom Penh · Sample data only'**
  String get splashFootnote;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to book and track your home services.'**
  String get loginSubtitle;

  /// No description provided for @loginIdentifierLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number or email'**
  String get loginIdentifierLabel;

  /// No description provided for @loginIdentifierHint.
  ///
  /// In en, this message translates to:
  /// **'name@example.com or 012 345 678'**
  String get loginIdentifierHint;

  /// No description provided for @loginIdentifierRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number or email'**
  String get loginIdentifierRequired;

  /// No description provided for @loginPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Your password'**
  String get loginPasswordHint;

  /// No description provided for @loginPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get loginPasswordRequired;

  /// No description provided for @loginPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get loginPasswordMinLength;

  /// No description provided for @loginRememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get loginRememberMe;

  /// No description provided for @loginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get loginForgotPassword;

  /// No description provided for @loginSubmit.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get loginSubmit;

  /// No description provided for @loginGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google (Customer)'**
  String get loginGoogle;

  /// No description provided for @loginNewPrompt.
  ///
  /// In en, this message translates to:
  /// **'New to ServicePilot?'**
  String get loginNewPrompt;

  /// No description provided for @loginCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get loginCreateAccount;

  /// No description provided for @roleSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'How will you use ServicePilot?'**
  String get roleSelectTitle;

  /// No description provided for @roleSelectSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick one. You can create another account later.'**
  String get roleSelectSubtitle;

  /// No description provided for @roleSelectHomeownerTitle.
  ///
  /// In en, this message translates to:
  /// **'Homeowner'**
  String get roleSelectHomeownerTitle;

  /// No description provided for @roleSelectHomeownerDesc.
  ///
  /// In en, this message translates to:
  /// **'Find, book and track home services'**
  String get roleSelectHomeownerDesc;

  /// No description provided for @roleSelectHomeownerContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue as homeowner'**
  String get roleSelectHomeownerContinue;

  /// No description provided for @roleSelectProviderTitle.
  ///
  /// In en, this message translates to:
  /// **'Service provider'**
  String get roleSelectProviderTitle;

  /// No description provided for @roleSelectProviderDesc.
  ///
  /// In en, this message translates to:
  /// **'Accept requests, send quotes, update jobs'**
  String get roleSelectProviderDesc;

  /// No description provided for @roleSelectProviderContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue as service provider'**
  String get roleSelectProviderContinue;

  /// No description provided for @roleSelectCompanyTitle.
  ///
  /// In en, this message translates to:
  /// **'Service company'**
  String get roleSelectCompanyTitle;

  /// No description provided for @roleSelectCompanyDesc.
  ///
  /// In en, this message translates to:
  /// **'Assign technicians to customer bookings'**
  String get roleSelectCompanyDesc;

  /// No description provided for @roleSelectCompanyContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue as service company'**
  String get roleSelectCompanyContinue;

  /// Heading on the placeholder home; name is the user's first name.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String homeGreeting(String name);

  /// No description provided for @homeFallbackName.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get homeFallbackName;

  /// User's full name followed by their company name.
  ///
  /// In en, this message translates to:
  /// **'{name} · {company}'**
  String homeNameWithCompany(String name, String company);

  /// No description provided for @homeSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get homeSignedIn;

  /// No description provided for @homeComingSoonNotice.
  ///
  /// In en, this message translates to:
  /// **'Booking, tracking and provider tools arrive in the next sprint.'**
  String get homeComingSoonNotice;

  /// No description provided for @homeLogOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get homeLogOut;

  /// No description provided for @homeAdminGreeting.
  ///
  /// In en, this message translates to:
  /// **'The platform admin dashboard is coming soon.'**
  String get homeAdminGreeting;

  /// No description provided for @homeCompanyGreeting.
  ///
  /// In en, this message translates to:
  /// **'Your team management and booking overview are coming soon.'**
  String get homeCompanyGreeting;

  /// No description provided for @homeCompanyTechnicianGreeting.
  ///
  /// In en, this message translates to:
  /// **'Your assigned jobs and schedule are coming soon.'**
  String get homeCompanyTechnicianGreeting;

  /// No description provided for @homeCustomerGreeting.
  ///
  /// In en, this message translates to:
  /// **'Your home repair booking dashboard is coming soon.'**
  String get homeCustomerGreeting;

  /// No description provided for @homeTechnicianGreeting.
  ///
  /// In en, this message translates to:
  /// **'Your job board and earnings dashboard are coming soon.'**
  String get homeTechnicianGreeting;

  /// No description provided for @registerContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get registerContinue;

  /// No description provided for @registerPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your password'**
  String get registerPasswordTitle;

  /// Subtitle on the password page of sign-up.
  ///
  /// In en, this message translates to:
  /// **'You will log in with {email} and this password.'**
  String registerPasswordSubtitle(String email);

  /// No description provided for @registerRuleLength.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get registerRuleLength;

  /// No description provided for @registerRuleMatch.
  ///
  /// In en, this message translates to:
  /// **'Both passwords match'**
  String get registerRuleMatch;

  /// No description provided for @registerRuleMet.
  ///
  /// In en, this message translates to:
  /// **'done'**
  String get registerRuleMet;

  /// No description provided for @registerRuleNotMet.
  ///
  /// In en, this message translates to:
  /// **'not yet'**
  String get registerRuleNotMet;

  /// No description provided for @registerOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get registerOk;

  /// No description provided for @registerCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer Registration'**
  String get registerCustomerTitle;

  /// No description provided for @registerCustomerSubmit.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerCustomerSubmit;

  /// No description provided for @registerCustomerHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Book repair services'**
  String get registerCustomerHeaderTitle;

  /// No description provided for @registerCustomerHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account to order fixes and maintenance.'**
  String get registerCustomerHeaderSubtitle;

  /// No description provided for @registerCustomerGoogleButton.
  ///
  /// In en, this message translates to:
  /// **'Sign up with Google'**
  String get registerCustomerGoogleButton;

  /// No description provided for @registerCustomerOrUseEmail.
  ///
  /// In en, this message translates to:
  /// **'or use your email'**
  String get registerCustomerOrUseEmail;

  /// No description provided for @registerCustomerNameHint.
  ///
  /// In en, this message translates to:
  /// **'Sok Dara'**
  String get registerCustomerNameHint;

  /// No description provided for @registerCustomerNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Must be 100 characters or fewer'**
  String get registerCustomerNameTooLong;

  /// No description provided for @registerCustomerEmailHint.
  ///
  /// In en, this message translates to:
  /// **'sok.dara@example.com'**
  String get registerCustomerEmailHint;

  /// No description provided for @registerCustomerPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'+855 12 345 678 or 012 345 678'**
  String get registerCustomerPhoneHint;

  /// No description provided for @registerCustomerSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Created!'**
  String get registerCustomerSuccessTitle;

  /// No description provided for @registerCustomerSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Your homeowner account has been created. You can now log in to browse providers and book services.'**
  String get registerCustomerSuccessMessage;

  /// No description provided for @registerCustomerGoToLogin.
  ///
  /// In en, this message translates to:
  /// **'Go to Login'**
  String get registerCustomerGoToLogin;

  /// No description provided for @registerTechnicianTitle.
  ///
  /// In en, this message translates to:
  /// **'Technician Registration'**
  String get registerTechnicianTitle;

  /// No description provided for @registerTechnicianSubmit.
  ///
  /// In en, this message translates to:
  /// **'Register as Technician'**
  String get registerTechnicianSubmit;

  /// No description provided for @registerTechnicianHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Offer your skills'**
  String get registerTechnicianHeaderTitle;

  /// No description provided for @registerTechnicianHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Register as an independent service provider in Phnom Penh.'**
  String get registerTechnicianHeaderSubtitle;

  /// No description provided for @registerTechnicianNotice.
  ///
  /// In en, this message translates to:
  /// **'Your account will have Pending Verification status until approved by the platform. You will be notified once active.'**
  String get registerTechnicianNotice;

  /// No description provided for @registerTechnicianNameHint.
  ///
  /// In en, this message translates to:
  /// **'Virak Chan'**
  String get registerTechnicianNameHint;

  /// No description provided for @registerTechnicianNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Full name must not exceed 100 characters'**
  String get registerTechnicianNameTooLong;

  /// No description provided for @registerTechnicianEmailHint.
  ///
  /// In en, this message translates to:
  /// **'virak.chan@example.com'**
  String get registerTechnicianEmailHint;

  /// No description provided for @registerTechnicianPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'+855 87 654 321 or 087 654 321'**
  String get registerTechnicianPhoneHint;

  /// No description provided for @registerTechnicianServiceAreaLabel.
  ///
  /// In en, this message translates to:
  /// **'Service Area / Sangkat'**
  String get registerTechnicianServiceAreaLabel;

  /// No description provided for @registerTechnicianServiceAreaHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Toul Kork, Sen Sok, Daun Penh'**
  String get registerTechnicianServiceAreaHint;

  /// No description provided for @registerTechnicianServiceAreaRequired.
  ///
  /// In en, this message translates to:
  /// **'Service area is required'**
  String get registerTechnicianServiceAreaRequired;

  /// No description provided for @registerTechnicianServiceAreaTooLong.
  ///
  /// In en, this message translates to:
  /// **'Service area must not exceed 300 characters'**
  String get registerTechnicianServiceAreaTooLong;

  /// No description provided for @registerTechnicianConfirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get registerTechnicianConfirmPasswordRequired;

  /// No description provided for @registerTechnicianSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending Review'**
  String get registerTechnicianSuccessTitle;

  /// No description provided for @registerTechnicianSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Your independent technician account has been submitted! Our team checks provider skills and IDs before activating bookings.'**
  String get registerTechnicianSuccessMessage;

  /// No description provided for @registerCompanyTitle.
  ///
  /// In en, this message translates to:
  /// **'Company Registration'**
  String get registerCompanyTitle;

  /// No description provided for @registerCompanySubmit.
  ///
  /// In en, this message translates to:
  /// **'Register Company'**
  String get registerCompanySubmit;

  /// No description provided for @registerCompanyHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your team'**
  String get registerCompanyHeaderTitle;

  /// No description provided for @registerCompanyHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Register your repair or maintenance company on ServicePilot.'**
  String get registerCompanyHeaderSubtitle;

  /// No description provided for @registerCompanyNotice.
  ///
  /// In en, this message translates to:
  /// **'Company accounts undergo business verification before receiving customer bookings. We check registration and contact details.'**
  String get registerCompanyNotice;

  /// No description provided for @registerCompanyDetailsSection.
  ///
  /// In en, this message translates to:
  /// **'Company details'**
  String get registerCompanyDetailsSection;

  /// No description provided for @registerCompanyOwnerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Owner / Admin Full Name'**
  String get registerCompanyOwnerNameLabel;

  /// No description provided for @registerCompanyOwnerNameHint.
  ///
  /// In en, this message translates to:
  /// **'Sophea Lim'**
  String get registerCompanyOwnerNameHint;

  /// No description provided for @registerCompanyOwnerNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Owner full name is required'**
  String get registerCompanyOwnerNameRequired;

  /// No description provided for @registerCompanyNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Company Name'**
  String get registerCompanyNameLabel;

  /// No description provided for @registerCompanyNameHint.
  ///
  /// In en, this message translates to:
  /// **'CoolAir Service Co.'**
  String get registerCompanyNameHint;

  /// No description provided for @registerCompanyNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Company name is required'**
  String get registerCompanyNameRequired;

  /// No description provided for @registerCompanyNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Must be 150 characters or fewer'**
  String get registerCompanyNameTooLong;

  /// No description provided for @registerCompanyEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Company Email Address'**
  String get registerCompanyEmailLabel;

  /// No description provided for @registerCompanyEmailHint.
  ///
  /// In en, this message translates to:
  /// **'contact@company.com'**
  String get registerCompanyEmailHint;

  /// No description provided for @registerCompanyPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact Phone Number'**
  String get registerCompanyPhoneLabel;

  /// No description provided for @registerCompanyPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'+855 11 223 344'**
  String get registerCompanyPhoneHint;

  /// No description provided for @registerCompanyAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Office Address & Service Area'**
  String get registerCompanyAddressLabel;

  /// No description provided for @registerCompanyAddressHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. St. 315, Toul Kork (Serves Sen Sok, 7 Makara)'**
  String get registerCompanyAddressHint;

  /// No description provided for @registerCompanyAddressRequired.
  ///
  /// In en, this message translates to:
  /// **'Address and service area are required'**
  String get registerCompanyAddressRequired;

  /// No description provided for @registerCompanySuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Company Registered'**
  String get registerCompanySuccessTitle;

  /// No description provided for @registerCompanySuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Your company profile and owner administrator account have been created! Once verified, you will be able to add technicians and accept customer bookings.'**
  String get registerCompanySuccessMessage;

  /// No description provided for @activationTitle.
  ///
  /// In en, this message translates to:
  /// **'Activate Account'**
  String get activationTitle;

  /// No description provided for @activationSubmit.
  ///
  /// In en, this message translates to:
  /// **'Activate Account'**
  String get activationSubmit;

  /// No description provided for @activationSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Activated!'**
  String get activationSuccessTitle;

  /// No description provided for @activationSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Your company technician account is active. You can now log in to view assigned repair jobs.'**
  String get activationSuccessMessage;

  /// No description provided for @activationGoToLogin.
  ///
  /// In en, this message translates to:
  /// **'Go to Login'**
  String get activationGoToLogin;

  /// No description provided for @activationInvalidLinkMessage.
  ///
  /// In en, this message translates to:
  /// **'This technician invitation link is invalid or has expired. Please ask your company administrator to send you a new invitation.'**
  String get activationInvalidLinkMessage;

  /// No description provided for @activationHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your account'**
  String get activationHeaderTitle;

  /// No description provided for @activationHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set your full name and password to activate your company technician profile.'**
  String get activationHeaderSubtitle;

  /// No description provided for @activationDefaultCompanyName.
  ///
  /// In en, this message translates to:
  /// **'Service Partner Company'**
  String get activationDefaultCompanyName;

  /// No description provided for @activationInvitedRole.
  ///
  /// In en, this message translates to:
  /// **'Invited Company Technician'**
  String get activationInvitedRole;

  /// No description provided for @activationEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address (From invitation)'**
  String get activationEmailLabel;

  /// No description provided for @activationFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Borey Nhem'**
  String get activationFullNameHint;

  /// No description provided for @activationPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Create Password'**
  String get activationPasswordLabel;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get forgotPasswordSubmit;

  /// No description provided for @forgotPasswordHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgotPasswordHeaderTitle;

  /// No description provided for @forgotPasswordHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the email you signed up with and we will send you a reset link.'**
  String get forgotPasswordHeaderSubtitle;

  /// No description provided for @forgotPasswordEmailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get forgotPasswordEmailHint;

  /// No description provided for @forgotPasswordSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox'**
  String get forgotPasswordSentTitle;

  /// No description provided for @forgotPasswordSentMessage.
  ///
  /// In en, this message translates to:
  /// **'We sent a time-limited password reset link to:'**
  String get forgotPasswordSentMessage;

  /// No description provided for @forgotPasswordResend.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t get it? Resend email'**
  String get forgotPasswordResend;

  /// Disabled resend button while the cooldown runs.
  ///
  /// In en, this message translates to:
  /// **'Resend email in {seconds}s'**
  String forgotPasswordResendCountdown(int seconds);

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Create New Password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordSubmit.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordSubmit;

  /// No description provided for @resetPasswordSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Password Reset!'**
  String get resetPasswordSuccessTitle;

  /// No description provided for @resetPasswordSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Your password has been successfully updated. You can now log in with your new credentials.'**
  String get resetPasswordSuccessMessage;

  /// No description provided for @resetPasswordGoToLogin.
  ///
  /// In en, this message translates to:
  /// **'Go to Login'**
  String get resetPasswordGoToLogin;

  /// No description provided for @resetPasswordRequestNewLink.
  ///
  /// In en, this message translates to:
  /// **'Request New Link'**
  String get resetPasswordRequestNewLink;

  /// No description provided for @resetPasswordInvalidLinkMessage.
  ///
  /// In en, this message translates to:
  /// **'This password reset link is invalid or has already been used. Please request a new link.'**
  String get resetPasswordInvalidLinkMessage;

  /// No description provided for @resetPasswordHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Set new password'**
  String get resetPasswordHeaderTitle;

  /// No description provided for @resetPasswordHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters.'**
  String get resetPasswordHeaderSubtitle;

  /// No description provided for @resetPasswordNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get resetPasswordNewPasswordLabel;

  /// No description provided for @resetPasswordConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get resetPasswordConfirmLabel;

  /// No description provided for @resetPasswordConfirmHint.
  ///
  /// In en, this message translates to:
  /// **'Repeat your new password'**
  String get resetPasswordConfirmHint;

  /// No description provided for @resetPasswordStrengthHint.
  ///
  /// In en, this message translates to:
  /// **'Add a capital letter and a number to make it stronger.'**
  String get resetPasswordStrengthHint;

  /// No description provided for @resetPasswordStrengthWeak.
  ///
  /// In en, this message translates to:
  /// **'Strength: Weak'**
  String get resetPasswordStrengthWeak;

  /// No description provided for @resetPasswordStrengthGood.
  ///
  /// In en, this message translates to:
  /// **'Strength: Good'**
  String get resetPasswordStrengthGood;

  /// No description provided for @resetPasswordStrengthStrong.
  ///
  /// In en, this message translates to:
  /// **'Strength: Strong'**
  String get resetPasswordStrengthStrong;
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
      <String>['en', 'km'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'km':
      return AppLocalizationsKm();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
