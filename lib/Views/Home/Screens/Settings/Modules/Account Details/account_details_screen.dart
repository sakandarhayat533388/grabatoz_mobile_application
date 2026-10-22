import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../../Controllers/authController.dart';
import '../../../../../../Utils/appcolors.dart';
import '../../../../../../Widgets/customappbar.dart';

class AccountDetailsScreen extends StatefulWidget {
  const AccountDetailsScreen({super.key});

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  final AuthController _authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _authController.getUserProfileData();
  }

  String _formatDisplayPhone(String rawPhone) {
    final clean = rawPhone.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (clean.isEmpty) return 'profile_not_specified'.tr;

    final validDialCodes = [
      '+971', '+966', '+968', '+974', '+973', '+965', '+91', '+92', '+44', '+1',
      '+63', '+20', '+962', '+961', '+86', '+81', '+82', '+49', '+33', '+39',
      '+34', '+61', '+55', '+7', '+90'
    ];

    for (final code in validDialCodes) {
      if (clean.startsWith(code)) {
        final numberPart = clean.substring(code.length);
        return '$code $numberPart';
      }
      final codeWithoutPlus = code.replaceFirst('+', '');
      if (clean.startsWith(codeWithoutPlus) && clean.length > codeWithoutPlus.length + 5) {
        final numberPart = clean.substring(codeWithoutPlus.length);
        return '$code $numberPart';
      }
    }

    String digits = clean.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    if (digits.length == 9 && (digits.startsWith('5') || digits.startsWith('4') || digits.startsWith('2') || digits.startsWith('3') || digits.startsWith('6') || digits.startsWith('7') || digits.startsWith('9'))) {
      return '+971 $digits';
    }

    if (digits.length == 10 && digits.startsWith('3')) {
      return '+92 $digits';
    }

    if (!clean.startsWith('+')) {
      return '+971 $digits';
    }

    return clean;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFD),
      appBar: CustomAppBar(titleText: 'profile_account_details'.tr),
      body: Obx(() {
        if (_authController.isProfileLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final fullName = _authController.fullName.value.isNotEmpty
            ? _authController.fullName.value
            : 'profile_not_specified'.tr;
        final email = _authController.email.value.isNotEmpty
            ? _authController.email.value
            : 'profile_not_specified'.tr;
        final phone = _authController.phoneNumber.value.isNotEmpty
            ? _formatDisplayPhone(_authController.phoneNumber.value)
            : 'profile_not_specified'.tr;
        final dob = _authController.dateOfBirth.value.isNotEmpty
            ? _authController.dateOfBirth.value
            : 'profile_not_specified'.tr;
        final gender = _authController.gender.value.isNotEmpty
            ? _authController.gender.value.capitalizeFirst ?? _authController.gender.value
            : 'profile_not_specified'.tr;
        final accountType = _authController.isAdmin.value ? 'profile_admin'.tr : 'profile_customer'.tr;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Text(
                'profile_account_details'.tr,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: kSecondaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'profile_account_overview'.tr,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              // 6 Read-only Detail Cards Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 550;
                  return isWide
                      ? GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 2.5,
                          children: [
                            _buildDetailCard(
                              label: 'profile_full_name'.tr,
                              value: fullName,
                              icon: Icons.person_outline,
                              iconBgColor: const Color(0xFFE8F5E9),
                              iconColor: const Color(0xFF4CAF50),
                            ),
                            _buildDetailCard(
                              label: 'profile_email'.tr,
                              value: email,
                              icon: Icons.email_outlined,
                              iconBgColor: const Color(0xFFE3F2FD),
                              iconColor: const Color(0xFF2196F3),
                            ),
                            _buildDetailCard(
                              label: 'profile_phone'.tr,
                              value: phone,
                              icon: Icons.phone_outlined,
                              iconBgColor: const Color(0xFFF3E5F5),
                              iconColor: const Color(0xFF9C27B0),
                            ),
                            _buildDetailCard(
                              label: 'profile_dob'.tr,
                              value: dob,
                              icon: Icons.calendar_today_outlined,
                              iconBgColor: const Color(0xFFFFF3E0),
                              iconColor: const Color(0xFFFF9800),
                            ),
                            _buildDetailCard(
                              label: 'profile_gender'.tr,
                              value: gender,
                              icon: Icons.tune_outlined,
                              iconBgColor: const Color(0xFFE0F2F1),
                              iconColor: const Color(0xFF009688),
                            ),
                            _buildDetailCard(
                              label: 'profile_account_type'.tr,
                              value: accountType,
                              icon: Icons.layers_outlined,
                              iconBgColor: const Color(0xFFE8EAF6),
                              iconColor: const Color(0xFF3F51B5),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _buildDetailCard(
                              label: 'profile_full_name'.tr,
                              value: fullName,
                              icon: Icons.person_outline,
                              iconBgColor: const Color(0xFFE8F5E9),
                              iconColor: const Color(0xFF4CAF50),
                            ),
                            const SizedBox(height: 12),
                            _buildDetailCard(
                              label: 'profile_email'.tr,
                              value: email,
                              icon: Icons.email_outlined,
                              iconBgColor: const Color(0xFFE3F2FD),
                              iconColor: const Color(0xFF2196F3),
                            ),
                            const SizedBox(height: 12),
                            _buildDetailCard(
                              label: 'profile_phone'.tr,
                              value: phone,
                              icon: Icons.phone_outlined,
                              iconBgColor: const Color(0xFFF3E5F5),
                              iconColor: const Color(0xFF9C27B0),
                            ),
                            const SizedBox(height: 12),
                            _buildDetailCard(
                              label: 'profile_dob'.tr,
                              value: dob,
                              icon: Icons.calendar_today_outlined,
                              iconBgColor: const Color(0xFFFFF3E0),
                              iconColor: const Color(0xFFFF9800),
                            ),
                            const SizedBox(height: 12),
                            _buildDetailCard(
                              label: 'profile_gender'.tr,
                              value: gender,
                              icon: Icons.tune_outlined,
                              iconBgColor: const Color(0xFFE0F2F1),
                              iconColor: const Color(0xFF009688),
                            ),
                            const SizedBox(height: 12),
                            _buildDetailCard(
                              label: 'profile_account_type'.tr,
                              value: accountType,
                              icon: Icons.layers_outlined,
                              iconBgColor: const Color(0xFFE8EAF6),
                              iconColor: const Color(0xFF3F51B5),
                            ),
                          ],
                        );
                },
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDetailCard({
    required String label,
    required String value,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: kSecondaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
