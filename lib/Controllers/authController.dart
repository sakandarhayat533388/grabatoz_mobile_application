import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:graba2z/Configs/config.dart';
import 'package:graba2z/Controllers/addtocart.dart';
import 'package:graba2z/Services/push_notification_service.dart';
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
  final gender = "".obs;
  final dateOfBirth = "".obs;
  final isAdmin = false.obs;
  final isEmailVerified = false.obs;
  final newsletterPref = true.obs;
  final notificationsPref = true.obs;
  final editDobController = TextEditingController();
  final editGenderController = TextEditingController();

  static String formatDob(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) {
        return "${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}";
      }
    } catch (_) {}
    return raw;
  }

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
    fullName.value = prefs.getString('userName]') ?? prefs.getString('user_name') ?? ''; // Convert to String
    email.value = prefs.getString('userEmail') ?? ''; // Convert to String

    update();
  }

  getUserProfileData() async {
    isProfileLoading.value = true;

    final prefs = await SharedPreferences.getInstance();
    token.value = prefs.getString('token') ?? token.value;
    String url = "${Configss.getuserProfile}";

    try {
      var response = await http.get(Uri.parse(url),
          headers: {"Authorization": "Bearer ${token.value}"});
      log('🔍 GET Profile API Response: ${response.body}');
      isProfileLoading.value = false;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        fullName.value = data['name'] ?? '';
        email.value = data['email'] ?? '';
        phoneNumber.value = data['phone'] ?? '';
        gender.value = data['gender'] ?? '';
        dateOfBirth.value = formatDob(data['dateOfBirth']?.toString());
        isAdmin.value = data['isAdmin'] == true;
        isEmailVerified.value = data['isEmailVerified'] == true;

        if (data['preferences'] is Map) {
          newsletterPref.value = data['preferences']['newsletter'] != false;
          notificationsPref.value = data['preferences']['notifications'] != false;
        }

        final addressData = data['address'] is Map
            ? data['address'] as Map<String, dynamic>
            : (data['addresses'] is List && (data['addresses'] as List).isNotEmpty
                ? (data['addresses'] as List)[0] as Map<String, dynamic>
                : null);

        final streetVal = addressData != null ? (addressData['street'] ?? addressData['address'] ?? '') : '';
        final cityVal = addressData != null ? (addressData['city'] ?? '') : '';
        final stateVal = addressData != null ? (addressData['state'] ?? '') : '';
        final zipCodeVal = addressData != null ? (addressData['zipCode'] ?? '') : '';

        address.value = streetVal.toString().replaceAll('"', '');

        // Always update controllers with fresh data from API
        editNameController.text = data['name'] ?? '';
        editemailController.text = data['email'] ?? '';
        editPhoneController.text = data['phone'] ?? '';
        editGenderController.text = data['gender'] ?? '';
        editDobController.text = formatDob(data['dateOfBirth']?.toString());
        editaddressController.text = streetVal.toString().replaceAll('"', '');
        editzipcodeController.text = zipCodeVal.toString().replaceAll('"', '');
        editcityController.text = cityVal.toString().replaceAll('"', '');
        editStateController.text = stateVal.toString().replaceAll('"', '');

        await prefs.setString('user_address', streetVal.toString().replaceAll('"', ''));
        await prefs.setString('user_zipCode', zipCodeVal.toString().replaceAll('"', ''));
        await prefs.setString('user_city', cityVal.toString().replaceAll('"', ''));
        await prefs.setString('user_state', stateVal.toString().replaceAll('"', ''));
        await prefs.setString('user_phone', (data['phone'] ?? '').toString());
        await prefs.setString('user_name', (data['name'] ?? '').toString());
        await prefs.setString('userName', (data['name'] ?? '').toString());
        await prefs.setString('userEmail', (data['email'] ?? '').toString());

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
        print('Failed to fetch profile: ${response.body}');
      }
    } catch (e) {
      isProfileLoading.value = false;
      print("⚠️ Exception fetching profile: $e");
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
    String? gender,
    String? dateOfBirth,
    String? street,
    String? city,
    String? state,
    String? zipCode,
    String? country,
    bool showSuccessMessage = true,
  }) async {
    final url = Uri.parse(Configss.updateProfile);
    final prefs = await SharedPreferences.getInstance();
    bearerToken.value = prefs.getString('token') ?? token.value;

    final Map<String, dynamic> data = {};

    final cleanEmail = (email == null || email.isEmpty) ? null : email.trim().toLowerCase();
    data["phone"] = (phone == null || phone.isEmpty) ? null : phone;
    data["name"] = (name == null || name.isEmpty) ? null : name;
    data["email"] = cleanEmail;
    if (gender != null && gender.isNotEmpty) data["gender"] = gender;
    if (dateOfBirth != null && dateOfBirth.isNotEmpty) data["dateOfBirth"] = dateOfBirth;

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
          'Authorization': 'Bearer ${bearerToken.value}',
        },
        body: jsonEncode(data),
      );

      print("📥 API Response Status: ${response.statusCode}");
      print("📥 API Response Body: ${response.body}");

      isprofileUpdating.value = false;
      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Update successful");

        final resObj = jsonDecode(response.body);
        final Map<String, dynamic>? resAddr = (resObj is Map && resObj['address'] is Map)
            ? resObj['address'] as Map<String, dynamic>
            : null;

        final finalPhone = (resObj is Map && resObj['phone'] != null) ? resObj['phone'].toString() : (phone ?? '');
        final finalName = (resObj is Map && resObj['name'] != null) ? resObj['name'].toString() : (name ?? '');
        final finalEmail = (resObj is Map && resObj['email'] != null) ? resObj['email'].toString() : (email ?? '');
        final finalGender = (resObj is Map && resObj['gender'] != null) ? resObj['gender'].toString() : (gender ?? '');
        final finalDob = (resObj is Map && resObj['dateOfBirth'] != null) ? resObj['dateOfBirth'].toString() : (dateOfBirth ?? '');

        final finalStreet = resAddr != null ? (resAddr['street'] ?? '').toString() : (street ?? '');
        final finalCity = resAddr != null ? (resAddr['city'] ?? '').toString() : (city ?? '');
        final finalState = resAddr != null ? (resAddr['state'] ?? '').toString() : (state ?? '');
        final finalZipCode = resAddr != null ? (resAddr['zipCode'] ?? '').toString() : (zipCode ?? '');

        // Update local controllers
        editPhoneController.text = finalPhone;
        editNameController.text = finalName;
        editemailController.text = finalEmail;
        editGenderController.text = finalGender;
        editDobController.text = formatDob(finalDob);
        editaddressController.text = finalStreet;
        editcityController.text = finalCity;
        editzipcodeController.text = finalZipCode;
        editStateController.text = finalState;

        // Also update observable values
        phoneNumber.value = finalPhone;
        fullName.value = finalName;
        this.email.value = finalEmail;
        this.gender.value = finalGender;
        this.dateOfBirth.value = formatDob(finalDob);
        address.value = finalStreet;

        // Save to SharedPreferences for persistence
        await prefs.setString('user_address', finalStreet);
        await prefs.setString('user_zipCode', finalZipCode);
        await prefs.setString('user_city', finalCity);
        await prefs.setString('user_state', finalState);
        await prefs.setString('user_phone', finalPhone);
        await prefs.setString('userName', finalName);
        await prefs.setString('user_name', finalName);
        await prefs.setString('userEmail', finalEmail);

        // Also sync to checkout if UserController exists
        try {
          if (Get.isRegistered<UserController>()) {
            final userController = Get.find<UserController>();
            String digitsOnlyPhone = finalPhone.trim();
            if (digitsOnlyPhone.startsWith('+971')) {
              digitsOnlyPhone = digitsOnlyPhone.substring(4);
            } else if (digitsOnlyPhone.startsWith('+')) {
              digitsOnlyPhone = digitsOnlyPhone.replaceFirst(RegExp(r'^\+\d{1,4}'), '');
            }
            while (digitsOnlyPhone.startsWith('0')) {
              digitsOnlyPhone = digitsOnlyPhone.substring(1);
            }
            userController.homePhoneController.text = digitsOnlyPhone;
            userController.phoneController.text = finalPhone;
            userController.homeNameController.text = finalName;
            userController.fullName.value = finalName;
            userController.street.value = finalStreet;
            userController.city.value = finalCity;
            userController.zipcode.value = finalZipCode;
            userController.state.value = finalState;

            final currentState = editStateController.text;
            if (currentState != finalState) {
              editStateController.text = finalState;
            }
          }
        } catch (e) {
          print('⚠️ UserController not available: $e');
        }

        update();

        if (showSuccessMessage) {
          Get.snackbar(
            'Success',
            'Profile updated successfully',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      } else {
        print("❌ Failed: ${response.statusCode} - ${response.body}");
        Get.snackbar(
          'Error',
          'Failed to update profile (${response.statusCode})',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      isprofileUpdating.value = false;
      print("⚠️ Error updating profile: $e");
      Get.snackbar(
        'Error',
        'An error occurred while updating profile',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  final isChangingPassword = false.obs;
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final url = Uri.parse(Configss.updateProfile);
    final prefs = await SharedPreferences.getInstance();
    final userToken = prefs.getString('token') ?? token.value;

    if (userToken.isEmpty) {
      Get.snackbar(
        'Error',
        'Please login to change password',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    isChangingPassword.value = true;
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'password': newPassword,
        }),
      );

      log('📥 Change Password Response (${response.statusCode}): ${response.body}');
      isChangingPassword.value = false;

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data is Map && data.containsKey('token') && data['token'] != null) {
          final newToken = data['token'].toString();
          await prefs.setString('token', newToken);
          token.value = newToken;
        }

        Get.snackbar(
          'Success',
          'Password changed successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return true;
      } else {
        Get.snackbar(
          'Error',
          data['message'] ?? 'Failed to change password',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    } catch (e) {
      isChangingPassword.value = false;
      log('⚠️ Error changing password: $e');
      Get.snackbar(
        'Error',
        'An error occurred while changing password',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
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

    final cleanEmail = email.trim().toLowerCase();
    var bodyobj = {"email": cleanEmail, "password": password};

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
        // FCM: attach this install's push token to the logged-in account
        try {
          await PushNotificationService.instance.registerDevice();
        } catch (_) {}
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

    setLoading(true);
    update();

    final cleanEmail = email.trim().toLowerCase();
    var bodyobj = {
      "name": userName,
      "email": cleanEmail,
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
      EasyLoading.showSuccess(data['message']);
      // FCM: register this install (re-registered again after login)
      try {
        await PushNotificationService.instance.registerDevice();
      } catch (_) {}
      Get.to(() => OtpScreen(email: cleanEmail, password: password));
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
    // FCM: stop pushes to this install (spec: DELETE on logout)
    try {
      await PushNotificationService.instance.deregisterDevice();
    } catch (_) {}
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
