import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:graba2z/Configs/config.dart';
import 'package:graba2z/Controllers/addtocart.dart';
import 'package:graba2z/Controllers/first_user_discount_controller.dart';
import 'package:graba2z/Views/Auth/otp_view.dart';
import 'package:graba2z/Views/Home/home.dart';
import 'package:graba2z/Controllers/checkout_controller.dart'; // Add this import

import '../Utils/packages.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class AuthController extends GetxController {
  // String? _userId;
  String? _emailErrorMessage;
  // guest user
  final isGuest = false.obs;
  // String? _loginemailErrorMessage;
  final loginemailErrorMessage = ''.obs;
  final loginpassworderrorMessage = ''.obs;
  String? _forgetemailErrorMessage;
  bool _isEmailValid = false;
  String? _passworderrorMessage;
  // String? _loginpassworderrorMessage;
  String? _firstnamemessage;
  String? _lastnamemessage;
  String? _phonenumbermessage;
  String? _addressmessage;
  bool _isPasswordObscure = true;
  final isProfileLoading = false.obs;
  final hasProfileDataLoaded = false.obs; // Add this flag
  bool get isPasswordObscure => _isPasswordObscure;
  bool get isEmailValid => _isEmailValid;
  String? get emailErrorMessage => _emailErrorMessage;
  String? get forgetemailErrorMessage => _forgetemailErrorMessage;
  String? get passwordErrorMessage => _passworderrorMessage;
  String? get firstnamemessage => _firstnamemessage;
  String? get lastnamemessage => _lastnamemessage;
  String? get phoneNumberErrorMessage => _phonenumbermessage;
  String? get addressErrorMessage => _addressmessage;
  // String? get loginEmailErrorMessage => _loginemailErrorMessage;
  // String? get loginPasswordErrorMessage => _loginpassworderrorMessage;
  // bool get isLoggedIn => _userId != null || _userId!.isNotEmpty
  // ;
  final editNameController = TextEditingController();
  final editemailController = TextEditingController();
  final editcityController = TextEditingController();
  final editaddressController = TextEditingController();
  final editzipcodeController = TextEditingController();
  final editPhoneController = TextEditingController();
  final editStateController = TextEditingController(); // Add this
  // final editNameController = TextEditingController();
  final bearerToken = ''.obs;
  final userID = ''.obs;
  final token = ''.obs;
  final fullName = "--".obs;
  final address = "--".obs;
  final phoneNumber = "--".obs;
  final email = "--".obs;

  String get _registrationPlatform {
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return Platform.operatingSystem;
  }

  void _refreshFirstUserDiscountStatus() {
    if (Get.isRegistered<FirstUserDiscountController>()) {
      Get.find<FirstUserDiscountController>().markAuthSessionPresent();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.isRegistered<FirstUserDiscountController>()) {
          Get.find<FirstUserDiscountController>().loadStatus();
        }
      });
    }
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    userID.value = prefs.getString('userId') ?? ''; // Convert to String
    token.value = prefs.getString('token') ?? ''; // Convert to String
    fullName.value = prefs.getString('userName') ?? ''; // Convert to String
    email.value = prefs.getString('userEmail') ?? ''; // Convert to String

    update();
  }

  getUserProfileData() async {
    isProfileLoading.value = true;

    final prefs = await SharedPreferences.getInstance();
    String url = "${Configss.getuserProfile}";

    var response = await http.get(Uri.parse(url),
        headers: {"Authorization": "Bearer ${token.value}"});
    log('🔍 GET Profile API Response: ${response.body}');
    isProfileLoading.value = false;

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      print("🔍 Phone from API: '${data['phone']}'");

      fullName.value = data['name'] ?? '';
      email.value = data['email'] ?? '';
      phoneNumber.value = data['phone'] ?? '';
      address.value = data['address']['street'] ?? '';

      // Always update controllers with fresh data from API
      editNameController.text = data['name'] ?? '';
      editemailController.text = data['email'] ?? '';
      editPhoneController.text = data['phone'] ?? '';
      editaddressController.text = data['address']['street'] ?? '';
      editzipcodeController.text = data['address']['zipCode'] ?? '';
      editcityController.text = data['address']['city'] ?? '';
      editStateController.text = data['address']['state'] ?? ''; // Add this

      prefs.setString('user_address', data['address']['street'] ?? '');
      prefs.setString('user_zipCode', data['address']['zipCode'] ?? '');
      prefs.setString('user_city', data['address']['city'] ?? '');
      prefs.setString('user_state', data['address']['state'] ?? '');

      hasProfileDataLoaded.value = true;
      update();
      return;
    }
    if (isGuest.value) {
      print("🟡 Guest user → profile API skipped");
      return;
    } else {
      await prefs.clear();
      final bottomNavProvider = Get.put(BottomNavigationController());
      bottomNavProvider.setTabIndex(0);
      Get.offAll(() => Home());
      print('Failed to fetch categories: ${response.body}');
    }
  }

  // Add a method to force refresh when needed
  Future<void> forceRefreshProfile() async {
    hasProfileDataLoaded.value = false;
    await getUserProfileData();
  }

  final isprofileUpdating = false.obs;
  Future<void> sendUserData({
    String? phone,
    String? name,
    String? email,
    String? street,
    String? city,
    String? state,
    String? zipCode,
    String? country,
    bool showSuccessMessage = true, // Add this parameter with default true
  }) async {
    final url = Uri.parse(Configss.updateProfile);
    final prefs = await SharedPreferences.getInstance();
    bearerToken.value = prefs.getString('token') ?? '';

    final Map<String, dynamic> data = {};

    // Send null for empty values to signal field deletion to API
    data["phone"] = (phone == null || phone.isEmpty) ? null : phone;
    data["name"] = (name == null || name.isEmpty) ? null : name;
    data["email"] = (email == null || email.isEmpty) ? null : email;

    // Always send address object with all fields
    final Map<String, dynamic> addressMap = {
      "street": (street == null || street.isEmpty) ? null : street,
      "city": (city == null || city.isEmpty) ? null : city,
      "state": (state == null || state.isEmpty) ? null : state,
      "zipCode": (zipCode == null || zipCode.isEmpty) ? null : zipCode,
      "country": country ?? 'UAE',
    };

    data["address"] = addressMap;

    print("📤 Sending data to API: ${jsonEncode(data)}");

    isprofileUpdating.value = true;
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $bearerToken',
        },
        body: jsonEncode(data),
      );

      print("📥 API Response Status: ${response.statusCode}");
      print("📥 API Response Body: ${response.body}");

      isprofileUpdating.value = false;
      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Update successful");

        // Update local controllers with whatever was sent (including empty strings)
        editPhoneController.text = phone ?? '';
        editNameController.text = name ?? '';
        editemailController.text = email ?? '';
        editaddressController.text = street ?? '';
        editcityController.text = city ?? '';
        editzipcodeController.text = zipCode ?? '';

        print("📝 Updated editPhoneController: '${editPhoneController.text}'");

        // Also update observable values
        phoneNumber.value = phone ?? '';
        fullName.value = name ?? '';
        this.email.value = email ?? '';
        address.value = street ?? '';

        print("📝 Updated phoneNumber observable: '${phoneNumber.value}'");

        // Save to SharedPreferences for persistence (including empty values)
        await prefs.setString('user_address', street ?? '');
        await prefs.setString('user_zipCode', zipCode ?? '');
        await prefs.setString('user_city', city ?? '');
        await prefs.setString('user_phone', phone ?? '');

        print("💾 Saved to SharedPreferences");

        // Also sync to checkout if UserController exists
        try {
          if (Get.isRegistered<UserController>()) {
            final userController = Get.find<UserController>();
            userController.homePhoneController.text = phone ?? '';
            userController.phoneController.text = phone ?? '';
            userController.street.value = street ?? '';
            userController.city.value = city ?? '';
            userController.zipcode.value = zipCode ?? '';
            // Force clear state even when API returns null
            userController.state.value =
                (state == null || state.isEmpty) ? '' : state;
            print(
                "🔄 Synced to UserController including state: '${userController.state.value}'");

            // Force update the editStateController to trigger listeners
            final currentState = editStateController.text;
            final newState = (state == null || state.isEmpty) ? '' : state;
            if (currentState != newState) {
              editStateController.text = newState;
              // Manually notify listeners
              editStateController.notifyListeners();
              print("🔔 Forced state controller update: '$newState'");
            }
          }
        } catch (e) {
          print('⚠️ UserController not available: $e');
        }

        // Trigger update to notify all listeners
        update();

        print("✅ All updates complete");

        // Show success message only if requested
        if (showSuccessMessage) {
          // Get.snackbar(
          //   'Success',
          //   'Profile updated successfully',
          //   backgroundColor: Colors.green,
          //   colorText: Colors.white,
          //   snackPosition: SnackPosition.BOTTOM,
          // );
        }
      } else {
        print("❌ Failed: ${response.statusCode} - ${response.body}");
        // Get.snackbar(
        //   'Error',
        //   'Failed to update profile',
        //   backgroundColor: Colors.red,
        //   colorText: Colors.white,
        //   snackPosition: SnackPosition.BOTTOM,
        // );
      }
    } catch (e) {
      isprofileUpdating.value = false;
      print("⚠️ Error: $e");
      Get.snackbar(
        'Error',
        'An error occurred',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  final bottomNavProvider = Get.put(BottomNavigationController());
  final isLoading = false.obs;
  // Function to toggle loading state
  void setLoading(bool loading) {
    isLoading.value = loading;
    update();
  }

  Future login(String email, String password, bool isforbottom) async {
    final prefs = await SharedPreferences.getInstance();

    // Encode the data as JSON

    var bodyobj = {"email": email, "password": password};

    try {
      setLoading(true);
      update();

      String url = Configss.login;
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(bodyobj),
      );
      log('the request is ${response.statusCode}');
      log('the request is ${response.body}');
      if (response.statusCode == 200) {
        // print('Response Data: ${response.data}'); // Debugging: Log the response

        final responseData = json.decode(response.body.toString());
        final String userId =
            (responseData['_id'] ?? '0').toString(); // Extract user_id
        final String userEmail = responseData['email'] ?? "";
        final String userName = responseData['name'];
        final String token = responseData['token'];

        // Save the user details in SharedPreferences
        await prefs.setString('userId', userId);
        await prefs.setString('userEmail', userEmail);
        await prefs.setString('userName', userName);
        await prefs.setString('user_name', userName);
        await prefs.setString('token', token);
        await prefs.remove('Guest');
        await prefs.remove('guest_name');
        await prefs.remove('guest_email');
        await prefs.remove('guest_phone');
        await prefs.remove('guest_address');
        await prefs.remove('guest_city');
        await prefs.remove('guest_state');
        await prefs.remove('guest_zip');
        if (Get.isRegistered<CartNotifier>()) {
          await Get.find<CartNotifier>().mergeGuestCart(userId);
        }
        print('Login successful: User details saved');
        print('User ID: $userId');
        print('User Email: $userEmail');
        print('User Name: $userName');
        EasyLoading.showSuccess('Logged In');
        await Future.delayed(const Duration(seconds: 1));
        EasyLoading.dismiss();
        if (isforbottom) {
          Get.back();
        } else {
          bottomNavProvider.setTabIndex(0);
          Get.offAll(() => Home());
        }

        loadUserData();
        _refreshFirstUserDiscountStatus();
        // Check if the response contains the 'success' field and is true
      } else if (response.statusCode == 401) {
        EasyLoading.showError('Invalid email or password');
        // throw Exception("Login failed: ${response.statusMessage}");
      }
    } catch (e) {
      print("Login error: $e");
      throw Exception("An unexpected error occurred: $e");
    } finally {
      setLoading(false);
      update();
    }
  }

  signUp(
    String userName,
    String email,
    String password,
  ) async {
    String url = Configss.signup;

    // try {
    setLoading(true);
    update();

    var bodyobj = {
      "name": userName,
      "email": email,
      "password": password,
      "registrationSource": "app",
      "registrationPlatform": _registrationPlatform,
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(bodyobj),
    );

    log('the requesting stt is ${response.statusCode}');
    log('the requesting parameter are ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body.toString());
      // print("Success: $data");
      EasyLoading.showSuccess(data['message']);
      Get.to(() => OtpScreen(email: email, password: password));
      return response;
    } else {
      final errorData = json.decode(response.body);
      String errorMessage =
          errorData['message'] ?? "An unknown error occurred.";
      EasyLoading.showSuccess(errorMessage);
    }
    // } catch (error) {
    //   print("Sign-up Error: $error");
    //   rethrow;
    // } finally {
    //   setLoading(false);
    //   update();
    // }
  }

  // Function to log out user
  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userEmail');
    await prefs.remove('userName');
    await prefs.remove('userId');
    await prefs.remove('user_address');
    await prefs.remove('user_zipCode');
    await prefs.remove('user_city');
    await prefs.remove('user_state');
    await prefs.remove('user_phone');

    // Clear all controllers
    editNameController.clear();
    editemailController.clear();
    editPhoneController.clear();
    editaddressController.clear();
    editcityController.clear();
    editzipcodeController.clear();
    editStateController.clear();

    // Reset observable values
    userID.value = '';
    fullName.value = '--';
    email.value = '--';
    phoneNumber.value = '--';
    address.value = '--';

    // Reset profile loaded flag so it will fetch fresh data on next login
    hasProfileDataLoaded.value = false;
    if (Get.isRegistered<FirstUserDiscountController>()) {
      Get.find<FirstUserDiscountController>().clearAll();
    }

    update();
  }

  void validateSignupEmail(String? value) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (value == null || value.isEmpty) {
      _emailErrorMessage = 'Please enter your email address.';
      _isEmailValid = false;
    } else if (!emailRegex.hasMatch(value)) {
      _emailErrorMessage = 'Please enter a valid email';
      _isEmailValid = false;
    } else {
      _emailErrorMessage = null;
      _isEmailValid = true;
    }
    update();
  }

  void validateLoginEmail(String? value) {
    // final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (value == null || value.isEmpty) {
      loginemailErrorMessage.value = 'Please enter your email address.';
      _isEmailValid = false;
    } else {
      loginemailErrorMessage.value = '';
      log("its availble email");
      _isEmailValid = true;
    }
    update();
  }

  void validateForgetEmail(String? value) {
    // final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (value == null || value.isEmpty) {
      _forgetemailErrorMessage = 'Please enter your email address.';
      _isEmailValid = false;
    } else {
      _forgetemailErrorMessage = null;
      _isEmailValid = true;
    }
    update();
  }

  void validateSignupPassword(String? value) {
    if (value == null || value.isEmpty) {
      _passworderrorMessage = 'Please enter your password.';
    } else if (value.length < 6) {
      _passworderrorMessage = 'Password must be at least 6 characters long.';
    } else {
      _passworderrorMessage = null;
    }
    update();
  }

  void validateLoginPassword(String? value) {
    if (value == null || value.isEmpty) {
      loginpassworderrorMessage.value = 'Please enter your password.';
    } else {
      loginpassworderrorMessage.value = '';

      log("its availble password");
    }
    update();
  }

  void validatefirstname(String? value) {
    if (value == null || value.isEmpty) {
      _firstnamemessage = 'Please enter your first name.';
    } else {
      _firstnamemessage = null;
    }
    update();
  }

  void validatelastname(String? value) {
    if (value == null || value.isEmpty) {
      _lastnamemessage = 'Please enter your last name.';
    } else {
      _lastnamemessage = null;
    }
    update();
  }

  void validatephonenumber(String? value) {
    if (value == null || value.isEmpty) {
      _phonenumbermessage = 'Please enter your phone number.';
    } else {
      _phonenumbermessage = null;
    }
    update();
  }

  void validateaddress(String? value) {
    if (value == null || value.isEmpty) {
      _addressmessage = 'Please enter your address.';
    } else {
      _addressmessage = null;
    }
    update();
  }

  void clearErrors() {
    _emailErrorMessage = null;
    _passworderrorMessage = null;
    loginemailErrorMessage.value = '';
    loginpassworderrorMessage.value = '';
    _forgetemailErrorMessage = null;
    _firstnamemessage = null;
    _lastnamemessage = null;
    _phonenumbermessage = null;
    _addressmessage = null;

    update();
  }

  void togglePasswordVisibility() {
    _isPasswordObscure = !_isPasswordObscure;
    update();
  }

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    // loadUserData();
  }
}
