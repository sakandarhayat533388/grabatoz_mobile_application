import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../../Controllers/delete_account_controller.dart';
import '../../../../../../Utils/appcolors.dart';
import '../../../../../../Views/Home/home.dart';
import '../../../../../../Widgets/customappbar.dart';
import '../../../../../../Widgets/primarybutton.dart';

class DangerZoneScreen extends StatefulWidget {
  const DangerZoneScreen({super.key});

  @override
  State<DangerZoneScreen> createState() => _DangerZoneScreenState();
}

class _DangerZoneScreenState extends State<DangerZoneScreen> {
  final DeleteAccountController _deleteAccountController =
      Get.put(DeleteAccountController());

  final TextEditingController _codeController = TextEditingController();
  bool _codeRequested = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _onRequestCode() async {
    final ok = await _deleteAccountController.requestAccountDeletion();
    if (ok) {
      setState(() {
        _codeRequested = true;
      });
      Get.snackbar(
        'profile_code_sent_title'.tr,
        'profile_code_sent_body'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    }
  }

  void _onConfirmDelete() async {
    final code = _codeController.text.trim();
    if (code.isEmpty || code.length < 6) {
      Get.snackbar(
        'profile_invalid_code_title'.tr,
        'profile_invalid_code_body'.tr,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    Get.dialog(
      AlertDialog(
        title: Text('profile_final_confirmation'.tr),
        content: Text(
            'profile_delete_confirm_body'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success =
                  await _deleteAccountController.verifyAccountDeletion(code);
              if (success) {
                Get.snackbar(
                  'profile_account_deleted_title'.tr,
                  'profile_account_deleted_body'.tr,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                Get.offAll(() => Home());
              }
            },
            child: Text('profile_delete_account'.tr,
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(titleText: 'profile_danger_zone'.tr),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Danger Zone Card Banner matching the UI mockup
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_amber_rounded,
                        color: Colors.red, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'profile_danger_zone'.tr,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'profile_deletion_data_removal'.tr,
                          style: TextStyle(fontSize: 12, color: kSecondaryColor),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 24),
            Text(
              'profile_deletion_warning'.tr,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kSecondaryColor,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kdefwhiteColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildWarningItem(
                    icon: Icons.highlight_remove,
                    text:
                        'profile_warning_1'.tr,
                  ),
                  const SizedBox(height: 12),
                  _buildWarningItem(
                    icon: Icons.history_toggle_off,
                    text:
                        'profile_warning_2'.tr,
                  ),
                  const SizedBox(height: 12),
                  _buildWarningItem(
                    icon: Icons.security,
                    text:
                        'profile_warning_3'.tr,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            if (!_codeRequested) ...[
              Obx(() => _deleteAccountController.isRequestingDeletion.value
                  ? const Center(child: CircularProgressIndicator())
                  : PrimaryButton(
                      buttonColor: Colors.red,
                      buttonText: 'profile_request_code'.tr,
                      onPressFunction: _onRequestCode,
                    )),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'profile_code_sent_info'.tr,
                        style: TextStyle(fontSize: 13, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'profile_enter_code'.tr,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: const TextStyle(
                    fontSize: 18, letterSpacing: 6, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: "123456",
                  hintStyle: TextStyle(
                      color: Colors.grey, letterSpacing: 6, fontSize: 16),
                  border: OutlineInputBorder(),
                  counterText: "",
                ),
              ),
              const SizedBox(height: 20),
              Obx(() => _deleteAccountController.isVerifyingCode.value
                  ? const Center(child: CircularProgressIndicator())
                  : PrimaryButton(
                      buttonColor: Colors.red,
                      buttonText: 'profile_delete_forever'.tr,
                      onPressFunction: _onConfirmDelete,
                    )),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: _onRequestCode,
                  child: Text('profile_resend_code'.tr,
                      style: TextStyle(color: kPrimaryColor)),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildWarningItem({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.red[400], size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: kSecondaryColor, height: 1.3),
          ),
        ),
      ],
    );
  }
}
