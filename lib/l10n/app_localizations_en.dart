// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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
      'Your assigned jobs are below, with where and when to work.';

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

  @override
  String get discoveryLocation => 'Phnom Penh';

  @override
  String get discoveryHomePrompt =>
      'What repair or maintenance service do you need?';

  @override
  String get discoveryBrowseServices => 'Browse services';

  @override
  String get discoveryHomeCategories => 'Service categories';

  @override
  String get discoveryCategoriesTitle => 'Repair & Maintenance';

  @override
  String get discoverySearchLabel => 'Search categories';

  @override
  String get discoveryClearSearch => 'Clear search';

  @override
  String get discoveryNoMatchingCategories =>
      'No categories match your search.';

  @override
  String get discoveryNoCategories =>
      'No service categories are available yet.';

  @override
  String get discoveryLoadingCategories => 'Loading categories';

  @override
  String get discoveryCategoriesError => 'Couldn’t load service categories.';

  @override
  String get discoveryHomeBookings => 'My repair bookings';

  @override
  String get discoveryNoBookings => 'You have no repair bookings yet.';

  @override
  String get discoveryBookingsError => 'Couldn’t load your bookings.';

  @override
  String get discoveryLoadingBookings => 'Loading your bookings';

  @override
  String get providerDirectoryTitle => 'Service providers';

  @override
  String get providerDirectoryEmpty =>
      'No providers are available for this category yet.';

  @override
  String get providerDirectoryError => 'Couldn’t load providers.';

  @override
  String get providerDirectoryRetry => 'Try again';

  @override
  String get providerDirectoryLoading => 'Loading providers';

  @override
  String get providerOtherCategories => 'Browse other categories';

  @override
  String get providerTypeIndependent => 'Independent technician';

  @override
  String get providerTypeCompany => 'Repair company';

  @override
  String get providerProfileTitle => 'Provider profile';

  @override
  String get providerProfileLoading => 'Loading provider profile';

  @override
  String get providerProfileError => 'Couldn’t load this provider’s profile.';

  @override
  String get providerProfileNotFound => 'Provider not found';

  @override
  String get providerProfileNotFoundBody =>
      'This profile is no longer available.';

  @override
  String get providerBack => 'Back to providers';

  @override
  String get providerAvailable => 'Available';

  @override
  String get providerUnavailable => 'Currently unavailable';

  @override
  String get providerSpecialties => 'Specialties';

  @override
  String get providerAreas => 'Service areas';

  @override
  String get providerAbout => 'About';

  @override
  String get providerNoReviews => 'No reviews yet';

  @override
  String get providerRatingUnavailable => 'Rating unavailable';

  @override
  String providerReviewCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString reviews',
      one: '$countString review',
    );
    return '$_temp0';
  }

  @override
  String providerRatingSummary(String score, String reviews) {
    return '$score · $reviews';
  }

  @override
  String providerRatingAnnouncement(String score, String reviews) {
    return '$score out of 5. $reviews';
  }

  @override
  String get providerContinueBooking => 'Continue to booking';

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
  String get bookingProblemPrivacyHelper =>
      'The provider can read this before accepting. Leave out your address and phone number.';

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
  String get bookingInboxTitle => 'Incoming requests';

  @override
  String get bookingInboxDetailTitle => 'Booking request';

  @override
  String get bookingInboxEmpty => 'You have no pending booking requests.';

  @override
  String get bookingInboxUnavailable => 'This booking request is unavailable.';

  @override
  String get bookingInboxPending => 'Pending';

  @override
  String get bookingInboxJobDetails => 'Job details';

  @override
  String get bookingInboxDateUnavailable => 'Appointment time unavailable';

  @override
  String get bookingInboxLoading => 'Loading booking requests';

  @override
  String get bookingInboxError =>
      'Could not load booking requests. Check your connection and try again.';

  @override
  String get bookingInboxRetry => 'Try again';

  @override
  String get offeringCreateTitle => 'Add Service Offering';

  @override
  String get offeringHeaderTitle => 'New Service Offering';

  @override
  String get offeringCreateSubtitle =>
      'Publish a new service offering with fixed or custom quote pricing.';

  @override
  String get offeringCategoryLabel => 'Service Category';

  @override
  String get offeringCategoryHint => 'Select category';

  @override
  String get offeringCategoryRequired => 'Please select a service category.';

  @override
  String get offeringCategoriesEmpty =>
      'There are no active service categories.';

  @override
  String get offeringCategoriesError =>
      'Couldn’t load service categories. Go back and reopen the form to try again.';

  @override
  String get offeringTitleLabel => 'Service Title';

  @override
  String get offeringTitleHint => 'e.g., Inverter Mainboard & PCB Replacement';

  @override
  String get offeringTitleRequired => 'Please enter a service title.';

  @override
  String get offeringTitleMinLength => 'Title must be at least 3 characters.';

  @override
  String get offeringDescLabel => 'Description';

  @override
  String get offeringDescHint =>
      'Explain the scope, prerequisites, or diagnosis required...';

  @override
  String get offeringDescRequired => 'Please enter a description.';

  @override
  String get offeringDescMinLength =>
      'Description must be at least 10 characters.';

  @override
  String get offeringPricingModeLabel => 'Pricing Mode';

  @override
  String get offeringModeQuote => 'Requires custom quote';

  @override
  String get offeringModeQuoteDesc =>
      'Excluded from fixed cart checkout. Customers submit inquiry for custom on-site estimation.';

  @override
  String get offeringNoticeQuoteMode =>
      'Quote Mode Active: Fixed price checkout is disabled. Homeowners will be guided to submit problem details and photos for quote intake.';

  @override
  String get offeringBadgeQuoteRequired => 'Quote Required';

  @override
  String get offeringCtaRequestQuote => 'Request a Quote';

  @override
  String get offeringCtaBookService => 'Book Service';

  @override
  String get offeringNoticeQuoteRequiredBooking =>
      'You are requesting a custom quote for this service. You will not be charged upfront. The provider will review your scope and provide a formal price estimate before work begins.';

  @override
  String get offeringModeFixed => 'Fixed upfront price';

  @override
  String get offeringModeFixedDesc => 'Upfront transparent flat-rate pricing.';

  @override
  String get offeringPriceLabel => 'Base Price (\$)';

  @override
  String get offeringPriceRequired => 'Please enter a valid base price.';

  @override
  String get offeringPricePositive =>
      'Enter an amount greater than zero with up to two decimal places.';

  @override
  String get offeringUnitLabel => 'Pricing Unit (Optional)';

  @override
  String get offeringUnitHint => 'e.g., job, hour, unit';

  @override
  String get offeringCreateButton => 'Publish Offering';

  @override
  String get offeringSuccessSnackbar =>
      'Service offering published successfully!';

  @override
  String get offeringPublishError =>
      'Couldn’t publish your offering. Check your connection and provider access, then try again.';

  @override
  String get offeringUnauthorized =>
      'Only registered service providers and companies can publish offerings.';

  @override
  String get offeringActiveRequired =>
      'Provider account must be active to publish service offerings.';

  @override
  String get offeringDashboardTitle => 'My Service Offerings';

  @override
  String get offeringAddButton => 'Add Offering';

  @override
  String get offeringEmptyNotice =>
      'You have not published any service offerings yet. Tap \"+ Add Offering\" to add fixed-price or quote-required services.';

  @override
  String get offeringLoadError =>
      'Unable to load service offerings right now. Please check your connection and try again.';

  @override
  String get adminDashboardTitle => 'Platform Administration';

  @override
  String get adminPendingProvidersSection => 'Pending provider applications';

  @override
  String get adminApprovedProvidersSection => 'Approved active providers';

  @override
  String get adminPendingProvidersEmpty =>
      'No pending provider applications require review right now.';

  @override
  String get adminPendingBadge => 'Pending verification';

  @override
  String get adminApprovedBadge => 'Approved & active';

  @override
  String get adminProviderReviewTitle => 'Review provider';

  @override
  String get adminReviewAction => 'Review application';

  @override
  String get adminApproveProviderButton => 'Approve provider';

  @override
  String adminProviderApprovedNotice(String provider) {
    return '$provider is now approved, active, and eligible for customer bookings.';
  }

  @override
  String get adminPendingVerificationNotice =>
      'This provider is awaiting verification and is hidden from customer search and bookings.';

  @override
  String get adminVerificationChecklistTitle => 'Verification details';

  @override
  String get adminContactEmailLabel => 'Email address';

  @override
  String get adminContactPhoneLabel => 'Contact phone';

  @override
  String get adminAccessDeniedTitle => 'Admin access required';

  @override
  String get adminAccessDeniedMessage =>
      'Only Platform Admins can review or approve provider accounts.';

  @override
  String get adminViewCustomerProfileButton => 'Preview customer profile';

  @override
  String get companyProfileEdit => 'Edit company profile';

  @override
  String get companyProfileDescription => 'Description (optional)';

  @override
  String get companyProfileDescriptionHint =>
      'Home plumbing and electrical repairs';

  @override
  String get companyProfileAreaHint => 'Sen Sok, Tuol Kork';

  @override
  String get companyProfileAreaRequired => 'Enter a service area.';

  @override
  String get companyProfileContacts => 'Contact links';

  @override
  String get companyProfileOptionalContacts => 'Contact links (optional)';

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
    return 'Enter a link like $example.';
  }

  @override
  String companyProfileLengthError(int limit) {
    return 'Use $limit characters or fewer.';
  }

  @override
  String get companyProfileUnavailable =>
      'No editable company profile is linked to this account.';

  @override
  String get companyProfileLoading => 'Loading company profile';

  @override
  String get companyProfileLoadError => 'Could not load your company profile.';

  @override
  String get companyProfileSaveError =>
      'Could not save your changes. Try again.';

  @override
  String get companyProfileSave => 'Save changes';

  @override
  String get companyProfileSaved => 'Company profile saved.';

  @override
  String get technicianProfileEdit => 'Edit technician profile';

  @override
  String get technicianProfileName => 'Full name';

  @override
  String get technicianProfileNameHint => 'Virak Chan';

  @override
  String get technicianProfileNameRequired => 'Enter your full name.';

  @override
  String get technicianProfileDescription => 'Bio / description (optional)';

  @override
  String get technicianProfileDescriptionHint =>
      'Certified AC technician with 7+ years of experience';

  @override
  String get technicianProfileAreaHint => 'Sen Sok, Tuol Kork';

  @override
  String get technicianProfileAreaRequired => 'Enter a service area.';

  @override
  String get technicianProfileContacts => 'Contact links';

  @override
  String get technicianProfileOptionalContacts => 'Contact links (optional)';

  @override
  String get technicianProfileTelegram => 'Telegram';

  @override
  String get technicianProfileTelegramExample => 'https://t.me/virakchan';

  @override
  String get technicianProfileMessenger => 'Messenger';

  @override
  String get technicianProfileMessengerExample => 'https://m.me/virakchan';

  @override
  String technicianProfileInvalidLink(String example) {
    return 'Enter a link like $example.';
  }

  @override
  String technicianProfileLengthError(int limit) {
    return 'Use $limit characters or fewer.';
  }

  @override
  String get technicianProfileUnavailable =>
      'No editable technician profile is linked to this account.';

  @override
  String get technicianProfileLoading => 'Loading technician profile';

  @override
  String get technicianProfileLoadError =>
      'Could not load your technician profile.';

  @override
  String get technicianProfileSaveError =>
      'Could not save your changes. Try again.';

  @override
  String get technicianProfileSave => 'Save changes';

  @override
  String get technicianProfileSaved => 'Technician profile saved.';

  @override
  String get providerOfferingsSection => 'Available Services & Offerings';

  @override
  String get bookingConfirmedAppointmentLabel => 'Confirmed Appointment';

  @override
  String get bookingPreferredAppointmentLabel => 'Preferred Date & Time';

  @override
  String get providerBookingsTitle => 'Accepted bookings';

  @override
  String get providerBookingsEmpty => 'You have no accepted bookings.';

  @override
  String get providerBookingsLoadError =>
      'Unable to load booking requests right now. Please try again.';

  @override
  String get providerBookingDetailTitle => 'Booking Request';

  @override
  String get providerBookingConfirmButton => 'Confirm Appointment';

  @override
  String get providerBookingConfirmSuccess =>
      'Appointment confirmed! The homeowner can now see the confirmed date and time.';

  @override
  String get providerBookingNotAuthorized =>
      'You are not authorized to confirm this booking.';

  @override
  String get providerBookingIneligible =>
      'This booking cannot be confirmed in its current state.';

  @override
  String get providerBookingReviewAction => 'Review';

  @override
  String get providerAssignmentTitle => 'Assign technician';

  @override
  String get providerAssignmentSave => 'Save assignment';

  @override
  String get providerAssignmentEmpty =>
      'There are no active technicians on your company roster.';

  @override
  String get providerAssignmentLoadError =>
      'Could not load your technicians. Try again.';

  @override
  String get providerAssignmentSaveError =>
      'Could not save the assignment. Open the picker and try again.';

  @override
  String get providerAssignmentIneligible =>
      'This booking can no longer be assigned.';

  @override
  String get providerBookingDeclineButton => 'Decline Request';

  @override
  String get providerBookingDeclineDialogTitle => 'Decline this request?';

  @override
  String get providerBookingDeclineDialogBody =>
      'The homeowner will see this request as Declined. You will not be able to confirm it afterwards.';

  @override
  String get providerBookingDeclineReasonLabel => 'Reason for declining';

  @override
  String get providerBookingDeclineReasonHint =>
      'For example: outside our service area that day';

  @override
  String get providerBookingDeclineReasonRequired =>
      'Add a short reason so the homeowner can make other arrangements.';

  @override
  String get providerBookingDeclineReasonTooLong =>
      'Keep the reason under 300 characters.';

  @override
  String get providerBookingDeclineKeep => 'Keep Request';

  @override
  String get providerBookingDeclineConfirm => 'Confirm Decline';

  @override
  String get providerBookingDeclineSuccess =>
      'Request declined. The homeowner can see this booking as Declined in their history.';

  @override
  String get providerBookingDeclinedNotice =>
      'You declined this request. The homeowner can see it as Declined in their booking history.';

  @override
  String get providerDeclinedRequestsTitle => 'Declined requests';

  @override
  String get providerDeclinedRequestsEmpty => 'You have no declined requests.';

  @override
  String get providerBookingDeclineIneligible =>
      'This request can no longer be declined.';

  @override
  String get providerBookingDeclineNotAuthorized =>
      'You are not authorized to decline this request.';

  @override
  String get cartAddButton => 'Add to cart';

  @override
  String cartAddedSnackbar(String serviceTitle) {
    return 'Added $serviceTitle to cart.';
  }

  @override
  String cartErrorDifferentProvider(String providerName) {
    return 'Your cart already has services from $providerName. Clear your cart before adding from another provider.';
  }

  @override
  String get cartErrorDifferentProviderGeneric =>
      'Your cart already has services from another provider. Clear your cart before adding this service.';

  @override
  String get cartErrorQuoteRequired =>
      'Quote-required services cannot be added to the cart. Use Request a Quote instead.';

  @override
  String get cartErrorUnavailable =>
      'This service is currently unavailable and cannot be added to the cart.';

  @override
  String cartBadgeLabel(int count) {
    return 'Cart ($count)';
  }

  @override
  String cartActiveProviderNotice(int count, String providerName) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count services',
      one: '1 service',
    );
    return 'Cart has $_temp0 from $providerName.';
  }

  @override
  String get cartTitle => 'Cart';

  @override
  String get cartHeading => 'Review your cart';

  @override
  String cartItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count services',
      one: '1 service',
    );
    return '$_temp0';
  }

  @override
  String get cartProviderLabel => 'Provider';

  @override
  String get cartProviderUnknown => 'Provider name unavailable';

  @override
  String cartItemQuantityPrice(int quantity, String price) {
    return '$quantity × $price';
  }

  @override
  String cartRemoveItem(String serviceTitle) {
    return 'Remove $serviceTitle';
  }

  @override
  String get cartTotalLabel => 'Total';

  @override
  String cartTotalSemantics(String price) {
    return 'Total $price';
  }

  @override
  String get cartPaymentNote =>
      'These are the provider\'s fixed prices. No payment is taken in the app; you pay the provider directly after the job.';

  @override
  String get cartEmptyTitle => 'Your cart is empty';

  @override
  String get cartEmptyBody =>
      'Add fixed-price services from a provider\'s page and they will appear here.';

  @override
  String get cartBrowseServices => 'Browse services';

  @override
  String cartOpenSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count services',
      one: '1 service',
    );
    return 'Open cart, $_temp0';
  }

  @override
  String get quoteFormTitle => 'Request a quote';

  @override
  String get quoteFormHeading => 'Describe the job';

  @override
  String quoteFormSubtitle(String provider) {
    return '$provider will review your details and photos and send a price quote.';
  }

  @override
  String get quoteSelectedOfferingLabel => 'Selected service';

  @override
  String get quoteDescriptionHint =>
      'For example: the outdoor AC board clicks and shows an E5 error after a power surge';

  @override
  String get quoteRequestFooterNote =>
      'This quote request stays separate from your cart. You can book a time after you review and approve the provider\'s price.';

  @override
  String get quoteSubmit => 'Send quote request';

  @override
  String get quoteErrorSaveFailed =>
      'We couldn\'t send your quote request. Check your connection and try again.';

  @override
  String get quoteOfferingUnavailable =>
      'This service isn\'t available for quote requests right now.';

  @override
  String get quoteOfferingNotFound =>
      'We couldn\'t find this service offering.';

  @override
  String get quoteSentTitle => 'Quote request sent';

  @override
  String quoteSentMessage(String provider) {
    return '$provider will review your request and send a price quote. Your cart was not changed.';
  }

  @override
  String get quoteStatusLabel => 'Status';

  @override
  String get quoteStatusRequested => 'Requested';

  @override
  String get quoteStatusQuoted => 'Quoted';

  @override
  String get quoteStatusApproved => 'Approved';

  @override
  String get quoteStatusRejected => 'Rejected';

  @override
  String get quoteSummaryProvider => 'Provider';

  @override
  String get quoteSummaryDescription => 'Problem details';

  @override
  String get quoteSentViewStatus => 'View quote request';

  @override
  String get quoteDetailTitle => 'Quote request';

  @override
  String get quoteDetailLoading => 'Loading quote request';

  @override
  String get quoteDetailNotFound => 'We couldn\'t find this quote request.';

  @override
  String get quoteDetailLoadFailed =>
      'Couldn\'t load this quote request. Try again.';

  @override
  String quoteDetailWaitingMessage(String provider) {
    return 'Waiting for $provider to review your details and send a price quote.';
  }

  @override
  String get discoveryHomeQuotes => 'My quote requests';

  @override
  String get discoveryNoQuotes => 'You have no quote requests yet.';

  @override
  String get discoveryQuotesError => 'Couldn\'t load your quote requests.';

  @override
  String get discoveryLoadingQuotes => 'Loading your quote requests';

  @override
  String get quoteLoadMore => 'Show older quote requests';

  @override
  String get providerQuotesTitle => 'Quote requests';

  @override
  String get providerQuotesEmpty => 'No quote requests yet.';

  @override
  String get providerQuotesLoadError =>
      'Couldn\'t load quote requests. Please try again.';

  @override
  String get providerQuoteDetailTitle => 'Quote request';

  @override
  String providerQuotePhotoLabel(int number) {
    return 'Request photo $number';
  }

  @override
  String providerQuotePhotoUnavailable(int number) {
    return 'Photo $number couldn\'t be loaded.';
  }

  @override
  String get providerQuoteNotFoundOrInaccessible =>
      'This quote request isn\'t available for your account.';

  @override
  String get providerQuotePriceLabel => 'Quoted price';

  @override
  String get providerQuotePriceNotSet => 'Not quoted yet';

  @override
  String get providerQuoteCustomerLabel => 'Homeowner';

  @override
  String get providerQuoteDecisionApproved =>
      'The homeowner approved your quoted price.';

  @override
  String get providerQuoteDecisionRejected =>
      'The homeowner declined your quoted price.';

  @override
  String get providerQuoteDecisionWaiting =>
      'Waiting for the homeowner to review your quoted price.';

  @override
  String get providerQuoteDecisionRequested =>
      'No price has been quoted for this request yet.';

  @override
  String get providerQuotePriceSection => 'Your price';

  @override
  String get providerQuotePriceInputLabel => 'Price (USD)';

  @override
  String get providerQuotePriceInputHint => '45.00';

  @override
  String get providerQuotePriceInputHelper =>
      'The homeowner sees this amount and approves it before booking a time.';

  @override
  String get providerQuotePriceRequired => 'Enter the price for this job.';

  @override
  String get providerQuoteSendPrice => 'Send quote';

  @override
  String get providerQuoteErrorAlreadyPriced =>
      'This request already has a price.';

  @override
  String get providerQuoteErrorNotAllowed =>
      'You can\'t price this request from this account.';

  @override
  String get providerQuoteErrorSaveFailed =>
      'We couldn\'t send your price. Check your connection and try again.';

  @override
  String quoteDetailReviewMessage(String provider, String price) {
    return '$provider quoted $price. Approve it to book a time.';
  }

  @override
  String quoteApproveButton(String price) {
    return 'Approve $price';
  }

  @override
  String get quoteApprovedPriceLabel => 'Approved price';

  @override
  String quoteApprovedMessage(String price, String provider) {
    return 'You approved $price. Book a time with $provider.';
  }

  @override
  String get quoteApproveErrorChanged =>
      'This quote has changed. Check its latest status.';

  @override
  String get quoteApproveErrorFailed =>
      'We couldn\'t approve this quote. Check your connection and try again.';

  @override
  String get quoteBookButton => 'Book a time';

  @override
  String get quoteViewBooking => 'View booking';

  @override
  String get quoteBookedMessage =>
      'You booked a time for this quote. Track it on the booking status page.';

  @override
  String get quoteBookingTitle => 'Book a time';

  @override
  String get quoteBookingHeading => 'Choose a time';

  @override
  String quoteBookingSubtitle(String service, String provider) {
    return '$service with $provider';
  }

  @override
  String quoteBookingPriceNote(String price) {
    return 'Your approved price of $price is saved with this request. No payment is taken in the app.';
  }

  @override
  String get quoteBookingSubmit => 'Send booking request';

  @override
  String get quoteBookingNotApproved =>
      'Approve the quoted price before you book a time.';

  @override
  String get quoteBookingAlreadyBooked =>
      'You already booked a time for this quote.';

  @override
  String get quoteBookingUnavailable =>
      'This quote can\'t be booked from your account.';

  @override
  String get providerActiveBookingsTitle => 'Current appointments & jobs';

  @override
  String get providerActiveBookingsEmpty =>
      'You have no active appointments or jobs right now.';

  @override
  String get providerAssignedTechnicianLabel => 'Assigned technician';

  @override
  String providerBookingTechnicianValue(String name) {
    return 'Assigned to $name';
  }

  @override
  String get providerBookingAddressLabel => 'Service address';

  @override
  String get providerBookingDescriptionLabel => 'Problem description';

  @override
  String get providerBookingEstimatedFeeLabel => 'Estimated fee';

  @override
  String get providerBookingStartButton => 'Start Job';

  @override
  String get providerBookingStartDialogTitle => 'Start this job?';

  @override
  String get providerBookingStartDialogBody =>
      'The homeowner will see this job as In Progress. Start it when you arrive on site.';

  @override
  String get providerBookingStartConfirm => 'Start Job';

  @override
  String get providerBookingStartKeep => 'Not yet';

  @override
  String get providerBookingStartedNotice =>
      'Job started. The homeowner can now see it as In Progress.';

  @override
  String get providerBookingStartNotAuthorized =>
      'You are not authorized to start this job.';

  @override
  String get providerBookingStartIneligible =>
      'This job cannot be started in its current state.';

  @override
  String get providerBookingStartQuotePending =>
      'The homeowner has not approved the quote for this job yet.';

  @override
  String get bookingStatusConfirmed => 'Confirmed';

  @override
  String get bookingStatusAssigned => 'Assigned';

  @override
  String get bookingStatusInProgress => 'In Progress';

  @override
  String get bookingStatusCompleted => 'Completed';

  @override
  String get bookingStatusCancelled => 'Cancelled';

  @override
  String get bookingStatusDeclined => 'Declined';

  @override
  String get bookingStatusPending => 'Pending';

  @override
  String get providerHistoryTitle => 'Service records';

  @override
  String get providerHistorySubtitle =>
      'Completed, cancelled, and declined bookings for your account.';

  @override
  String get providerHistoryButton => 'Completed & closed records';

  @override
  String get providerHistoryEmpty =>
      'You have no completed, cancelled, or declined service records yet.';

  @override
  String get providerHistoryLoadError =>
      'Unable to load service records right now. Please try again.';

  @override
  String get providerBookingCompleteButton => 'Mark as Completed';

  @override
  String get providerBookingCompleteSuccess =>
      'Job marked as completed! Both you and the homeowner now see it in service history.';

  @override
  String get providerBookingCompleteUnauthorized =>
      'Only the authorized service provider can complete this booking.';

  @override
  String get providerBookingCompleteIneligible =>
      'Only In Progress jobs can be marked as completed.';

  @override
  String get cartCheckoutButton => 'Continue to checkout';

  @override
  String get cartCheckoutTitle => 'Checkout';

  @override
  String get cartCheckoutServicesSection => 'Your services';

  @override
  String get bookingErrorCartInvalid =>
      'A service in your cart can no longer be booked. Go back to your cart, check it and try again.';

  @override
  String get bookingErrorCartMixedProviders =>
      'Your cart has services from more than one provider. Keep services from one provider and try again.';

  @override
  String get bookingSummaryReference => 'Booking reference';

  @override
  String get bookingSummaryServices => 'Services';

  @override
  String get bookingSummaryTotal => 'Total';

  @override
  String bookingSummaryItemLine(String serviceTitle, String price) {
    return '$serviceTitle: $price';
  }

  @override
  String get technicianJobsTitle => 'My assigned jobs';

  @override
  String get technicianJobsEmpty =>
      'No jobs are assigned to you right now. Jobs your company assigns to you appear here.';

  @override
  String get technicianJobsLoadError =>
      'Couldn\'t load your jobs. Check your connection and try again.';

  @override
  String get technicianJobsLoading => 'Loading your jobs';

  @override
  String get technicianJobDetailTitle => 'Job details';

  @override
  String get technicianJobUnavailable =>
      'This job isn\'t assigned to you, or it is no longer active.';

  @override
  String get technicianJobAppointmentLabel => 'Appointment';

  @override
  String get technicianJobPreferredTimeLabel =>
      'Preferred time (not confirmed yet)';

  @override
  String get technicianJobServiceLabel => 'Service';

  @override
  String get technicianJobStartedNotice =>
      'Job started. The company and homeowner can now see it as In Progress.';

  @override
  String technicianJobAppointmentValue(String time) {
    return 'Appointment: $time';
  }

  @override
  String technicianJobPreferredTimeValue(String time) {
    return 'Preferred time (not confirmed yet): $time';
  }
}
