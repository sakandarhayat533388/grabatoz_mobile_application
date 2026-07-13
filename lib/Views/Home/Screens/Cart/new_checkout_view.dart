import 'dart:convert';

import 'package:easy_stepper/easy_stepper.dart';
import 'package:get/get.dart';
import 'package:graba2z/Configs/config.dart';
import 'package:graba2z/Controllers/addtocart.dart';
import 'package:graba2z/Controllers/checkout_controller.dart';
import 'package:graba2z/Controllers/deliveryController.dart';
import 'package:graba2z/Controllers/payment_charges_controller.dart';
import 'package:graba2z/Utils/appextensions.dart';
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
  void _parseAndSetCountry(String phone) {
    if (phone.isEmpty || _isParsingPhone) return;

    _isParsingPhone = true; // Set flag to prevent recursive calls

    String cleanPhone = phone.trim();
    if (!cleanPhone.startsWith('+')) {
      cleanPhone = '+$cleanPhone';
    }

    // Try to find matching country code (longest match first)
    String detectedCountry = 'AE';
    String detectedDialCode = '+971';

    // Sort by length descending to match longer codes first (+971 before +97)
    final sortedCodes = dialCodeToCountry.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (String dialCode in sortedCodes) {
      if (cleanPhone.startsWith(dialCode)) {
        detectedCountry = dialCodeToCountry[dialCode]!;
        detectedDialCode = dialCode;

        // Extract just the number part (without country code)
        String numberPart = cleanPhone.substring(dialCode.length);
        _userController.homePhoneController.text = numberPart;

        break;
      }
    }

    initialCountryCode = detectedCountry;
    selectedCountryCode = detectedDialCode;
    completePhoneNumber = cleanPhone;

    if (mounted) setState(() {});

    _isParsingPhone = false; // Reset flag
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

  @override
  void initState() {
    super.initState();
    if (widget.isforguest) {
      _resetGuestCheckoutState();
    }
    getUserInformation();
    final deliveryCtrl = Get.put(DeliveryController());
    deliveryCtrl.fetchMethods();
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

    // Only parse if phone has country code and is different from what we already have
    if (phone.isNotEmpty &&
        phone.startsWith('+') &&
        completePhoneNumber != phone) {
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
      Get.snackbar("Error", "Please enter email");
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
      EasyLoading.showError("Please enter the OTP");
      return;
    }

    EasyLoading.show(status: "Verifying OTP...");

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
          EasyLoading.showSuccess("OTP Verified Successfully");
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('guest_email', email);

          setState(() {
            isCodeSent = false;
            isotpVerified = true;
            isVerifying = false;
          });
          // Next step: navigate to another screen or mark verified
        } else {
          EasyLoading.showError(data['message'] ?? "OTP Verification Failed");
        }
      } else {
        EasyLoading.showError(
            "OTP Verification Failed: ${response.statusCode}");
      }
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError("Error verifying OTP: $e");
    }
  }

  // Send Email Verification code
  Future<void> sendEmailVerificationCode(String email) async {
    try {
      EasyLoading.show(status: "Sending code...");

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
            "Success",
            "Verification code sent to your email",
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
            "Error",
            data["message"] ?? "Failed to send code",
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } else {
        Get.snackbar(
          "Error",
          "Server error. Try again",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      EasyLoading.dismiss();
      Get.snackbar(
        "Error",
        "Something went wrong",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Pull data from AuthController (used in Edit Profile) into checkout fields
  void _prefillFromProfile() {
    try {
      final phone = _authController.editPhoneController.text.trim();
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
        'Warning',
        'Please complete all guest details before continuing',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    setState(() => _isRegisteringGuest = true);
    EasyLoading.show(status: 'Checking guest account...');

    try {
      final response = await http.post(
        Uri.parse(Configss.registerGuest),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "name": name,
          "email": email,
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
        data['message']?.toString() ?? 'Unable to continue as guest',
      );
      return false;
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('Unable to continue as guest');
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
                  child: const Icon(
                    Icons.person_search_rounded,
                    color: kPrimaryColor,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Account Already Exists',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: kdefblackColor,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'This email is already registered. Please log in to continue with your order.',
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
                    label: const Text(
                      'Go to Login',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your cart is safe while you sign in.',
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
  @override
  Widget build(BuildContext context) {
    // Re-sync state every time widget rebuilds (when returning from Edit Profile)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentState = _userController.state.value;
      final authState = _authController.editStateController.text;
      if (currentState != authState && mounted) {
        _userController.state.value = authState;
        setState(() {});
        print("🔄 Force synced state on rebuild: '$authState'");
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text("Checkout"),
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
                    steps: const [
                      EasyStep(
                          icon: Icon(Icons.local_shipping), title: 'Shipping'),
                      EasyStep(
                          icon: Icon(Icons.receipt_long), title: 'Summary'),
                      EasyStep(icon: Icon(Icons.payment), title: 'Payment'),
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
          addressCustomer:
              "${_userController.street.value.replaceAll('"', '')}, "
              "${_userController.city.value.replaceAll('"', '')}, "
              "${_userController.state.value.replaceAll('"', '')}, "
              "${_userController.zipcode.value.replaceAll('"', '')}",
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
                          "Home Delivery",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _userController.isHomeDelivery.value
                                ? kdefwhiteColor
                                : kdefblackColor,
                          ),
                        ),
                        4.0.heightbox,
                        Text(
                          'Free',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _userController.isHomeDelivery.value
                                ? kdefwhiteColor
                                : kPrimaryColor,
                          ),
                        ),
                        4.0.heightbox,
                        Text(
                          "Deliver at doorstep",
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
                          "Pick From Point",
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
                          "Free Delivery",
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
                          "Pick from the Store",
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
                    const Text("Contact Details",
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
                            decoration: const InputDecoration(
                              labelText: "E-mail",
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
                                  child: const Text(
                                    "Verifed",
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
                                  child: const Text(
                                    "Verify",
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
                                  decoration: const InputDecoration(
                                    counterText: "",
                                    labelText: "OTP",
                                    hintText: "6-digit code",
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                canResend
                                    ? GestureDetector(
                                        onTap: () {},
                                        child: const Text(
                                          "Resend",
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        "$otpSeconds sec",
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
                                        : const Text("Verify Code"),
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
                        labelText: 'Phone Number',
                        hintText: 'Enter phone number',
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
                        setState(() {
                          completePhoneNumber = phone.completeNumber;
                          selectedCountryCode = '+${phone.countryCode}';
                          if (phone.number.isEmpty) {
                            _homePhoneError = 'Phone is required';
                          } else {
                            _homePhoneError = null;
                          }
                        });
                      },
                      onCountryChanged: (country) {
                        setState(() {
                          selectedCountryCode = '+${country.dialCode}';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Obx(
                      () => _userController.street.value.isNotEmpty
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Shipping Address",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
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
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                      top: Radius.circular(20)),
                                            ),
                                            builder: (context) =>
                                                AddressDetailsBottomSheet(
                                              isforGuest: widget.isforguest,
                                              phone: _userController
                                                  .homePhoneController.text
                                                  .toString(),
                                              existingStreet:
                                                  _userController.street.value,
                                              existingCity:
                                                  _userController.city.value,
                                              existingState:
                                                  _userController.state.value,
                                              existingZipCode:
                                                  _userController.zipcode.value,
                                            ),
                                          );
                                        },
                                        child: const Text("Edit Address"),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          // Clear from checkout controller
                                          _userController.street.value = '';
                                          _userController.city.value = '';
                                          _userController.state.value = '';
                                          _userController.zipcode.value = '';

                                          // Also clear from AuthController for Edit Profile sync
                                          _authController.editaddressController
                                              .clear();
                                          _authController.editcityController
                                              .clear();
                                          _authController.editzipcodeController
                                              .clear();
                                          _authController.editStateController
                                              .clear();

                                          // Update observable values
                                          _authController.address.value = '';

                                          // Clear from SharedPreferences to prevent reload
                                          final prefs = await SharedPreferences
                                              .getInstance();
                                          await prefs.remove('user_address');
                                          await prefs.remove('user_zipCode');
                                          await prefs.remove('user_city');
                                          await prefs.remove('user_state');

                                          // IMPORTANT: Update backend API to persist the removal
                                          await _authController.sendUserData(
                                            phone: _authController
                                                .editPhoneController.text,
                                            name: _authController
                                                .editNameController.text,
                                            email: _authController
                                                .editemailController.text,
                                            street: '',
                                            city: '',
                                            state: '',
                                            zipCode: '',
                                            country: 'UAE',
                                            showSuccessMessage: false,
                                          );
                                        },
                                        child: const Text(
                                          "Remove Address",
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            )
                          : SizedBox.fromSize(),
                    ),
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
                          'Warning', 'Please enter a Email and verify it',
                          backgroundColor: Colors.red, colorText: Colors.white);
                      return;
                    }
                  }
                  // Validate phone number - check both homePhone and completePhoneNumber
                  if (homePhone.isEmpty || fullPhoneNumber.isEmpty) {
                    setState(() {
                      _homePhoneError = 'Phone is required';
                    });
                    Get.snackbar('Warning', 'Please enter a valid phone number',
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

                  if (_userController.street.value.isEmpty &&
                      _userController.activeStep.value == 0) {
                    // Save phone to backend BEFORE showing address form
                    await _authController.sendUserData(
                      phone: fullPhoneNumber,
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
                        phone: homePhone,
                      ),
                    );
                  } else {
                    if (widget.isforguest &&
                        !await _registerGuestAccount(fullPhoneNumber)) {
                      return;
                    }
                    // Sync phone and address to edit profile before continuing
                    _syncToAuthController();

                    setState(() {
                      _userController.activeStep.value = 1;
                    });
                  }
                } else {
                  final pickupPhone =
                      _userController.phoneController.text.trim();

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
                    Get.snackbar('Warning', 'Please choose one store address',
                        backgroundColor: Colors.red, colorText: Colors.white);
                    return;
                  }

                  // Validate phone
                  if (pickupPhone.isEmpty || !_isValidUaePhone(pickupPhone)) {
                    print('❌ Invalid pickup phone');
                    Get.snackbar('', 'Please enter a valid phone number',
                        backgroundColor: Colors.red, colorText: Colors.white);
                    return;
                  }

                  // Validate store details are populated
                  if (_userController.storeId.value.trim().isEmpty ||
                      _userController.storeName.value.trim().isEmpty ||
                      _userController.storeAddress.value.trim().isEmpty) {
                    print('❌ Store details missing after selection');
                    Get.snackbar('Error',
                        'Store information is missing. Please select a store again.',
                        backgroundColor: Colors.red, colorText: Colors.white);
                    return;
                  }

                  print('✅ All validations passed');

                  // Sync phone to edit profile first
                  _authController.editPhoneController.text = pickupPhone;
                  _authController.phoneNumber.value = pickupPhone;

                  if (_userController.street.value.isEmpty &&
                      _userController.activeStep.value == 0) {
                    // Save phone to backend BEFORE showing address form
                    await _authController.sendUserData(
                      phone: pickupPhone,
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
                        phone: pickupPhone,
                      ),
                    );
                  } else {
                    // Sync phone and address to edit profile before continuing
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('guest_phone', pickupPhone);
                    if (widget.isforguest &&
                        !await _registerGuestAccount(pickupPhone)) {
                      return;
                    }
                    _syncToAuthController();

                    setState(() {
                      _userController.activeStep.value = 1;
                    });
                  }
                }
              },
              child: const Text(
                "Continue",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
