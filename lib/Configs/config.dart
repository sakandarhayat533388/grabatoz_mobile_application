class Configss {
  static String baseUrl = 'https://api.grabatoz.ae';

  // static String baseUrl = 'https://graba2z-backend-orpin.vercel.app';
  static String signup = "$baseUrl/api/users/register";
  static String registerGuest = "$baseUrl/api/users/register-guest";
  static String login = "$baseUrl/api/users/login";
  static String getAllCategories = '$baseUrl/api/categories';
  static String getSubCategories = '$baseUrl/api/subcategories';
  static String getBanners = '$baseUrl/api/banners';
  static String getallbrands = '$baseUrl/api/brands';
  static String getAllProducts = '$baseUrl/api/mobile/products';
  static String productSystemMakeOptions =
      '$baseUrl/api/product-system-options/make';
  static String productSystemModelOptions =
      '$baseUrl/api/product-system-options/model';

  static String productSystemOptions(String type) =>
      '$baseUrl/api/product-system-options/$type';
  static String shopQueryProducts = '$baseUrl/api/products/shop-query';
  static String getuserProfile = '$baseUrl/api/users/profile';
  static String verifyEmail = "$baseUrl/api/users/verify-email";
  static String forgotPassword = "$baseUrl/api/users/forgot-password";
  static String resendVerification = "$baseUrl/api/users/resend-verification";

  // static String postReview = "$baseUrl/api/products";
  static String postReview = "$baseUrl/api/reviews";
  static String getReview = "$baseUrl/api/reviews/product/:productId";

  // Add guest verification endpoints
  static String verifyReviewEmail = "$baseUrl/api/reviews/verify-email";
  static String resendReviewVerification =
      "$baseUrl/api/reviews/resend-verification";
  static String getCoupon = "$baseUrl/api/coupons";
  static String requestCallback = "$baseUrl/api/request-callback";
  static String firstUserDiscountStatus =
      "$baseUrl/api/app-discounts/me/first-user-discount";
  static String firstUserDiscountPreview = "$baseUrl/api/app-discounts/preview";

  // static String userProfile = "$baseUrl/api/users/profile";
  static String updateProfile = "$baseUrl/api/users/profile";
  static String createOrder = "$baseUrl/api/orders";
  static String paymentCardRequest = "$baseUrl/api/payment/ngenius/card";
  static String getOrders = "$baseUrl/api/orders/myorders";
  static String trackOrders = "$baseUrl/api/orders/track";
  static String applyCoupon = "$baseUrl/api/coupons/validate";

  // static String rangeFilter = "$baseUrl/api/app/products";
  static String getShippingCharge = "$baseUrl/api/delivery-charges";
  static String getActivePaymentCharges = "$baseUrl/api/payment-charges/active";
  static String searchAll = "$baseUrl/api/mobile/products";

  // Public website URL for Tamara redirects
  static String webBaseUrl = "https://grabatoz.ae";

  // Tamara checkout creation endpoint (adjust if your backend uses a different path)
  static String paymentTamaraRequest = "$baseUrl/api/payment/tamara/checkout";

  // Endpoint to resolve allowed payment methods dynamically based on cart items
  static String resolvePaymentMethods =
      "$baseUrl/api/product-payment-methods/resolve";
  static String menu = "$baseUrl/api/categories/tree";
  static String product = "$baseUrl/api/products";
  static String newHomeCategory = "$baseUrl/api/custom-slider-items/active";

  // Account deletion endpoints
  static String requestAccountDeletion =
      "$baseUrl/api/users/request-account-deletion";
  static String verifyAccountDeletion =
      "$baseUrl/api/users/verify-account-deletion";
}
