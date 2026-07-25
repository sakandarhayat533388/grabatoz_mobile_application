import 'dart:convert';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:graba2z/Api/Models/ordercreatemodel.dart' as order_create;
import 'package:graba2z/Configs/config.dart';
import 'package:graba2z/Controllers/first_user_discount_controller.dart';
import 'package:http/http.dart' as http;
import '../Utils/packages.dart';
import 'package:get/get.dart';

class CartNotifier extends GetxController {
  Map<String, String>? _selectedAddress; // Store selected address

  Map<String, String>? get selectedAddress => _selectedAddress;

  void setSelectedAddress(Map<String, String> address) {
    _selectedAddress = address;
    update();
  }

  final cartItems = <order_create.LineItems>[];
  // final coupon = <order_create.CouponLines>[];
  // double promoPrice = 0;

  var cartOtherInfoList = <CartOtherInfo>[];
  final postCouponList = [].obs;
  final appliedCouponCode = ''.obs;
  int get totalItems {
    return cartOtherInfoList.fold(0, (sum, item) => sum + (item.quantity ?? 0));
  }

  int? _selectedDeliveryIndex = 0;

  int? get selectedDeliveryIndex => _selectedDeliveryIndex;

  // void selectDelivreyOption(int index) {
  //   _selectedDeliveryIndex = index;
  //   update(); // Notify listeners to update UI
  // }

  void selectDelivreyOption(int index) {
    _selectedDeliveryIndex = index; // Update the selected delivery option
    update();
  }

  // double get deliveryFee {
  //   // Check which delivery option is selected
  //   if (_selectedDeliveryIndex == 0) {
  //     return _homeDeliveryFee; // Home Delivery
  //   } else {
  //     return 0; // Pick From Point
  //   }
  // }
  double get deliveryFee {
    if (_selectedDeliveryIndex == 0) {
      return cartTotalPriceF() < 500
          ? 20.0
          : 0.0; // ₹20 if <500, otherwise free
    } else if (_selectedDeliveryIndex == 1) {
      return 0.0; // Pickup from the point is free
    } else {
      return 0.0; // No selection, no fee
    }
  }

  void _refreshFirstUserDiscountPreview() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<FirstUserDiscountController>()) {
        Get.find<FirstUserDiscountController>().previewCart(cartOtherInfoList);
      }
    });
  }

  Future<Map<String, dynamic>?> applyCouponRe(
      String couponCode, List cpList) async {
    final String baseUrl = Configss.applyCoupon;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      var bodyobj = {
        "code": couponCode,
        "orderSource": "app",
        "cartItems": cpList
      };

      final Map<String, String> headers = {
        'Content-Type': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      print('🔍 [Coupon Validate] Request Payload: ${jsonEncode(bodyobj)}');
      var response = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: jsonEncode(bodyobj),
      );
      print('🔍 [Coupon Validate] Response Status: ${response.statusCode}');
      print('🔍 [Coupon Validate] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body.toString());
        return responseData; // Return the coupon details
      } else {
        return null; // Coupon not found
      }
    } catch (e) {
      print("Error fetching coupon: $e");
      return null;
    }
  }

  /// **Get Cart Key (Guest or Logged-in User)**
  Future<String> _getCartKey(String? userId) async {
    return userId != null ? 'cartData_$userId' : 'guest_cart';
  }

  /// **Save Cart to SharedPreferences**
  Future<void> saveCartToPrefs(String? userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String cartKey = await _getCartKey(userId);
    await prefs.setString(cartKey, cartOtherInfoListToJson(cartOtherInfoList));
  }

  /// **Load Cart from SharedPreferences**
  Future<void> loadCartFromPrefs(String? userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String cartKey = await _getCartKey(userId);
    String? cartData = prefs.getString(cartKey);

    if (cartData != null && cartData.isNotEmpty) {
      cartOtherInfoList = cartOtherInfoListFromJson(cartData);
      createLineItems();
    } else {
      cartOtherInfoList = [];
    }
    update();
    _refreshFirstUserDiscountPreview();
  }

  /// **Merge Guest Cart into User Cart After Login**
  Future<void> mergeGuestCart(String userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? guestCartData = prefs.getString('guest_cart');
    String userCartKey = await _getCartKey(userId);
    String? userCartData = prefs.getString(userCartKey);

    if (guestCartData == null || guestCartData.isEmpty) {
      await loadCartFromPrefs(userId);
      return;
    }

    List<CartOtherInfo> mergedCart =
        userCartData != null && userCartData.isNotEmpty
            ? cartOtherInfoListFromJson(userCartData)
            : <CartOtherInfo>[];
    List<CartOtherInfo> guestCart = cartOtherInfoListFromJson(guestCartData);

    for (var guestItem in guestCart) {
      final guestKey = _cartLineKey(guestItem);
      int existingIndex =
          mergedCart.indexWhere((item) => _cartLineKey(item) == guestKey);

      if (existingIndex >= 0) {
        mergedCart[existingIndex].quantity =
            (mergedCart[existingIndex].quantity ?? 0) +
                (guestItem.quantity ?? 1);
      } else {
        mergedCart.add(guestItem);
      }
    }

    cartOtherInfoList = mergedCart;
    createLineItems();
    await prefs.setString(
        userCartKey, cartOtherInfoListToJson(cartOtherInfoList));
    await prefs.remove('guest_cart');
    update();
    _refreshFirstUserDiscountPreview();
  }

  /// **Clear Cart**
  Future<void> clearCartDataInPrefs(String? userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String cartKey = await _getCartKey(userId);
    await prefs.remove(cartKey);
    cartOtherInfoList.clear();
    update();
    _refreshFirstUserDiscountPreview();
  }

  void increaseQuantity(int index, String? userId) {
    cartOtherInfoList[index].quantity =
        (cartOtherInfoList[index].quantity ?? 0) + 1;
    createLineItems();
    saveCartToPrefs(userId);
    update();
    _refreshFirstUserDiscountPreview();
  }

  void decreaseQuantity(int index, String? userId) {
    if ((cartOtherInfoList[index].quantity ?? 1) > 1) {
      cartOtherInfoList[index].quantity =
          (cartOtherInfoList[index].quantity ?? 1) - 1;
      createLineItems();
      saveCartToPrefs(userId);
      update();
      _refreshFirstUserDiscountPreview();
    }
  }

  void createLineItems() {
    cartItems.clear();
    for (var element in cartOtherInfoList) {
      cartItems.add(order_create.LineItems(
        productId: element.productId,
        quantity: element.quantity,
        variationId: element.variationId?.toInt() ?? 0,
        addedToCartTime: element.addedToCartTime?.toUtc().toString(),
      ));
    }
  }

  String _cartLineKey(CartOtherInfo item) {
    final productId = item.productId ?? '';
    final colorIndex = item.selectedColorIndex;
    return colorIndex == null
        ? '${productId}_nocolor'
        : '${productId}_$colorIndex';
  }

  var selectedDeliveryMethodId = ''.obs;
  var deliveryFeeCharge = 0.0.obs;

  var totalAmount = 0.0.obs;
  var discountAmountApplied = 0.0.obs;

  addCoupon(String couponCode, TextEditingController couponController,
      List cpList, BuildContext context) async {
    EasyLoading.show(status: 'Applying Coupon...');

    List dynamicCpList = cartOtherInfoList.map((item) => {
      "product": item.productId,
      "qty": item.quantity,
    }).toList();

    var couponData = await applyCouponRe(couponCode, dynamicCpList);

    if (couponData == null) {
      EasyLoading.dismiss();
      EasyLoading.showError("Invalid Coupon Code");
      print("❌ Invalid Coupon Code: $couponCode");
      return;
    }

    double discountAmount = 0.0;
    if (couponData['coupon'] is Map) {
      final couponObj = Map<String, dynamic>.from(couponData['coupon']);
      if (couponObj['rules'] is List && (couponObj['rules'] as List).isNotEmpty) {
        if (Get.isRegistered<FirstUserDiscountController>()) {
          discountAmount = FirstUserDiscountController.calculateDiscount(
            cartItems: cartOtherInfoList,
            discountObj: couponObj,
          );
        } else {
          discountAmount = double.tryParse(couponData['discountAmount'].toString()) ?? 0.0;
        }
      } else {
        discountAmount = double.tryParse(couponData['discountAmount'].toString()) ?? 0.0;
      }
    } else {
      discountAmount = double.tryParse(couponData['discountAmount'].toString()) ?? 0.0;
    }

    double originalTotal = cartTotalPriceF();

    // Ensure discount doesn't exceed total
    if (discountAmount > originalTotal) {
      discountAmount = originalTotal;
    }

    double finalTotal = originalTotal - discountAmount;

    // Save values in observables
    discountAmountApplied.value =
        double.parse(discountAmount.toStringAsFixed(2));
    totalAmount.value = double.parse(finalTotal.toStringAsFixed(2));
    appliedCouponCode.value = couponCode;

    // Clear field & update UI
    couponController.clear();
    update();

    EasyLoading.dismiss();
    EasyLoading.showSuccess(
        "Coupon Applied!\nDiscount: ${discountAmountApplied.value.toStringAsFixed(2)} AED\n"
        "Total After Discount: ${totalAmount.value.toStringAsFixed(2)} AED");

    print("✅ Coupon Applied: $couponCode");
    print("🔹 Original Total: $originalTotal");
    print("🔹 Discount Amount: ${discountAmountApplied.value}");
    print("🔹 Final Total: ${totalAmount.value}");
  }

  // var totalAmount = 0.0.obs;

  // addCoupon(String couponCode, TextEditingController couponController,
  //     List cpList, BuildContext context) async {
  //   EasyLoading.show(status: 'Applying Coupon...'); // ✅ Show loading indicator
  //   // var couponData = await null;
  //   var couponData = await applyCouponRe(couponCode, cpList);

  //   if (couponData == null) {
  //     EasyLoading.showError("Invalid Coupon Code"); // ❌ Hide loading on failure
  //     EasyLoading.dismiss(); // ❌ Hide loading on failure

  //     print("❌ Invalid Coupon Code: $couponCode");

  //     return;
  //   }

  //   double discountAmount =
  //       double.tryParse(couponData['coupon']['discountValue'].toString()) ??
  //           0.0;
  //   String discountType =
  //       couponData['coupon']['discountType']; // 'fixed' or 'percentage'

  //   update(); // Update the UI

  //   // ✅ Clear the text field
  //   couponController.clear();
  //   EasyLoading.showSuccess(
  //       "Coupon Applied! Discount: ${discountAmount.toStringAsFixed(2)} AED");
  //   EasyLoading.dismiss(); // ✅ Hide loading after applying coupon
  // }

  void removeCoupon() {
    // coupon.clear();
    discountAmountApplied.value = 0.0;
    totalAmount.value = 0.0;
    appliedCouponCode.value = '';
    update();
  }

  /// **Add Item to Cart (Handles Guest & Logged-in User)**
  Future<void> addItemInfo(CartOtherInfo cart, String? userId,
      {bool showNotification = true}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isNotificationEnabled = prefs.getBool('notification_enabled') ?? true;
    final cartKey = _cartLineKey(cart);
    int existingItemIndex =
        cartOtherInfoList.indexWhere((item) => _cartLineKey(item) == cartKey);

    if (existingItemIndex >= 0) {
      cartOtherInfoList[existingItemIndex].quantity =
          (cartOtherInfoList[existingItemIndex].quantity ?? 0) +
              (cart.quantity ?? 1);
      cartOtherInfoList[existingItemIndex].addedToCartTime = DateTime.now();

      if (isNotificationEnabled && showNotification) {
        AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: 1,
            channelKey: "basic_channel",
            title: "Cart Updated",
            body:
                '${cart.productName} quantity updated to ${cartOtherInfoList[existingItemIndex].quantity}',
            actionType: ActionType.Default,
          ),
        );
      }
    } else {
      cart.addedToCartTime = DateTime.now();
      cartOtherInfoList.add(cart);

      if (isNotificationEnabled && showNotification) {
        AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: 1,
            channelKey: "basic_channel",
            title: "Item Added to Cart",
            body: '${cart.productName} has been added to your cart!',
            actionType: ActionType.Default,
          ),
        );
      }
    }

    createLineItems();
    await saveCartToPrefs(userId);
    update();
    _refreshFirstUserDiscountPreview();
  }

  void removeItemInfo(String name, String? userId) {
    cartOtherInfoList.removeWhere((element) => element.productName == name);
    createLineItems();
    saveCartToPrefs(userId);
    update();
    _refreshFirstUserDiscountPreview();
  }

  double cartTotalPriceF() {
    double cartTotalPrice = cartOtherInfoList.fold(
        0.0,
        (sum, element) =>
            sum + (element.cartBasePrice * (element.quantity ?? 1)));

    return double.parse(cartTotalPrice.toStringAsFixed(2));
  }

  String cartOtherInfoListToJson(List<CartOtherInfo> cartList) {
    List<Map<String, dynamic>> cartJsonList =
        cartList.map((cart) => cart.toJson()).toList();
    return jsonEncode(cartJsonList);
  }

  List<CartOtherInfo> cartOtherInfoListFromJson(String cartData) {
    List<dynamic> cartJsonList = jsonDecode(cartData);
    return cartJsonList.map((json) => CartOtherInfo.fromJson(json)).toList();
  }
}

class CartOtherInfo {
  int? variationId;
  String? productId;
  String? type;
  String? productName;
  String? productImage;
  double? productPrice;
  double? originalPrice;
  Color? productColor;
  String? productSize;
  int? quantity;
  DateTime? addedToCartTime;
  int? selectedColorIndex;
  Map<String, dynamic>? selectedColorData;
  int? selectedDosIndex;
  bool? isProtection;
  String? protectionFor;
  String? protectionData;

  List<dynamic>? attributesName;
  List<dynamic>? selectedAttributes;

  CartOtherInfo({
    this.variationId,
    this.productId,
    this.type,
    this.productName,
    this.productImage,
    this.productPrice,
    this.originalPrice,
    this.productColor,
    this.productSize,
    this.quantity,
    this.attributesName,
    this.selectedAttributes,
    this.addedToCartTime,
    this.selectedColorIndex,
    this.selectedColorData,
    this.selectedDosIndex,
    this.isProtection,
    this.protectionFor,
    this.protectionData,
  }) {
    variationId = variationId?.toInt();
  }

  CartOtherInfo.fromJson(Map<String, dynamic> json) {
    variationId = json['variationId']?.toInt();
    productId = json['productId'];
    type = json['type'];
    productName = json['productName'];
    productImage = json['productImage'];
    productPrice = json['productPrice'] != null
        ? double.tryParse(json['productPrice'].toString())
        : null;
    originalPrice = json['originalPrice'] != null
        ? double.tryParse(json['originalPrice'].toString())
        : null;
    productColor = json['productColor'];
    productSize = json['productSize'];
    quantity = json['quantity'];
    attributesName = json['attributesName'];
    selectedAttributes = json['selectedAttributes'];
    selectedColorIndex = json['selectedColorIndex'] is int
        ? json['selectedColorIndex']
        : int.tryParse((json['selectedColorIndex'] ?? '').toString());
    selectedColorData = json['selectedColorData'] is Map
        ? Map<String, dynamic>.from(json['selectedColorData'])
        : null;
    selectedDosIndex = json['selectedDosIndex'] is int
        ? json['selectedDosIndex']
        : int.tryParse((json['selectedDosIndex'] ?? '').toString());
    isProtection = json['isProtection'] == true;
    protectionFor = json['protectionFor'];
    protectionData = json['protectionData'];
    addedToCartTime = json['addedToCartTime'] != null
        ? DateTime.parse(json['addedToCartTime'])
        : null;
  }

  double get cartBasePrice {
    return productPrice ?? 0.0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['variationId'] = variationId;
    data['productId'] = productId;
    data['type'] = type;
    data['productName'] = productName;
    data['productImage'] = productImage;
    data['productPrice'] = productPrice;
    data['originalPrice'] = originalPrice;
    data['productColor'] = productColor;
    data['productSize'] = productSize;
    data['quantity'] = quantity;
    data['attributesName'] = attributesName;
    data['selectedAttributes'] = selectedAttributes;
    data['selectedColorIndex'] = selectedColorIndex;
    data['selectedColorData'] = selectedColorData;
    data['selectedDosIndex'] = selectedDosIndex;
    data['isProtection'] = isProtection;
    data['protectionFor'] = protectionFor;
    data['protectionData'] = protectionData;
    // Store addedToCartTime as a String (ISO8601 format)
    data['addedToCartTime'] = addedToCartTime?.toIso8601String();

    return data;
  }
}
