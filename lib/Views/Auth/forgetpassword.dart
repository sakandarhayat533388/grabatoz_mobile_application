// ignore_for_file: use_build_context_synchronously

import 'package:graba2z/Api/Services/apiservices.dart';
import 'package:graba2z/Utils/appextensions.dart';
// Remove this import as we don't need to navigate to newpassword screen
// import 'package:graba2z/Views/Auth/newpassword.dart';
import '../../Utils/packages.dart';
import 'package:get/get.dart';

class ForgetPassword extends StatefulWidget {
  const ForgetPassword({super.key});

  @override
  State<ForgetPassword> createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword> {
  final formKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  bool _isCurvedContainerVisible = false; // For curved container
  bool _isBodyVisible = false; // For the form and content
  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();

    // Trigger animations after the screen builds
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _isCurvedContainerVisible =
            true; // Start the curved container animation
      });

      Future.delayed(const Duration(milliseconds: 800), () {
        setState(() {
          _isBodyVisible = true; // Then show the body content
        });
      });
    });
  }

  @override
  void dispose() {
    emailController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () {
        hideKeyboard(context);
        Get.find<FocusController>();
      },
      child: Scaffold(
        body: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeInOut,
              bottom: _isCurvedContainerVisible ? 0 : -screenHeight,
              child: CurvedBottomContainer(
                height: Get.height / 1.3,
                width: MediaQuery.of(context).size.width, // Full width
                color: kPrimaryColor, // Your desired background color
                animate:
                    _isCurvedContainerVisible, // Controls animation (if needed)
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(seconds: 2),
              opacity:
                  _isBodyVisible ? 1.0 : 0.0, // Show when body animation starts
              child: Padding(
                padding: defaultPadding(),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        40.0.heightbox,
                        Center(
                          child: GetBuilder<FocusController>(
                            builder: (
                              provider,
                            ) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: provider.isFocused
                                    ? Get.width * 0.4
                                    : Get.width * 0.6,
                                child: Image.asset(
                                  AppImages.logoicon,
                                  color: kdefwhiteColor,
                                ),
                              );
                            },
                          ),
                        ),
                        50.0.heightbox,
                        Text('auth_forget_password_title'.tr,
                            style: TextStyle(
                                fontSize: 34.0,
                                fontWeight: FontWeight.bold,
                                color: kdefwhiteColor)),
                        20.0.heightbox,
                        Text(
                          'auth_forget_password_subtitle'.tr,
                          style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w500,
                              color: kdefwhiteColor),
                          textAlign: TextAlign.center,
                        ),
                        40.0.heightbox,
                        GetBuilder<AuthController>(builder: (
                          emailvalidate,
                        ) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PrimaryTextField(
                                controller: emailController,
                                onChanged: emailvalidate.validateForgetEmail,
                                suffix: emailvalidate.isEmailValid
                                    ? const Icon(Icons.check,
                                        color: kdefwhiteColor)
                                    : null,
                                hintText: 'auth_email_hint'.tr,
                              ),
                              if (emailvalidate.forgetemailErrorMessage != null)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 8.0, left: 5),
                                  child: Text(
                                    emailvalidate.forgetemailErrorMessage ??
                                        "Unknown error",
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                            ],
                          );
                        }),
                        40.0.heightbox,
                        GetBuilder<AuthController>(builder: (
                          authProvider,
                        ) {
                          final apiservice = Get.find<ApiServiceController>();
                          final bottomNavProvider =
                              Get.put(BottomNavigationController());
                          return PrimaryButton(
                            buttonColor: kdefwhiteColor,
                            textColor: kSecondaryColor,
                            buttonText: 'auth_send_btn'.tr,
                            onPressFunction: () async {
                              final email = emailController.text.trim();
                              authProvider.validateForgetEmail(email);
                              if (authProvider.forgetemailErrorMessage ==
                                  null) {
                                if (formKey.currentState!.validate()) {
                                  formKey.currentState!.save();
                                  print(emailController.text);

                                  try {
                                    EasyLoading.show(status: 'auth_sending'.tr);
                                    final message = await apiservice.forgotPassword(email);
                                    EasyLoading.dismiss();
                                    
                                    // Show success dialog
                                    Get.dialog(
                                      AlertDialog(
                                        title: Text('auth_email_sent_title'.tr),
                                        content: Text(message),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Get.back(); // Close dialog
                                              Get.back(); // Go back to previous screen
                                            },
                                            child: Text('ok'.tr),
                                          ),
                                        ],
                                      ),
                                    );
                                  } catch (error) {
                                    EasyLoading.dismiss();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(error
                                              .toString()
                                              .replaceAll('Exception: ', ''))),
                                    );
                                  }
                                }
                              }
                            },
                          );
                        }),
                        100.0.heightbox,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FocusController extends GetxController {
  bool _isFocused = false;

  bool get isFocused => _isFocused;

  void setFocus(bool value) {
    _isFocused = value;
    update();
  }
}
