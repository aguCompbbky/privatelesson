import 'package:easy_localization/easy_localization.dart';

/// Single access point for translated user-facing texts.
///
/// Every getter resolves the translation when it is called, so a language
/// change is reflected the next time the widget tree rebuilds.
abstract final class TextUtils {
  /// Application title.
  static String get appTitle => _AppKeys.appTitle.tr();

  /// Title of the placeholder home page.
  static String get homeTitle => _AppKeys.homeTitle.tr();

  /// Message of the placeholder home page.
  static String get homeMessage => _AppKeys.homeMessage.tr();

  /// Title of the login page.
  static String get loginTitle => _AppKeys.loginTitle.tr();

  /// Label of the Google sign-in action.
  static String get signInWithGoogle => _AppKeys.signInWithGoogle.tr();

  /// Accessible status announced while sign-in is pending.
  static String get signingIn => _AppKeys.signingIn.tr();

  /// Message shown when the user cancels sign-in.
  static String get signInCancelled => _AppKeys.signInCancelled.tr();

  /// Message shown when the authentication service cannot be reached.
  static String get signInConnectionError =>
      _AppKeys.signInConnectionError.tr();

  /// Message shown when identity authentication fails.
  static String get signInAuthenticationError =>
      _AppKeys.signInAuthenticationError.tr();

  /// Message shown when the authenticated profile cannot be loaded.
  static String get signInProfileLoadingError =>
      _AppKeys.signInProfileLoadingError.tr();

  /// Label for switching to English.
  static String get switchToEnglish => _AppKeys.switchToEnglish.tr();

  /// Label for switching to Turkish.
  static String get switchToTurkish => _AppKeys.switchToTurkish.tr();

  /// Label of the sign-out action.
  static String get signOut => _AppKeys.signOut.tr();

  /// Title of the profile completion page.
  static String get completeProfileTitle => _AppKeys.completeProfileTitle.tr();

  /// Label of the editable display name.
  static String get displayNameLabel => _AppKeys.displayNameLabel.tr();

  /// Label of the profile role selector.
  static String get roleLabel => _AppKeys.roleLabel.tr();

  /// Translated student role.
  static String get studentRole => _AppKeys.studentRole.tr();

  /// Translated teacher role.
  static String get teacherRole => _AppKeys.teacherRole.tr();

  /// Label of the profile save action.
  static String get saveProfile => _AppKeys.saveProfile.tr();

  /// Accessible status while a profile is saving.
  static String get savingProfile => _AppKeys.savingProfile.tr();

  /// Validation message for a blank display name.
  static String get profileInvalidDisplayName =>
      _AppKeys.profileInvalidDisplayName.tr();

  /// Validation message for an invalid user identifier.
  static String get profileInvalidUserId => _AppKeys.profileInvalidUserId.tr();

  /// Message for a profile read failure.
  static String get profileLoadFailed => _AppKeys.profileLoadFailed.tr();

  /// Message for a profile write failure.
  static String get profileSaveFailed => _AppKeys.profileSaveFailed.tr();

  /// Title of the lesson listings page.
  static String get listingsTitle => _AppKeys.listingsTitle.tr();

  /// Title of the listing detail page.
  static String get listingDetailTitle => _AppKeys.listingDetailTitle.tr();

  /// Accessible action returning to the listings.
  static String get backToListings => _AppKeys.backToListings.tr();

  /// Label of the listing search input.
  static String get listingsSearch => _AppKeys.listingsSearch.tr();

  /// Label for all delivery modes.
  static String get allDeliveryModes => _AppKeys.allDeliveryModes.tr();

  /// Label of the delivery mode filter.
  static String get deliveryModeLabel => _AppKeys.deliveryModeLabel.tr();

  /// Label of in-person lessons.
  static String get inPersonLesson => _AppKeys.inPersonLesson.tr();

  /// Label of online lessons.
  static String get onlineLesson => _AppKeys.onlineLesson.tr();

  /// Label of recorded lessons.
  static String get recordedVideoLesson => _AppKeys.recordedVideoLesson.tr();

  /// Label of the certificate declaration filter.
  static String get certificateOnly => _AppKeys.certificateOnly.tr();

  /// Notice that listing filters are active.
  static String get activeListingFilters => _AppKeys.activeListingFilters.tr();

  /// Action clearing every listing filter.
  static String get clearListingFilters => _AppKeys.clearListingFilters.tr();

  /// Accessible status while listings are loading.
  static String get listingsLoading => _AppKeys.listingsLoading.tr();

  /// Accessible status while detail is loading.
  static String get listingDetailLoading => _AppKeys.listingDetailLoading.tr();

  /// Message when no listings match the criteria.
  static String get noListings => _AppKeys.noListings.tr();

  /// Action retrying a listing request.
  static String get retryListings => _AppKeys.retryListings.tr();

  /// Message for a missing listing.
  static String get listingNotFound => _AppKeys.listingNotFound.tr();

  /// Message for a listing connection failure.
  static String get listingConnectionError =>
      _AppKeys.listingConnectionError.tr();

  /// Message for a listing storage failure.
  static String get listingStorageError => _AppKeys.listingStorageError.tr();

  /// Fallback for other controlled listing failures.
  static String get listingLoadError => _AppKeys.listingLoadError.tr();

  /// Status when a teacher declares a certificate.
  static String get certificateAvailable => _AppKeys.certificateAvailable.tr();

  /// Status when no certificate is declared.
  static String get certificateNotProvided =>
      _AppKeys.certificateNotProvided.tr();

  /// Heading of the teacher-provided lesson description.
  static String get lessonDescription => _AppKeys.lessonDescription.tr();

  /// Heading of the external contact section.
  static String get contactTeacher => _AppKeys.contactTeacher.tr();

  /// Action opening the published WhatsApp number.
  static String get contactWhatsApp => _AppKeys.contactWhatsApp.tr();

  /// Action opening the published email address.
  static String get contactEmail => _AppKeys.contactEmail.tr();

  /// Accessible status for a pending contact action.
  static String get contactOpening => _AppKeys.contactOpening.tr();

  /// Message offering a fallback when an external app cannot open.
  static String get contactCannotOpen => _AppKeys.contactCannotOpen.tr();

  /// Message for an invalid published contact value.
  static String get contactInvalidValue => _AppKeys.contactInvalidValue.tr();

  /// Message for a clipboard failure.
  static String get contactClipboardFailed =>
      _AppKeys.contactClipboardFailed.tr();

  /// Action copying the affected contact value.
  static String get copyContact => _AppKeys.copyContact.tr();

  /// Confirmation after successful clipboard access.
  static String get contactCopied => _AppKeys.contactCopied.tr();

  /// Localized listing creation title.
  static String get createListingTitle => _AppKeys.createListingTitle.tr();

  /// Localized listing creation subject.
  static String get createListingSubject => _AppKeys.createListingSubject.tr();

  /// Localized listing creation hasCertificate.
  static String get createListingHasCertificate =>
      _AppKeys.createListingHasCertificate.tr();

  /// Localized listing creation certificateDescription.
  static String get createListingCertificateDescription =>
      _AppKeys.createListingCertificateDescription.tr();

  /// Localized listing creation contactNotice.
  static String get createListingContactNotice =>
      _AppKeys.createListingContactNotice.tr();

  /// Localized listing creation shareWhatsApp.
  static String get createListingShareWhatsApp =>
      _AppKeys.createListingShareWhatsApp.tr();

  /// Localized listing creation whatsAppNumber.
  static String get createListingWhatsAppNumber =>
      _AppKeys.createListingWhatsAppNumber.tr();

  /// Localized listing creation whatsAppHint.
  static String get createListingWhatsAppHint =>
      _AppKeys.createListingWhatsAppHint.tr();

  /// Localized listing creation shareEmail.
  static String get createListingShareEmail =>
      _AppKeys.createListingShareEmail.tr();

  /// Localized listing creation emailAddress.
  static String get createListingEmailAddress =>
      _AppKeys.createListingEmailAddress.tr();

  /// Localized listing creation emailHint.
  static String get createListingEmailHint =>
      _AppKeys.createListingEmailHint.tr();

  /// Localized listing creation submit.
  static String get createListingSubmit => _AppKeys.createListingSubmit.tr();

  /// Localized listing creation submitting.
  static String get createListingSubmitting =>
      _AppKeys.createListingSubmitting.tr();

  /// Localized listing creation errors unauthorizedRole.
  static String get createListingUnauthorizedRoleError =>
      _AppKeys.createListingUnauthorizedRoleError.tr();

  /// Localized listing creation errors invalidTeacherInfo.
  static String get createListingInvalidTeacherInfoError =>
      _AppKeys.createListingInvalidTeacherInfoError.tr();

  /// Localized listing creation errors invalidSubject.
  static String get createListingInvalidSubjectError =>
      _AppKeys.createListingInvalidSubjectError.tr();

  /// Localized listing creation errors invalidDescription.
  static String get createListingInvalidDescriptionError =>
      _AppKeys.createListingInvalidDescriptionError.tr();

  /// Localized listing creation errors missingCertificateDescription.
  static String get createListingMissingCertificateDescriptionError =>
      _AppKeys.createListingMissingCertificateDescriptionError.tr();

  /// Localized listing creation errors missingContactMethod.
  static String get createListingMissingContactMethodError =>
      _AppKeys.createListingMissingContactMethodError.tr();

  /// Localized listing creation errors invalidWhatsAppNumber.
  static String get createListingInvalidWhatsAppNumberError =>
      _AppKeys.createListingInvalidWhatsAppNumberError.tr();

  /// Localized listing creation errors invalidEmailAddress.
  static String get createListingInvalidEmailAddressError =>
      _AppKeys.createListingInvalidEmailAddressError.tr();

  /// Localized listing creation errors notFound.
  static String get createListingNotFoundError =>
      _AppKeys.createListingNotFoundError.tr();

  /// Localized listing creation errors connection.
  static String get createListingConnectionError =>
      _AppKeys.createListingConnectionError.tr();

  /// Localized listing creation errors storage.
  static String get createListingStorageError =>
      _AppKeys.createListingStorageError.tr();
}

abstract final class _AppKeys {
  static const String appTitle = 'app.title';
  static const String homeTitle = 'home.title';
  static const String homeMessage = 'home.message';
  static const String loginTitle = 'auth.loginTitle';
  static const String signInWithGoogle = 'auth.signInWithGoogle';
  static const String signingIn = 'auth.signingIn';
  static const String signInCancelled = 'auth.errors.cancelled';
  static const String signInConnectionError = 'auth.errors.connection';
  static const String signInAuthenticationError = 'auth.errors.authentication';
  static const String signInProfileLoadingError = 'auth.errors.profileLoading';
  static const String switchToEnglish = 'language.switchToEnglish';
  static const String switchToTurkish = 'language.switchToTurkish';
  static const String signOut = 'auth.signOut';
  static const String completeProfileTitle = 'profile.title';
  static const String displayNameLabel = 'profile.displayName';
  static const String roleLabel = 'profile.role';
  static const String studentRole = 'profile.roles.student';
  static const String teacherRole = 'profile.roles.teacher';
  static const String saveProfile = 'profile.save';
  static const String savingProfile = 'profile.saving';
  static const String profileInvalidDisplayName =
      'profile.errors.invalidDisplayName';
  static const String profileInvalidUserId = 'profile.errors.invalidUserId';
  static const String profileLoadFailed = 'profile.errors.loadFailed';
  static const String profileSaveFailed = 'profile.errors.saveFailed';
  static const String listingsTitle = 'listings.title';
  static const String listingDetailTitle = 'listings.detailTitle';
  static const String backToListings = 'listings.back';
  static const String listingsSearch = 'listings.search';
  static const String allDeliveryModes = 'listings.allModes';
  static const String deliveryModeLabel = 'listings.deliveryMode';
  static const String inPersonLesson = 'listings.modes.inPerson';
  static const String onlineLesson = 'listings.modes.online';
  static const String recordedVideoLesson = 'listings.modes.recordedVideo';
  static const String certificateOnly = 'listings.certificateOnly';
  static const String activeListingFilters = 'listings.activeFilters';
  static const String clearListingFilters = 'listings.clearFilters';
  static const String listingsLoading = 'listings.loading';
  static const String listingDetailLoading = 'listings.detailLoading';
  static const String noListings = 'listings.empty';
  static const String retryListings = 'listings.retry';
  static const String listingNotFound = 'listings.errors.notFound';
  static const String listingConnectionError = 'listings.errors.connection';
  static const String listingStorageError = 'listings.errors.storage';
  static const String listingLoadError = 'listings.errors.other';
  static const String certificateAvailable = 'listings.certificateAvailable';
  static const String certificateNotProvided =
      'listings.certificateNotProvided';
  static const String lessonDescription = 'listings.description';
  static const String contactTeacher = 'listings.contact.title';
  static const String contactWhatsApp = 'listings.contact.whatsApp';
  static const String contactEmail = 'listings.contact.email';
  static const String contactOpening = 'listings.contact.pending';
  static const String contactCannotOpen =
      'listings.contact.errors.cannotOpenExternalApp';
  static const String contactInvalidValue =
      'listings.contact.errors.invalidContactValue';
  static const String contactClipboardFailed =
      'listings.contact.errors.clipboardFailed';
  static const String copyContact = 'listings.contact.copy';
  static const String contactCopied = 'listings.contact.copied';
  static const String createListingTitle = 'listings.create.title';
  static const String createListingSubject = 'listings.create.subject';
  static const String createListingHasCertificate =
      'listings.create.hasCertificate';
  static const String createListingCertificateDescription =
      'listings.create.certificateDescription';
  static const String createListingContactNotice =
      'listings.create.contactNotice';
  static const String createListingShareWhatsApp =
      'listings.create.shareWhatsApp';
  static const String createListingWhatsAppNumber =
      'listings.create.whatsAppNumber';
  static const String createListingWhatsAppHint =
      'listings.create.whatsAppHint';
  static const String createListingShareEmail = 'listings.create.shareEmail';
  static const String createListingEmailAddress =
      'listings.create.emailAddress';
  static const String createListingEmailHint = 'listings.create.emailHint';
  static const String createListingSubmit = 'listings.create.submit';
  static const String createListingSubmitting = 'listings.create.submitting';
  static const String createListingUnauthorizedRoleError =
      'listings.create.errors.unauthorizedRole';
  static const String createListingInvalidTeacherInfoError =
      'listings.create.errors.invalidTeacherInfo';
  static const String createListingInvalidSubjectError =
      'listings.create.errors.invalidSubject';
  static const String createListingInvalidDescriptionError =
      'listings.create.errors.invalidDescription';
  static const String createListingMissingCertificateDescriptionError =
      'listings.create.errors.missingCertificateDescription';
  static const String createListingMissingContactMethodError =
      'listings.create.errors.missingContactMethod';
  static const String createListingInvalidWhatsAppNumberError =
      'listings.create.errors.invalidWhatsAppNumber';
  static const String createListingInvalidEmailAddressError =
      'listings.create.errors.invalidEmailAddress';
  static const String createListingNotFoundError =
      'listings.create.errors.notFound';
  static const String createListingConnectionError =
      'listings.create.errors.connection';
  static const String createListingStorageError =
      'listings.create.errors.storage';
}
