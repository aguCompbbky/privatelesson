/// Route names and paths used by the application router.
abstract final class AppRoutes {
  /// Path of the login route.
  static const String loginPath = '/login';

  /// Name of the login route.
  static const String loginName = 'login';

  /// Path of the required profile completion route.
  static const String completeProfilePath = '/complete-profile';

  /// Name of the required profile completion route.
  static const String completeProfileName = 'completeProfile';

  /// Path of the teacher-only creation route.
  static const String createListingPath = '/listings/new';

  /// Name of the teacher-only creation route.
  static const String createListingName = 'createListing';

  /// Path of the home route.
  static const String homePath = '/';

  /// Name of the home route.
  static const String homeName = 'home';

  /// Path parameter containing the listing identifier.
  static const String listingIdParam = 'listingId';

  /// Detail path relative to the home route.
  static const String listingDetailSubPath = 'listings/:listingId';

  /// Name of the listing detail route.
  static const String listingDetailName = 'listingDetail';

  /// Builds an absolute path for a listing identifier.
  static String listingDetailPath(String listingId) => '/listings/$listingId';
}
