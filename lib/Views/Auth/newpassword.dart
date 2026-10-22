// ignore_for_file: use_build_context_synchronously

import 'package:get/get.dart';
import 'package:graba2z/Api/Services/apiservices.dart';
import 'package:graba2z/Utils/appextensions.dart';
import '../../Utils/packages.dart';

class UpdatePassword extends StatefulWidget {
  const UpdatePassword({super.key});

  @override
  State<UpdatePassword> createState() => _UpdatePasswordState();
}

class _UpdatePasswordState extends State<UpdatePassword> {
  final formKey = GlobalKey<FormState>();

  TextEditingController keyController = TextEditingController();
  TextEditingController loginController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  bool _isCurvedContainerVisible = false; // For curved container
  bool _isBodyVisible = false; // For the form and content
  @override
  void initState() {
    super.initState();
    keyController = TextEditingController();
    loginController = TextEditingController();
    newPasswordController = TextEditingController();

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
    keyController.dispose();
    loginController.dispose();
    newPasswordController.dispose();

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
                padding: defaultPadding(vertical: 10),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        50.0.heightbox,
                        Text(
                          'auth_new_credentials_title'.tr,
                          style: TextStyle(
                            fontSize: 40.0,
                            fontWeight: FontWeight.bold,
                            color: kdefwhiteColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        30.0.heightbox,
                        Text(
                          'auth_new_credentials_subtitle'.tr,
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w500,
                            color: kdefwhiteColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        20.0.heightbox,
                        GetBuilder<AuthController>(builder: (
                          emailvalidate,
                        ) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PrimaryTextField(
                                controller: keyController,
                                hintText: 'auth_reset_key_hint'.tr,
                              ),
                              30.0.heightbox,
                              PrimaryTextField(
                                controller: loginController,
                                hintText: 'auth_username_hint'.tr,
                              ),
                              30.0.heightbox,
                              GetBuilder<AuthController>(builder: (
                                authProvider,
                              ) {
                                return PrimaryTextField(
                                  controller: newPasswordController,
                                  hintText: 'auth_new_password_hint'.tr,
                                  obsecure: authProvider.isPasswordObscure,
                                  suffix: GestureDetector(
                                    onTap: () {
                                      authProvider.togglePasswordVisibility();
                                    },
                                    child: Icon(
                                      authProvider.isPasswordObscure
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: kdefwhiteColor,
                                    ),
                                  ),
                                );
                              }),
                            ],
                          );
                        }),
                        60.0.heightbox,
                        GetBuilder<ApiServiceController>(builder: (
                          apiservice,
                        ) {
                          return PrimaryButton(
                              buttonColor: kdefwhiteColor,
                              textColor: kSecondaryColor,
                              buttonText: 'auth_update_btn'.tr,
                              onPressFunction: () async {
                                final key = keyController.text.trim();
                                final username = loginController.text.trim();
                                final newPassword =
                                    newPasswordController.text.trim();

                                if (formKey.currentState!.validate()) {
                                  formKey.currentState!.save();

                                  try {
                                    EasyLoading.show(status: 'auth_updating'.tr);
                                    // await apiservice.updatePassword(
                                    //     key, username, newPassword);
                                    EasyLoading.showSuccess('auth_password_changed'.tr);
                                    await Future.delayed(
                                        const Duration(seconds: 1));
                                    EasyLoading.dismiss();
                                    context.route(const Login());
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
                              });
                        }),
                        80.0.heightbox,
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

    // Scaffold(
    //   appBar: AppBar(title: const Text("Update Password")),
    //   body: Padding(
    //     padding: defaultPadding(),
    //     child: Column(
    //       children: [
    //         PrimaryTextField(
    //           controller: keyController,
    //           labelText: "Reset Key",
    //         ),
    //         10.0.heightbox,
    //         PrimaryTextField(
    //           controller: loginController,
    //           labelText: "Login",
    //         ),
    //         10.0.heightbox,
    //         PrimaryTextField(
    //           controller: newPasswordController,
    //           labelText: "New Password",
    //           // obscureText: true,
    //         ),
    //         20.0.heightbox,
    //         Consumer<ApiServiceProvider>(builder: (cont, apiservice, _) {
    //           return PrimaryButton(
    //             buttonText: "Update Password",
    //             onPressFunction: () async {
    //               try {
    //                 EasyLoading.show(status: 'Updating...');
    //                 await apiservice.updatePassword(
    //                   keyController.text.trim(),
    //                   loginController.text.trim(),
    //                   newPasswordController.text.trim(),
    //                 );
    //                 EasyLoading.showSuccess('Password Updated');
    //                 await Future.delayed(const Duration(seconds: 1));
    //                 EasyLoading.dismiss();
    //                 context.routeoffall(const Login());
    //               } catch (error) {
    //                 EasyLoading.dismiss();
    //                 ScaffoldMessenger.of(context).showSnackBar(
    //                   SnackBar(
    //                       content: Text(
    //                           error.toString().replaceAll('Exception: ', ''))),
    //                 );
    //               }
    //             },
    //           );
    //         }),
    //       ],
    //     ),
    //   ),
    // );
  }
}
