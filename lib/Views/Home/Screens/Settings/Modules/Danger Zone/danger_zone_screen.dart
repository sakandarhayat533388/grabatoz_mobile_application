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
        "Verification Code Sent",
        "A 6-digit verification code has been sent to your registered email address.",
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
        "Invalid Code",
        "Please enter the 6-digit code sent to your email",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    Get.dialog(
      AlertDialog(
        title: const Text("Final Confirmation"),
        content: const Text(
            "Are you absolutely sure you want to permanently delete your account? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success =
                  await _deleteAccountController.verifyAccountDeletion(code);
              if (success) {
                Get.snackbar(
                  "Account Deleted",
                  "Your account has been deleted successfully.",
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                Get.offAll(() => Home());
              }
            },
            child: const Text("Delete Account",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(titleText: "Danger Zone"),
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Danger Zone",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Account Deletion & Data Removal",
                          style: TextStyle(fontSize: 12, color: kSecondaryColor),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              "Account Deletion Warning",
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
                        "Deleting your account will permanently remove your profile, address book, and account settings.",
                  ),
                  const SizedBox(height: 12),
                  _buildWarningItem(
                    icon: Icons.history_toggle_off,
                    text:
                        "You will lose access to order history links and saved discount preferences.",
                  ),
                  const SizedBox(height: 12),
                  _buildWarningItem(
                    icon: Icons.security,
                    text:
                        "This action is immediate and non-reversible. We will send a 6-digit security code to your email first.",
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
                      buttonText: "Request Account Deletion Code",
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
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Code sent! Please check your email inbox (and spam folder) for the 6-digit deletion code.",
                        style: TextStyle(fontSize: 13, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Enter 6-Digit Verification Code *",
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
                      buttonText: "Permanently Delete My Account",
                      onPressFunction: _onConfirmDelete,
                    )),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: _onRequestCode,
                  child: const Text("Resend Code",
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
