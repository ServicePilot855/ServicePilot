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
  /// **'Your assigned jobs are below, with where and when to work.'**
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

  /// No description provided for @discoveryLocation.
  ///
  /// In en, this message translates to:
  /// **'Phnom Penh'**
  String get discoveryLocation;

  /// No description provided for @discoveryHomePrompt.
  ///
  /// In en, this message translates to:
  /// **'What repair or maintenance service do you need?'**
  String get discoveryHomePrompt;

  /// No description provided for @discoveryBrowseServices.
  ///
  /// In en, this message translates to:
  /// **'Browse services'**
  String get discoveryBrowseServices;

  /// No description provided for @discoveryHomeCategories.
  ///
  /// In en, this message translates to:
  /// **'Service categories'**
  String get discoveryHomeCategories;

  /// No description provided for @discoveryCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Repair & Maintenance'**
  String get discoveryCategoriesTitle;

  /// No description provided for @discoverySearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search categories'**
  String get discoverySearchLabel;

  /// No description provided for @discoveryClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get discoveryClearSearch;

  /// No description provided for @discoveryNoMatchingCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories match your search.'**
  String get discoveryNoMatchingCategories;

  /// No description provided for @discoveryNoCategories.
  ///
  /// In en, this message translates to:
  /// **'No service categories are available yet.'**
  String get discoveryNoCategories;

  /// No description provided for @discoveryLoadingCategories.
  ///
  /// In en, this message translates to:
  /// **'Loading categories'**
  String get discoveryLoadingCategories;

  /// No description provided for @discoveryCategoriesError.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load service categories.'**
  String get discoveryCategoriesError;

  /// No description provided for @discoveryHomeBookings.
  ///
  /// In en, this message translates to:
  /// **'My repair bookings'**
  String get discoveryHomeBookings;

  /// No description provided for @discoveryNoBookings.
  ///
  /// In en, this message translates to:
  /// **'You have no repair bookings yet.'**
  String get discoveryNoBookings;

  /// No description provided for @discoveryBookingsError.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load your bookings.'**
  String get discoveryBookingsError;

  /// No description provided for @discoveryLoadingBookings.
  ///
  /// In en, this message translates to:
  /// **'Loading your bookings'**
  String get discoveryLoadingBookings;

  /// No description provided for @providerDirectoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Service providers'**
  String get providerDirectoryTitle;

  /// No description provided for @providerDirectoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No providers are available for this category yet.'**
  String get providerDirectoryEmpty;

  /// No description provided for @providerDirectoryError.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load providers.'**
  String get providerDirectoryError;

  /// No description provided for @providerDirectoryRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get providerDirectoryRetry;

  /// No description provided for @providerDirectoryLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading providers'**
  String get providerDirectoryLoading;

  /// No description provided for @providerOtherCategories.
  ///
  /// In en, this message translates to:
  /// **'Browse other categories'**
  String get providerOtherCategories;

  /// No description provided for @providerTypeIndependent.
  ///
  /// In en, this message translates to:
  /// **'Independent technician'**
  String get providerTypeIndependent;

  /// No description provided for @providerTypeCompany.
  ///
  /// In en, this message translates to:
  /// **'Repair company'**
  String get providerTypeCompany;

  /// No description provided for @providerProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Provider profile'**
  String get providerProfileTitle;

  /// No description provided for @providerProfileLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading provider profile'**
  String get providerProfileLoading;

  /// No description provided for @providerProfileError.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load this provider’s profile.'**
  String get providerProfileError;

  /// No description provided for @providerProfileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Provider not found'**
  String get providerProfileNotFound;

  /// No description provided for @providerProfileNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'This profile is no longer available.'**
  String get providerProfileNotFoundBody;

  /// No description provided for @providerBack.
  ///
  /// In en, this message translates to:
  /// **'Back to providers'**
  String get providerBack;

  /// No description provided for @providerAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get providerAvailable;

  /// No description provided for @providerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Currently unavailable'**
  String get providerUnavailable;

  /// No description provided for @providerSpecialties.
  ///
  /// In en, this message translates to:
  /// **'Specialties'**
  String get providerSpecialties;

  /// No description provided for @providerAreas.
  ///
  /// In en, this message translates to:
  /// **'Service areas'**
  String get providerAreas;

  /// No description provided for @providerAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get providerAbout;

  /// No description provided for @providerNoReviews.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get providerNoReviews;

  /// No description provided for @providerRatingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Rating unavailable'**
  String get providerRatingUnavailable;

  /// No description provided for @providerReviewCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} review} other{{count} reviews}}'**
  String providerReviewCount(int count);

  /// No description provided for @providerRatingSummary.
  ///
  /// In en, this message translates to:
  /// **'{score} · {reviews}'**
  String providerRatingSummary(String score, String reviews);

  /// No description provided for @providerRatingAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'{score} out of 5. {reviews}'**
  String providerRatingAnnouncement(String score, String reviews);

  /// No description provided for @providerContinueBooking.
  ///
  /// In en, this message translates to:
  /// **'Continue to booking'**
  String get providerContinueBooking;

  /// No description provided for @bookingFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Book a repair'**
  String get bookingFormTitle;

  /// No description provided for @bookingFormHeading.
  ///
  /// In en, this message translates to:
  /// **'Request a repair'**
  String get bookingFormHeading;

  /// No description provided for @bookingFormSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{provider} will review your request and confirm or decline it.'**
  String bookingFormSubtitle(String provider);

  /// No description provided for @bookingServiceSection.
  ///
  /// In en, this message translates to:
  /// **'Which service do you need?'**
  String get bookingServiceSection;

  /// No description provided for @bookingServiceGeneral.
  ///
  /// In en, this message translates to:
  /// **'General repair visit'**
  String get bookingServiceGeneral;

  /// No description provided for @bookingProblemSection.
  ///
  /// In en, this message translates to:
  /// **'What\'s wrong?'**
  String get bookingProblemSection;

  /// No description provided for @bookingProblemLabel.
  ///
  /// In en, this message translates to:
  /// **'Describe the problem'**
  String get bookingProblemLabel;

  /// No description provided for @bookingProblemHint.
  ///
  /// In en, this message translates to:
  /// **'For example: the bedroom AC blows warm air and drips water'**
  String get bookingProblemHint;

  /// No description provided for @bookingProblemPrivacyHelper.
  ///
  /// In en, this message translates to:
  /// **'The provider can read this before accepting. Leave out your address and phone number.'**
  String get bookingProblemPrivacyHelper;

  /// No description provided for @bookingAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Repair address'**
  String get bookingAddressLabel;

  /// No description provided for @bookingAddressHint.
  ///
  /// In en, this message translates to:
  /// **'House no., street, sangkat, khan'**
  String get bookingAddressHint;

  /// No description provided for @bookingAddressHelper.
  ///
  /// In en, this message translates to:
  /// **'Include the street and khan so the technician can find you.'**
  String get bookingAddressHelper;

  /// No description provided for @bookingWhereSection.
  ///
  /// In en, this message translates to:
  /// **'Where is the repair?'**
  String get bookingWhereSection;

  /// No description provided for @bookingLocationAdd.
  ///
  /// In en, this message translates to:
  /// **'Pin it on the map'**
  String get bookingLocationAdd;

  /// No description provided for @bookingLocationAddHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional. Helps the technician find a borey or alley.'**
  String get bookingLocationAddHelper;

  /// No description provided for @bookingLocationPinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned on the map'**
  String get bookingLocationPinned;

  /// No description provided for @bookingLocationChange.
  ///
  /// In en, this message translates to:
  /// **'Change pin'**
  String get bookingLocationChange;

  /// No description provided for @bookingLocationRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove pin'**
  String get bookingLocationRemove;

  /// No description provided for @bookingPhotosLabel.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get bookingPhotosLabel;

  /// No description provided for @bookingPhotosHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional. Up to {max} photos, {mb} MB each. They help the provider bring the right parts.'**
  String bookingPhotosHelper(int max, int mb);

  /// No description provided for @bookingPhotosAdd.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get bookingPhotosAdd;

  /// No description provided for @bookingPhotosTake.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get bookingPhotosTake;

  /// No description provided for @bookingPhotosChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get bookingPhotosChoose;

  /// No description provided for @bookingPhotoRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove photo {number}'**
  String bookingPhotoRemove(int number);

  /// No description provided for @bookingPhotoCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo attached} other{{count} photos attached}}'**
  String bookingPhotoCount(int count);

  /// No description provided for @bookingErrorTooManyPhotos.
  ///
  /// In en, this message translates to:
  /// **'You can add up to {max} photos.'**
  String bookingErrorTooManyPhotos(int max);

  /// No description provided for @bookingErrorPhotoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Each photo must be {mb} MB or smaller. Choose a smaller photo.'**
  String bookingErrorPhotoTooLarge(int mb);

  /// No description provided for @bookingErrorPhotoPick.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t open your photos. Check the app\'s camera and photo permissions.'**
  String get bookingErrorPhotoPick;

  /// No description provided for @bookingSummaryPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get bookingSummaryPhotos;

  /// No description provided for @locationPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Pin the repair address'**
  String get locationPickerTitle;

  /// No description provided for @locationPickerHint.
  ///
  /// In en, this message translates to:
  /// **'Move the map until the pin sits on the place that needs the repair.'**
  String get locationPickerHint;

  /// No description provided for @locationPickerConfirm.
  ///
  /// In en, this message translates to:
  /// **'Use this location'**
  String get locationPickerConfirm;

  /// No description provided for @locationPickerZoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get locationPickerZoomIn;

  /// No description provided for @locationPickerZoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get locationPickerZoomOut;

  /// No description provided for @bookingWhenSection.
  ///
  /// In en, this message translates to:
  /// **'When should they come?'**
  String get bookingWhenSection;

  /// No description provided for @bookingDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get bookingDateLabel;

  /// No description provided for @bookingTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get bookingTimeLabel;

  /// No description provided for @bookingDatePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Choose a date'**
  String get bookingDatePlaceholder;

  /// No description provided for @bookingTimePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Choose a time'**
  String get bookingTimePlaceholder;

  /// No description provided for @bookingEstimateLabel.
  ///
  /// In en, this message translates to:
  /// **'Starting price'**
  String get bookingEstimateLabel;

  /// No description provided for @bookingEstimateValue.
  ///
  /// In en, this message translates to:
  /// **'From {price}'**
  String bookingEstimateValue(String price);

  /// No description provided for @bookingPaymentNote.
  ///
  /// In en, this message translates to:
  /// **'This is a request, not a payment. You pay the provider directly after the job, once the final price is agreed.'**
  String get bookingPaymentNote;

  /// No description provided for @bookingSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send booking request'**
  String get bookingSubmit;

  /// No description provided for @bookingErrorServiceRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose the service you need.'**
  String get bookingErrorServiceRequired;

  /// No description provided for @bookingErrorDescriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Describe the problem so the provider knows what to expect.'**
  String get bookingErrorDescriptionRequired;

  /// No description provided for @bookingErrorDescriptionTooShort.
  ///
  /// In en, this message translates to:
  /// **'Add a little more detail (at least {min} characters).'**
  String bookingErrorDescriptionTooShort(int min);

  /// No description provided for @bookingErrorDescriptionTooLong.
  ///
  /// In en, this message translates to:
  /// **'Keep the description under {max} characters.'**
  String bookingErrorDescriptionTooLong(int max);

  /// No description provided for @bookingErrorAddressRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the address where the repair is needed.'**
  String get bookingErrorAddressRequired;

  /// No description provided for @bookingErrorAddressTooShort.
  ///
  /// In en, this message translates to:
  /// **'Add your street and khan so the technician can find you.'**
  String get bookingErrorAddressTooShort;

  /// No description provided for @bookingErrorAddressTooLong.
  ///
  /// In en, this message translates to:
  /// **'Keep the address under {max} characters.'**
  String bookingErrorAddressTooLong(int max);

  /// No description provided for @bookingErrorDateTimeRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a date and a time.'**
  String get bookingErrorDateTimeRequired;

  /// No description provided for @bookingErrorDateTimeTooSoon.
  ///
  /// In en, this message translates to:
  /// **'Choose a time at least {hours} hour from now.'**
  String bookingErrorDateTimeTooSoon(int hours);

  /// No description provided for @bookingErrorDateTimeTooFar.
  ///
  /// In en, this message translates to:
  /// **'Choose a date within the next {days} days.'**
  String bookingErrorDateTimeTooFar(int days);

  /// No description provided for @bookingErrorSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t send your request. Check your connection and try again.'**
  String get bookingErrorSaveFailed;

  /// No description provided for @bookingProviderUnavailable.
  ///
  /// In en, this message translates to:
  /// **'{provider} isn\'t taking new bookings right now.'**
  String bookingProviderUnavailable(String provider);

  /// No description provided for @bookingProviderNotFound.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find this provider.'**
  String get bookingProviderNotFound;

  /// No description provided for @bookingSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get bookingSentTitle;

  /// No description provided for @bookingSentMessage.
  ///
  /// In en, this message translates to:
  /// **'{provider} will review it and confirm or decline. You\'ll see their answer on the booking status page.'**
  String bookingSentMessage(String provider);

  /// No description provided for @bookingSentMessageGeneric.
  ///
  /// In en, this message translates to:
  /// **'The provider will review it and confirm or decline. You\'ll see their answer on the booking status page.'**
  String get bookingSentMessageGeneric;

  /// No description provided for @bookingSummaryService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get bookingSummaryService;

  /// No description provided for @bookingSummaryWhen.
  ///
  /// In en, this message translates to:
  /// **'Date and time'**
  String get bookingSummaryWhen;

  /// No description provided for @bookingSummaryAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get bookingSummaryAddress;

  /// No description provided for @bookingSentViewStatus.
  ///
  /// In en, this message translates to:
  /// **'View booking status'**
  String get bookingSentViewStatus;

  /// No description provided for @bookingSentBackHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get bookingSentBackHome;

  /// No description provided for @bookingInboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Incoming requests'**
  String get bookingInboxTitle;

  /// No description provided for @bookingInboxDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking request'**
  String get bookingInboxDetailTitle;

  /// No description provided for @bookingInboxEmpty.
  ///
  /// In en, this message translates to:
  /// **'You have no pending booking requests.'**
  String get bookingInboxEmpty;

  /// No description provided for @bookingInboxUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This booking request is unavailable.'**
  String get bookingInboxUnavailable;

  /// No description provided for @bookingInboxPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get bookingInboxPending;

  /// No description provided for @bookingInboxJobDetails.
  ///
  /// In en, this message translates to:
  /// **'Job details'**
  String get bookingInboxJobDetails;

  /// No description provided for @bookingInboxDateUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Appointment time unavailable'**
  String get bookingInboxDateUnavailable;

  /// No description provided for @bookingInboxLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading booking requests'**
  String get bookingInboxLoading;

  /// No description provided for @bookingInboxError.
  ///
  /// In en, this message translates to:
  /// **'Could not load booking requests. Check your connection and try again.'**
  String get bookingInboxError;

  /// No description provided for @bookingInboxRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get bookingInboxRetry;

  /// No description provided for @offeringCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Service Offering'**
  String get offeringCreateTitle;

  /// No description provided for @offeringHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'New Service Offering'**
  String get offeringHeaderTitle;

  /// No description provided for @offeringCreateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Publish a new service offering with fixed or custom quote pricing.'**
  String get offeringCreateSubtitle;

  /// No description provided for @offeringCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Service Category'**
  String get offeringCategoryLabel;

  /// No description provided for @offeringCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get offeringCategoryHint;

  /// No description provided for @offeringCategoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a service category.'**
  String get offeringCategoryRequired;

  /// No description provided for @offeringCategoriesEmpty.
  ///
  /// In en, this message translates to:
  /// **'There are no active service categories.'**
  String get offeringCategoriesEmpty;

  /// No description provided for @offeringCategoriesError.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load service categories. Go back and reopen the form to try again.'**
  String get offeringCategoriesError;

  /// No description provided for @offeringTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Service Title'**
  String get offeringTitleLabel;

  /// No description provided for @offeringTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Inverter Mainboard & PCB Replacement'**
  String get offeringTitleHint;

  /// No description provided for @offeringTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a service title.'**
  String get offeringTitleRequired;

  /// No description provided for @offeringTitleMinLength.
  ///
  /// In en, this message translates to:
  /// **'Title must be at least 3 characters.'**
  String get offeringTitleMinLength;

  /// No description provided for @offeringDescLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get offeringDescLabel;

  /// No description provided for @offeringDescHint.
  ///
  /// In en, this message translates to:
  /// **'Explain the scope, prerequisites, or diagnosis required...'**
  String get offeringDescHint;

  /// No description provided for @offeringDescRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a description.'**
  String get offeringDescRequired;

  /// No description provided for @offeringDescMinLength.
  ///
  /// In en, this message translates to:
  /// **'Description must be at least 10 characters.'**
  String get offeringDescMinLength;

  /// No description provided for @offeringPricingModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Pricing Mode'**
  String get offeringPricingModeLabel;

  /// No description provided for @offeringModeQuote.
  ///
  /// In en, this message translates to:
  /// **'Requires custom quote'**
  String get offeringModeQuote;

  /// No description provided for @offeringModeQuoteDesc.
  ///
  /// In en, this message translates to:
  /// **'Excluded from fixed cart checkout. Customers submit inquiry for custom on-site estimation.'**
  String get offeringModeQuoteDesc;

  /// No description provided for @offeringNoticeQuoteMode.
  ///
  /// In en, this message translates to:
  /// **'Quote Mode Active: Fixed price checkout is disabled. Homeowners will be guided to submit problem details and photos for quote intake.'**
  String get offeringNoticeQuoteMode;

  /// No description provided for @offeringBadgeQuoteRequired.
  ///
  /// In en, this message translates to:
  /// **'Quote Required'**
  String get offeringBadgeQuoteRequired;

  /// No description provided for @offeringCtaRequestQuote.
  ///
  /// In en, this message translates to:
  /// **'Request a Quote'**
  String get offeringCtaRequestQuote;

  /// No description provided for @offeringCtaBookService.
  ///
  /// In en, this message translates to:
  /// **'Book Service'**
  String get offeringCtaBookService;

  /// No description provided for @offeringNoticeQuoteRequiredBooking.
  ///
  /// In en, this message translates to:
  /// **'You are requesting a custom quote for this service. You will not be charged upfront. The provider will review your scope and provide a formal price estimate before work begins.'**
  String get offeringNoticeQuoteRequiredBooking;

  /// No description provided for @offeringModeFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed upfront price'**
  String get offeringModeFixed;

  /// No description provided for @offeringModeFixedDesc.
  ///
  /// In en, this message translates to:
  /// **'Upfront transparent flat-rate pricing.'**
  String get offeringModeFixedDesc;

  /// No description provided for @offeringPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Base Price (\$)'**
  String get offeringPriceLabel;

  /// No description provided for @offeringPriceRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid base price.'**
  String get offeringPriceRequired;

  /// No description provided for @offeringPricePositive.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount greater than zero with up to two decimal places.'**
  String get offeringPricePositive;

  /// No description provided for @offeringUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Pricing Unit (Optional)'**
  String get offeringUnitLabel;

  /// No description provided for @offeringUnitHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., job, hour, unit'**
  String get offeringUnitHint;

  /// No description provided for @offeringCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Publish Offering'**
  String get offeringCreateButton;

  /// No description provided for @offeringSuccessSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Service offering published successfully!'**
  String get offeringSuccessSnackbar;

  /// No description provided for @offeringPublishError.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t publish your offering. Check your connection and provider access, then try again.'**
  String get offeringPublishError;

  /// No description provided for @offeringUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Only registered service providers and companies can publish offerings.'**
  String get offeringUnauthorized;

  /// No description provided for @offeringActiveRequired.
  ///
  /// In en, this message translates to:
  /// **'Provider account must be active to publish service offerings.'**
  String get offeringActiveRequired;

  /// No description provided for @offeringDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'My Service Offerings'**
  String get offeringDashboardTitle;

  /// No description provided for @offeringAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add Offering'**
  String get offeringAddButton;

  /// No description provided for @offeringEmptyNotice.
  ///
  /// In en, this message translates to:
  /// **'You have not published any service offerings yet. Tap \"+ Add Offering\" to add fixed-price or quote-required services.'**
  String get offeringEmptyNotice;

  /// No description provided for @offeringLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load service offerings right now. Please check your connection and try again.'**
  String get offeringLoadError;

  /// No description provided for @adminDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Platform Administration'**
  String get adminDashboardTitle;

  /// No description provided for @adminPendingProvidersSection.
  ///
  /// In en, this message translates to:
  /// **'Pending provider applications'**
  String get adminPendingProvidersSection;

  /// No description provided for @adminApprovedProvidersSection.
  ///
  /// In en, this message translates to:
  /// **'Approved active providers'**
  String get adminApprovedProvidersSection;

  /// No description provided for @adminPendingProvidersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No pending provider applications require review right now.'**
  String get adminPendingProvidersEmpty;

  /// No description provided for @adminPendingBadge.
  ///
  /// In en, this message translates to:
  /// **'Pending verification'**
  String get adminPendingBadge;

  /// No description provided for @adminApprovedBadge.
  ///
  /// In en, this message translates to:
  /// **'Approved & active'**
  String get adminApprovedBadge;

  /// No description provided for @adminProviderReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review provider'**
  String get adminProviderReviewTitle;

  /// No description provided for @adminReviewAction.
  ///
  /// In en, this message translates to:
  /// **'Review application'**
  String get adminReviewAction;

  /// No description provided for @adminApproveProviderButton.
  ///
  /// In en, this message translates to:
  /// **'Approve provider'**
  String get adminApproveProviderButton;

  /// No description provided for @adminProviderApprovedNotice.
  ///
  /// In en, this message translates to:
  /// **'{provider} is now approved, active, and eligible for customer bookings.'**
  String adminProviderApprovedNotice(String provider);

  /// No description provided for @adminPendingVerificationNotice.
  ///
  /// In en, this message translates to:
  /// **'This provider is awaiting verification and is hidden from customer search and bookings.'**
  String get adminPendingVerificationNotice;

  /// No description provided for @adminVerificationChecklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification details'**
  String get adminVerificationChecklistTitle;

  /// No description provided for @adminContactEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get adminContactEmailLabel;

  /// No description provided for @adminContactPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact phone'**
  String get adminContactPhoneLabel;

  /// No description provided for @adminAccessDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin access required'**
  String get adminAccessDeniedTitle;

  /// No description provided for @adminAccessDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'Only Platform Admins can review or approve provider accounts.'**
  String get adminAccessDeniedMessage;

  /// No description provided for @adminViewCustomerProfileButton.
  ///
  /// In en, this message translates to:
  /// **'Preview customer profile'**
  String get adminViewCustomerProfileButton;

  /// No description provided for @companyProfileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit company profile'**
  String get companyProfileEdit;

  /// No description provided for @companyProfileDescription.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get companyProfileDescription;

  /// No description provided for @companyProfileDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Home plumbing and electrical repairs'**
  String get companyProfileDescriptionHint;

  /// No description provided for @companyProfileAreaHint.
  ///
  /// In en, this message translates to:
  /// **'Sen Sok, Tuol Kork'**
  String get companyProfileAreaHint;

  /// No description provided for @companyProfileAreaRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a service area.'**
  String get companyProfileAreaRequired;

  /// No description provided for @companyProfileContacts.
  ///
  /// In en, this message translates to:
  /// **'Contact links'**
  String get companyProfileContacts;

  /// No description provided for @companyProfileOptionalContacts.
  ///
  /// In en, this message translates to:
  /// **'Contact links (optional)'**
  String get companyProfileOptionalContacts;

  /// No description provided for @companyProfileTelegram.
  ///
  /// In en, this message translates to:
  /// **'Telegram'**
  String get companyProfileTelegram;

  /// No description provided for @companyProfileTelegramExample.
  ///
  /// In en, this message translates to:
  /// **'https://t.me/coolair'**
  String get companyProfileTelegramExample;

  /// No description provided for @companyProfileMessenger.
  ///
  /// In en, this message translates to:
  /// **'Messenger'**
  String get companyProfileMessenger;

  /// No description provided for @companyProfileMessengerExample.
  ///
  /// In en, this message translates to:
  /// **'https://m.me/coolair'**
  String get companyProfileMessengerExample;

  /// No description provided for @companyProfileInvalidLink.
  ///
  /// In en, this message translates to:
  /// **'Enter a link like {example}.'**
  String companyProfileInvalidLink(String example);

  /// No description provided for @companyProfileLengthError.
  ///
  /// In en, this message translates to:
  /// **'Use {limit} characters or fewer.'**
  String companyProfileLengthError(int limit);

  /// No description provided for @companyProfileUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No editable company profile is linked to this account.'**
  String get companyProfileUnavailable;

  /// No description provided for @companyProfileLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading company profile'**
  String get companyProfileLoading;

  /// No description provided for @companyProfileLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your company profile.'**
  String get companyProfileLoadError;

  /// No description provided for @companyProfileSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save your changes. Try again.'**
  String get companyProfileSaveError;

  /// No description provided for @companyProfileSave.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get companyProfileSave;

  /// No description provided for @companyProfileSaved.
  ///
  /// In en, this message translates to:
  /// **'Company profile saved.'**
  String get companyProfileSaved;

  /// No description provided for @technicianProfileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit technician profile'**
  String get technicianProfileEdit;

  /// No description provided for @technicianProfileName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get technicianProfileName;

  /// No description provided for @technicianProfileNameHint.
  ///
  /// In en, this message translates to:
  /// **'Virak Chan'**
  String get technicianProfileNameHint;

  /// No description provided for @technicianProfileNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name.'**
  String get technicianProfileNameRequired;

  /// No description provided for @technicianProfileDescription.
  ///
  /// In en, this message translates to:
  /// **'Bio / description (optional)'**
  String get technicianProfileDescription;

  /// No description provided for @technicianProfileDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Certified AC technician with 7+ years of experience'**
  String get technicianProfileDescriptionHint;

  /// No description provided for @technicianProfileAreaHint.
  ///
  /// In en, this message translates to:
  /// **'Sen Sok, Tuol Kork'**
  String get technicianProfileAreaHint;

  /// No description provided for @technicianProfileAreaRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a service area.'**
  String get technicianProfileAreaRequired;

  /// No description provided for @technicianProfileContacts.
  ///
  /// In en, this message translates to:
  /// **'Contact links'**
  String get technicianProfileContacts;

  /// No description provided for @technicianProfileOptionalContacts.
  ///
  /// In en, this message translates to:
  /// **'Contact links (optional)'**
  String get technicianProfileOptionalContacts;

  /// No description provided for @technicianProfileTelegram.
  ///
  /// In en, this message translates to:
  /// **'Telegram'**
  String get technicianProfileTelegram;

  /// No description provided for @technicianProfileTelegramExample.
  ///
  /// In en, this message translates to:
  /// **'https://t.me/virakchan'**
  String get technicianProfileTelegramExample;

  /// No description provided for @technicianProfileMessenger.
  ///
  /// In en, this message translates to:
  /// **'Messenger'**
  String get technicianProfileMessenger;

  /// No description provided for @technicianProfileMessengerExample.
  ///
  /// In en, this message translates to:
  /// **'https://m.me/virakchan'**
  String get technicianProfileMessengerExample;

  /// No description provided for @technicianProfileInvalidLink.
  ///
  /// In en, this message translates to:
  /// **'Enter a link like {example}.'**
  String technicianProfileInvalidLink(String example);

  /// No description provided for @technicianProfileLengthError.
  ///
  /// In en, this message translates to:
  /// **'Use {limit} characters or fewer.'**
  String technicianProfileLengthError(int limit);

  /// No description provided for @technicianProfileUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No editable technician profile is linked to this account.'**
  String get technicianProfileUnavailable;

  /// No description provided for @technicianProfileLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading technician profile'**
  String get technicianProfileLoading;

  /// No description provided for @technicianProfileLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your technician profile.'**
  String get technicianProfileLoadError;

  /// No description provided for @technicianProfileSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save your changes. Try again.'**
  String get technicianProfileSaveError;

  /// No description provided for @technicianProfileSave.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get technicianProfileSave;

  /// No description provided for @technicianProfileSaved.
  ///
  /// In en, this message translates to:
  /// **'Technician profile saved.'**
  String get technicianProfileSaved;

  /// No description provided for @providerOfferingsSection.
  ///
  /// In en, this message translates to:
  /// **'Available Services & Offerings'**
  String get providerOfferingsSection;

  /// No description provided for @bookingConfirmedAppointmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirmed Appointment'**
  String get bookingConfirmedAppointmentLabel;

  /// No description provided for @bookingPreferredAppointmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Preferred Date & Time'**
  String get bookingPreferredAppointmentLabel;

  /// No description provided for @providerBookingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Accepted bookings'**
  String get providerBookingsTitle;

  /// No description provided for @providerBookingsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You have no accepted bookings.'**
  String get providerBookingsEmpty;

  /// No description provided for @providerBookingsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load booking requests right now. Please try again.'**
  String get providerBookingsLoadError;

  /// No description provided for @providerBookingDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking Request'**
  String get providerBookingDetailTitle;

  /// No description provided for @providerBookingConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm Appointment'**
  String get providerBookingConfirmButton;

  /// No description provided for @providerBookingConfirmSuccess.
  ///
  /// In en, this message translates to:
  /// **'Appointment confirmed! The homeowner can now see the confirmed date and time.'**
  String get providerBookingConfirmSuccess;

  /// No description provided for @providerBookingNotAuthorized.
  ///
  /// In en, this message translates to:
  /// **'You are not authorized to confirm this booking.'**
  String get providerBookingNotAuthorized;

  /// No description provided for @providerBookingIneligible.
  ///
  /// In en, this message translates to:
  /// **'This booking cannot be confirmed in its current state.'**
  String get providerBookingIneligible;

  /// No description provided for @providerBookingReviewAction.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get providerBookingReviewAction;

  /// No description provided for @providerAssignmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Assign technician'**
  String get providerAssignmentTitle;

  /// No description provided for @providerAssignmentSave.
  ///
  /// In en, this message translates to:
  /// **'Save assignment'**
  String get providerAssignmentSave;

  /// No description provided for @providerAssignmentEmpty.
  ///
  /// In en, this message translates to:
  /// **'There are no active technicians on your company roster.'**
  String get providerAssignmentEmpty;

  /// No description provided for @providerAssignmentLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your technicians. Try again.'**
  String get providerAssignmentLoadError;

  /// No description provided for @providerAssignmentSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save the assignment. Open the picker and try again.'**
  String get providerAssignmentSaveError;

  /// No description provided for @providerAssignmentIneligible.
  ///
  /// In en, this message translates to:
  /// **'This booking can no longer be assigned.'**
  String get providerAssignmentIneligible;

  /// No description provided for @providerBookingDeclineButton.
  ///
  /// In en, this message translates to:
  /// **'Decline Request'**
  String get providerBookingDeclineButton;

  /// No description provided for @providerBookingDeclineDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Decline this request?'**
  String get providerBookingDeclineDialogTitle;

  /// No description provided for @providerBookingDeclineDialogBody.
  ///
  /// In en, this message translates to:
  /// **'The homeowner will see this request as Declined. You will not be able to confirm it afterwards.'**
  String get providerBookingDeclineDialogBody;

  /// No description provided for @providerBookingDeclineReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason for declining'**
  String get providerBookingDeclineReasonLabel;

  /// No description provided for @providerBookingDeclineReasonHint.
  ///
  /// In en, this message translates to:
  /// **'For example: outside our service area that day'**
  String get providerBookingDeclineReasonHint;

  /// No description provided for @providerBookingDeclineReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Add a short reason so the homeowner can make other arrangements.'**
  String get providerBookingDeclineReasonRequired;

  /// No description provided for @providerBookingDeclineReasonTooLong.
  ///
  /// In en, this message translates to:
  /// **'Keep the reason under 300 characters.'**
  String get providerBookingDeclineReasonTooLong;

  /// No description provided for @providerBookingDeclineKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep Request'**
  String get providerBookingDeclineKeep;

  /// No description provided for @providerBookingDeclineConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm Decline'**
  String get providerBookingDeclineConfirm;

  /// No description provided for @providerBookingDeclineSuccess.
  ///
  /// In en, this message translates to:
  /// **'Request declined. The homeowner can see this booking as Declined in their history.'**
  String get providerBookingDeclineSuccess;

  /// No description provided for @providerBookingDeclinedNotice.
  ///
  /// In en, this message translates to:
  /// **'You declined this request. The homeowner can see it as Declined in their booking history.'**
  String get providerBookingDeclinedNotice;

  /// No description provided for @providerDeclinedRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Declined requests'**
  String get providerDeclinedRequestsTitle;

  /// No description provided for @providerDeclinedRequestsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You have no declined requests.'**
  String get providerDeclinedRequestsEmpty;

  /// No description provided for @providerBookingDeclineIneligible.
  ///
  /// In en, this message translates to:
  /// **'This request can no longer be declined.'**
  String get providerBookingDeclineIneligible;

  /// No description provided for @providerBookingDeclineNotAuthorized.
  ///
  /// In en, this message translates to:
  /// **'You are not authorized to decline this request.'**
  String get providerBookingDeclineNotAuthorized;

  /// No description provided for @cartAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add to cart'**
  String get cartAddButton;

  /// No description provided for @cartAddedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Added {serviceTitle} to cart.'**
  String cartAddedSnackbar(String serviceTitle);

  /// No description provided for @cartErrorDifferentProvider.
  ///
  /// In en, this message translates to:
  /// **'Your cart already has services from {providerName}. Clear your cart before adding from another provider.'**
  String cartErrorDifferentProvider(String providerName);

  /// No description provided for @cartErrorDifferentProviderGeneric.
  ///
  /// In en, this message translates to:
  /// **'Your cart already has services from another provider. Clear your cart before adding this service.'**
  String get cartErrorDifferentProviderGeneric;

  /// No description provided for @cartErrorQuoteRequired.
  ///
  /// In en, this message translates to:
  /// **'Quote-required services cannot be added to the cart. Use Request a Quote instead.'**
  String get cartErrorQuoteRequired;

  /// No description provided for @cartErrorUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This service is currently unavailable and cannot be added to the cart.'**
  String get cartErrorUnavailable;

  /// No description provided for @cartBadgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Cart ({count})'**
  String cartBadgeLabel(int count);

  /// No description provided for @cartActiveProviderNotice.
  ///
  /// In en, this message translates to:
  /// **'Cart has {count, plural, =1{1 service} other{{count} services}} from {providerName}.'**
  String cartActiveProviderNotice(int count, String providerName);

  /// No description provided for @cartTitle.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cartTitle;

  /// No description provided for @cartHeading.
  ///
  /// In en, this message translates to:
  /// **'Review your cart'**
  String get cartHeading;

  /// No description provided for @cartItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 service} other{{count} services}}'**
  String cartItemCount(int count);

  /// No description provided for @cartProviderLabel.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get cartProviderLabel;

  /// No description provided for @cartProviderUnknown.
  ///
  /// In en, this message translates to:
  /// **'Provider name unavailable'**
  String get cartProviderUnknown;

  /// No description provided for @cartItemQuantityPrice.
  ///
  /// In en, this message translates to:
  /// **'{quantity} × {price}'**
  String cartItemQuantityPrice(int quantity, String price);

  /// No description provided for @cartRemoveItem.
  ///
  /// In en, this message translates to:
  /// **'Remove {serviceTitle}'**
  String cartRemoveItem(String serviceTitle);

  /// No description provided for @cartTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get cartTotalLabel;

  /// No description provided for @cartTotalSemantics.
  ///
  /// In en, this message translates to:
  /// **'Total {price}'**
  String cartTotalSemantics(String price);

  /// No description provided for @cartPaymentNote.
  ///
  /// In en, this message translates to:
  /// **'These are the provider\'s fixed prices. No payment is taken in the app; you pay the provider directly after the job.'**
  String get cartPaymentNote;

  /// No description provided for @cartEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get cartEmptyTitle;

  /// No description provided for @cartEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add fixed-price services from a provider\'s page and they will appear here.'**
  String get cartEmptyBody;

  /// No description provided for @cartBrowseServices.
  ///
  /// In en, this message translates to:
  /// **'Browse services'**
  String get cartBrowseServices;

  /// No description provided for @cartOpenSemantics.
  ///
  /// In en, this message translates to:
  /// **'Open cart, {count, plural, =1{1 service} other{{count} services}}'**
  String cartOpenSemantics(int count);

  /// No description provided for @quoteFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Request a quote'**
  String get quoteFormTitle;

  /// No description provided for @quoteFormHeading.
  ///
  /// In en, this message translates to:
  /// **'Describe the job'**
  String get quoteFormHeading;

  /// No description provided for @quoteFormSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{provider} will review your details and photos and send a price quote.'**
  String quoteFormSubtitle(String provider);

  /// No description provided for @quoteSelectedOfferingLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected service'**
  String get quoteSelectedOfferingLabel;

  /// No description provided for @quoteDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'For example: the outdoor AC board clicks and shows an E5 error after a power surge'**
  String get quoteDescriptionHint;

  /// No description provided for @quoteRequestFooterNote.
  ///
  /// In en, this message translates to:
  /// **'This quote request stays separate from your cart. You can book a time after you review and approve the provider\'s price.'**
  String get quoteRequestFooterNote;

  /// No description provided for @quoteSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send quote request'**
  String get quoteSubmit;

  /// No description provided for @quoteErrorSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t send your quote request. Check your connection and try again.'**
  String get quoteErrorSaveFailed;

  /// No description provided for @quoteOfferingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This service isn\'t available for quote requests right now.'**
  String get quoteOfferingUnavailable;

  /// No description provided for @quoteOfferingNotFound.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find this service offering.'**
  String get quoteOfferingNotFound;

  /// No description provided for @quoteSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Quote request sent'**
  String get quoteSentTitle;

  /// No description provided for @quoteSentMessage.
  ///
  /// In en, this message translates to:
  /// **'{provider} will review your request and send a price quote. Your cart was not changed.'**
  String quoteSentMessage(String provider);

  /// No description provided for @quoteStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get quoteStatusLabel;

  /// No description provided for @quoteStatusRequested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get quoteStatusRequested;

  /// No description provided for @quoteStatusQuoted.
  ///
  /// In en, this message translates to:
  /// **'Quoted'**
  String get quoteStatusQuoted;

  /// No description provided for @quoteStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get quoteStatusApproved;

  /// No description provided for @quoteStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get quoteStatusRejected;

  /// No description provided for @quoteSummaryProvider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get quoteSummaryProvider;

  /// No description provided for @quoteSummaryDescription.
  ///
  /// In en, this message translates to:
  /// **'Problem details'**
  String get quoteSummaryDescription;

  /// No description provided for @quoteSentViewStatus.
  ///
  /// In en, this message translates to:
  /// **'View quote request'**
  String get quoteSentViewStatus;

  /// No description provided for @quoteDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Quote request'**
  String get quoteDetailTitle;

  /// No description provided for @quoteDetailLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading quote request'**
  String get quoteDetailLoading;

  /// No description provided for @quoteDetailNotFound.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find this quote request.'**
  String get quoteDetailNotFound;

  /// No description provided for @quoteDetailLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this quote request. Try again.'**
  String get quoteDetailLoadFailed;

  /// No description provided for @quoteDetailWaitingMessage.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {provider} to review your details and send a price quote.'**
  String quoteDetailWaitingMessage(String provider);

  /// No description provided for @discoveryHomeQuotes.
  ///
  /// In en, this message translates to:
  /// **'My quote requests'**
  String get discoveryHomeQuotes;

  /// No description provided for @discoveryNoQuotes.
  ///
  /// In en, this message translates to:
  /// **'You have no quote requests yet.'**
  String get discoveryNoQuotes;

  /// No description provided for @discoveryQuotesError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your quote requests.'**
  String get discoveryQuotesError;

  /// No description provided for @discoveryLoadingQuotes.
  ///
  /// In en, this message translates to:
  /// **'Loading your quote requests'**
  String get discoveryLoadingQuotes;

  /// No description provided for @quoteLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Show older quote requests'**
  String get quoteLoadMore;

  /// No description provided for @providerQuotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Quote requests'**
  String get providerQuotesTitle;

  /// No description provided for @providerQuotesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No quote requests yet.'**
  String get providerQuotesEmpty;

  /// No description provided for @providerQuotesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load quote requests. Please try again.'**
  String get providerQuotesLoadError;

  /// No description provided for @providerQuoteDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Quote request'**
  String get providerQuoteDetailTitle;

  /// No description provided for @providerQuotePhotoLabel.
  ///
  /// In en, this message translates to:
  /// **'Request photo {number}'**
  String providerQuotePhotoLabel(int number);

  /// No description provided for @providerQuotePhotoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Photo {number} couldn\'t be loaded.'**
  String providerQuotePhotoUnavailable(int number);

  /// No description provided for @providerQuoteNotFoundOrInaccessible.
  ///
  /// In en, this message translates to:
  /// **'This quote request isn\'t available for your account.'**
  String get providerQuoteNotFoundOrInaccessible;

  /// No description provided for @providerQuotePriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Quoted price'**
  String get providerQuotePriceLabel;

  /// No description provided for @providerQuotePriceNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not quoted yet'**
  String get providerQuotePriceNotSet;

  /// No description provided for @providerQuoteCustomerLabel.
  ///
  /// In en, this message translates to:
  /// **'Homeowner'**
  String get providerQuoteCustomerLabel;

  /// No description provided for @providerQuoteDecisionApproved.
  ///
  /// In en, this message translates to:
  /// **'The homeowner approved your quoted price.'**
  String get providerQuoteDecisionApproved;

  /// No description provided for @providerQuoteDecisionRejected.
  ///
  /// In en, this message translates to:
  /// **'The homeowner declined your quoted price.'**
  String get providerQuoteDecisionRejected;

  /// No description provided for @providerQuoteDecisionWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the homeowner to review your quoted price.'**
  String get providerQuoteDecisionWaiting;

  /// No description provided for @providerQuoteDecisionRequested.
  ///
  /// In en, this message translates to:
  /// **'No price has been quoted for this request yet.'**
  String get providerQuoteDecisionRequested;

  /// No description provided for @providerQuotePriceSection.
  ///
  /// In en, this message translates to:
  /// **'Your price'**
  String get providerQuotePriceSection;

  /// No description provided for @providerQuotePriceInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Price (USD)'**
  String get providerQuotePriceInputLabel;

  /// No description provided for @providerQuotePriceInputHint.
  ///
  /// In en, this message translates to:
  /// **'45.00'**
  String get providerQuotePriceInputHint;

  /// No description provided for @providerQuotePriceInputHelper.
  ///
  /// In en, this message translates to:
  /// **'The homeowner sees this amount and approves it before booking a time.'**
  String get providerQuotePriceInputHelper;

  /// No description provided for @providerQuotePriceRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the price for this job.'**
  String get providerQuotePriceRequired;

  /// No description provided for @providerQuoteSendPrice.
  ///
  /// In en, this message translates to:
  /// **'Send quote'**
  String get providerQuoteSendPrice;

  /// No description provided for @providerQuoteErrorAlreadyPriced.
  ///
  /// In en, this message translates to:
  /// **'This request already has a price.'**
  String get providerQuoteErrorAlreadyPriced;

  /// No description provided for @providerQuoteErrorNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'You can\'t price this request from this account.'**
  String get providerQuoteErrorNotAllowed;

  /// No description provided for @providerQuoteErrorSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t send your price. Check your connection and try again.'**
  String get providerQuoteErrorSaveFailed;

  /// No description provided for @quoteDetailReviewMessage.
  ///
  /// In en, this message translates to:
  /// **'{provider} quoted {price}. Approve it to book a time.'**
  String quoteDetailReviewMessage(String provider, String price);

  /// No description provided for @quoteApproveButton.
  ///
  /// In en, this message translates to:
  /// **'Approve {price}'**
  String quoteApproveButton(String price);

  /// No description provided for @quoteApprovedPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Approved price'**
  String get quoteApprovedPriceLabel;

  /// No description provided for @quoteApprovedMessage.
  ///
  /// In en, this message translates to:
  /// **'You approved {price}. Book a time with {provider}.'**
  String quoteApprovedMessage(String price, String provider);

  /// No description provided for @quoteApproveErrorChanged.
  ///
  /// In en, this message translates to:
  /// **'This quote has changed. Check its latest status.'**
  String get quoteApproveErrorChanged;

  /// No description provided for @quoteApproveErrorFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t approve this quote. Check your connection and try again.'**
  String get quoteApproveErrorFailed;

  /// No description provided for @quoteBookButton.
  ///
  /// In en, this message translates to:
  /// **'Book a time'**
  String get quoteBookButton;

  /// No description provided for @quoteViewBooking.
  ///
  /// In en, this message translates to:
  /// **'View booking'**
  String get quoteViewBooking;

  /// No description provided for @quoteBookedMessage.
  ///
  /// In en, this message translates to:
  /// **'You booked a time for this quote. Track it on the booking status page.'**
  String get quoteBookedMessage;

  /// No description provided for @quoteBookingTitle.
  ///
  /// In en, this message translates to:
  /// **'Book a time'**
  String get quoteBookingTitle;

  /// No description provided for @quoteBookingHeading.
  ///
  /// In en, this message translates to:
  /// **'Choose a time'**
  String get quoteBookingHeading;

  /// No description provided for @quoteBookingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{service} with {provider}'**
  String quoteBookingSubtitle(String service, String provider);

  /// No description provided for @quoteBookingPriceNote.
  ///
  /// In en, this message translates to:
  /// **'Your approved price of {price} is saved with this request. No payment is taken in the app.'**
  String quoteBookingPriceNote(String price);

  /// No description provided for @quoteBookingSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send booking request'**
  String get quoteBookingSubmit;

  /// No description provided for @quoteBookingNotApproved.
  ///
  /// In en, this message translates to:
  /// **'Approve the quoted price before you book a time.'**
  String get quoteBookingNotApproved;

  /// No description provided for @quoteBookingAlreadyBooked.
  ///
  /// In en, this message translates to:
  /// **'You already booked a time for this quote.'**
  String get quoteBookingAlreadyBooked;

  /// No description provided for @quoteBookingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This quote can\'t be booked from your account.'**
  String get quoteBookingUnavailable;

  /// No description provided for @providerActiveBookingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Current appointments & jobs'**
  String get providerActiveBookingsTitle;

  /// No description provided for @providerActiveBookingsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You have no active appointments or jobs right now.'**
  String get providerActiveBookingsEmpty;

  /// No description provided for @providerAssignedTechnicianLabel.
  ///
  /// In en, this message translates to:
  /// **'Assigned technician'**
  String get providerAssignedTechnicianLabel;

  /// No description provided for @providerBookingTechnicianValue.
  ///
  /// In en, this message translates to:
  /// **'Assigned to {name}'**
  String providerBookingTechnicianValue(String name);

  /// No description provided for @providerBookingAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Service address'**
  String get providerBookingAddressLabel;

  /// No description provided for @providerBookingDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Problem description'**
  String get providerBookingDescriptionLabel;

  /// No description provided for @providerBookingEstimatedFeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Estimated fee'**
  String get providerBookingEstimatedFeeLabel;

  /// No description provided for @providerBookingStartButton.
  ///
  /// In en, this message translates to:
  /// **'Start Job'**
  String get providerBookingStartButton;

  /// No description provided for @providerBookingStartDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Start this job?'**
  String get providerBookingStartDialogTitle;

  /// No description provided for @providerBookingStartDialogBody.
  ///
  /// In en, this message translates to:
  /// **'The homeowner will see this job as In Progress. Start it when you arrive on site.'**
  String get providerBookingStartDialogBody;

  /// No description provided for @providerBookingStartConfirm.
  ///
  /// In en, this message translates to:
  /// **'Start Job'**
  String get providerBookingStartConfirm;

  /// No description provided for @providerBookingStartKeep.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get providerBookingStartKeep;

  /// No description provided for @providerBookingStartedNotice.
  ///
  /// In en, this message translates to:
  /// **'Job started. The homeowner can now see it as In Progress.'**
  String get providerBookingStartedNotice;

  /// No description provided for @providerBookingStartNotAuthorized.
  ///
  /// In en, this message translates to:
  /// **'You are not authorized to start this job.'**
  String get providerBookingStartNotAuthorized;

  /// No description provided for @providerBookingStartIneligible.
  ///
  /// In en, this message translates to:
  /// **'This job cannot be started in its current state.'**
  String get providerBookingStartIneligible;

  /// No description provided for @providerBookingStartQuotePending.
  ///
  /// In en, this message translates to:
  /// **'The homeowner has not approved the quote for this job yet.'**
  String get providerBookingStartQuotePending;

  /// No description provided for @bookingStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get bookingStatusConfirmed;

  /// No description provided for @bookingStatusAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get bookingStatusAssigned;

  /// No description provided for @bookingStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get bookingStatusInProgress;

  /// No description provided for @bookingStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get bookingStatusCompleted;

  /// No description provided for @bookingStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get bookingStatusCancelled;

  /// No description provided for @bookingStatusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get bookingStatusDeclined;

  /// No description provided for @bookingStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get bookingStatusPending;

  /// No description provided for @providerHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Service records'**
  String get providerHistoryTitle;

  /// No description provided for @providerHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Completed, cancelled, and declined bookings for your account.'**
  String get providerHistorySubtitle;

  /// No description provided for @providerHistoryButton.
  ///
  /// In en, this message translates to:
  /// **'Completed & closed records'**
  String get providerHistoryButton;

  /// No description provided for @providerHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'You have no completed, cancelled, or declined service records yet.'**
  String get providerHistoryEmpty;

  /// No description provided for @providerHistoryLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load service records right now. Please try again.'**
  String get providerHistoryLoadError;

  /// No description provided for @providerBookingCompleteButton.
  ///
  /// In en, this message translates to:
  /// **'Mark as Completed'**
  String get providerBookingCompleteButton;

  /// No description provided for @providerBookingCompleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Job marked as completed! Both you and the homeowner now see it in service history.'**
  String get providerBookingCompleteSuccess;

  /// No description provided for @providerBookingCompleteUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Only the authorized service provider can complete this booking.'**
  String get providerBookingCompleteUnauthorized;

  /// No description provided for @providerBookingCompleteIneligible.
  ///
  /// In en, this message translates to:
  /// **'Only In Progress jobs can be marked as completed.'**
  String get providerBookingCompleteIneligible;

  /// No description provided for @cartCheckoutButton.
  ///
  /// In en, this message translates to:
  /// **'Continue to checkout'**
  String get cartCheckoutButton;

  /// No description provided for @cartCheckoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get cartCheckoutTitle;

  /// No description provided for @cartCheckoutServicesSection.
  ///
  /// In en, this message translates to:
  /// **'Your services'**
  String get cartCheckoutServicesSection;

  /// No description provided for @bookingErrorCartInvalid.
  ///
  /// In en, this message translates to:
  /// **'A service in your cart can no longer be booked. Go back to your cart, check it and try again.'**
  String get bookingErrorCartInvalid;

  /// No description provided for @bookingErrorCartMixedProviders.
  ///
  /// In en, this message translates to:
  /// **'Your cart has services from more than one provider. Keep services from one provider and try again.'**
  String get bookingErrorCartMixedProviders;

  /// No description provided for @bookingSummaryReference.
  ///
  /// In en, this message translates to:
  /// **'Booking reference'**
  String get bookingSummaryReference;

  /// No description provided for @bookingSummaryServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get bookingSummaryServices;

  /// No description provided for @bookingSummaryTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get bookingSummaryTotal;

  /// No description provided for @bookingSummaryItemLine.
  ///
  /// In en, this message translates to:
  /// **'{serviceTitle}: {price}'**
  String bookingSummaryItemLine(String serviceTitle, String price);

  /// No description provided for @technicianJobsTitle.
  ///
  /// In en, this message translates to:
  /// **'My assigned jobs'**
  String get technicianJobsTitle;

  /// No description provided for @technicianJobsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No jobs are assigned to you right now. Jobs your company assigns to you appear here.'**
  String get technicianJobsEmpty;

  /// No description provided for @technicianJobsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your jobs. Check your connection and try again.'**
  String get technicianJobsLoadError;

  /// No description provided for @technicianJobsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading your jobs'**
  String get technicianJobsLoading;

  /// No description provided for @technicianJobDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Job details'**
  String get technicianJobDetailTitle;

  /// No description provided for @technicianJobUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This job isn\'t assigned to you, or it is no longer active.'**
  String get technicianJobUnavailable;

  /// No description provided for @technicianJobAppointmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Appointment'**
  String get technicianJobAppointmentLabel;

  /// No description provided for @technicianJobPreferredTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Preferred time (not confirmed yet)'**
  String get technicianJobPreferredTimeLabel;

  /// No description provided for @technicianJobServiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get technicianJobServiceLabel;

  /// No description provided for @technicianJobStartedNotice.
  ///
  /// In en, this message translates to:
  /// **'Job started. The company and homeowner can now see it as In Progress.'**
  String get technicianJobStartedNotice;

  /// No description provided for @technicianJobCompletedNotice.
  ///
  /// In en, this message translates to:
  /// **'Job marked as completed! The company and homeowner can now see it in service history.'**
  String get technicianJobCompletedNotice;

  /// No description provided for @technicianJobCompleteUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Only the technician assigned to this job can mark it as completed.'**
  String get technicianJobCompleteUnauthorized;

  /// No description provided for @technicianJobAppointmentValue.
  ///
  /// In en, this message translates to:
  /// **'Appointment: {time}'**
  String technicianJobAppointmentValue(String time);

  /// No description provided for @technicianJobPreferredTimeValue.
  ///
  /// In en, this message translates to:
  /// **'Preferred time (not confirmed yet): {time}'**
  String technicianJobPreferredTimeValue(String time);

  /// No description provided for @companyInviteTechnicianButton.
  ///
  /// In en, this message translates to:
  /// **'Invite Technician'**
  String get companyInviteTechnicianButton;

  /// No description provided for @companyInviteTechnicianTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite Company Technician'**
  String get companyInviteTechnicianTitle;

  /// No description provided for @companyInviteTechnicianSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the technician\'s email to generate an activation link for your company.'**
  String get companyInviteTechnicianSubtitle;

  /// No description provided for @companyInviteTechnicianEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Technician Email'**
  String get companyInviteTechnicianEmailLabel;

  /// No description provided for @companyInviteTechnicianEmailHint.
  ///
  /// In en, this message translates to:
  /// **'tech@company.com'**
  String get companyInviteTechnicianEmailHint;

  /// No description provided for @companyInviteTechnicianInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get companyInviteTechnicianInvalidEmail;

  /// No description provided for @companyInviteTechnicianSubmit.
  ///
  /// In en, this message translates to:
  /// **'Create Invite Link'**
  String get companyInviteTechnicianSubmit;

  /// No description provided for @companyInviteTechnicianCreated.
  ///
  /// In en, this message translates to:
  /// **'Activation link created! Share this link with the technician (or open it after signing out to test).'**
  String get companyInviteTechnicianCreated;

  /// No description provided for @companyInviteTechnicianCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get companyInviteTechnicianCopyLink;

  /// No description provided for @companyInviteTechnicianCopied.
  ///
  /// In en, this message translates to:
  /// **'Activation link copied to clipboard.'**
  String get companyInviteTechnicianCopied;

  /// No description provided for @companyInviteTechnicianError.
  ///
  /// In en, this message translates to:
  /// **'Could not create invite. Make sure your company is verified and try again.'**
  String get companyInviteTechnicianError;
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
