import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import '../../../../../../Controllers/authController.dart';
import '../../../../../../Utils/appcolors.dart';
import '../../../../../../Widgets/customappbar.dart';
import '../../../../../../Widgets/primarybutton.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  EditProfileState createState() => EditProfileState();
}

class EditProfileState extends State<EditProfile> {
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController _phoneDisplayController = TextEditingController();

  String completePhoneNumber = '';
  String selectedCountryCode = '+971';
  String initialCountryCode = 'AE';
  bool _isParsingPhone = false;
  String? _phoneError;

  final Map<String, String> dialCodeToCountry = {
    '+971': 'AE', '+966': 'SA', '+968': 'OM', '+974': 'QA', '+973': 'BH',
    '+965': 'KW', '+91': 'IN', '+92': 'PK', '+44': 'GB', '+1': 'US',
    '+63': 'PH', '+20': 'EG', '+962': 'JO', '+961': 'LB', '+86': 'CN',
    '+81': 'JP', '+82': 'KR', '+49': 'DE', '+33': 'FR', '+39': 'IT',
    '+34': 'ES', '+61': 'AU', '+55': 'BR', '+7': 'RU', '+90': 'TR',
  };

  @override
  void initState() {
    super.initState();
    _authController.getUserProfileData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final phone = _authController.editPhoneController.text.trim();
      if (phone.isNotEmpty) {
        _parseAndSetCountry(phone);
      }
    });

    _authController.editPhoneController.addListener(_onPhoneChanged);
  }

  void _onPhoneChanged() {
    if (_isParsingPhone) return;

    final phone = _authController.editPhoneController.text.trim();
    if (phone.isNotEmpty && completePhoneNumber != phone) {
      _parseAndSetCountry(phone);
    } else if (phone.isEmpty) {
      _phoneDisplayController.clear();
      completePhoneNumber = '';
      selectedCountryCode = '+971';
      initialCountryCode = 'AE';
      if (mounted) setState(() {});
    }
  }

  void _parseAndSetCountry(String phone) {
    if (phone.isEmpty || _isParsingPhone) return;
    _isParsingPhone = true;

    String cleanPhone = phone.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!cleanPhone.startsWith('+')) {
      cleanPhone = '+$cleanPhone';
    }

    final sortedCodes = dialCodeToCountry.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (String dialCode in sortedCodes) {
      if (cleanPhone.startsWith(dialCode)) {
        String numberPart = cleanPhone.substring(dialCode.length);
        final digitsOnlyNumber = _digitsOnly(numberPart);

        initialCountryCode = dialCodeToCountry[dialCode]!;
        selectedCountryCode = dialCode;
        completePhoneNumber = digitsOnlyNumber.isEmpty ? '' : cleanPhone;
        _phoneDisplayController.text = digitsOnlyNumber;

        if (mounted) setState(() {});
        _isParsingPhone = false;
        return;
      }
    }

    String digitsOnlyPhone = _digitsOnly(cleanPhone);
    if (digitsOnlyPhone.startsWith('0')) {
      digitsOnlyPhone = digitsOnlyPhone.substring(1);
    }

    initialCountryCode = 'AE';
    selectedCountryCode = '+971';
    _phoneDisplayController.text = digitsOnlyPhone;
    completePhoneNumber = digitsOnlyPhone.isEmpty ? '' : '+971$digitsOnlyPhone';

    if (mounted) setState(() {});
    _isParsingPhone = false;
  }

  @override
  void dispose() {
    _authController.editPhoneController.removeListener(_onPhoneChanged);
    _phoneDisplayController.dispose();
    super.dispose();
  }

  String _digitsOnly(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

  void _saveProfileChanges() {
    final phone = _phoneDisplayController.text.trim();
    if (phone.isNotEmpty && _digitsOnly(phone).length < 6) {
      setState(() {
        _phoneError = 'profile_invalid_phone'.tr;
      });
      Get.snackbar('profile_warning'.tr, 'profile_enter_valid_phone'.tr,
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    final fullPhone = completePhoneNumber.isNotEmpty
        ? completePhoneNumber
        : (phone.isNotEmpty ? '$selectedCountryCode${_digitsOnly(phone)}' : '');

    _authController.sendUserData(
      name: _authController.editNameController.text.trim(),
      email: _authController.editemailController.text.trim(),
      phone: fullPhone,
      gender: _authController.editGenderController.text.trim(),
      dateOfBirth: _authController.editDobController.text.trim(),
      showSuccessMessage: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          await _authController.getUserProfileData();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFBFBFD),
        appBar: CustomAppBar(titleText: 'profile_edit'.tr),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Text(
                'profile_edit_details'.tr,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: kSecondaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'profile_edit_subtitle'.tr,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              // Responsive Grid Form Layout
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 550;
                  return isWide
                      ? Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildInputGroup(
                                    label: 'profile_full_name_required'.tr,
                                    child: _buildTextField(
                                      controller: _authController.editNameController,
                                      hintText: 'profile_enter_full_name'.tr,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildInputGroup(
                                    label: 'profile_email_required'.tr,
                                    child: _buildTextField(
                                      controller: _authController.editemailController,
                                      hintText: 'profile_enter_email'.tr,
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildInputGroup(
                                    label: 'profile_phone'.tr,
                                    child: _buildPhoneField(),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildInputGroup(
                                    label: 'profile_dob'.tr,
                                    child: _buildDobField(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildInputGroup(
                                    label: 'profile_gender'.tr,
                                    child: _buildGenderDropdown(),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(child: SizedBox()),
                              ],
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputGroup(
                              label: 'profile_full_name_required'.tr,
                              child: _buildTextField(
                                controller: _authController.editNameController,
                                hintText: 'profile_enter_full_name'.tr,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildInputGroup(
                              label: 'profile_email_required'.tr,
                              child: _buildTextField(
                                controller: _authController.editemailController,
                                hintText: 'profile_enter_email'.tr,
                                keyboardType: TextInputType.emailAddress,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildInputGroup(
                              label: 'profile_phone'.tr,
                              child: _buildPhoneField(),
                            ),
                            const SizedBox(height: 16),
                            _buildInputGroup(
                              label: 'profile_dob'.tr,
                              child: _buildDobField(),
                            ),
                            const SizedBox(height: 16),
                            _buildInputGroup(
                              label: 'profile_gender'.tr,
                              child: _buildGenderDropdown(),
                            ),
                          ],
                        );
                },
              ),

              const SizedBox(height: 32),

              // Save Changes Action Button
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: Get.width > 550 ? 200 : double.infinity,
                  child: Obx(
                    () => _authController.isprofileUpdating.value
                        ? const Center(child: CircularProgressIndicator())
                        : PrimaryButton(
                            buttonColor: kPrimaryColor,
                            textColor: kdefwhiteColor,
                            buttonText: 'profile_save_changes'.tr,
                            onPressFunction: _saveProfileChanges,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputGroup({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: kSecondaryColor,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        filled: true,
        fillColor: kdefwhiteColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return IntlPhoneField(
      key: ValueKey(initialCountryCode),
      controller: _phoneDisplayController,
      decoration: InputDecoration(
        hintText: 'profile_enter_phone'.tr,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        filled: true,
        fillColor: kdefwhiteColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        errorText: _phoneError,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
        ),
      ),
      initialCountryCode: initialCountryCode,
      disableLengthCheck: true,
      dropdownIconPosition: IconPosition.trailing,
      flagsButtonPadding: const EdgeInsets.only(left: 10),
      showDropdownIcon: true,
      dropdownTextStyle: const TextStyle(fontSize: 14),
      onChanged: (PhoneNumber phone) {
        setState(() {
          completePhoneNumber = phone.number.isEmpty ? '' : phone.completeNumber;
          selectedCountryCode = phone.countryCode.startsWith('+')
              ? phone.countryCode
              : '+${phone.countryCode}';
          _phoneError = null;
        });
      },
    );
  }

  Widget _buildGenderDropdown() {
    final currentGender = _authController.editGenderController.text.toLowerCase().trim();
    String? dropdownValue;
    if (['male', 'female', 'other'].contains(currentGender)) {
      dropdownValue = currentGender;
    }

    return DropdownButtonFormField<String>(
      initialValue: dropdownValue,
      decoration: InputDecoration(
        hintText: 'profile_select_gender'.tr,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        filled: true,
        fillColor: kdefwhiteColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
        ),
      ),
      items: [
        DropdownMenuItem(value: 'male', child: Text('profile_male'.tr)),
        DropdownMenuItem(value: 'female', child: Text('profile_female'.tr)),
        DropdownMenuItem(value: 'other', child: Text('profile_other'.tr)),
      ],
      onChanged: (val) {
        if (val != null) {
          _authController.editGenderController.text = val;
          setState(() {});
        }
      },
    );
  }

  Widget _buildDobField() {
    return TextField(
      controller: _authController.editDobController,
      readOnly: true,
      onTap: () async {
        DateTime initialDate = DateTime.tryParse(_authController.editDobController.text) ??
            DateTime(1995, 1, 1);
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime(1920),
          lastDate: DateTime.now(),
        );
        if (pickedDate != null) {
          final formatted =
              "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
          _authController.editDobController.text = formatted;
          setState(() {});
        }
      },
      decoration: InputDecoration(
        hintText: 'mm/dd/yyyy',
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        filled: true,
        fillColor: kdefwhiteColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
        ),
        suffixIcon: const Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 20),
      ),
    );
  }
}
