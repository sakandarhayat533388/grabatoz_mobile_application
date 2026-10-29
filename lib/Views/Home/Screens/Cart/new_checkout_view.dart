import 'dart:convert';

import 'package:easy_stepper/easy_stepper.dart';
import 'package:get/get.dart';
import 'package:graba2z/Configs/config.dart';
import 'package:graba2z/Controllers/address_controller.dart';
import 'package:graba2z/Controllers/addtocart.dart';
import 'package:graba2z/Controllers/checkout_controller.dart';
import 'package:graba2z/Controllers/deliveryController.dart';
import 'package:graba2z/Controllers/payment_charges_controller.dart';
import 'package:graba2z/Utils/appextensions.dart';
import 'package:graba2z/Utils/price_formatter.dart';
import 'package:graba2z/Utils/guest_checkout_storage.dart';
import 'package:graba2z/Utils/packages.dart'; // for AuthController
import 'package:graba2z/Views/Home/Screens/Cart/address_formt.dart';
import 'package:graba2z/Views/Home/Screens/Cart/new_payment.dart';
import 'package:graba2z/Views/Home/Screens/Cart/new_summary_view.dart';
import 'package:graba2z/Views/Home/Screens/Cart/store_selection.dart';
import 'package:graba2z/Utils/popup_helper.dart';
import 'package:http/http.dart' as http;
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';

class CheckoutStepper extends StatefulWidget {
  final bool isforguest;
  const CheckoutStepper({super.key, required this.isforguest});

  @override
  State<CheckoutStepper> createState() => _CheckoutStepperState();
}

class _CheckoutStepperState extends State<CheckoutStepper> {
  String userEmail = '';
  String? _selectedAddressId;
  bool isCodeSent = false;
  bool isVerifying = true;
  TextEditingController otpController = TextEditingController();
  bool isotpVerified = false;
  bool isOtpVerifying = false;
  bool canResend = false;

  // Phone number with country code
  String completePhoneNumber = '';
  String selectedCountryCode = '+971';
  String initialCountryCode = 'AE';
  bool _isParsingPhone = false; // Flag to prevent recursive parsing

  // Country dial code to ISO code mapping
  final Map<String, String> dialCodeToCountry = {
    '+971': 'AE', // UAE
    '+966': 'SA', // Saudi Arabia
    '+968': 'OM', // Oman
    '+974': 'QA', // Qatar
    '+973': 'BH', // Bahrain
    '+965': 'KW', // Kuwait
    '+91': 'IN', // India
    '+92': 'PK', // Pakistan
    '+44': 'GB', // UK
    '+1': 'US', // USA
    '+63': 'PH', // Philippines
    '+20': 'EG', // Egypt
    '+962': 'JO', // Jordan
    '+961': 'LB', // Lebanon
    '+86': 'CN', // China
    '+81': 'JP', // Japan
    '+82': 'KR', // South Korea
    '+49': 'DE', // Germany
    '+33': 'FR', // France
    '+39': 'IT', // Italy
    '+34': 'ES', // Spain
    '+61': 'AU', // Australia
    '+55': 'BR', // Brazil
    '+7': 'RU', // Russia
    '+90': 'TR', // Turkey
    '+27': 'ZA', // South Africa
    '+234': 'NG', // Nigeria
    '+254': 'KE', // Kenya
    '+880': 'BD', // Bangladesh
    '+94': 'LK', // Sri Lanka
    '+977': 'NP', // Nepal
    '+60': 'MY', // Malaysia
    '+65': 'SG', // Singapore
    '+62': 'ID', // Indonesia
    '+66': 'TH', // Thailand
    '+84': 'VN', // Vietnam
  };

  // Parse phone number and detect country
  void _parseAndSetCountry(String rawPhone) {
    if (rawPhone.trim().isEmpty || _isParsingPhone) return;

    _isParsingPhone = true;

    String text = rawPhone.trim();
    if (text.startsWith('00')) {
      text = '+${text.substring(2)}';
    }

    // Extract all digits, preserving leading plus sign if present
    final StringBuffer digitsBuf = StringBuffer();
    final bool hasPlus = text.startsWith('+');
    for (int i = 0; i < text.length; i++) {
      if (RegExp(r'\d').hasMatch(text[i])) {
        digitsBuf.write(text[i]);
      }
    }
    final String digits = digitsBuf.toString();
    if (digits.isEmpty) {
      _isParsingPhone = false;
      return;
    }

    // A bare national number (no '+' or '00' prefix) must NEVER be
    // reinterpreted as having a dial code: its leading digits belong to
    // the number itself (e.g. Pakistani "3326723213" is NOT "+33...").
    // Keep the currently selected country and use the digits as-is.
    if (!hasPlus) {
      String nationalOnly = digits;
      while (nationalOnly.startsWith('0')) {
        nationalOnly = nationalOnly.substring(1);
      }
      completePhoneNumber = '$selectedCountryCode$nationalOnly';
      _userController.homePhoneController.text = nationalOnly;
      if (mounted) setState(() {});
      _isParsingPhone = false;
      return;
    }

    String formattedFull = '+$digits';

    String detectedCountry = 'AE';
    String detectedDialCode = '+971';
    String nationalNumber = digits;

    final sortedCodes = dialCodeToCountry.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    bool matched = false;
    for (String dialCode in sortedCodes) {
      if (formattedFull.startsWith(dialCode)) {
        detectedCountry = dialCodeToCountry[dialCode]!;
        detectedDialCode = dialCode;
        final dialDigits = dialCode.replaceAll('+', '');
        nationalNumber = digits.substring(dialDigits.length);
        matched = true;
        break;
      }
    }

    if (!matched) {
      detectedCountry = 'AE';
      detectedDialCode = '+971';
      nationalNumber = digits;
    }

    // Strip leading zero for national number (e.g. 0505033860 -> 505033860)
    while (nationalNumber.startsWith('0')) {
      nationalNumber = nationalNumber.substring(1);
    }

    initialCountryCode = detectedCountry;
    selectedCountryCode = detectedDialCode;
    completePhoneNumber = '$detectedDialCode$nationalNumber';
    _userController.homePhoneController.text = nationalNumber;

    if (mounted) setState(() {});

    _isParsingPhone = false;
  }

  bool checkguest = true;
  int otpSeconds = 60;
  Timer? otpTimer;

  getUserInformation() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    userEmail = widget.isforguest ? '' : sp.getString('userEmail') ?? '';
    _userController.homeemailAddress.text = userEmail;
    if (widget.isforguest) {
      setState(() {
        checkguest = true;
      });
    }
    setState(() {});
  }

  final AuthController _authController = Get.isRegistered<AuthController>()
      ? Get.find<AuthController>()
      : Get.put(AuthController(), permanent: true);

  final AddressController _addressController = Get.isRegistered<AddressController>()
      ? Get.find<AddressController>()
      : Get.put(AddressController());

  final DeliveryController _deliveryCtrl = Get.isRegistered<DeliveryController>()
      ? Get.find<DeliveryController>()
      : Get.put(DeliveryController());

  @override
  void initState() {
    super.initState();
    if (widget.isforguest) {
      _resetGuestCheckoutState();
    } else {
      _addressController.fetchAddresses();
    }
    getUserInformation();
    _deliveryCtrl.fetchMethods();
    final paymentChargesCtrl = Get.isRegistered<PaymentChargesController>()
        ? Get.find<PaymentChargesController>()
        : Get.put(PaymentChargesController());
    paymentChargesCtrl.fetchActiveCharges();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        PopupHelper.showIfNeeded(context, 'checkout');
      }
      if (widget.isforguest) return;
      _userController.getUserInformation();
      // Fetch profile like Edit Profile, prefill now, and keep in sync when data arrives
      _authController.getUserProfileData();
      _authController.getUserProfileData();
      _attachAuthControllerListeners();
      _prefillFromProfile(); // immediate attempt (in case data is already available)
    });
  }

  Future<void> _resetGuestCheckoutState() async {
    await clearGuestCheckoutData();
    _userController.homeNameController.clear();
    _userController.homeemailAddress.clear();
    _userController.homePhoneController.clear();
    _userController.phoneController.clear();
    _userController.street.value = '';
    _userController.city.value = '';
    _userController.state.value = '';
    _userController.zipcode.value = '';
    completePhoneNumber = '';
    selectedCountryCode = '+971';
    initialCountryCode = 'AE';
    isotpVerified = false;
    isVerifying = true;
    isCodeSent = false;
    if (mounted) setState(() {});
  }

  void _attachAuthControllerListeners() {
    // Keep checkout fields in sync when Edit Profile text controllers get populated
    _authController.editPhoneController.addListener(_syncFromAuthControllers);
    _authController.editaddressController.addListener(_syncFromAuthControllers);
    _authController.editcityController.addListener(_syncFromAuthControllers);
    _authController.editzipcodeController.addListener(_syncFromAuthControllers);
    _authController.editStateController
        .addListener(_syncFromAuthControllers); // Add this line
  }

  void _syncFromAuthControllers() {
    if (_isParsingPhone) return; // Prevent recursive calls

    // Sync all fields including state from Edit Profile to Checkout
    final phone = _authController.editPhoneController.text.trim();
    final street = _authController.editaddressController.text.trim();
    final city = _authController.editcityController.text.trim();
    final zip = _authController.editzipcodeController.text.trim();
    final state = _authController.editStateController.text.trim();
    bool changed = false;

    // Parse and set country if phone number is different from what we already have
    if (phone.isNotEmpty && completePhoneNumber != phone) {
      // Parse country code from phone number
      _parseAndSetCountry(phone);
      changed = true;
    }

    if (street.isNotEmpty && _userController.street.value != street) {
      _userController.street.value = street;
      changed = true;
    }

    if (city.isNotEmpty && _userController.city.value != city) {
      _userController.city.value = city;
      changed = true;
    }

    if (zip.isNotEmpty && _userController.zipcode.value != zip) {
      _userController.zipcode.value = zip;
      changed = true;
    }

    // Sync state - including when it's cleared (empty string)
    if (_userController.state.value != state) {
      _userController.state.value = state;
      changed = true;
      print("🔄 Synced state from Edit Profile: '$state'");
    }

    if (changed && mounted) setState(() {});
  }

  // Timer set for resend code
  void startOtpTimer() {
    otpSeconds = 60;
    canResend = false;

    otpTimer?.cancel();
    otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (otpSeconds == 0) {
        timer.cancel();
        setState(() => canResend = true);
      } else {
        setState(() => otpSeconds--);
      }
      setState(() {});
    });
  }

  Future<void> _sendCode() async {
    final email = _userController.homeemailAddress.text.trim();
    if (email.isEmpty) {
      Get.snackbar('checkout_error_title'.tr, 'checkout_enter_email'.tr);
      return;
    }
    setState(() {
      isCodeSent = true;
    });
    await sendEmailVerificationCode(email);
    startOtpTimer(); // ⏱ start countdown
  }

// Verify otp
  Future<void> verifyOtp() async {
    final email = _userController.homeemailAddress.text.trim();
    final otp = otpController.text.trim();
    if (otp.isEmpty) {
      EasyLoading.showError('checkout_enter_otp'.tr);
      return;
    }

    EasyLoading.show(status: 'checkout_verifying_otp'.tr);

    final url =
        Uri.parse("${Configss.baseUrl}/api/request-callback/verify-code");

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "email": email,
          "code": otp,
        }),
      );

      EasyLoading.dismiss();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final email = _userController.homeemailAddress.text.trim();
          EasyLoading.showSuccess('checkout_otp_verified'.tr);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('guest_email', email);

          setState(() {
            isCodeSent = false;
            isotpVerified = true;
            isVerifying = false;
          });
          // Next step: navigate to another screen or mark verified
        } else {
          EasyLoading.showError(data['message'] ?? 'checkout_otp_failed'.tr);
        }
      } else {
        EasyLoading.showError(
            'checkout_otp_failed_code'.trParams({'code': response.statusCode.toString()}));
      }
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('checkout_otp_error'.trParams({'error': e.toString()}));
    }
  }

  // Send Email Verification code
  Future<void> sendEmailVerificationCode(String email) async {
    try {
      EasyLoading.show(status: 'checkout_sending_code'.tr);

      final response = await http.post(
        Uri.parse("${Configss.baseUrl}/api/request-callback/send-verification"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "email": email,
        }),
      );

      EasyLoading.dismiss();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["success"] == true) {
          setState(() {
            isVerifying = false;
            isCodeSent = true; // 👈 SHOW OTP FIELD
          });
          Get.snackbar(
            'checkout_success_title'.tr,
            'checkout_code_sent'.tr,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );

          /// OTP FIELD SHOW + TIMER START
          setState(() {
            isCodeSent = true;
          });
          startOtpTimer();
        } else {
          Get.snackbar(
            'checkout_error_title'.tr,
            data["message"] ?? 'checkout_failed_send_code'.tr,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } else {
        Get.snackbar(
          'checkout_error_title'.tr,
          'checkout_server_error'.tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      EasyLoading.dismiss();
      Get.snackbar(
        'checkout_error_title'.tr,
        'checkout_something_wrong'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _prefillFromProfile() {
    try {
      final phone = _authController.editPhoneController.text.trim().isNotEmpty
          ? _authController.editPhoneController.text.trim()
          : _userController.homePhoneController.text.trim();
      if (phone.isNotEmpty) {
        // Parse phone and detect country code
        _parseAndSetCountry(phone);
      }
      final street = _authController.editaddressController.text.trim();
      final city = _authController.editcityController.text.trim();
      final zip = _authController.editzipcodeController.text.trim();
      final state = _authController.editStateController.text.trim();

      if (street.isNotEmpty) _userController.street.value = street;
      if (city.isNotEmpty) _userController.city.value = city;
      if (zip.isNotEmpty) _userController.zipcode.value = zip;
      _userController.state.value = state; // Sync state even if empty

      if (mounted) setState(() {});
    } catch (_) {
      // swallow; keep existing values
    }
  }

  void _syncToAuthController() {
    // Sync checkout data back to edit profile controllers
    // Use complete phone number with country code
    final fullPhone = completePhoneNumber.isNotEmpty
        ? completePhoneNumber
        : (_userController.isHomeDelivery.value
            ? _userController.homePhoneController.text
            : _userController.phoneController.text);

    _authController.editPhoneController.text = fullPhone;

    _authController.editaddressController.text = _userController.street.value;
    _authController.editcityController.text = _userController.city.value;
    _authController.editzipcodeController.text = _userController.zipcode.value;
    _authController.editStateController.text = _userController.state.value;

    // Also update observable values in auth controller
    _authController.phoneNumber.value = fullPhone;
    _authController.address.value = _userController.street.value;
  }

  @override
  void dispose() {
    // Remove listeners to avoid leaks
    _authController.editPhoneController
        .removeListener(_syncFromAuthControllers);
    _authController.editaddressController
        .removeListener(_syncFromAuthControllers);
    _authController.editcityController.removeListener(_syncFromAuthControllers);
    _authController.editzipcodeController
        .removeListener(_syncFromAuthControllers);
    _authController.editStateController
        .removeListener(_syncFromAuthControllers); // Add this line
    super.dispose();
  }

  final _cartNotifier = Get.put(CartNotifier());
  double vatPerItem = 0.0;
  double subtotal = 0.0;
  String? _homePhoneError;
  bool _isRegisteringGuest = false;

  String _digitsOnly(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

  bool _isValidPhone(String input) {
    final d = _digitsOnly(input);
    return d.length >= 7 && d.length <= 15;
  }

  // Alias for backwards compatibility
  bool _isValidUaePhone(String input) => _isValidPhone(input);

  // Get full phone number with country code
  String getFullPhoneNumber() {
    return completePhoneNumber;
  }

  Future<bool> _registerGuestAccount(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    final name = (prefs.getString('guest_name') ??
            _userController.homeNameController.text)
        .trim();
    final email = _userController.homeemailAddress.text.trim();
    final address = (prefs.getString('guest_address') ??
            _userController.street.value.replaceAll('"', ''))
        .trim();
    final city = (prefs.getString('guest_city') ??
            _userController.city.value.replaceAll('"', ''))
        .trim();
    final state = (prefs.getString('guest_state') ??
            _userController.state.value.replaceAll('"', ''))
        .trim();
    final zipCode = (prefs.getString('guest_zip') ??
            _userController.zipcode.value.replaceAll('"', ''))
        .trim();
    final registeredEmail = prefs.getString('guest_registered_email') ?? '';

    if (registeredEmail == email && email.isNotEmpty) {
      return true;
    }

    if (name.isEmpty ||
        email.isEmpty ||
        phone.trim().isEmpty ||
        address.isEmpty ||
        city.isEmpty ||
        state.isEmpty ||
        zipCode.isEmpty) {
      Get.snackbar(
        'checkout_warning_title'.tr,
        'checkout_complete_guest_details'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    setState(() => _isRegisteringGuest = true);
    EasyLoading.show(status: 'checkout_checking_guest'.tr);

    try {
      final response = await http.post(
        Uri.parse(Configss.registerGuest),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "name": name,
          "email": email.trim().toLowerCase(),
          "phone": phone.trim(),
          "address": {
            "address": address,
            "city": city,
            "state": state,
            "zipCode": zipCode,
            "country": "UAE",
          }
        }),
      );

      EasyLoading.dismiss();

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 && data['alreadyExists'] == true) {
        await _showGuestAlreadyRegisteredDialog();
        return false;
      }

      if (response.statusCode == 201 ||
          (response.statusCode == 200 && data['success'] == true)) {
        await prefs.setBool('Guest', true);
        await prefs.setString('guest_email', email);
        await prefs.setString('guest_registered_email', email);
        return true;
      }

      EasyLoading.showError(
        data['message']?.toString() ?? 'checkout_unable_guest'.tr,
      );
      return false;
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('checkout_unable_guest'.tr);
      return false;
    } finally {
      if (mounted) {
        setState(() => _isRegisteringGuest = false);
      }
    }
  }

  Future<void> _showGuestAlreadyRegisteredDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_search_rounded,
                    color: kPrimaryColor,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'checkout_account_exists'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: kdefblackColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'checkout_email_registered'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: kmediumblackColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shadowColor: kPrimaryColor.withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    onPressed: () async {
                      await clearGuestCheckoutData();
                      if (Navigator.of(dialogContext).canPop()) {
                        Navigator.of(dialogContext).pop();
                      }
                      Get.offAll(() => const Login());
                    },
                    icon: const Icon(Icons.login_rounded, size: 20),
                    label: Text(
                      'checkout_go_to_login'.tr,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'checkout_cart_safe'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  getcalculations() {
    subtotal = _cartNotifier.cartOtherInfoList.fold(
        0.0, (sum, item) => sum + (item.cartBasePrice * (item.quantity ?? 0)));

    if (subtotal <= 500) {
      _cartNotifier.totalAmount.value =
          subtotal + _cartNotifier.deliveryFeeCharge.value;
    } else {
      _cartNotifier.totalAmount.value = subtotal;
    }
  }

  String? selectedSubCategoryId;
  final UserController _userController = Get.put(UserController());
  void _handleBackPress() {
    if (_userController.activeStep.value > 0) {
      setState(() {
        _userController.activeStep.value--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBackPress,
          ),
          title: Text('checkout'.tr),
          surfaceTintColor: Colors.white,
        ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Obx(
                  () => EasyStepper(
                    activeStep: _userController.activeStep.value,
                    stepShape: StepShape.circle,
                    stepRadius: 20,
                    showLoadingAnimation: false,
                    direction: Axis.horizontal,
                    activeStepTextColor: Colors.green,
                    finishedStepTextColor: Colors.black,
                    internalPadding: 8,
                    unreachedStepTextColor: Colors.grey,
                    activeStepBorderColor: Colors.green,
                    steps: [
                      EasyStep(
                          icon: Icon(Icons.local_shipping), title: 'checkout_shipping'.tr),
                      EasyStep(
                          icon: Icon(Icons.receipt_long), title: 'checkout_summary'.tr),
                      EasyStep(icon: Icon(Icons.payment), title: 'checkout_payment'.tr),
                    ],
                    onStepReached: (index) => setState(
                        () => _userController.activeStep.value = index),
                  ),
                )),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Obx(() => _buildStepContent()),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildStepContent() {
    // Use completePhoneNumber which is set by IntlPhoneField
    final displayPhone = _userController.isHomeDelivery.value
        ? completePhoneNumber
        : _userController.phoneController.text;

    switch (_userController.activeStep.value) {
      case 0:
        return _shippingStep();
      case 1:
        return NewSummaryView(
          addressCustomer: [
            _userController.street.value.replaceAll('"', '').trim(),
            _userController.city.value.replaceAll('"', '').trim(),
            _userController.state.value.replaceAll('"', '').trim(),
            _userController.zipcode.value.replaceAll('"', '').trim(),
          ].where((s) => s.isNotEmpty).join(', '),
          companyAddress: _userController.storeAddress.value,
          companyName: _userController.storeName.value,
          customerEmail: userEmail,
          phone: displayPhone,
          shippingType: _userController.isHomeDelivery.value
              ? 'Home Delivery'
              : 'Store Pickup',
          subtotal: subtotal,
        );
      case 2:
        return PaymentMethodScreen();
      default:
        return const SizedBox();
    }
  }

  Widget _shippingStep() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    _userController.isHomeDelivery.value = true;
                    setState(() {});
                  },
                  child: defaultStyledContainer(
                    backgroundColor: _userController.isHomeDelivery.value
                        ? kPrimaryColor
                        : kdefwhiteColor,
                    child: Column(
                      children: [
                        Text(
                          'checkout_home_delivery'.tr,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _userController.isHomeDelivery.value
                                ? kdefwhiteColor
                                : kdefblackColor,
                          ),
                        ),
                        Obx(() {
                          if (!_deliveryCtrl.hasActiveDeliveryCharges) {
                            return const SizedBox.shrink();
                          }
                          final subtotal = _cartNotifier.cartOtherInfoList
                              .fold(0.0, (s, i) => s + (i.productPrice ?? 0.0) * (i.quantity ?? 1));
                          final fee = _deliveryCtrl.calculateShippingFee(subtotal);
                          final text = (fee == null || fee == 0.0)
                              ? 'checkout_free'.tr
                              : formatPriceForSelected(fee);
                          return Column(
                            children: [
                              4.0.heightbox,
                              Text(
                                text,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _userController.isHomeDelivery.value
                                      ? kdefwhiteColor
                                      : kPrimaryColor,
                                ),
                              ),
                            ],
                          );
                        }),
                        4.0.heightbox,
                        Text(
                          'checkout_deliver_doorstep'.tr,
                          style: TextStyle(
                            fontSize: 13,
                            color: _userController.isHomeDelivery.value
                                ? kdefwhiteColor
                                : kdefblackColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              10.0.widthbox,
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    _userController.isHomeDelivery.value = false;
                    setState(() {});
                  },
                  child: defaultStyledContainer(
                    backgroundColor:
                        _userController.isHomeDelivery.value == false
                            ? kPrimaryColor
                            : kdefwhiteColor,
                    child: Column(
                      children: [
                        Text(
                          'checkout_pick_from_point'.tr,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _userController.isHomeDelivery.value == false
                                ? kdefwhiteColor
                                : kdefblackColor,
                          ),
                        ),
                        4.0.heightbox,
                        Text(
                          'checkout_free_delivery'.tr,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _userController.isHomeDelivery.value == false
                                ? kdefwhiteColor
                                : kPrimaryColor,
                          ),
                        ),
                        4.0.heightbox,
                        Text(
                          'checkout_pick_from_store'.tr,
                          style: TextStyle(
                            fontSize: 13,
                            color: _userController.isHomeDelivery.value == false
                                ? kdefwhiteColor
                                : kdefblackColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _userController.isHomeDelivery.value
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('checkout_contact_details'.tr,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _userController.homeemailAddress,
                            keyboardType: TextInputType.emailAddress,
                            readOnly: !widget
                                .isforguest, // login user email edit na kar sake
                            decoration: InputDecoration(
                              labelText: 'checkout_email_label'.tr,
                              hintText: "example@email.com",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),

                        /// ✅ ONLY FOR GUEST USER
                        if (widget.isforguest) ...[
                          const SizedBox(width: 8),
                          if (isotpVerified) ...[
                            Expanded(
                              flex: 1,
                              child: SizedBox(
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: () async {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  child: Text(
                                    'checkout_verified'.tr,
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (isVerifying) ...[
                            Expanded(
                              flex: 1,
                              child: SizedBox(
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    _sendCode();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  child: Text(
                                    'checkout_verify'.tr,
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 13),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),

                    const SizedBox(height: 10),
                    if (isCodeSent) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// OTP FIELD
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: otpController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  decoration: InputDecoration(
                                    counterText: "",
                                    labelText: 'checkout_otp_label'.tr,
                                    hintText: 'checkout_otp_hint'.tr,
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                canResend
                                    ? GestureDetector(
                                        onTap: () {},
                                        child: Text(
                                          'checkout_resend'.tr,
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        'checkout_otp_seconds'.trParams({'seconds': otpSeconds.toString()}),
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          /// VERIFY BUTTON + TIMER
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed:
                                        isOtpVerifying ? null : verifyOtp,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                    child: isOtpVerifying
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text('checkout_verify_code'.tr),
                                  ),
                                ),

                                const SizedBox(height: 6),

                                /// COUNTDOWN / RESEND
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // International Phone Field
                    IntlPhoneField(
                      key: ValueKey(
                          initialCountryCode), // Rebuild when country changes
                      controller: _userController.homePhoneController,
                      decoration: InputDecoration(
                        labelText: 'checkout_phone_label'.tr,
                        hintText: 'checkout_phone_hint'.tr,
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        errorText: _homePhoneError,
                      ),
                      initialCountryCode: initialCountryCode,
                      disableLengthCheck: false,
                      dropdownIconPosition: IconPosition.trailing,
                      flagsButtonPadding: const EdgeInsets.only(left: 10),
                      showDropdownIcon: true,
                      dropdownTextStyle: const TextStyle(fontSize: 14),
                      onChanged: (PhoneNumber phone) {
                        final dial = phone.countryCode.startsWith('+')
                            ? phone.countryCode
                            : '+${phone.countryCode}';
                        String numOnly = phone.number.trim();
                        while (numOnly.startsWith('0')) {
                          numOnly = numOnly.substring(1);
                        }
                        setState(() {
                          selectedCountryCode = dial.isNotEmpty ? dial : '+971';
                          completePhoneNumber = '$selectedCountryCode$numOnly';
                          if (numOnly.isEmpty) {
                            _homePhoneError = 'checkout_phone_required'.tr;
                          } else {
                            _homePhoneError = null;
                          }
                        });
                      },
                      onCountryChanged: (country) {
                        final dial = country.dialCode.startsWith('+')
                            ? country.dialCode
                            : '+${country.dialCode}';
                        String numOnly = _userController.homePhoneController.text.trim();
                        while (numOnly.startsWith('0')) {
                          numOnly = numOnly.substring(1);
                        }
                        setState(() {
                          selectedCountryCode = dial;
                          completePhoneNumber = '$selectedCountryCode$numOnly';
                        });
                      },
                    ),
                    _buildSavedAddressSelection(),
                    const SizedBox(height: 20),
                  ],
                )
              : StoreSelectionScreen(),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () async {
                if (_isRegisteringGuest) return;
                if (_userController.isHomeDelivery.value) {
                  final homePhone =
                      _userController.homePhoneController.text.trim();
                  // Use complete phone number from IntlPhoneField
                  final fullPhoneNumber = completePhoneNumber;

                  if (widget.isforguest) {
                    if (checkguest && isVerifying) {
                      Get.snackbar(
                          'checkout_warning_title'.tr, 'checkout_enter_email_verify'.tr,
                          backgroundColor: Colors.red, colorText: Colors.white);
                      return;
                    }
                  }
                  // Validate phone number - check both homePhone and completePhoneNumber
                  if (homePhone.isEmpty || fullPhoneNumber.isEmpty) {
                    setState(() {
                      _homePhoneError = 'checkout_phone_required'.tr;
                    });
                    Get.snackbar('checkout_warning_title'.tr, 'checkout_valid_phone'.tr,
                        backgroundColor: Colors.red, colorText: Colors.white);
                    return;
                  }
                  final prefs = await SharedPreferences.getInstance();
                  // Save full phone number with country code
                  await prefs.setString('guest_phone', fullPhoneNumber);
                  await prefs.setString(
                      'guest_country_code', selectedCountryCode);

                  // Sync full phone to edit profile (but NOT homePhoneController - IntlPhoneField manages that)
                  _authController.editPhoneController.text = fullPhoneNumber;
                  _authController.phoneNumber.value = fullPhoneNumber;

                  if (_selectedAddressId == null ||
                      _userController.street.value.trim().isEmpty) {
                    Get.snackbar(
                      'checkout_warning_title'.tr,
                      'checkout_select_address'.tr,
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                      snackPosition: SnackPosition.TOP,
                    );
                    return;
                  }

                  if (widget.isforguest &&
                      !await _registerGuestAccount(fullPhoneNumber)) {
                    return;
                  }

                  // Update phone number in the selected address if user changed it
                  if (_selectedAddressId != null &&
                      _selectedAddressId != 'profile_default' &&
                      _addressController.addresses
                          .any((a) => a.id == _selectedAddressId)) {
                    final selectedAddr = _addressController.addresses
                        .firstWhere((a) => a.id == _selectedAddressId);
                    if (selectedAddr.phone.trim() != fullPhoneNumber.trim()) {
                      final updatedPayload = {
                        "name": selectedAddr.name,
                        "phone": fullPhoneNumber.trim(),
                        "email": selectedAddr.email,
                        "address": selectedAddr.address,
                        "city": selectedAddr.city,
                        "state": selectedAddr.state,
                        "zipCode": selectedAddr.zipCode,
                        "isDefault": selectedAddr.isDefault,
                      };
                      await _addressController.updateAddress(
                          selectedAddr.id, updatedPayload);
                    }
                  }
                  // Sync phone and address to edit profile before continuing
                  _syncToAuthController();

                  if (!widget.isforguest) {
                    await _authController.sendUserData(
                      phone: fullPhoneNumber,
                      name: _authController.editNameController.text,
                      email: _authController.editemailController.text,
                      street: _userController.street.value,
                      city: _userController.city.value,
                      state: _userController.state.value,
                      zipCode: _userController.zipcode.value,
                      country: 'UAE',
                      showSuccessMessage: false,
                    );
                  }

                  setState(() {
                    _userController.activeStep.value = 1;
                  });
                } else {
                  final pickupPhone =
                      _userController.phoneController.text.trim();
                  
                  // Use full phone number with country code
                  String fullPickupPhone = pickupPhone;
                  if (fullPickupPhone.isNotEmpty && !fullPickupPhone.startsWith('+')) {
                    fullPickupPhone = '$selectedCountryCode$fullPickupPhone';
                  }

                  // Debug current state
                  print('🔍 Continue button pressed for pickup');
                  print(
                      '   selectedStoreIndex: ${_userController.selectedStoreIndex?.value}');
                  print('   storeId: "${_userController.storeId.value}"');
                  print('   storeName: "${_userController.storeName.value}"');
                  print(
                      '   storeAddress: "${_userController.storeAddress.value}"');
                  print('   storePhone: "${_userController.storePhone.value}"');
                  print('   pickupPhone: "$pickupPhone"');

                  // Validate store selection
                  if (_userController.selectedStoreIndex?.value == null ||
                      _userController.selectedStoreIndex!.value == -1) {
                    print('❌ No store selected');
                    Get.snackbar('checkout_warning_title'.tr, 'checkout_choose_store'.tr,
                        backgroundColor: Colors.red, colorText: Colors.white);
                    return;
                  }

                  // Validate phone
                  if (pickupPhone.isEmpty || !_isValidUaePhone(pickupPhone)) {
                    print('❌ Invalid pickup phone');
                    Get.snackbar('', 'checkout_valid_phone'.tr,
                        backgroundColor: Colors.red, colorText: Colors.white);
                    return;
                  }

                  // Validate store details are populated
                  if (_userController.storeId.value.trim().isEmpty ||
                      _userController.storeName.value.trim().isEmpty ||
                      _userController.storeAddress.value.trim().isEmpty) {
                    print('❌ Store details missing after selection');
                    Get.snackbar('checkout_error_title'.tr,
                        'checkout_store_info_missing'.tr,
                        backgroundColor: Colors.red, colorText: Colors.white);
                    return;
                  }

                  print('✅ All validations passed');

                  // Sync phone to edit profile first
                  _authController.editPhoneController.text = fullPickupPhone;
                  _authController.phoneNumber.value = fullPickupPhone;

                  if (_userController.street.value.isEmpty &&
                      _userController.activeStep.value == 0) {
                    // Save phone to backend BEFORE showing address form
                    await _authController.sendUserData(
                      phone: fullPickupPhone,
                      name: _authController.editNameController.text,
                      email: _authController.editemailController.text,
                      street: _authController.editaddressController.text,
                      city: _authController.editcityController.text,
                      state: _authController.editStateController.text,
                      zipCode: _authController.editzipcodeController.text,
                      country: 'UAE',
                      showSuccessMessage: false,
                    );

                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) => AddressDetailsBottomSheet(
                        isforGuest: widget.isforguest,
                        phone: fullPickupPhone,
                      ),
                    );
                  } else {
                    // Sync phone and address to edit profile before continuing
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('guest_phone', fullPickupPhone);
                    if (widget.isforguest &&
                        !await _registerGuestAccount(fullPickupPhone)) {
                      return;
                    }
                    _syncToAuthController();

                    if (!widget.isforguest) {
                      await _authController.sendUserData(
                        phone: fullPickupPhone,
                        name: _authController.editNameController.text,
                        email: _authController.editemailController.text,
                        street: _userController.street.value,
                        city: _userController.city.value,
                        state: _userController.state.value,
                        zipCode: _userController.zipcode.value,
                        country: 'UAE',
                        showSuccessMessage: false,
                      );
                    }

                    setState(() {
                      _userController.activeStep.value = 1;
                    });
                  }
                }
              },
              child: Text(
                'continue'.tr,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildSavedAddressSelection() {
    if (widget.isforguest) {
      return Obx(
        () => _userController.street.value.isNotEmpty
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('checkout_shipping_address'.tr,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text(
                        "${_userController.street.value.replaceAll('"', '')}, "
                        "${_userController.city.value.replaceAll('"', '')}, "
                        "${_userController.state.value.replaceAll('"', '')}, "
                        "${_userController.zipcode.value.replaceAll('"', '')}"),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20)),
                              ),
                              builder: (context) => AddressDetailsBottomSheet(
                                isforGuest: widget.isforguest,
                                phone: _userController.homePhoneController.text
                                    .toString(),
                                existingStreet: _userController.street.value,
                                existingCity: _userController.city.value,
                                existingState: _userController.state.value,
                                existingZipCode: _userController.zipcode.value,
                              ),
                            );
                          },
                          child: Text('checkout_edit_address'.tr),
                        ),
                      ],
                    )
                  ],
                ),
              )
            : const SizedBox(),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_outlined, color: kPrimaryColor, size: 20),
              SizedBox(width: 8),
              Text(
                'checkout_select_saved_address'.tr,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kSecondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Obx(() {
            if (_addressController.isLoading.value) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final addresses = List<AddressModel>.from(_addressController.addresses);

            // If API addresses list is empty but profile has an address, show it as a saved address card
            if (addresses.isEmpty && _userController.street.value.trim().isNotEmpty) {
              addresses.add(
                AddressModel(
                  id: 'profile_default',
                  name: 'checkout_primary_address'.tr,
                  phone: completePhoneNumber,
                  email: userEmail,
                  address: _userController.street.value,
                  city: _userController.city.value,
                  state: _userController.state.value.isNotEmpty
                      ? _userController.state.value
                      : 'Dubai',
                  zipCode: _userController.zipcode.value,
                  isDefault: true,
                ),
              );
            }

            if (addresses.isNotEmpty) {
              final hasSelected = _selectedAddressId != null &&
                  addresses.any((a) => a.id == _selectedAddressId);

              if (!hasSelected) {
                final defaultAddr = addresses.firstWhere(
                  (a) => a.isDefault,
                  orElse: () => addresses.first,
                );
                _selectedAddressId = defaultAddr.id;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _selectAddressForCheckout(defaultAddr);
                });
              }
            } else {
              _selectedAddressId = null;
            }

            if (addresses.isEmpty) {
              return Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.location_off_outlined,
                        size: 36, color: Colors.grey[400]),
                    const SizedBox(height: 6),
                    Text(
                      'checkout_no_saved_addresses'.tr,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'checkout_add_address_below'.tr,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: addresses.map((addr) {
                  final isSelected = addr.id == _selectedAddressId ||
                      (_selectedAddressId == null && addr.isDefault) ||
                      (_selectedAddressId == null &&
                          _userController.street.value == addr.address);

                  return GestureDetector(
                    onTap: () {
                      _selectedAddressId = addr.id;
                      _selectAddressForCheckout(addr);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 220,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? kPrimaryColor.withValues(alpha: 0.05)
                            : kdefwhiteColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? kPrimaryColor
                              : Colors.grey.withValues(alpha: 0.25),
                          width: isSelected ? 1.8 : 1,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: kPrimaryColor.withValues(alpha: 0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  addr.name.isNotEmpty ? addr.name : 'checkout_address_fallback'.tr,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: kSecondaryColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      _openCheckoutAddAddressDialog(
                                          address: addr);
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Icon(
                                        Icons.edit_outlined,
                                        color: isSelected
                                            ? kPrimaryColor
                                            : Colors.grey[600],
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: kPrimaryColor,
                                      size: 20,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            addr.address,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "${addr.city}${addr.city.isNotEmpty && addr.state.isNotEmpty ? ', ' : ''}${addr.state}",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }),
          const SizedBox(height: 14),
          InkWell(
            onTap: () => _openCheckoutAddAddressDialog(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: kPrimaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kPrimaryColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle_outline,
                      color: kPrimaryColor, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'checkout_add_new_address'.tr,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectAddressForCheckout(AddressModel addr) {
    _selectedAddressId = addr.id;
    _userController.street.value = addr.address;
    _userController.city.value = addr.city;
    _userController.state.value = addr.state;
    _userController.zipcode.value = addr.zipCode;

    // Sync to AuthController as well so listeners/rebuilds stay 100% in sync
    _authController.editaddressController.text = addr.address;
    _authController.editcityController.text = addr.city;
    _authController.editStateController.text = addr.state;
    _authController.editzipcodeController.text = addr.zipCode;

    if (addr.phone.isNotEmpty) {
      _parseAndSetCountry(addr.phone);
    }
    if (mounted) setState(() {});
  }

  void _openCheckoutAddAddressDialog({AddressModel? address}) {
    final isEdit = address != null;
    final nameController = TextEditingController(text: address?.name ?? '');
    final phoneController = TextEditingController(
        text: (address != null && address.phone.isNotEmpty)
            ? address.phone
            : completePhoneNumber);
    final emailController = TextEditingController(
        text: (address != null && address.email.isNotEmpty)
            ? address.email
            : (userEmail.isNotEmpty ? userEmail : _authController.email.value));
    final streetController = TextEditingController(text: address?.address ?? '');
    final cityController = TextEditingController(text: address?.city ?? '');
    final zipController = TextEditingController(text: address?.zipCode ?? '');

    String selectedState = (address != null && address.state.isNotEmpty)
        ? address.state
        : 'Select State';
    bool isDefault = address?.isDefault ?? false;

    final List<String> uaeStates = [
      'Select State',
      'Abu Dhabi',
      'Ajman',
      'Al Ain',
      'Dubai',
      'Fujairah',
      'Ras Al Khaimah',
      'Sharjah',
      'Umm al-Qaywain',
    ];

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 550),
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEdit ? 'checkout_edit_address_details'.tr : 'checkout_add_address_details'.tr,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: kSecondaryColor,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close,
                                color: Colors.grey, size: 22),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text('checkout_address_label'.tr,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: kSecondaryColor)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nameController,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'checkout_address_label_hint'.tr,
                          hintStyle:
                              const TextStyle(color: Colors.grey, fontSize: 13),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Colors.grey.withValues(alpha: 0.3))),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Colors.grey.withValues(alpha: 0.3))),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: kPrimaryColor, width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // PHONE *
                      Text('checkout_phone_star'.tr,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: kSecondaryColor)),
                      const SizedBox(height: 6),
                      IntlPhoneField(
                        key: ValueKey(initialCountryCode),
                        initialCountryCode: initialCountryCode,
                        initialValue: _digitsOnly(
                            _userController.homePhoneController.text),
                        style: const TextStyle(fontSize: 13),
                        dropdownTextStyle:
                            const TextStyle(fontSize: 13),
                        disableLengthCheck: true,
                        dropdownIconPosition: IconPosition.trailing,
                        flagsButtonPadding:
                            const EdgeInsets.only(left: 10),
                        showDropdownIcon: true,
                        decoration: InputDecoration(
                          hintText: 'checkout_phone_label'.tr,
                          hintStyle: const TextStyle(
                              color: Colors.grey, fontSize: 13),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Colors.grey.withValues(alpha: 0.3))),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Colors.grey.withValues(alpha: 0.3))),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: kPrimaryColor, width: 1.5)),
                        ),
                        onChanged: (phone) {
                          phoneController.text = phone.completeNumber;
                        },
                      ),
                      const SizedBox(height: 14),

                      // EMAIL
                      Text('checkout_email_caps'.tr,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: kSecondaryColor)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: emailController,
                        readOnly: true,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey[700]),
                        decoration: InputDecoration(
                          hintText: "sakandarhayat388@gmail.com",
                          hintStyle: const TextStyle(
                              color: Colors.grey, fontSize: 13),
                          filled: true,
                          fillColor: const Color(0xFFF1F3F5),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Colors.grey.withValues(alpha: 0.3))),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Colors.grey.withValues(alpha: 0.3))),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ADDRESS STREET *
                      Text('checkout_street_star'.tr,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: kSecondaryColor)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: streetController,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'checkout_street_hint'.tr,
                          hintStyle:
                              const TextStyle(color: Colors.grey, fontSize: 13),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Colors.grey.withValues(alpha: 0.3))),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Colors.grey.withValues(alpha: 0.3))),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: kPrimaryColor, width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // STATE / EMIRATE *
                      Text('checkout_state_emirate'.tr,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: kSecondaryColor)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: selectedState,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Colors.grey.withValues(alpha: 0.3))),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Colors.grey.withValues(alpha: 0.3))),
                        ),
                        items: uaeStates
                            .map((st) => DropdownMenuItem(
                                value: st,
                                child: Text(st,
                                    style: const TextStyle(
                                        fontSize: 13))))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(
                                () => selectedState = val);
                          }
                        },
                      ),
                      const SizedBox(height: 14),

                      // CITY *
                      Text('checkout_city_star'.tr,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: kSecondaryColor)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: cityController,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'checkout_city_hint'.tr,
                          hintStyle: const TextStyle(
                              color: Colors.grey, fontSize: 13),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Colors.grey.withValues(alpha: 0.3))),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Colors.grey.withValues(alpha: 0.3))),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text('checkout_zipcode'.tr,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: kSecondaryColor)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: zipController,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: "00000",
                          hintStyle:
                              const TextStyle(color: Colors.grey, fontSize: 13),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Colors.grey.withValues(alpha: 0.3))),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Colors.grey.withValues(alpha: 0.3))),
                        ),
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: () =>
                            setDialogState(() => isDefault = !isDefault),
                        borderRadius: BorderRadius.circular(4),
                        child: Row(
                          children: [
                            Checkbox(
                              value: isDefault,
                              activeColor: kPrimaryColor,
                              onChanged: (val) => setDialogState(
                                  () => isDefault = val ?? false),
                            ),
                            Text('checkout_set_default'.tr,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: kSecondaryColor)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(
                                    color: Colors.grey.withValues(alpha: 0.4)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: Text('cancel'.tr,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: kSecondaryColor)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Obx(() => _addressController.isSaving.value
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kPrimaryColor,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                    onPressed: () async {
                                      final labelVal =
                                          nameController.text.trim();
                                      final streetVal =
                                          streetController.text.trim();
                                      final cityVal =
                                          cityController.text.trim();

                                      if (labelVal.isEmpty) {
                                        Get.snackbar('checkout_warning_title'.tr,
                                            'checkout_address_label_required'.tr,
                                            backgroundColor: Colors.orange,
                                            colorText: Colors.white);
                                        return;
                                      }
                                      if (streetVal.isEmpty) {
                                        Get.snackbar('checkout_warning_title'.tr,
                                            'checkout_address_street_required'.tr,
                                            backgroundColor: Colors.orange,
                                            colorText: Colors.white);
                                        return;
                                      }

                                      final payload = {
                                        "name": labelVal,
                                        "phone": phoneController.text
                                                .trim()
                                                .isNotEmpty
                                            ? phoneController.text.trim()
                                            : completePhoneNumber,
                                        "email": emailController.text.trim(),
                                        "address": streetVal,
                                        "city": cityVal.isNotEmpty
                                            ? cityVal
                                            : "Dubai",
                                        "state": selectedState == 'Select State'
                                            ? 'Dubai'
                                            : selectedState,
                                        "zipCode":
                                            zipController.text.trim().isNotEmpty
                                                ? zipController.text.trim()
                                                : "00000",
                                        "isDefault": isDefault,
                                      };

                                      bool ok;
                                      if (address != null) {
                                        ok = await _addressController
                                            .updateAddress(address.id, payload);
                                      } else {
                                        ok = await _addressController
                                            .addAddress(payload);
                                      }
                                      if (ok && mounted) {
                                        Navigator.pop(context);
                                        if (address != null) {
                                          _selectedAddressId = address.id;
                                        }
                                        _userController.street.value = streetVal;
                                        _userController.city.value =
                                            cityVal.isNotEmpty
                                                ? cityVal
                                                : "Dubai";
                                        _userController.state.value =
                                            selectedState == 'Select State'
                                                ? 'Dubai'
                                                : selectedState;
                                        _userController.zipcode.value =
                                            zipController.text.trim().isNotEmpty
                                                ? zipController.text.trim()
                                                : "00000";
                                        if (phoneController.text.trim().isNotEmpty) {
                                          _parseAndSetCountry(phoneController.text.trim());
                                        }
                                        setState(() {});
                                      }
                                    },
                                    child: Text(
                                        isEdit ? 'checkout_update_address'.tr : 'checkout_save_address'.tr,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white)),
                                  )),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
