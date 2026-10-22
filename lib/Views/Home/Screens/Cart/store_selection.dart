import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:graba2z/Controllers/checkout_controller.dart';
import 'package:graba2z/Utils/appcolors.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:url_launcher/url_launcher.dart';

class StoreSelectionScreen extends StatefulWidget {
  @override
  _StoreSelectionScreenState createState() => _StoreSelectionScreenState();
}

class _StoreSelectionScreenState extends State<StoreSelectionScreen> {
  String? _pickupPhoneError;

  // Phone country code detection
  String completePhoneNumber = '';
  String selectedCountryCode = '+971';
  String initialCountryCode = 'AE';
  bool _isParsingPhone = false;

  // Country dial code to ISO code mapping
  final Map<String, String> dialCodeToCountry = {
    '+971': 'AE',
    '+966': 'SA',
    '+968': 'OM',
    '+974': 'QA',
    '+973': 'BH',
    '+965': 'KW',
    '+91': 'IN',
    '+92': 'PK',
    '+44': 'GB',
    '+1': 'US',
    '+63': 'PH',
    '+20': 'EG',
    '+962': 'JO',
    '+961': 'LB',
    '+86': 'CN',
    '+81': 'JP',
    '+82': 'KR',
    '+49': 'DE',
    '+33': 'FR',
    '+39': 'IT',
    '+34': 'ES',
    '+61': 'AU',
    '+55': 'BR',
    '+7': 'RU',
    '+90': 'TR',
    '+27': 'ZA',
    '+234': 'NG',
    '+254': 'KE',
    '+880': 'BD',
    '+94': 'LK',
    '+977': 'NP',
    '+60': 'MY',
    '+65': 'SG',
    '+62': 'ID',
    '+66': 'TH',
    '+84': 'VN',
  };

  final List<Map<String, String>> stores = [
    {
      "storeId": '0',
      "title": "CROWN EXCEL (Experience Center)",
      "address":
          "Admiral Plaza Hotel Building - 37C Street - Shop 5 - Khalid Bin Al Waleed Rd - Bur Dubai - Dubai - United Arab Emirates",
      "phone": "+971543540656"
    },
    {
      "title": "Crown Excel Head Office",
      "storeId": '1',
      "address":
          "Al Jahra Building, 2nd floor, office 204, 18th st - Al Raffa - Khalid Bin Al Waleed Rd - Bur Dubai - Dubai - United Arab Emirates",
      "phone": "+971543540656"
    },
    {
      "title": "CROWN EXCEL (branch 2)",
      "storeId": '2',
      "address":
          "Shop No. 2, Building 716 Khalid Bin Al Waleed Rd - opposite Main Entrance of Admiral Plaza Hotel - Dubai - Al Souq Al Kabeer - Dubai - United Arab Emirates",
      "phone": "+97142316533"
    },
    // {
    //   "title": "GrabAtoZ",
    //   "storeId": '3',
    //   "address":
    //       "Al Jahra Building, 2nd floor, 18th st - Khalid Bin Al Waleed Rd - Al Raffa - Dubai - United Arab Emirates",
    //   "phone": "+97143357974"
    // },
  ];

  String _digitsOnly(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

  bool _isValidUaePhone(String input) {
    final d = _digitsOnly(input);
    final numPart = d.startsWith('0') ? d.substring(1) : d;
    return numPart.length == 9;
  }

  UserController _userController = Get.put(UserController());

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        children: [
          // Phone number field with IntlPhoneField
          IntlPhoneField(
            key: ValueKey(initialCountryCode),
            controller: _userController.phoneController,
            decoration: InputDecoration(
              labelText: 'checkout_phone_label'.tr,
              hintText: 'checkout_phone_hint'.tr,
              hintStyle: const TextStyle(color: Colors.grey),
              border: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey)),
              enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey)),
              errorText: _pickupPhoneError,
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
                  _pickupPhoneError = 'checkout_phone_required'.tr;
                } else {
                  _pickupPhoneError = null;
                }
              });
            },
            onCountryChanged: (country) {
              setState(() {
                selectedCountryCode = '+${country.dialCode}';
              });
            },
          ),
          SizedBox(height: 20),

          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'checkout_select_store'.tr,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                TextButton(
                    onPressed: () {
                      openMapLocation(
                          _userController.storeAddress.value.toString());
                    },
                    child: Text(
                      'checkout_open_in_map'.tr,
                      style: TextStyle(
                          decoration: TextDecoration.underline,
                          decorationColor: kPrimaryColor),
                    ))
              ],
            ),
          ),
          SizedBox(height: 10),

          ListView.builder(
            itemCount: stores.length,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final store = stores[index];
              return Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _userController.selectedStoreIndex?.value == index
                        ? Colors.green
                        : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: RadioListTile<int>(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 0,
                  ),
                  value: index,
                  groupValue: _userController.selectedStoreIndex?.value,
                  onChanged: (val) {
                    print('🔘 Radio onChanged called with value: $val');
                    print('   Store data from map:');
                    print('   - storeId: ${store['storeId']}');
                    print('   - title: ${store['title']}');
                    print('   - address: ${store['address']}');
                    print('   - phone: ${store['phone']}');

                    setState(() {
                      // Set all values directly without nullable operators
                      if (_userController.selectedStoreIndex != null) {
                        _userController.selectedStoreIndex!.value = val ?? 0;
                      }
                      _userController.storeId.value = store['storeId'] ?? '';
                      _userController.storeName.value = store['title'] ?? '';
                      _userController.storeAddress.value =
                          store['address'] ?? '';
                      _userController.storePhone.value = store['phone'] ?? '';

                      // Verify values were set immediately
                      print('✅ Values set in controller:');
                      print(
                          '   - selectedStoreIndex: ${_userController.selectedStoreIndex?.value}');
                      print('   - storeId: "${_userController.storeId.value}"');
                      print(
                          '   - storeName: "${_userController.storeName.value}"');
                      print(
                          '   - storeAddress: "${_userController.storeAddress.value}"');
                      print(
                          '   - storePhone: "${_userController.storePhone.value}"');
                    });

                    log('Store selection completed: ${val}');
                  },
                  title: Text(
                    store['title'] ?? '',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text(
                        store['address'] ?? '',
                        style: TextStyle(fontSize: 13),
                      ),
                      SizedBox(height: 6),
                      Text(
                        store['phone'] ?? '',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              );
            },
          ),

          SizedBox(height: 10),
        ],
      ),
    );
  }

  Future<void> openMapLocation(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final googleMapsUrl =
        'https://www.google.com/maps/search/?api=1&query=$encodedAddress';

    if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
      await launchUrl(Uri.parse(googleMapsUrl),
          mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch Maps for $address';
    }
  }
}
