import 'package:get/get.dart';
import 'package:graba2z/Controllers/checkout_controller.dart';
import 'package:graba2z/Utils/packages.dart'; // for AuthController

class AddressDetailsBottomSheet extends StatefulWidget {
  final String phone;
  final bool isforGuest;
  final String? existingStreet;
  final String? existingCity;
  final String? existingState;
  final String? existingZipCode;

  const AddressDetailsBottomSheet({
    super.key,
    required this.phone,
    required this.isforGuest,
    this.existingStreet,
    this.existingCity,
    this.existingState,
    this.existingZipCode,
  });

  @override
  State<AddressDetailsBottomSheet> createState() =>
      _AddressDetailsBottomSheetState();
}

class _AddressDetailsBottomSheetState extends State<AddressDetailsBottomSheet> {
  String addressType = 'home'.tr;
  String selectedState = 'Select State';
  List<String> states = [
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

  bool isDefault = false;
  final addressController = TextEditingController();
  final zipCodeController = TextEditingController();
  final nameController = TextEditingController();
  final cityController = TextEditingController();
  final UserController _userController = Get.put(UserController());
  final AuthController _authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    // Prefill with existing data if available
    if (widget.existingStreet != null && widget.existingStreet!.isNotEmpty) {
      addressController.text = widget.existingStreet!.replaceAll('"', '');
    }
    if (widget.existingCity != null && widget.existingCity!.isNotEmpty) {
      cityController.text = widget.existingCity!.replaceAll('"', '');
    }
    if (widget.existingZipCode != null && widget.existingZipCode!.isNotEmpty) {
      zipCodeController.text = widget.existingZipCode!.replaceAll('"', '');
    }
    if (widget.existingState != null && widget.existingState!.isNotEmpty) {
      final cleanState = widget.existingState!.replaceAll('"', '');
      if (states.contains(cleanState)) {
        selectedState = cleanState;
      }
    }
  }

  Future<void> _saveAndSyncAddress() async {
    final hasRequiredAddress = addressController.text.trim().isNotEmpty &&
        cityController.text.trim().isNotEmpty &&
        selectedState != 'Select State' &&
        zipCodeController.text.trim().isNotEmpty;
    final hasRequiredGuestName =
        !widget.isforGuest || nameController.text.trim().isNotEmpty;

    if (hasRequiredAddress && hasRequiredGuestName) {
      if (widget.isforGuest) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('guest_name', nameController.text.trim());
        await prefs.setString('guest_city', cityController.text.trim());
        await prefs.setString('guest_address', addressController.text.trim());
        await prefs.setString('guest_zip', zipCodeController.text.trim());
        await prefs.setString('guest_state', selectedState);
        await prefs.setBool('Guest', true);

        _userController.homeNameController.text = nameController.text.trim();
        _userController.street.value = addressController.text.trim();
        _userController.city.value = cityController.text.trim();
        _userController.state.value = selectedState;
        _userController.zipcode.value = zipCodeController.text.trim();
        if (mounted) Navigator.pop(context);
      } else {
        _userController.saveAddress(
          phone: widget.phone,
          street: addressController.text.toString(),
          city: cityController.text.toString(),
          state: selectedState,
          zipCode: zipCodeController.text.toString(),
          country: 'UAE',
        );

        // Also sync to AuthController for Edit Profile
        _authController.editaddressController.text = addressController.text;
        _authController.editcityController.text = cityController.text;
        _authController.editzipcodeController.text = zipCodeController.text;
        _authController.editStateController.text = selectedState;

        // Update observable values too
        _authController.address.value = addressController.text;
      }
    } else {
      Get.snackbar('checkout_warning_title'.tr, 'checkout_missing_fields'.tr,
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      margin: EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Text(
                    'checkout_address_details'.tr,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      _buildRadioOption('home'.tr),
                      SizedBox(width: 20),
                      _buildRadioOption('checkout_office'.tr),
                    ],
                  ),
                  SizedBox(height: 16),
                  if (widget.isforGuest) ...[
                    _buildTextField('checkout_name_star'.tr, controller: nameController),
                    SizedBox(height: 12),
                  ],
                  _buildTextField('checkout_address_star'.tr, controller: addressController),
                  SizedBox(height: 12),
                  _buildTextField('checkout_zipcode_star'.tr, controller: zipCodeController),
                  SizedBox(height: 12),
                  Text('checkout_country_label'.tr),
                  SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: 'UAE',
                    items: ['UAE']
                        .map((country) => DropdownMenuItem<String>(
                              value: country,
                              child: Text(country),
                            ))
                        .toList(),
                    onChanged: null,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text('checkout_state_region'.tr),
                  SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedState,
                    items: states
                        .map((state) => DropdownMenuItem<String>(
                              value: state,
                              child: Text(state),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedState = value!;
                      });
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  _buildTextField('checkout_city_star'.tr, controller: cityController),
                  SizedBox(height: 12),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('cancel'.tr),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                          child: Obx(
                        () => _userController.isLoading.value
                            ? SizedBox(
                                width: 30,
                                child:
                                    Center(child: CircularProgressIndicator()))
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF8FD034),
                                ),
                                onPressed: _saveAndSyncAddress,
                                child: Text(
                                  'checkout_save_address'.tr,
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                      )),
                    ],
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRadioOption(String type) {
    final isSelected = addressType == type;
    return InkWell(
      onTap: () => setState(() => addressType = type),
      child: Row(
        children: [
          Container(
            height: 20,
            width: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? kPrimaryColor : Colors.grey,
                width: 1.8,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      height: 10,
                      width: 10,
                      decoration: BoxDecoration(
                        color: kPrimaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null,
          ),
          SizedBox(width: 8),
          Text(type),
        ],
      ),
    );
  }

  Widget _buildTextField(String label,
      {required TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: label,
            hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
