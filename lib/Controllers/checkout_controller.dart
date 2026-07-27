import 'dart:convert';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:graba2z/Configs/config.dart';
import 'package:graba2z/Utils/packages.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserController extends GetxController {
  final String apiUrl =
      Configss.getuserProfile; // Replace this with your API URL
  // final String apiUrl = Configss.userProfile; // Replace this with your API URL
  final isHomeDelivery = true.obs;
  var isLoading = false.obs;
  var iscodLoading = false.obs;
  var iscardLoading = false.obs;
  var token = ''.obs;
  var street = ''.obs;
  var city = ''.obs;
  var state = ''.obs;
  var subtotalAmount = 0.0.obs;
  var fullName = ''.obs;
  final namecontroller = TextEditingController();
  final homeNameController = TextEditingController();
  final homeemailAddress = TextEditingController();
  final optionalNote = TextEditingController();
  final homePhoneController = TextEditingController();
  final orderItems = [].obs;
  var storeAddress = ''.obs;
  var storeId = ''.obs;
  var storePhone = ''.obs;
  var storeName = ''.obs;
  final activeStep = 0.obs;
  var phoneController = TextEditingController();
  var zipcode = ''.obs;
  RxInt? selectedStoreIndex = (-1).obs; // Changed back to -1 for no selection

  @override
  void onInit() {
    super.onInit();
    // Ensure selectedStoreIndex is initialized
    selectedStoreIndex ??= (-1).obs;

    // Debug initialization
    print('🔧 UserController.onInit()');
    print('   storeId initialized: ${storeId.value}');
    print('   storeName initialized: ${storeName.value}');
    print('   storeAddress initialized: ${storeAddress.value}');
    print('   storePhone initialized: ${storePhone.value}');
    print('   selectedStoreIndex initialized: ${selectedStoreIndex?.value}');
  }

  getUserInformation() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    fullName.value = sp.getString('user_name') ?? sp.getString('userName') ?? '';

    if (fullName.value.isNotEmpty) {
      homeNameController.text = fullName.value;
    }
    street.value = (sp.getString('user_address') ?? '').replaceAll('"', '');
    city.value = (sp.getString('user_city') ?? '').replaceAll('"', '');
    state.value = (sp.getString('user_state') ?? '').replaceAll('"', '');
    zipcode.value = (sp.getString('user_zipCode') ?? '').replaceAll('"', '');
  }

  Future<void> saveAddress({
    required String phone,
    required String street,
    required String city,
    required String state,
    required String zipCode,
    required String country,
    String? name,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      token.value = prefs.getString('token') ?? '';
      isLoading.value = true;

      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token.value}',
        },
        body: jsonEncode({
          if (name != null && name.isNotEmpty) "name": name,
          "phone": phone,
          "address": {
            "street": street,
            "city": city,
            "state": state,
            "zipCode": zipCode,
            "country": country,
          }
        }),
      );
      log('Address update HTTP ${response.statusCode}: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();

        final resAddr = (data is Map && data['address'] is Map)
            ? data['address'] as Map<String, dynamic>
            : null;

        if ((data['name'] ?? '').toString().isNotEmpty) {
          await prefs.setString('user_name', data['name'].toString());
          fullName.value = data['name'].toString();
          homeNameController.text = fullName.value;
        } else if (name != null && name.isNotEmpty) {
          await prefs.setString('user_name', name);
          fullName.value = name;
          homeNameController.text = fullName.value;
        }

        final streetStr = resAddr != null ? (resAddr['street'] ?? '').toString() : street;
        final cityStr = resAddr != null ? (resAddr['city'] ?? '').toString() : city;
        final zipStr = resAddr != null ? (resAddr['zipCode'] ?? '').toString() : zipCode;
        final stateStr = resAddr != null ? (resAddr['state'] ?? '').toString() : state;

        await prefs.setString('user_address', streetStr);
        await prefs.setString('user_city', cityStr);
        await prefs.setString('user_zipCode', zipStr);
        await prefs.setString('user_state', stateStr);
        await prefs.setString('user_phone', phone);

        getUserInformation();
        Get.back();
      } else {
        final prefs = await SharedPreferences.getInstance();

        if (name != null && name.isNotEmpty) {
          await prefs.setString('user_name', name);
          fullName.value = name;
          homeNameController.text = fullName.value;
        }
        await prefs.setString('user_address', street);
        await prefs.setString('user_city', city);
        await prefs.setString('user_zipCode', zipCode);
        await prefs.setString('user_state', state);
        await prefs.setString('user_phone', phone);
        Get.back();
        getUserInformation();
      }
    } catch (e) {
      Get.snackbar("Exception", e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
