import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import '../../../../../../Controllers/address_controller.dart';
import '../../../../../../Controllers/authController.dart';
import '../../../../../../Utils/appcolors.dart';
import '../../../../../../Widgets/customappbar.dart';
import '../../../../../../Widgets/primarybutton.dart';

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  final AddressController _addressController = Get.put(AddressController());
  final AuthController _authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _addressController.fetchAddresses();
    _authController.getUserProfileData();
  }

  void _openAddressDialog({AddressModel? address}) {
    final isEdit = address != null;

    final defaultPhone = _authController.phoneNumber.value.isNotEmpty
        ? _authController.phoneNumber.value
        : _authController.editPhoneController.text;

    final defaultEmail = _authController.email.value.isNotEmpty
        ? _authController.email.value
        : _authController.editemailController.text;

    final rawPhone = formatNormalizedPhone(
        (address != null && address.phone.isNotEmpty)
            ? address.phone
            : defaultPhone);

    final Map<String, String> dialCodeToCountry = {
      '+971': 'AE', '+966': 'SA', '+968': 'OM', '+974': 'QA', '+973': 'BH',
      '+965': 'KW', '+91': 'IN', '+92': 'PK', '+44': 'GB', '+1': 'US',
      '+63': 'PH', '+20': 'EG', '+962': 'JO', '+961': 'LB', '+86': 'CN',
      '+81': 'JP', '+82': 'KR', '+49': 'DE', '+33': 'FR', '+39': 'IT',
      '+34': 'ES', '+61': 'AU', '+55': 'BR', '+7': 'RU', '+90': 'TR',
    };

    String initialCountryCode = 'AE';
    String completePhone = rawPhone;
    String initialNumberDigits = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');

    String cleanPhone = rawPhone.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleanPhone.isNotEmpty && !cleanPhone.startsWith('+')) {
      cleanPhone = '+$cleanPhone';
    }

    final sortedCodes = dialCodeToCountry.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (String code in sortedCodes) {
      if (cleanPhone.startsWith(code)) {
        initialCountryCode = dialCodeToCountry[code]!;
        initialNumberDigits = cleanPhone.substring(code.length).replaceAll(RegExp(r'[^0-9]'), '');
        completePhone = cleanPhone;
        break;
      }
    }

    final nameController = TextEditingController(
      text: address?.name ?? '',
    );
    final emailController = TextEditingController(
      text: (address != null && address.email.isNotEmpty)
          ? address.email
          : defaultEmail,
    );
    final streetController = TextEditingController(
      text: address?.address ?? '',
    );
    final cityController = TextEditingController(
      text: address?.city ?? '',
    );
    final zipController = TextEditingController(
      text: address?.zipCode ?? '',
    );

    String selectedState = address?.state.isNotEmpty == true ? address!.state : 'address_select_state'.tr;
    bool isDefault = address?.isDefault ?? false;

    final List<String> uaeStates = [
      'address_select_state'.tr,
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
              backgroundColor: kdefwhiteColor,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
                      // Dialog Title Bar with Close Icon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEdit ? 'address_edit_title'.tr : 'address_add_title'.tr,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: kSecondaryColor,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, color: Colors.grey, size: 22),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ADDRESS LABEL *
                      _buildDialogFieldGroup(
                        label: 'address_label'.tr,
                        child: _buildDialogTextField(
                          controller: nameController,
                          hintText: 'address_label_hint'.tr,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // PHONE *
                      _buildDialogFieldGroup(
                        label: 'address_phone'.tr,
                        child: _buildDialogPhoneField(
                          initialCountryCode: initialCountryCode,
                          initialNumber: initialNumberDigits,
                          onChanged: (val) {
                            completePhone = val;
                          },
                        ),
                      ),
                      const SizedBox(height: 14),

                      // EMAIL
                      _buildDialogFieldGroup(
                        label: 'address_email'.tr,
                        child: _buildDialogTextField(
                          controller: emailController,
                          hintText: "sakandarhayat388@gmail.com",
                          keyboardType: TextInputType.emailAddress,
                          readOnly: true,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ADDRESS STREET *
                      _buildDialogFieldGroup(
                        label: 'address_street'.tr,
                        child: _buildDialogTextField(
                          controller: streetController,
                          hintText: 'address_street_hint'.tr,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // STATE / EMIRATE *
                      _buildDialogFieldGroup(
                        label: 'address_state'.tr,
                        child: DropdownButtonFormField<String>(
                          initialValue: uaeStates.contains(selectedState)
                              ? selectedState
                              : 'address_select_state'.tr,
                          decoration: _inputDecoration(hintText: 'address_select_state'.tr),
                          items: uaeStates
                              .map((st) => DropdownMenuItem(
                                    value: st,
                                    child: Text(st, style: const TextStyle(fontSize: 13)),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                selectedState = val;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 14),

                      // CITY *
                      _buildDialogFieldGroup(
                        label: 'address_city'.tr,
                        child: _buildDialogTextField(
                          controller: cityController,
                          hintText: 'address_city_hint'.tr,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ZIP CODE / POST CODE
                      _buildDialogFieldGroup(
                        label: 'address_zip'.tr,
                        child: _buildDialogTextField(
                          controller: zipController,
                          hintText: "00000",
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Checkbox: Set as Default Address
                      InkWell(
                        onTap: () {
                          setDialogState(() {
                            isDefault = !isDefault;
                          });
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Row(
                          children: [
                            Checkbox(
                              value: isDefault,
                              activeColor: kPrimaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(3),
                              ),
                              onChanged: (val) {
                                setDialogState(() {
                                  isDefault = val ?? false;
                                });
                              },
                            ),
                            Text(
                              'address_set_default'.tr,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: kSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Dialog Buttons (Cancel & Save Address)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: Colors.grey.withValues(alpha: 0.4)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'cancel'.tr,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: kSecondaryColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Obx(() => _addressController.isSaving.value
                                ? const Center(child: CircularProgressIndicator())
                                : PrimaryButton(
                                    buttonColor: kPrimaryColor,
                                    textColor: kdefwhiteColor,
                                    buttonText: 'address_save'.tr,
                                    onPressFunction: () async {
                                      final labelVal = nameController.text.trim();
                                      final streetVal = streetController.text.trim();
                                      final cityVal = cityController.text.trim();

                                      if (labelVal.isEmpty) {
                                        Get.snackbar('address_warning'.tr, 'address_label_required'.tr,
                                            backgroundColor: Colors.orange, colorText: Colors.white);
                                        return;
                                      }

                                      if (streetVal.isEmpty) {
                                        Get.snackbar('address_warning'.tr, 'address_street_required'.tr,
                                            backgroundColor: Colors.orange, colorText: Colors.white);
                                        return;
                                      }

                                      final payload = {
                                        "name": labelVal,
                                        "phone": completePhone,
                                        "email": emailController.text.trim(),
                                        "address": streetVal,
                                        "city": cityVal.isNotEmpty ? cityVal : "Dubai",
                                        "state": selectedState == 'address_select_state'.tr ? 'Dubai' : selectedState,
                                        "zipCode": zipController.text.trim().isNotEmpty
                                            ? zipController.text.trim()
                                            : "00000",
                                        "isDefault": isDefault,
                                      };

                                      bool ok = false;
                                      if (isEdit) {
                                        ok = await _addressController.updateAddress(address.id, payload);
                                      } else {
                                        ok = await _addressController.addAddress(payload);
                                      }

                                      if (ok && mounted) {
                                        Navigator.pop(context);
                                      }
                                    },
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

  Widget _buildDialogPhoneField({
    required String initialCountryCode,
    required String initialNumber,
    required ValueChanged<String> onChanged,
  }) {
    return IntlPhoneField(
      key: ValueKey(initialCountryCode),
      initialCountryCode: initialCountryCode,
      initialValue: initialNumber,
      style: const TextStyle(fontSize: 13),
      dropdownTextStyle: const TextStyle(fontSize: 13),
      disableLengthCheck: true,
      dropdownIconPosition: IconPosition.trailing,
      flagsButtonPadding: const EdgeInsets.only(left: 10),
      showDropdownIcon: true,
      decoration: _inputDecoration(hintText: 'profile_phone'.tr),
      onChanged: (PhoneNumber phone) {
        onChanged(phone.number.isEmpty ? '' : phone.completeNumber);
      },
    );
  }

  Widget _buildDialogFieldGroup({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: kSecondaryColor,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      style: TextStyle(
        fontSize: 13,
        color: readOnly ? Colors.grey[700] : kSecondaryColor,
      ),
      decoration: _inputDecoration(
        hintText: hintText,
        fillColor: readOnly ? const Color(0xFFF1F3F5) : kdefwhiteColor,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    Color fillColor = kdefwhiteColor,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFD),
      appBar: CustomAppBar(titleText: 'profile_saved_addresses'.tr),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddressDialog(),
        backgroundColor: kPrimaryColor,
        icon: const Icon(Icons.add, color: kdefwhiteColor),
        label: Text(
          'address_add_new'.tr,
          style: TextStyle(color: kdefwhiteColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: Obx(() {
        if (_addressController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_addressController.addresses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_off_outlined, size: 70, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'address_empty_title'.tr,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kSecondaryColor),
                ),
                const SizedBox(height: 8),
                Text('address_empty_hint'.tr, style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _openAddressDialog(),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: Text('address_add_new'.tr, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _addressController.addresses.length,
          itemBuilder: (context, index) {
            final addr = _addressController.addresses[index];
            final displayEmail = addr.email.isNotEmpty
                ? addr.email
                : _authController.email.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFFCFDFB),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: addr.isDefault
                      ? kPrimaryColor
                      : Colors.grey.withValues(alpha: 0.3),
                  width: addr.isDefault ? 1.8 : 1.2,
                ),
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
                  // Top Row: Title, Default Pill Badge & Action Icons (Edit / Delete)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              addr.name.isNotEmpty ? addr.name : 'address_fallback'.tr,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: kSecondaryColor,
                              ),
                            ),
                            if (addr.isDefault)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check,
                                        size: 14, color: kPrimaryColor),
                                    SizedBox(width: 4),
                                    Text(
                                      'address_default'.tr,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: kPrimaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              InkWell(
                                onTap: () => _addressController
                                    .setDefaultAddress(addr.id),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'address_set_default_btn'.tr,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Edit Button
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                            icon: Icon(Icons.edit_outlined,
                                color: Colors.grey[600], size: 18),
                            onPressed: () => _openAddressDialog(address: addr),
                          ),
                          const SizedBox(width: 6),
                          // Delete Button
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                            icon: Icon(Icons.delete_outline,
                                color: Colors.grey[600], size: 18),
                            onPressed: () => _showDeleteDialog(addr),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Street Address
                  if (addr.address.isNotEmpty)
                    Text(
                      addr.address,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.3,
                      ),
                    ),

                  // City, State Zip
                  if (addr.city.isNotEmpty || addr.state.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      "${addr.city}${addr.city.isNotEmpty && addr.state.isNotEmpty ? ', ' : ''}${addr.state} ${addr.zipCode}",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.3,
                      ),
                    ),
                  ],

                  // Phone Row
                  if (addr.phone.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.phone_outlined,
                            size: 15, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          formatNormalizedPhone(addr.phone),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Email Row
                  if (displayEmail.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.email_outlined,
                            size: 15, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          displayEmail,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      }),
    );
  }

  void _showDeleteDialog(AddressModel addr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('address_delete_title'.tr),
        content: Text('address_delete_confirm'.trParams({'name': addr.name})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _addressController.deleteAddress(addr.id);
            },
            child: Text('address_delete'.tr, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
