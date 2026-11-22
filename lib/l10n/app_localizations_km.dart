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
  String get commonBack => 'ត្រឡប់ក្រោយ';

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
    return 'សួស្តី $name';
  }

  @override
  String get homeFallbackName => 'អ្នកប្រើប្រាស់';

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
  String get homeLogOut => 'ចាកចេញពីគណនី';

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
  String get registerCompanyNameLabel => 'ឈ្មោះក្រុមហ៊ុន';

  @override
  String get registerCompanyNameHint => 'ក្រុមហ៊ុនសេវាជួសជុល CoolAir';

  @override
  String get registerCompanyNameRequired => 'សូមបញ្ចូលឈ្មោះក្រុមហ៊ុន។';

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

  @override
  String get discoveryLocation => 'ភ្នំពេញ';

  @override
  String get discoveryHomePrompt => 'តើអ្នកត្រូវការសេវាជួសជុល ឬថែទាំអ្វី?';

  @override
  String get discoveryBrowseServices => 'មើលសេវាកម្ម';

  @override
  String get discoveryHomeCategories => 'ប្រភេទសេវាកម្ម';

  @override
  String get discoveryCategoriesTitle => 'សេវាជួសជុល និងថែទាំ';

  @override
  String get discoverySearchLabel => 'ស្វែងរកប្រភេទសេវា';

  @override
  String get discoveryClearSearch => 'សម្អាតការស្វែងរក';

  @override
  String get discoveryNoMatchingCategories =>
      'រកមិនឃើញប្រភេទសេវាដែលត្រូវនឹងការស្វែងរករបស់អ្នកទេ។';

  @override
  String get discoveryNoCategories => 'មិនទាន់មានប្រភេទសេវាកម្មទេ។';

  @override
  String get discoveryLoadingCategories => 'កំពុងផ្ទុកប្រភេទសេវាកម្ម';

  @override
  String get discoveryCategoriesError => 'មិនអាចផ្ទុកប្រភេទសេវាកម្មបានទេ។';

  @override
  String get discoveryHomeBookings => 'ការកក់សេវាជួសជុលរបស់ខ្ញុំ';

  @override
  String get discoveryNoBookings => 'អ្នកមិនទាន់បានកក់សេវាជួសជុលទេ។';

  @override
  String get discoveryBookingsError => 'មិនអាចផ្ទុកការកក់របស់អ្នកបានទេ។';

  @override
  String get discoveryLoadingBookings => 'កំពុងផ្ទុកការកក់របស់អ្នក';

  @override
  String get providerDirectoryTitle => 'អ្នកផ្តល់សេវា';

  @override
  String get providerDirectoryEmpty =>
      'មិនទាន់មានអ្នកផ្តល់សេវាសម្រាប់ប្រភេទនេះទេ។';

  @override
  String get providerDirectoryError => 'មិនអាចផ្ទុកបញ្ជីអ្នកផ្តល់សេវាបានទេ។';

  @override
  String get providerDirectoryRetry => 'ព្យាយាមម្តងទៀត';

  @override
  String get providerDirectoryLoading => 'កំពុងផ្ទុកបញ្ជីអ្នកផ្តល់សេវា';

  @override
  String get providerOtherCategories => 'មើលប្រភេទសេវាផ្សេងទៀត';

  @override
  String get providerTypeIndependent => 'ជាងជួសជុលឯករាជ្យ';

  @override
  String get providerTypeCompany => 'ក្រុមហ៊ុនជួសជុល';

  @override
  String get providerProfileTitle => 'ព័ត៌មានអ្នកផ្តល់សេវា';

  @override
  String get providerProfileLoading => 'កំពុងផ្ទុកព័ត៌មានអ្នកផ្តល់សេវា';

  @override
  String get providerProfileError => 'មិនអាចផ្ទុកព័ត៌មានអ្នកផ្តល់សេវានេះបានទេ។';

  @override
  String get providerProfileNotFound => 'រកមិនឃើញអ្នកផ្តល់សេវា';

  @override
  String get providerProfileNotFoundBody => 'ព័ត៌មាននេះលែងអាចមើលបានហើយ។';

  @override
  String get providerBack => 'ត្រឡប់ទៅបញ្ជីអ្នកផ្តល់សេវា';

  @override
  String get providerAvailable => 'អាចទទួលការកក់';

  @override
  String get providerUnavailable => 'មិនអាចទទួលការកក់ឥឡូវនេះ';

  @override
  String get providerSpecialties => 'ជំនាញ';

  @override
  String get providerAreas => 'តំបន់ផ្តល់សេវា';

  @override
  String get providerAbout => 'អំពីអ្នកផ្តល់សេវា';

  @override
  String get providerNoReviews => 'មិនទាន់មានការវាយតម្លៃ';

  @override
  String get providerRatingUnavailable => 'មិនមានព័ត៌មានវាយតម្លៃ';

  @override
  String providerReviewCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'ការវាយតម្លៃ $countString';
  }

  @override
  String providerRatingSummary(String score, String reviews) {
    return '$score · $reviews';
  }

  @override
  String providerRatingAnnouncement(String score, String reviews) {
    return '$score លើ ៥ ពិន្ទុ។ $reviews';
  }

  @override
  String get providerContinueBooking => 'បន្តទៅការកក់';

  @override
  String get bookingFormTitle => 'Book a repair';

  @override
  String get bookingFormHeading => 'Request a repair';

  @override
  String bookingFormSubtitle(String provider) {
    return '$provider will review your request and confirm or decline it.';
  }

  @override
  String get bookingServiceSection => 'Which service do you need?';

  @override
  String get bookingServiceGeneral => 'General repair visit';

  @override
  String get bookingProblemSection => 'What\'s wrong?';

  @override
  String get bookingProblemLabel => 'Describe the problem';

  @override
  String get bookingProblemHint =>
      'For example: the bedroom AC blows warm air and drips water';

  @override
  String get bookingAddressLabel => 'Repair address';

  @override
  String get bookingAddressHint => 'House no., street, sangkat, khan';

  @override
  String get bookingAddressHelper =>
      'Include the street and khan so the technician can find you.';

  @override
  String get bookingWhereSection => 'Where is the repair?';

  @override
  String get bookingLocationAdd => 'Pin it on the map';

  @override
  String get bookingLocationAddHelper =>
      'Optional. Helps the technician find a borey or alley.';

  @override
  String get bookingLocationPinned => 'Pinned on the map';

  @override
  String get bookingLocationChange => 'Change pin';

  @override
  String get bookingLocationRemove => 'Remove pin';

  @override
  String get bookingPhotosLabel => 'Photos';

  @override
  String bookingPhotosHelper(int max, int mb) {
    return 'Optional. Up to $max photos, $mb MB each. They help the provider bring the right parts.';
  }

  @override
  String get bookingPhotosAdd => 'Add photo';

  @override
  String get bookingPhotosTake => 'Take a photo';

  @override
  String get bookingPhotosChoose => 'Choose from gallery';

  @override
  String bookingPhotoRemove(int number) {
    return 'Remove photo $number';
  }

  @override
  String bookingPhotoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos attached',
      one: '1 photo attached',
    );
    return '$_temp0';
  }

  @override
  String bookingErrorTooManyPhotos(int max) {
    return 'You can add up to $max photos.';
  }

  @override
  String bookingErrorPhotoTooLarge(int mb) {
    return 'Each photo must be $mb MB or smaller. Choose a smaller photo.';
  }

  @override
  String get bookingErrorPhotoPick =>
      'We couldn\'t open your photos. Check the app\'s camera and photo permissions.';

  @override
  String get bookingSummaryPhotos => 'Photos';

  @override
  String get locationPickerTitle => 'Pin the repair address';

  @override
  String get locationPickerHint =>
      'Move the map until the pin sits on the place that needs the repair.';

  @override
  String get locationPickerConfirm => 'Use this location';

  @override
  String get locationPickerZoomIn => 'Zoom in';

  @override
  String get locationPickerZoomOut => 'Zoom out';

  @override
  String get bookingWhenSection => 'When should they come?';

  @override
  String get bookingDateLabel => 'Date';

  @override
  String get bookingTimeLabel => 'Time';

  @override
  String get bookingDatePlaceholder => 'Choose a date';

  @override
  String get bookingTimePlaceholder => 'Choose a time';

  @override
  String get bookingEstimateLabel => 'Starting price';

  @override
  String bookingEstimateValue(String price) {
    return 'From $price';
  }

  @override
  String get bookingPaymentNote =>
      'This is a request, not a payment. You pay the provider directly after the job, once the final price is agreed.';

  @override
  String get bookingSubmit => 'Send booking request';

  @override
  String get bookingErrorServiceRequired => 'Choose the service you need.';

  @override
  String get bookingErrorDescriptionRequired =>
      'Describe the problem so the provider knows what to expect.';

  @override
  String bookingErrorDescriptionTooShort(int min) {
    return 'Add a little more detail (at least $min characters).';
  }

  @override
  String bookingErrorDescriptionTooLong(int max) {
    return 'Keep the description under $max characters.';
  }

  @override
  String get bookingErrorAddressRequired =>
      'Enter the address where the repair is needed.';

  @override
  String get bookingErrorAddressTooShort =>
      'Add your street and khan so the technician can find you.';

  @override
  String bookingErrorAddressTooLong(int max) {
    return 'Keep the address under $max characters.';
  }

  @override
  String get bookingErrorDateTimeRequired => 'Choose a date and a time.';

  @override
  String bookingErrorDateTimeTooSoon(int hours) {
    return 'Choose a time at least $hours hour from now.';
  }

  @override
  String bookingErrorDateTimeTooFar(int days) {
    return 'Choose a date within the next $days days.';
  }

  @override
  String get bookingErrorSaveFailed =>
      'We couldn\'t send your request. Check your connection and try again.';

  @override
  String bookingProviderUnavailable(String provider) {
    return '$provider isn\'t taking new bookings right now.';
  }

  @override
  String get bookingProviderNotFound => 'We couldn\'t find this provider.';

  @override
  String get bookingSentTitle => 'Request sent';

  @override
  String bookingSentMessage(String provider) {
    return '$provider will review it and confirm or decline. You\'ll see their answer on the booking status page.';
  }

  @override
  String get bookingSentMessageGeneric =>
      'The provider will review it and confirm or decline. You\'ll see their answer on the booking status page.';

  @override
  String get bookingSummaryService => 'Service';

  @override
  String get bookingSummaryWhen => 'Date and time';

  @override
  String get bookingSummaryAddress => 'Address';

  @override
  String get bookingSentViewStatus => 'View booking status';

  @override
  String get bookingSentBackHome => 'Back to home';

  @override
  String get adminDashboardTitle => 'ការគ្រប់គ្រងប្រព័ន្ធ';

  @override
  String get adminPendingProvidersSection =>
      'ពាក្យស្នើសុំអ្នកផ្តល់សេវាដែលកំពុងរង់ចាំ';

  @override
  String get adminApprovedProvidersSection => 'អ្នកផ្តល់សេវាដែលបានអនុម័ត';

  @override
  String get adminPendingProvidersEmpty =>
      'មិនមានពាក្យស្នើសុំអ្នកផ្តល់សេវាដែលត្រូវពិនិត្យទេ។';

  @override
  String get adminPendingBadge => 'កំពុងរង់ចាំការផ្ទៀងផ្ទាត់';

  @override
  String get adminApprovedBadge => 'បានអនុម័ត និងសកម្ម';

  @override
  String get adminProviderReviewTitle => 'ពិនិត្យអ្នកផ្តល់សេវា';

  @override
  String get adminReviewAction => 'ពិនិត្យពាក្យស្នើសុំ';

  @override
  String get adminApproveProviderButton => 'អនុម័តអ្នកផ្តល់សេវា';

  @override
  String adminProviderApprovedNotice(String provider) {
    return '$provider ត្រូវបានអនុម័ត សកម្ម និងអាចទទួលការកក់ពីអតិថិជនបាន។';
  }

  @override
  String get adminPendingVerificationNotice =>
      'អ្នកផ្តល់សេវានេះកំពុងរង់ចាំការផ្ទៀងផ្ទាត់ ហើយមិនទាន់បង្ហាញក្នុងការស្វែងរករបស់អតិថិជនទេ។';

  @override
  String get adminVerificationChecklistTitle => 'ព័ត៌មានផ្ទៀងផ្ទាត់';

  @override
  String get adminContactEmailLabel => 'អ៊ីមែល';

  @override
  String get adminContactPhoneLabel => 'លេខទូរស័ព្ទទំនាក់ទំនង';

  @override
  String get adminAccessDeniedTitle => 'តម្រូវឱ្យមានសិទ្ធិអ្នកគ្រប់គ្រង';

  @override
  String get adminAccessDeniedMessage =>
      'មានតែអ្នកគ្រប់គ្រងប្រព័ន្ធប៉ុណ្ណោះដែលអាចពិនិត្យ ឬអនុម័តគណនីអ្នកផ្តល់សេវាបាន។';

  @override
  String get adminViewCustomerProfileButton => 'មើលទម្រង់សម្រាប់អតិថិជន';

  @override
  String get companyProfileEdit => 'កែព័ត៌មានក្រុមហ៊ុន';

  @override
  String get companyProfileDescription => 'ការពិពណ៌នា (ស្រេចចិត្ត)';

  @override
  String get companyProfileDescriptionHint =>
      'ជួសជុលប្រព័ន្ធទឹក និងអគ្គិសនីតាមផ្ទះ';

  @override
  String get companyProfileAreaHint => 'សែនសុខ ទួលគោក';

  @override
  String get companyProfileAreaRequired => 'សូមបញ្ចូលតំបន់ផ្តល់សេវា។';

  @override
  String get companyProfileContacts => 'តំណទំនាក់ទំនង';

  @override
  String get companyProfileOptionalContacts => 'តំណទំនាក់ទំនង (ស្រេចចិត្ត)';

  @override
  String get companyProfileTelegram => 'Telegram';

  @override
  String get companyProfileTelegramExample => 'https://t.me/coolair';

  @override
  String get companyProfileMessenger => 'Messenger';

  @override
  String get companyProfileMessengerExample => 'https://m.me/coolair';

  @override
  String companyProfileInvalidLink(String example) {
    return 'សូមបញ្ចូលតំណដូចជា $example។';
  }

  @override
  String companyProfileLengthError(int limit) {
    return 'សូមប្រើអក្សរមិនលើសពី $limit តួ។';
  }

  @override
  String get companyProfileUnavailable =>
      'គណនីនេះមិនមានព័ត៌មានក្រុមហ៊ុនដែលអាចកែបានទេ។';

  @override
  String get companyProfileLoading => 'កំពុងផ្ទុកព័ត៌មានក្រុមហ៊ុន';

  @override
  String get companyProfileLoadError =>
      'មិនអាចផ្ទុកព័ត៌មានក្រុមហ៊ុនរបស់អ្នកបានទេ។';

  @override
  String get companyProfileSaveError =>
      'មិនអាចរក្សាទុកការកែប្រែបានទេ។ សូមព្យាយាមម្តងទៀត។';

  @override
  String get companyProfileSave => 'រក្សាទុកការកែប្រែ';

  @override
  String get companyProfileSaved => 'បានរក្សាទុកព័ត៌មានក្រុមហ៊ុនហើយ។';
}
