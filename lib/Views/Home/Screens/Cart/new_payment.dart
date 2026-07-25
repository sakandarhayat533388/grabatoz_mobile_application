import 'dart:convert';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:graba2z/Configs/config.dart';
import 'package:graba2z/Controllers/addtocart.dart';
import 'package:graba2z/Controllers/checkout_controller.dart';
import 'package:graba2z/Controllers/deliveryController.dart';
import 'package:graba2z/Controllers/first_user_discount_controller.dart';
import 'package:graba2z/Controllers/payment_charges_controller.dart';
import 'package:graba2z/Utils/guest_checkout_storage.dart';
import 'package:graba2z/Utils/packages.dart';
import 'package:graba2z/Views/success_page/successpayment.dart';
import 'package:graba2z/Views/Home/Screens/Cart/pay_by_card_webview.dart';
import 'package:http/http.dart' as http;

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  String selectedMethod = 'COD';
  List<String> allowedPaymentMethods = ['tamara', 'tabby', 'card', 'cod'];
  bool isLoadingPaymentMethods = true;
  final CartNotifier _cartNotifier = Get.put(CartNotifier());
  final UserController _usercontroller = Get.put(UserController());
  late DeliveryController _deliveryCtrl;
  late PaymentChargesController _paymentChargesCtrl;
  double vatPerItem = 0.0;
  double totalVAT = 0.0;
  double total = 0.0;
  double deliveryFee = 0.0;
  double subtotal = 0.0;

  double _firstOrderDiscountAmount() {
    if (!Get.isRegistered<FirstUserDiscountController>()) return 0.0;

    final discountController = Get.find<FirstUserDiscountController>();
    if (!discountController.previewApplied.value) return 0.0;

    return discountController.previewDiscountAmount.value;
  }

  double _payableTotalAfterFirstOrderDiscount(double baseTotal) {
    return (baseTotal - _firstOrderDiscountAmount())
        .clamp(0.0, double.infinity)
        .toDouble();
  }

  double get _cartOriginalTotal => _cartNotifier.cartOtherInfoList.fold(
        0.0,
        (sum, item) =>
            sum +
            (((item.originalPrice ?? item.productPrice) ?? 0.0) *
                (item.quantity ?? 0)),
      );

  bool get _isCodSelected => selectedMethod == 'COD';

  String get _selectedPaymentMethodKey => _mapPaymentMethod(selectedMethod);

  bool _isCodPaymentMethod(String method) {
    final normalized = method.trim().toLowerCase();
    return normalized == 'cod' || normalized == 'cash on delivery';
  }

  double _totalBeforeDiscountForSelectedMethod(double baseTotal) {
    final paymentChargeTotal =
        _paymentChargesCtrl.totalFor(_selectedPaymentMethodKey);
    if (!_isCodSelected) return baseTotal + paymentChargeTotal;

    final standardShipping = _standardShippingAppliedToCurrentCart();

    return ((baseTotal - standardShipping).clamp(0.0, double.infinity) +
            paymentChargeTotal)
        .toDouble();
  }

  double _standardShippingAppliedToCurrentCart() {
    final currentSubtotal = subtotal > 0
        ? subtotal
        : _cartNotifier.cartOtherInfoList.fold(
            0.0,
            (sum, item) => sum + (item.cartBasePrice * (item.quantity ?? 0)),
          );

    if (!_usercontroller.isHomeDelivery.value || currentSubtotal > 500) {
      return 0.0;
    }

    return _deliveryCtrl.selectedCharge;
  }

  double _currentBaseTotalBeforePaymentCharges() {
    return _cartNotifier.totalAmount.value == 0.0
        ? total
        : _cartNotifier.totalAmount.value;
  }

  double _selectedPayableTotal() {
    return _payableTotalAfterFirstOrderDiscount(
      _totalBeforeDiscountForSelectedMethod(
          _currentBaseTotalBeforePaymentCharges()),
    );
  }

  getcalculations() {
    _deliveryCtrl = Get.find<DeliveryController>();
    subtotal = _cartNotifier.cartOtherInfoList.fold(
        0.0, (sum, item) => sum + (item.cartBasePrice * (item.quantity ?? 0)));
    _usercontroller.subtotalAmount.value = subtotal;

    deliveryFee = _usercontroller.isHomeDelivery.value && subtotal <= 500
        ? _deliveryCtrl.selectedCharge
        : 0.0;

    totalVAT = _cartNotifier.cartOtherInfoList
        .fold(0.0, (sum, item) => sum + (vatPerItem * (item.quantity ?? 0)));

    total = subtotal + totalVAT + deliveryFee;
    _cartNotifier.deliveryFeeCharge.value = deliveryFee;
    _cartNotifier.totalAmount.value = total;
    setState(() {});
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _deliveryCtrl = Get.find<DeliveryController>();
    _paymentChargesCtrl = Get.isRegistered<PaymentChargesController>()
        ? Get.find<PaymentChargesController>()
        : Get.put(PaymentChargesController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      getcalculations();
      fetchAllowedPaymentMethods();
      _paymentChargesCtrl.fetchActiveCharges();
      if (!Get.isRegistered<FirstUserDiscountController>()) return;
      final discountController = Get.find<FirstUserDiscountController>();
      discountController.loadStatus().then((_) {
        discountController.previewCart(_cartNotifier.cartOtherInfoList);
      });
    });
  }

  Future<void> fetchAllowedPaymentMethods() async {
    setState(() {
      isLoadingPaymentMethods = true;
    });

    try {
      final productIds = _cartNotifier.cartOtherInfoList
          .map((item) => item.productId)
          .whereType<String>()
          .toList();

      if (productIds.isEmpty) {
        setState(() {
          allowedPaymentMethods = ['tamara', 'tabby', 'card', 'cod'];
          isLoadingPaymentMethods = false;
        });
        return;
      }

      final url = Uri.parse(Configss.resolvePaymentMethods);
      log('Fetching allowed payment methods from $url with productIds: $productIds');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'productIds': productIds}),
      );

      if (response.statusCode == 200) {
        final rawData = jsonDecode(response.body);
        log('Resolve payment methods response: $rawData');
        
        List<String> resolved = [];
        if (rawData is List) {
          resolved = rawData.map((e) => e.toString().toLowerCase().trim()).toList();
        } else if (rawData is Map) {
          final methods = rawData['allowedMethods'] ?? rawData['paymentMethods'] ?? rawData['data'];
          if (methods is List) {
            resolved = methods.map((e) => e.toString().toLowerCase().trim()).toList();
          }
        }

        if (resolved.isNotEmpty) {
          setState(() {
            allowedPaymentMethods = resolved;
            
            // Auto-select the first available method if current selection is not allowed
            final currentMapped = _mapPaymentMethod(selectedMethod).toLowerCase();
            if (!allowedPaymentMethods.contains(currentMapped)) {
              if (allowedPaymentMethods.contains('cod')) {
                selectedMethod = 'COD';
              } else if (allowedPaymentMethods.contains('card')) {
                selectedMethod = 'Card';
              } else if (allowedPaymentMethods.contains('tabby')) {
                selectedMethod = 'Tabby';
              } else if (allowedPaymentMethods.contains('tamara')) {
                selectedMethod = 'Tamara';
              } else {
                final first = allowedPaymentMethods.first;
                if (first == 'cod') selectedMethod = 'COD';
                else if (first == 'card') selectedMethod = 'Card';
                else if (first == 'tabby') selectedMethod = 'Tabby';
                else if (first == 'tamara') selectedMethod = 'Tamara';
              }
            }
            isLoadingPaymentMethods = false;
          });
          return;
        }
      } else {
        log('Error resolving payment methods: Status Code ${response.statusCode}, Body ${response.body}');
      }
    } catch (e) {
      log('Exception resolving payment methods: $e');
    }

    // Fallback on error or empty response
    setState(() {
      allowedPaymentMethods = ['tamara', 'tabby', 'card', 'cod'];
      isLoadingPaymentMethods = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              "Payment Method",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (isLoadingPaymentMethods)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(color: kPrimaryColor),
                  SizedBox(height: 12),
                  Text(
                    "Loading available payment options...",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
          )
        else ...[
          _buildGroupedPaymentSection(),
        ],
        // Payment charges box removed per user request
        Obx(() {
          _paymentChargesCtrl.activeCharges.length;
          _paymentChargesCtrl.isLoading.value;
          if (Get.isRegistered<FirstUserDiscountController>()) {
            final discountController = Get.find<FirstUserDiscountController>();
            discountController.previewApplied.value;
            discountController.previewDiscountAmount.value;
          }
          return _buildOrderSummaryCard();
        }),
        // const Spacer(),
        Row(
          children: [
            // Expanded(
            //   child: OutlinedButton(
            //     onPressed: () {
            //       Navigator.pop(context);
            //     },
            //     child: const Text("Back"),
            //   ),
            // ),
            // const SizedBox(width: 12),
            Expanded(
                child: Obx(
              () => _usercontroller.iscardLoading.value
                  ? Container(
                      margin: EdgeInsets.only(top: 30),
                      height: 30,
                      width: 25,
                      child: Center(child: CircularProgressIndicator()))
                  : ElevatedButton(
                      onPressed: () async {
                        // Resolve customer name: prefer typed name, then stored full name, else empty
                        final String customerName = _usercontroller
                                .homeNameController.text
                                .trim()
                                .isNotEmpty
                            ? _usercontroller.homeNameController.text.trim()
                            : _usercontroller.fullName.value.trim();

                        final currentMapped = _mapPaymentMethod(selectedMethod).toLowerCase();
                        if (allowedPaymentMethods.contains(currentMapped)) {
                          if (_usercontroller.isHomeDelivery.value) {
                            SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                            bool? checkGuest = prefs.getBool('Guest') ?? false;
                            String? guestName = prefs.getString('guest_name');
                            String? guestCity = prefs.getString('guest_city');
                            String? guestZipCode = prefs.getString('guest_zip');
                            String? guestState = prefs.getString('guest_state');
                            String? guestAddress =
                                prefs.getString('guest_address');
                            String? guestEmail = prefs.getString('guest_email');
                            String? guestPhone = prefs.getString('guest_phone');

                            if (checkGuest) {
                              createOrder(
                                  _usercontroller.orderItems,
                                  'home',
                                  {
                                    "name": guestName,
                                    "email": guestEmail,
                                    "phone": guestPhone,
                                    "address": guestAddress,
                                    "city": guestCity,
                                    "state": guestState,
                                    "zipCode": guestZipCode
                                  },
                                  {},
                                  _usercontroller.subtotalAmount.value,
                                  _standardShippingAppliedToCurrentCart(),
                                  _cartNotifier.totalAmount.value,
                                  _mapPaymentMethod(selectedMethod),
                                  _usercontroller.optionalNote.text);
                            } else {
                              // Get full phone number with country code from SharedPreferences
                              String fullPhone =
                                  prefs.getString('guest_phone') ??
                                      _usercontroller.homePhoneController.text;

                              createOrder(
                                  _usercontroller.orderItems,
                                  'home',
                                  {
                                    "name": customerName,
                                    "email":
                                        _usercontroller.homeemailAddress.text,
                                    "phone": fullPhone,
                                    "address": _usercontroller.street.value
                                        .replaceAll('"', ''),
                                    "city": _usercontroller.city.value
                                        .replaceAll('"', ''),
                                    "state": _usercontroller.state.value
                                        .replaceAll('"', ''),
                                    "zipCode": _usercontroller.zipcode.value
                                        .replaceAll('"', '')
                                  },
                                  {},
                                  _usercontroller.subtotalAmount.value,
                                  _standardShippingAppliedToCurrentCart(),
                                  _cartNotifier.totalAmount.value,
                                  _mapPaymentMethod(selectedMethod),
                                  _usercontroller.optionalNote.text);
                            }
                          } else {
                            SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                            bool? checkGuest = prefs.getBool('Guest') ?? false;
                            String? guestName = prefs.getString('guest_name');
                            String? guestCity = prefs.getString('guest_city');
                            String? guestZipCode = prefs.getString('guest_zip');
                            String? guestState = prefs.getString('guest_state');
                            String? guestAddress =
                                prefs.getString('guest_address');
                            String? guestEmail = prefs.getString('guest_email');
                            String? guestPhone = prefs.getString('guest_phone');

                            if (checkGuest) {
                              createOrder(
                                  _usercontroller.orderItems,
                                  'pickup',
                                  {
                                    "name": guestName,
                                    "email": guestEmail,
                                    "phone": guestPhone,
                                    "address": guestAddress,
                                    "city": guestCity,
                                    "state": guestState,
                                    "zipCode": guestZipCode
                                  },
                                  {},
                                  _usercontroller.subtotalAmount.value,
                                  0.0,
                                  _cartNotifier.totalAmount.value,
                                  _mapPaymentMethod(selectedMethod),
                                  _usercontroller.optionalNote.text);
                            } else {
                              // Get full phone number with country code from SharedPreferences
                              String fullPhonePickup =
                                  prefs.getString('guest_phone') ??
                                      _usercontroller.homePhoneController.text;

                              createOrder(
                                  _usercontroller.orderItems,
                                  'pickup',
                                  {
                                    "name": customerName,
                                    "email":
                                        _usercontroller.homeemailAddress.text,
                                    "phone": fullPhonePickup,
                                    "address": _usercontroller.street.value
                                        .replaceAll('"', ''),
                                    "city": _usercontroller.city.value
                                        .replaceAll('"', ''),
                                    "state": _usercontroller.state.value
                                        .replaceAll('"', ''),
                                    "zipCode": _usercontroller.zipcode.value
                                        .replaceAll('"', '')
                                  },
                                  {
                                    "phone": _usercontroller.storePhone.value,
                                    "location": _usercontroller.storeName.value,
                                    "storeId": _usercontroller.storeId.value
                                  },
                                  _usercontroller.subtotalAmount.value,
                                  0.0,
                                  _cartNotifier.totalAmount.value,
                                  _mapPaymentMethod(selectedMethod),
                                  _usercontroller.optionalNote.text);
                            }
                          }
                        } else {
                          EasyLoading.showError('Payment Method Not Available');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                      ),
                      child: Obx(
                        () {
                          _paymentChargesCtrl.activeCharges.length;
                          _paymentChargesCtrl.isLoading.value;
                          if (Get.isRegistered<FirstUserDiscountController>()) {
                            final discountController =
                                Get.find<FirstUserDiscountController>();
                            discountController.previewApplied.value;
                            discountController.previewDiscountAmount.value;
                          }
                          final displayTotal = _selectedPayableTotal();
                          return Text(
                            "Place Order - AED ${displayTotal.toStringAsFixed(2)}",
                            style: TextStyle(color: Colors.white),
                          );
                        },
                      )),
            )),
          ],
        )
      ],
    );
  }

  // Map UI selection to backend-expected identifiers
  String _mapPaymentMethod(String method) {
    switch (method) {
      case 'COD':
        return 'cod';
      case 'Card':
        return 'card'; // align with backend alias if needed
      case 'Tabby':
        return 'tabby';
      case 'Tamara':
        return 'tamara';
      default:
        return method.toLowerCase();
    }
  }

  double _toDouble(dynamic value, {double fallback = 0.0}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

  double _codHandlingCharge(String paymentMethod) {
    final handling =
        _paymentChargesCtrl.amountMatching(paymentMethod, ['handling']);
    if (handling > 0) return handling;

    final lines = _paymentChargesCtrl.linesFor(paymentMethod);
    if (lines.isEmpty) return 0.0;
    final shipping = _paymentChargesCtrl
        .amountMatching(paymentMethod, ['shipping', 'delivery']);
    return (lines.fold(0.0, (sum, charge) => sum + charge.amount) - shipping)
        .clamp(0.0, double.infinity)
        .toDouble();
  }

  double _codShippingCharge(String paymentMethod) {
    return _paymentChargesCtrl.amountMatching(
      paymentMethod,
      ['shipping', 'delivery'],
    );
  }

  bool _hasText(dynamic value) {
    return value?.toString().trim().isNotEmpty ?? false;
  }

  bool _validateGuestOrderData(
    Map<String, dynamic>? shippingAddress,
  ) {
    if (shippingAddress == null) return false;
    return _hasText(shippingAddress['name']) &&
        _hasText(shippingAddress['email']) &&
        _hasText(shippingAddress['phone']) &&
        _hasText(shippingAddress['address']) &&
        _hasText(shippingAddress['city']) &&
        _hasText(shippingAddress['state']) &&
        _hasText(shippingAddress['zipCode']);
  }

  List<Map<String, dynamic>> _paymentChargePayload(String paymentMethod) {
    return _paymentChargesCtrl
        .linesFor(paymentMethod)
        .map((charge) => charge.toJson())
        .toList();
  }

  Future<void> createOrder(
    List orderItems,
    String deliveryType,
    dynamic shippingAdress,
    dynamic pickupDetails,
    double itemsPrice,
    double shippingPrice,
    double totalPrice,
    String paymentMethod,
    String customerNotes,
  ) async {
    final url = Uri.parse(Configss.createOrder);
    SharedPreferences sp = await SharedPreferences.getInstance();
    _usercontroller.token.value = sp.getString('token') ?? '';
    final bool isGuestOrder = sp.getBool('Guest') ?? false;
    final normalizedShippingAddress = shippingAdress is Map
        ? Map<String, dynamic>.from(shippingAdress)
        : <String, dynamic>{};

    // Basic validations (do not set loading yet)
    // if (_usercontroller.token.value.isEmpty) {
    //   EasyLoading.showError('Session expired. Please login again.');
    //   return;
    // }
    // Validate based on actual cart content, not the passed orderItems list
    if (_cartNotifier.cartOtherInfoList.isEmpty) {
      EasyLoading.showError('Your cart is empty.');
      return;
    }
    if (deliveryType == 'home') {
      final hasAddress =
          normalizedShippingAddress['address']?.toString().trim().isNotEmpty ??
              false;
      if (!hasAddress) {
        EasyLoading.showError('Please provide a valid shipping address.');
        return;
      }
    }
    if (isGuestOrder && !_validateGuestOrderData(normalizedShippingAddress)) {
      EasyLoading.showError(
        'Please enter guest name, email, phone and address before placing order.',
      );
      return;
    }

    // Always build from the live cart so selected color metadata is preserved.
    List composedOrderItems = _buildOrderItemsFromCart();
    if (composedOrderItems.isEmpty) {
      composedOrderItems = orderItems;
    }
    log('Composed orderItems from cart: ${jsonEncode(composedOrderItems)}');

    _usercontroller.iscardLoading.value = true;

    final firstOrderDiscount = _firstOrderDiscountAmount();
    final isCodPayment = _isCodPaymentMethod(paymentMethod);
    final paymentCharge = _paymentChargesCtrl.chargeFor(paymentMethod);
    final paymentChargeTotal = _paymentChargesCtrl.totalFor(paymentMethod);
    final codFee = isCodPayment ? _codHandlingCharge(paymentMethod) : 0.0;
    final codShippingFee =
        isCodPayment ? _codShippingCharge(paymentMethod) : 0.0;
    final standardShippingInput =
        deliveryType == 'home' && itemsPrice <= 500 ? shippingPrice : 0.0;
    final standardShippingPrice = isCodPayment ? 0.0 : standardShippingInput;
    final totalBeforeDiscount = isCodPayment
        ? ((totalPrice - standardShippingInput).clamp(0.0, double.infinity) +
                paymentChargeTotal)
            .toDouble()
        : (totalPrice + paymentChargeTotal).toDouble();
    final payableTotal =
        _payableTotalAfterFirstOrderDiscount(totalBeforeDiscount);

    String? couponCode;
    if (firstOrderDiscount > 0 && Get.isRegistered<FirstUserDiscountController>()) {
      final discountController = Get.find<FirstUserDiscountController>();
      couponCode = discountController.previewDiscount.value?['code'] ??
          discountController.discount.value?['name'];
    } else if (_cartNotifier.appliedCouponCode.value.isNotEmpty) {
      couponCode = _cartNotifier.appliedCouponCode.value;
    }

    final Map<String, dynamic> orderData = {
      "orderSource": "app",
      "orderItems": composedOrderItems,
      "deliveryType": deliveryType,
      "shippingAddress": shippingAdress,
      "pickupDetails": pickupDetails,
      "itemsPrice": (itemsPrice).toDouble(),
      "shippingPrice": standardShippingPrice.toDouble(),
      "deliveryChargeId": deliveryType == 'home' ? _deliveryCtrl.selectedId.value : null,
      "codFee": codFee,
      "codShippingFee": codShippingFee,
      "paymentChargeId": paymentCharge?.id,
      "paymentChargeTotal": paymentChargeTotal,
      "paymentCharges": _paymentChargePayload(paymentMethod),
      "totalPrice": payableTotal,
      "originalTotalPrice": totalBeforeDiscount.toDouble(),
      "appDiscountAmount": firstOrderDiscount,
      "appDiscountPreviewApplied": firstOrderDiscount > 0,
      "couponCode": couponCode,
      "paymentMethod": paymentMethod,
      "actualPaymentMethod": paymentMethod,
      "customerNotes": customerNotes
    };

    log('POST $url');
    log('Token present: ${_usercontroller.token.value.isNotEmpty}');
    log('Order payload: ${jsonEncode(orderData)}');

    final Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
      'X-Order-Source': 'app',
    };
    if (_usercontroller.token.value.isNotEmpty && !isGuestOrder) {
      requestHeaders['Authorization'] = 'Bearer ${_usercontroller.token.value}';
    }

    try {
      final response = await http.post(
        url,
        headers: requestHeaders,
        body: jsonEncode(orderData),
      );
      _usercontroller.iscardLoading.value = false;

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final serverTotalPrice = _toDouble(
          data['totalPrice'],
          fallback:
              _toDouble(data['finalTotal'], fallback: totalBeforeDiscount),
        );
        final bool backendAppDiscountApplied =
            !isGuestOrder && data['appDiscountApplied'] == true;
        final bool localAppDiscountApplied =
            !isGuestOrder && firstOrderDiscount > 0;
        final bool appDiscountApplied =
            backendAppDiscountApplied || localAppDiscountApplied;
        final payableTotalPrice = isGuestOrder
            ? totalBeforeDiscount
            : backendAppDiscountApplied
                ? serverTotalPrice
                : localAppDiscountApplied
                    ? payableTotal
                    : serverTotalPrice;
        final double appDiscountAmount = backendAppDiscountApplied
            ? _toDouble(data['appDiscountAmount'])
            : (localAppDiscountApplied ? firstOrderDiscount : 0.0);
        final String appDiscountName = appDiscountApplied
            ? (data['appDiscountName']?.toString() ?? '')
            : '';
        final String? userId = sp.getString('userId')?.toString();
        if (selectedMethod == 'Card') {
          await paymentRequest(
            data['_id'],
            payableTotalPrice,
            userId: userId,
            appDiscountApplied: appDiscountApplied,
            appDiscountAmount: appDiscountAmount,
            appDiscountName: appDiscountName,
          );
        } else if (selectedMethod == 'Tabby') {
          await tabbyPaymentRequest(
            orderId: data['_id'],
            totalAmount: payableTotalPrice,
            customer: {
              "name": shippingAdress?['name'] ?? '',
              "email": shippingAdress?['email'] ?? '',
              "phone": shippingAdress?['phone'] ?? '',
            },
            userId: userId,
            appDiscountApplied: appDiscountApplied,
            appDiscountAmount: appDiscountAmount,
            appDiscountName: appDiscountName,
          );
        } else if (selectedMethod == 'Tamara') {
          await tamaraPaymentRequest(
            orderId: data['_id'],
            totalAmount: payableTotalPrice,
            customer: {
              "name": shippingAdress?['name'] ?? '',
              "email": shippingAdress?['email'] ?? '',
              "phone": shippingAdress?['phone'] ?? '',
            },
            userId: userId,
            appDiscountApplied: appDiscountApplied,
            appDiscountAmount: appDiscountAmount,
            appDiscountName: appDiscountName,
          );
        } else {
          final navigationProvider = Get.put(BottomNavigationController());
          navigationProvider.setTabIndex(0);
          setState(() {});
          await _cartNotifier.clearCartDataInPrefs(userId);
          if (isGuestOrder) {
            await clearGuestCheckoutData();
          }
          if (Get.isRegistered<FirstUserDiscountController>()) {
            await Get.find<FirstUserDiscountController>().refreshAfterOrder();
          }
          Get.offAll(() => SuccessPayment(
                appDiscountApplied: appDiscountApplied,
                appDiscountAmount: appDiscountAmount,
                appDiscountName: appDiscountName,
              ));
        }
        print('Order Created: $data');
      } else {
        final msg = _extractServerMessage(response.body);
        EasyLoading.showError('Create order failed: $msg');
        print('Failed to create order: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      _usercontroller.iscardLoading.value = false;
      EasyLoading.showError('Create order error: ${e.toString()}');
      print('Error creating order: $e');
    }
  }

  String _formatPhoneForTabby(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.startsWith('00')) {
      cleaned = '+' + cleaned.substring(2);
    }
    if (cleaned.startsWith('0')) {
      cleaned = '+971' + cleaned.substring(1);
    }
    if (!cleaned.startsWith('+')) {
      cleaned = '+' + cleaned;
    }
    return cleaned;
  }

  List<Map<String, dynamic>> _buildTabbyItemsFromCart() {
    final List<Map<String, dynamic>> list = [];
    for (final item in _cartNotifier.cartOtherInfoList) {
      try {
        final qty = (item.quantity ?? 1).toInt();
        final unit = item.cartBasePrice;
        list.add({
          "title": item.productName ?? "",
          "quantity": qty,
          "unit_price": unit.toStringAsFixed(2),
          "reference_id": (item.productId ?? '').toString(),
        });
      } catch (e) {
        log('Skipping cart item for Tabby mapping: $e');
      }
    }
    return list;
  }

  Map<String, dynamic> _buildTabbyAddress() {
    final city = _usercontroller.city.value.replaceAll('"', '').trim();
    final street = _usercontroller.street.value.replaceAll('"', '').trim();
    final zip = _usercontroller.zipcode.value.replaceAll('"', '').trim();
    return {
      "city": city.isNotEmpty ? city : "Dubai",
      "address": street.isNotEmpty ? street : "Address not specified",
      "zip": zip.isNotEmpty ? zip : "00000",
    };
  }

  Future<void> tabbyPaymentRequest({
    required String orderId,
    required double totalAmount,
    Map<String, dynamic>? customer,
    String? userId,
    bool appDiscountApplied = false,
    double appDiscountAmount = 0.0,
    String appDiscountName = '',
  }) async {
    final url = Uri.parse("https://api.tabby.ai/api/v2/checkout");
    EasyLoading.show(status: 'Please wait...');

    final name = (customer?['name'] as String? ?? '').trim();
    final email = (customer?['email'] as String? ?? '').trim();
    final phone = _formatPhoneForTabby((customer?['phone'] as String? ?? '').trim());

    final List<Map<String, dynamic>> items = _buildTabbyItemsFromCart();
    final shippingAddress = _buildTabbyAddress();

    final Map<String, dynamic> payload = {
      "payment": {
        "amount": totalAmount.toStringAsFixed(2),
        "currency": "AED",
        "buyer": {
          "phone": phone,
          "email": email,
          "name": name,
        },
        "order": {
          "reference_id": orderId,
          "items": items,
        },
        "shipping_address": shippingAddress,
      },
      "lang": "en",
      "merchant_code": "AE",
      "merchant_urls": {
        "success": "${Configss.webBaseUrl}/payment/success",
        "cancel": "${Configss.webBaseUrl}/payment/cancel",
        "failure": "${Configss.webBaseUrl}/payment/failure",
      }
    };

    log('Tabby request payload: ${jsonEncode(payload)}');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer sk_95cb5ca6-170d-4cef-91f9-0454cae7bd6d',
        },
        body: jsonEncode(payload),
      );
      EasyLoading.dismiss();

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String checkoutUrl = '';
        try {
          final config = data['configuration'];
          if (config != null) {
            final availableProducts = config['available_products'];
            if (availableProducts != null) {
              final installments = availableProducts['installments'];
              if (installments is List && installments.isNotEmpty) {
                checkoutUrl = installments[0]['web_url']?.toString() ?? '';
              }
            }
          }
        } catch (e) {
          log('Error parsing Tabby web_url: $e');
        }

        if (checkoutUrl.isEmpty) {
          checkoutUrl = data['web_url'] ?? '';
        }

        if (checkoutUrl.isEmpty) {
          EasyLoading.showError('Invalid Tabby response structure');
          return;
        }

        Get.to(() => WebViewScreen(
              url: checkoutUrl,
              userId: userId,
              appDiscountApplied: appDiscountApplied,
              appDiscountAmount: appDiscountAmount,
              appDiscountName: appDiscountName,
            ));
      } else {
        final msg = _extractServerMessage(response.body);
        EasyLoading.showError('Tabby init failed: $msg');
        log('Tabby init failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('Tabby init error: ${e.toString()}');
    }
  }

  Future<void> tamaraPaymentRequest({
    required String orderId,
    required double totalAmount,
    Map<String, dynamic>? customer,
    String? userId,
    bool appDiscountApplied = false,
    double appDiscountAmount = 0.0,
    String appDiscountName = '',
  }) async {
    final url = Uri.parse(Configss.paymentTamaraRequest);
    SharedPreferences sp = await SharedPreferences.getInstance();
    _usercontroller.token.value = sp.getString('token') ?? '';
    EasyLoading.show(status: 'Please wait...');

    // Derive customer info and split name
    final name = (customer?['name'] as String? ?? '').trim();
    final email = (customer?['email'] as String? ?? '').trim();
    final phone = (customer?['phone'] as String? ?? '').trim();
    final firstLast = _splitName(name);

    // Build Tamara-required payload
    final List<Map<String, dynamic>> items = _buildTamaraItemsFromCart();
    final shippingAddress = _buildTamaraAddress();
    final billingAddress = shippingAddress; // use same for now

    final Map<String, dynamic> payload = {
      "order_reference_id": orderId,
      "order_number": "ORD_$orderId",
      "total_amount": {
        "amount": totalAmount,
        "currency": "AED",
      },
      "shipping_amount": {
        "amount": 0,
        "currency": "AED",
      },
      "tax_amount": {
        "amount": 0,
        "currency": "AED",
      },
      "items": items,
      "consumer": {
        "email": email,
        "first_name": firstLast['first_name'],
        "last_name": firstLast['last_name'],
        "phone_number": phone,
      },
      "country_code": "AE",
      "description": "Order for ${items.length} item(s) from Graba2z",
      "merchant_url": {
        "cancel": "${Configss.webBaseUrl}/payment/cancel",
        "failure": "${Configss.webBaseUrl}/payment/failure",
        "success": "${Configss.webBaseUrl}/payment/success",
        "notification": "${Configss.baseUrl}/api/webhooks/tamara",
      },
      "payment_type": "PAY_BY_INSTALMENTS",
      "instalments": 3,
      "billing_address": billingAddress,
      "shipping_address": shippingAddress,
      "platform": "Graba2z Mobile App",
      "is_mobile": true,
      "locale": "en_US",
    };
    log('Tamara request payload: ${jsonEncode(payload)}');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_usercontroller.token.value}',
        },
        body: jsonEncode(payload),
      );
      EasyLoading.dismiss();

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String checkoutUrl =
            data['checkout_url'] ?? data['paymentUrl'] ?? '';
        if (checkoutUrl.isEmpty) {
          EasyLoading.showError('Invalid Tamara response');
          return;
        }
        Get.to(() => WebViewScreen(
              url: checkoutUrl,
              userId: userId,
              appDiscountApplied: appDiscountApplied,
              appDiscountAmount: appDiscountAmount,
              appDiscountName: appDiscountName,
            ));
      } else {
        final msg = _extractServerMessage(response.body);
        EasyLoading.showError('Tamara init failed: $msg');
        log('Tamara init failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('Tamara init error: ${e.toString()}');
    }
  }

  // Build Tamara items format
  List<Map<String, dynamic>> _buildTamaraItemsFromCart() {
    final List<Map<String, dynamic>> list = [];
    for (final item in _cartNotifier.cartOtherInfoList) {
      try {
        final qty = (item.quantity ?? 1).toInt();
        final unit = item.cartBasePrice;
        final total = (unit * qty).toDouble();
        list.add({
          "name": item.productName ?? "",
          "type": "Physical",
          "reference_id": (item.productId ?? '').toString(),
          "sku": (item.productId ?? '').toString(),
          "quantity": qty,
          "discount_amount": {"amount": 0, "currency": "AED"},
          "tax_amount": {"amount": 0, "currency": "AED"},
          "unit_price": {"amount": unit, "currency": "AED"},
          "total_amount": {"amount": total, "currency": "AED"},
        });
      } catch (e) {
        log('Skipping cart item for Tamara mapping: $e');
      }
    }
    return list;
  }

  // Build Tamara address from current shipping data
  Map<String, dynamic> _buildTamaraAddress() {
    final String fullName =
        _usercontroller.homeNameController.text.trim().isNotEmpty
            ? _usercontroller.homeNameController.text.trim()
            : _usercontroller.fullName.value.trim();
    final name = _splitName(fullName);
    return {
      "city": _usercontroller.city.value.replaceAll('"', ''),
      "country_code": "AE",
      "first_name": name['first_name'],
      "last_name": name['last_name'],
      "line1": _usercontroller.street.value.replaceAll('"', ''),
      "line2": "",
      "phone_number": _usercontroller.homePhoneController.text,
      "region": _usercontroller.state.value.replaceAll('"', ''),
    };
  }

  Map<String, String> _splitName(String name) {
    final parts = name.trim().split(RegExp(r"\s+"));
    if (parts.isEmpty) {
      return {"first_name": "", "last_name": ""};
    }
    if (parts.length == 1) {
      return {"first_name": parts.first, "last_name": ""};
    }
    return {
      "first_name": parts.first,
      "last_name": parts.sublist(1).join(' '),
    };
  }

  Future<void> paymentRequest(
    String orderId,
    double totalAmount, {
    String? userId,
    bool appDiscountApplied = false,
    double appDiscountAmount = 0.0,
    String appDiscountName = '',
  }) async {
    final url = Uri.parse(Configss.paymentCardRequest); // <-- replace this
    SharedPreferences sp = await SharedPreferences.getInstance();
    _usercontroller.token.value = sp.getString('token') ?? '';
    EasyLoading.show(status: 'Please wait...');
    final Map<String, dynamic> orderData = {
      "amount": totalAmount,
      "currencyCode": "AED",
      "orderId": orderId
    };
    log('the object from my side $orderData');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer ${_usercontroller.token.value}', // <-- Add your token here
        },
        body: jsonEncode(orderData),
      );
      EasyLoading.dismiss();
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final paymentUrl = data['paymentUrl']?.toString() ?? '';
        if (paymentUrl.isEmpty) {
          EasyLoading.showError('Invalid payment response');
          return;
        }
        Get.to(() => WebViewScreen(
              url: paymentUrl,
              userId: userId,
              appDiscountApplied: appDiscountApplied,
              appDiscountAmount: appDiscountAmount,
              appDiscountName: appDiscountName,
            ));
        print('payment order Created: $data');
      } else {
        EasyLoading.showError('Failed to create order');
        print('Failed to create order: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      EasyLoading.dismiss();
      print('Error creating order: $e');
    }
  }

  Widget _buildOrderSummaryCard() {
    final currentSubtotal = subtotal > 0
        ? subtotal
        : _cartNotifier.cartOtherInfoList.fold(
            0.0,
            (sum, item) => sum + (item.cartBasePrice * (item.quantity ?? 0)),
          );
    final originalTotal = _cartOriginalTotal > currentSubtotal
        ? _cartOriginalTotal
        : currentSubtotal;
    final savings =
        (originalTotal - currentSubtotal).clamp(0.0, double.infinity);
    final standardShipping =
        _isCodSelected ? 0.0 : _standardShippingAppliedToCurrentCart();
    final paymentChargeLines =
        _paymentChargesCtrl.linesFor(_selectedPaymentMethodKey);
    final firstOrderDiscount = _firstOrderDiscountAmount();
    final displayTotal = _selectedPayableTotal();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Order Summary",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 14),
          _buildSummaryRowWithStyle(
            "Original Price",
            "AED ${originalTotal.toStringAsFixed(2)}",
            valueStyle: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRowWithStyle(
            "Discounted Price",
            "AED ${currentSubtotal.toStringAsFixed(2)}",
            valueStyle: const TextStyle(
              fontSize: 13,
              color: Color(0xFFD32F2F),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRowWithStyle(
            "Total Savings",
            "- AED ${savings.toStringAsFixed(2)}",
            titleStyle: const TextStyle(
              fontSize: 13,
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.bold,
            ),
            valueStyle: const TextStyle(
              fontSize: 13,
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.black12, height: 1),
          const SizedBox(height: 12),
          _buildSummaryRowWithStyle(
            "Subtotal",
            "AED ${currentSubtotal.toStringAsFixed(2)}",
            valueStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRowWithStyle(
            "Shipping",
            standardShipping > 0
                ? "AED ${standardShipping.toStringAsFixed(2)}"
                : "Free",
          ),
          if (paymentChargeLines.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...paymentChargeLines.map(
              (charge) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildSummaryRowWithStyle(
                  charge.name.isEmpty ? "Payment charge" : charge.name,
                  "AED ${charge.amount.toStringAsFixed(2)}",
                  titleStyle: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF92400E),
                    fontWeight: FontWeight.bold,
                  ),
                  valueStyle: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF92400E),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
          if (firstOrderDiscount > 0) ...[
            _buildSummaryRowWithStyle(
              "First order discount",
              "- AED ${firstOrderDiscount.toStringAsFixed(2)}",
              titleStyle: const TextStyle(
                fontSize: 13,
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.bold,
              ),
              valueStyle: const TextStyle(
                fontSize: 13,
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
          ],
          _buildSummaryRowWithStyle("VAT Included", "Included"),
          const SizedBox(height: 16),
          const Divider(color: Colors.black12, height: 1),
          const SizedBox(height: 16),
          _buildSummaryRowWithStyle(
            "Total Amount",
            "AED ${displayTotal.toStringAsFixed(2)}",
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            valueStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRowWithStyle(
    String title,
    String value, {
    TextStyle? titleStyle,
    TextStyle? valueStyle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: titleStyle ??
                const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
          ),
        ),
        const SizedBox(width: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 96, maxWidth: 132),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: valueStyle ??
                  const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentChargeBreakdown() {
    final paymentCharge =
        _paymentChargesCtrl.chargeFor(_selectedPaymentMethodKey);
    final lines = paymentCharge?.charges ?? <PaymentChargeLine>[];
    if (paymentCharge == null || lines.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEA),
        border: Border.all(color: const Color(0xFFFDE047)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 20,
                color: Color(0xFF92400E),
              ),
              SizedBox(width: 10),
              Text(
                "Payment Charges",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF78350F),
                ),
              ),
            ],
          ),
          if (paymentCharge.description.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              paymentCharge.description,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFA16207),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 12),
          ...lines.map(
            (charge) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildPaymentChargeLine(
                charge.name.isEmpty ? 'Payment charge' : charge.name,
                charge.amount,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentChargeLine(String title, double amount) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.add_circle_outline,
          size: 16,
          color: Color(0xFF92400E),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF78350F),
              ),
              children: [
                TextSpan(
                  text: "$title: ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: "AED ${amount.toStringAsFixed(2)}"),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupedPaymentSection() {
    final List<Map<String, dynamic>> active = [];

    if (allowedPaymentMethods.contains('card')) {
      active.add({
        'value': 'Card',
        'title': 'Debit/Credit Card',
        'logo': _buildCardLogos(),
        'expand': _buildPaymentOptionExpandContent('Card', "You'll be redirected to Debit/Credit Card to complete your purchase."),
      });
    }
    if (allowedPaymentMethods.contains('tabby')) {
      active.add({
        'value': 'Tabby',
        'title': 'Pay later with Tabby',
        'logo': _buildTabbyLogo(),
        'expand': _buildPaymentOptionExpandContent('Tabby', "You'll be redirected to Tabby to complete your purchase."),
      });
    }
    if (allowedPaymentMethods.contains('tamara')) {
      active.add({
        'value': 'Tamara',
        'title': 'Tamara - Monthly payments. Sharia compliant',
        'logo': _buildTamaraLogo(),
        'expand': _buildPaymentOptionExpandContent('Tamara', "You'll be redirected to Tamara to complete your purchase."),
      });
    }
    if (allowedPaymentMethods.contains('cod')) {
      active.add({
        'value': 'COD',
        'title': 'Cash on Delivery (COD)',
        'logo': const SizedBox.shrink(),
        'expand': _buildPaymentOptionExpandContent('COD', "Pay with cash upon delivery."),
      });
    }

    if (active.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
          child: Text(
            "No payment methods are available for the items in your cart. Please contact support.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Column(
          children: List.generate(active.length, (index) {
            final item = active[index];
            return _buildPaymentOption(
              value: item['value'],
              title: item['title'],
              logoWidget: item['logo'],
              isFirst: index == 0,
              isLast: index == active.length - 1,
              expandContent: item['expand'],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String value,
    required String title,
    required Widget logoWidget,
    required bool isFirst,
    required bool isLast,
    Widget? expandContent,
  }) {
    final bool isSelected = selectedMethod == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMethod = value;
          log('the select method is $selectedMethod');
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF8FAFC) : Colors.white,
          border: isSelected
              ? Border.all(color: const Color(0xFF2563EB), width: 1.5)
              : Border(
                  bottom: isLast
                      ? BorderSide.none
                      : BorderSide(color: Colors.grey.shade200, width: 1),
                ),
          borderRadius: isSelected
              ? (isFirst && isLast
                  ? BorderRadius.circular(11)
                  : isFirst
                      ? const BorderRadius.vertical(top: Radius.circular(11))
                      : isLast
                          ? const BorderRadius.vertical(bottom: Radius.circular(11))
                          : BorderRadius.zero)
              : BorderRadius.zero,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 20,
                  width: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade400,
                      width: 1.8,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            height: 10,
                            width: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2563EB),
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                logoWidget,
              ],
            ),
            if (isSelected && expandContent != null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 34),
                child: expandContent,
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildCardLogos() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLogoBadge('assets/images/visa.png'),
        const SizedBox(width: 4),
        _buildLogoBadge('assets/images/master.jpg'),
        const SizedBox(width: 4),
        Container(
          height: 18,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(3),
          ),
          child: const Center(
            child: Text(
              'SAMSUNG\npay',
              style: TextStyle(
                fontSize: 4,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                height: 1.1,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Container(
          height: 18,
          width: 26,
          decoration: BoxDecoration(
            color: const Color(0xFF0F766E),
            borderRadius: BorderRadius.circular(3),
          ),
          child: const Center(
            child: Icon(Icons.credit_card_outlined, color: Colors.white, size: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildTabbyLogo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF3DF2B4),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'tabby',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Color(0xFF003822),
        ),
      ),
    );
  }

  Widget _buildTamaraLogo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoBadge(String assetPath) {
    return Container(
      height: 18,
      width: 26,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (context, _, __) => const Icon(Icons.credit_card, size: 12),
        ),
      ),
    );
  }

  Widget _buildPaymentOptionExpandContent(String value, String defaultRedirectText) {
    final methodKey = _mapPaymentMethod(value);
    return Obx(() {
      _paymentChargesCtrl.activeCharges.length;
      _paymentChargesCtrl.isLoading.value;

      final currentCharge = _paymentChargesCtrl.chargeFor(methodKey);
      final currentChargesList = currentCharge?.charges ?? <PaymentChargeLine>[];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            defaultRedirectText,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          if (currentChargesList.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...currentChargesList.map((charge) {
              String formattedText = '• ${charge.name}';
              if (charge.name.toLowerCase().contains('%') || charge.name.toLowerCase().contains('fee')) {
                formattedText = '• ${charge.name} (AED ${charge.amount.toStringAsFixed(2)})';
              } else {
                formattedText = '• ${charge.name}: AED ${charge.amount.toStringAsFixed(2)}';
              }
              return Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  formattedText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }),
          ],
        ],
      );
    });
  }

  // Build orderItems in backend expected format (used when controller list is empty)
  List<Map<String, dynamic>> _buildOrderItemsFromCart() {
    final List<Map<String, dynamic>> items = [];
    for (final item in _cartNotifier.cartOtherInfoList) {
      try {
        final Map<String, dynamic> orderItem = {
          "product": item.productId,
          "quantity": (item.quantity ?? 1),
        };

        // Standard legacy fields for backward compatibility with other endpoints
        orderItem["name"] = item.productName ?? '';
        orderItem["price"] = item.cartBasePrice;
        orderItem["image"] = item.productImage ?? '';

        if (item.isProtection == true) {
          orderItem["isProtection"] = true;
          orderItem["protectionFor"] = item.protectionFor;
          orderItem["protectionData"] = item.protectionData;
        } else {
          if (item.selectedColorIndex != null) {
            orderItem["selectedColorIndex"] = item.selectedColorIndex;
          }
          if (item.selectedDosIndex != null) {
            orderItem["selectedDosIndex"] = item.selectedDosIndex;
          }
        }

        items.add(orderItem);
      } catch (e) {
        log('Skipping cart item due to mapping error: $e');
      }
    }
    return items;
  }

  String _extractServerMessage(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map) {
        return (data['message'] ??
                data['error'] ??
                data['errors'] ??
                data['detail'] ??
                body)
            .toString();
      }
      return body;
    } catch (_) {
      return body;
    }
  }
}
