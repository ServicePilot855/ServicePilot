// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Khmer Central Khmer (`km`).
class AppLocalizationsKm extends AppLocalizations {
  AppLocalizationsKm([String locale = 'km']) : super(locale);

  @override
  String get appName => 'ServicePilot';

  @override
  String get commonBack => 'Back';

  @override
  String get commonOr => 'or';

  @override
  String commonLoading(String label) {
    return '$label, loading';
  }

  @override
  String commonStepOf(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String commonStepCount(int step, int total) {
    return '$step of $total';
  }

  @override
  String get commonShowPassword => 'Show password';

  @override
  String get commonHidePassword => 'Hide password';

  @override
  String get commonLogInLink => 'Log in';

  @override
  String get commonAlreadyHaveAccount => 'Already have an account?';

  @override
  String get commonBackToLogin => 'Back to Login';

  @override
  String get commonYourDetails => 'Your details';

  @override
  String get commonSecurity => 'Security';

  @override
  String get commonFullNameLabel => 'Full Name';

  @override
  String get commonEmailAddressLabel => 'Email Address';

  @override
  String get commonPhoneCambodiaLabel => 'Phone Number (Cambodia)';

  @override
  String get commonPasswordLabel => 'Password';

  @override
  String get commonConfirmPasswordLabel => 'Confirm Password';

  @override
  String get commonPasswordHint => 'Min. 8 characters';

  @override
  String get commonRepeatPasswordHint => 'Repeat your password';

  @override
  String get commonFullNameRequired => 'Full name is required';

  @override
  String get commonEmailRequired => 'Email is required';

  @override
  String get commonEmailInvalid => 'Please enter a valid email address';

  @override
  String get commonPhoneRequired => 'Phone number is required';

  @override
  String get commonPhoneInvalid => 'Enter a valid Cambodian phone (+855...)';

  @override
  String get commonPasswordRequired => 'Password is required';

  @override
  String get commonPasswordMinLength => 'Must be at least 8 characters';

  @override
  String get commonPasswordsDoNotMatch => 'Passwords do not match';

  @override
  String get commonInvalidLinkTitle => 'Invalid or Expired Link';

  @override
  String get roleHomeowner => 'Customer';

  @override
  String get roleIndependentProvider => 'Independent Technician';

  @override
  String get roleCompany => 'Service Company';

  @override
  String get roleCompanyTechnician => 'Company Technician';

  @override
  String get roleAdmin => 'Platform Admin';

  @override
  String get splashTagline => 'Home repairs, booked in one place.';

  @override
  String get splashFootnote =>
      'Student prototype · Phnom Penh · Sample data only';

  @override
  String get loginTitle => 'Welcome back';

  @override
  String get loginSubtitle => 'Log in to book and track your home services.';

  @override
  String get loginIdentifierLabel => 'Phone number or email';

  @override
  String get loginIdentifierHint => 'name@example.com or 012 345 678';

  @override
  String get loginIdentifierRequired =>
      'Please enter your phone number or email';

  @override
  String get loginPasswordHint => 'Your password';

  @override
  String get loginPasswordRequired => 'Please enter your password';

  @override
  String get loginPasswordMinLength => 'Password must be at least 8 characters';

  @override
  String get loginRememberMe => 'Remember me';

  @override
  String get loginForgotPassword => 'Forgot password?';

  @override
  String get loginSubmit => 'Log In';

  @override
  String get loginGoogle => 'Continue with Google (Customer)';

  @override
  String get loginNewPrompt => 'New to ServicePilot?';

  @override
  String get loginCreateAccount => 'Create an account';

  @override
  String get roleSelectTitle => 'How will you use ServicePilot?';

  @override
  String get roleSelectSubtitle =>
      'Pick one. You can create another account later.';

  @override
  String get roleSelectHomeownerTitle => 'Homeowner';

  @override
  String get roleSelectHomeownerDesc => 'Find, book and track home services';

  @override
  String get roleSelectHomeownerContinue => 'Continue as homeowner';

  @override
  String get roleSelectProviderTitle => 'Service provider';

  @override
  String get roleSelectProviderDesc =>
      'Accept requests, send quotes, update jobs';

  @override
  String get roleSelectProviderContinue => 'Continue as service provider';

  @override
  String get roleSelectCompanyTitle => 'Service company';

  @override
  String get roleSelectCompanyDesc => 'Assign technicians to customer bookings';

  @override
  String get roleSelectCompanyContinue => 'Continue as service company';

  @override
  String homeGreeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get homeFallbackName => 'User';

  @override
  String homeNameWithCompany(String name, String company) {
    return '$name · $company';
  }

  @override
  String get homeSignedIn => 'Signed in';

  @override
  String get homeComingSoonNotice =>
      'Booking, tracking and provider tools arrive in the next sprint.';

  @override
  String get homeLogOut => 'Log out';

  @override
  String get homeAdminGreeting =>
      'The platform admin dashboard is coming soon.';

  @override
  String get homeCompanyGreeting =>
      'Your team management and booking overview are coming soon.';

  @override
  String get homeCompanyTechnicianGreeting =>
      'Your assigned jobs and schedule are coming soon.';

  @override
  String get homeCustomerGreeting =>
      'Your home repair booking dashboard is coming soon.';

  @override
  String get homeTechnicianGreeting =>
      'Your job board and earnings dashboard are coming soon.';

  @override
  String get registerContinue => 'Continue';

  @override
  String get registerPasswordTitle => 'Set up your password';

  @override
  String registerPasswordSubtitle(String email) {
    return 'You will log in with $email and this password.';
  }

  @override
  String get registerRuleLength => 'At least 8 characters';

  @override
  String get registerRuleMatch => 'Both passwords match';

  @override
  String get registerRuleMet => 'done';

  @override
  String get registerRuleNotMet => 'not yet';

  @override
  String get registerOk => 'OK';

  @override
  String get registerCustomerTitle => 'Customer Registration';

  @override
  String get registerCustomerSubmit => 'Create Account';

  @override
  String get registerCustomerHeaderTitle => 'Book repair services';

  @override
  String get registerCustomerHeaderSubtitle =>
      'Create your account to order fixes and maintenance.';

  @override
  String get registerCustomerGoogleButton => 'Sign up with Google';

  @override
  String get registerCustomerOrUseEmail => 'or use your email';

  @override
  String get registerCustomerNameHint => 'Sok Dara';

  @override
  String get registerCustomerNameTooLong => 'Must be 100 characters or fewer';

  @override
  String get registerCustomerEmailHint => 'sok.dara@example.com';

  @override
  String get registerCustomerPhoneHint => '+855 12 345 678 or 012 345 678';

  @override
  String get registerCustomerSuccessTitle => 'Account Created!';

  @override
  String get registerCustomerSuccessMessage =>
      'Your homeowner account has been created. You can now log in to browse providers and book services.';

  @override
  String get registerCustomerGoToLogin => 'Go to Login';

  @override
  String get registerTechnicianTitle => 'Technician Registration';

  @override
  String get registerTechnicianSubmit => 'Register as Technician';

  @override
  String get registerTechnicianHeaderTitle => 'Offer your skills';

  @override
  String get registerTechnicianHeaderSubtitle =>
      'Register as an independent service provider in Phnom Penh.';

  @override
  String get registerTechnicianNotice =>
      'Your account will have Pending Verification status until approved by the platform. You will be notified once active.';

  @override
  String get registerTechnicianNameHint => 'Virak Chan';

  @override
  String get registerTechnicianNameTooLong =>
      'Full name must not exceed 100 characters';

  @override
  String get registerTechnicianEmailHint => 'virak.chan@example.com';

  @override
  String get registerTechnicianPhoneHint => '+855 87 654 321 or 087 654 321';

  @override
  String get registerTechnicianServiceAreaLabel => 'Service Area / Sangkat';

  @override
  String get registerTechnicianServiceAreaHint =>
      'e.g. Toul Kork, Sen Sok, Daun Penh';

  @override
  String get registerTechnicianServiceAreaRequired =>
      'Service area is required';

  @override
  String get registerTechnicianServiceAreaTooLong =>
      'Service area must not exceed 300 characters';

  @override
  String get registerTechnicianConfirmPasswordRequired =>
      'Please confirm your password';

  @override
  String get registerTechnicianSuccessTitle => 'Pending Review';

  @override
  String get registerTechnicianSuccessMessage =>
      'Your independent technician account has been submitted! Our team checks provider skills and IDs before activating bookings.';

  @override
  String get registerCompanyTitle => 'Company Registration';

  @override
  String get registerCompanySubmit => 'Register Company';

  @override
  String get registerCompanyHeaderTitle => 'Manage your team';

  @override
  String get registerCompanyHeaderSubtitle =>
      'Register your repair or maintenance company on ServicePilot.';

  @override
  String get registerCompanyNotice =>
      'Company accounts undergo business verification before receiving customer bookings. We check registration and contact details.';

  @override
  String get registerCompanyDetailsSection => 'Company details';

  @override
  String get registerCompanyOwnerNameLabel => 'Owner / Admin Full Name';

  @override
  String get registerCompanyOwnerNameHint => 'Sophea Lim';

  @override
  String get registerCompanyOwnerNameRequired => 'Owner full name is required';

  @override
  String get registerCompanyNameLabel => 'Company Name';

  @override
  String get registerCompanyNameHint => 'CoolAir Service Co.';

  @override
  String get registerCompanyNameRequired => 'Company name is required';

  @override
  String get registerCompanyNameTooLong => 'Must be 150 characters or fewer';

  @override
  String get registerCompanyEmailLabel => 'Company Email Address';

  @override
  String get registerCompanyEmailHint => 'contact@company.com';

  @override
  String get registerCompanyPhoneLabel => 'Contact Phone Number';

  @override
  String get registerCompanyPhoneHint => '+855 11 223 344';

  @override
  String get registerCompanyAddressLabel => 'Office Address & Service Area';

  @override
  String get registerCompanyAddressHint =>
      'e.g. St. 315, Toul Kork (Serves Sen Sok, 7 Makara)';

  @override
  String get registerCompanyAddressRequired =>
      'Address and service area are required';

  @override
  String get registerCompanySuccessTitle => 'Company Registered';

  @override
  String get registerCompanySuccessMessage =>
      'Your company profile and owner administrator account have been created! Once verified, you will be able to add technicians and accept customer bookings.';

  @override
  String get activationTitle => 'Activate Account';

  @override
  String get activationSubmit => 'Activate Account';

  @override
  String get activationSuccessTitle => 'Account Activated!';

  @override
  String get activationSuccessMessage =>
      'Your company technician account is active. You can now log in to view assigned repair jobs.';

  @override
  String get activationGoToLogin => 'Go to Login';

  @override
  String get activationInvalidLinkMessage =>
      'This technician invitation link is invalid or has expired. Please ask your company administrator to send you a new invitation.';

  @override
  String get activationHeaderTitle => 'Complete your account';

  @override
  String get activationHeaderSubtitle =>
      'Set your full name and password to activate your company technician profile.';

  @override
  String get activationDefaultCompanyName => 'Service Partner Company';

  @override
  String get activationInvitedRole => 'Invited Company Technician';

  @override
  String get activationEmailLabel => 'Email Address (From invitation)';

  @override
  String get activationFullNameHint => 'Borey Nhem';

  @override
  String get activationPasswordLabel => 'Create Password';

  @override
  String get forgotPasswordTitle => 'Reset Password';

  @override
  String get forgotPasswordSubmit => 'Send Reset Link';

  @override
  String get forgotPasswordHeaderTitle => 'Forgot your password?';

  @override
  String get forgotPasswordHeaderSubtitle =>
      'Enter the email you signed up with and we will send you a reset link.';

  @override
  String get forgotPasswordEmailHint => 'you@example.com';

  @override
  String get forgotPasswordSentTitle => 'Check your inbox';

  @override
  String get forgotPasswordSentMessage =>
      'We sent a time-limited password reset link to:';

  @override
  String get forgotPasswordResend => 'Didn\'t get it? Resend email';

  @override
  String forgotPasswordResendCountdown(int seconds) {
    return 'Resend email in ${seconds}s';
  }

  @override
  String get resetPasswordTitle => 'Create New Password';

  @override
  String get resetPasswordSubmit => 'Reset Password';

  @override
  String get resetPasswordSuccessTitle => 'Password Reset!';

  @override
  String get resetPasswordSuccessMessage =>
      'Your password has been successfully updated. You can now log in with your new credentials.';

  @override
  String get resetPasswordGoToLogin => 'Go to Login';

  @override
  String get resetPasswordRequestNewLink => 'Request New Link';

  @override
  String get resetPasswordInvalidLinkMessage =>
      'This password reset link is invalid or has already been used. Please request a new link.';

  @override
  String get resetPasswordHeaderTitle => 'Set new password';

  @override
  String get resetPasswordHeaderSubtitle => 'Use at least 8 characters.';

  @override
  String get resetPasswordNewPasswordLabel => 'New Password';

  @override
  String get resetPasswordConfirmLabel => 'Confirm New Password';

  @override
  String get resetPasswordConfirmHint => 'Repeat your new password';

  @override
  String get resetPasswordStrengthHint =>
      'Add a capital letter and a number to make it stronger.';

  @override
  String get resetPasswordStrengthWeak => 'Strength: Weak';

  @override
  String get resetPasswordStrengthGood => 'Strength: Good';

  @override
  String get resetPasswordStrengthStrong => 'Strength: Strong';
}
