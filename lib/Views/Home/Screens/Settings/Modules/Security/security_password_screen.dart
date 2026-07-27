import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../../Controllers/authController.dart';
import '../../../../../../Utils/appcolors.dart';
import '../../../../../../Widgets/customappbar.dart';
import '../../../../../../Widgets/primarybutton.dart';

class SecurityPasswordScreen extends StatefulWidget {
  const SecurityPasswordScreen({super.key});

  @override
  State<SecurityPasswordScreen> createState() => _SecurityPasswordScreenState();
}

class _SecurityPasswordScreenState extends State<SecurityPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthController _authController = Get.find<AuthController>();

  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitChangePassword() async {
    final currentPass = _currentPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (currentPass.isEmpty) {
      Get.snackbar('Warning', 'Please enter your current password',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    if (newPass.length < 6) {
      Get.snackbar('Warning', 'New password must be at least 6 characters',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    if (newPass != confirmPass) {
      Get.snackbar('Warning', 'New password and confirmation do not match',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    FocusScope.of(context).unfocus();

    final success = await _authController.changePassword(
      currentPassword: currentPass,
      newPassword: newPass,
    );

    if (success && mounted) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFD),
      appBar: const CustomAppBar(titleText: "Security & Password"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              const Text(
                "Security & Password",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: kSecondaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Update your password to keep your account safe.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              // Form Fields Section
              _buildInputGroup(
                label: "Current Password",
                child: _buildPasswordField(
                  controller: _currentPasswordController,
                  hintText: "Enter current password",
                  obscureText: _obscureCurrent,
                  onToggleObscure: () {
                    setState(() {
                      _obscureCurrent = !_obscureCurrent;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),

              _buildInputGroup(
                label: "New Password",
                child: _buildPasswordField(
                  controller: _newPasswordController,
                  hintText: "Enter new password",
                  obscureText: _obscureNew,
                  onToggleObscure: () {
                    setState(() {
                      _obscureNew = !_obscureNew;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),

              _buildInputGroup(
                label: "Confirm New Password",
                child: _buildPasswordField(
                  controller: _confirmPasswordController,
                  hintText: "Confirm new password",
                  obscureText: _obscureConfirm,
                  onToggleObscure: () {
                    setState(() {
                      _obscureConfirm = !_obscureConfirm;
                    });
                  },
                ),
              ),

              const SizedBox(height: 32),

              // Action Button
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: Get.width > 550 ? 200 : double.infinity,
                  child: Obx(
                    () => _authController.isChangingPassword.value
                        ? const Center(child: CircularProgressIndicator())
                        : PrimaryButton(
                            buttonColor: kPrimaryColor,
                            textColor: kdefwhiteColor,
                            buttonText: "Update Password",
                            onPressFunction: _submitChangePassword,
                          ),
                  ),
                ),
              ),
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggleObscure,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
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
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.grey,
            size: 20,
          ),
          onPressed: onToggleObscure,
        ),
      ),
    );
  }
}
