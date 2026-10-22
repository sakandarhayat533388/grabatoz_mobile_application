import 'package:get/get.dart';
import 'package:graba2z/Utils/appextensions.dart';
import '../../../../../../../Utils/packages.dart';

class ChangePassword extends StatelessWidget {
  const ChangePassword({super.key});

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();

    final authProvider = Get.find<AuthController>();

    final oldpasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmpasswordcontroller = TextEditingController();

    return GestureDetector(
      onTap: () {
        hideKeyboard(context);
      },
      child: Scaffold(
        body: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              20.0.heightbox,
              Padding(
                padding: defaultPadding(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('profile_change_password'.tr,
                        style: TextStyle(
                            fontSize: 22.0,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryColor)),
                    10.0.heightbox,
                    Text('profile_secure_password_hint'.tr,
                        style:
                            TextStyle(fontSize: 15.0, color: kdefblackColor)),
                    30.0.heightbox,
                    PrimaryTextField(
                      controller: oldpasswordController,
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
                      hintText: 'profile_old_password'.tr,
                    ),
                    15.0.heightbox,
                    GestureDetector(
                      onTap: () {
                        // context.route(const ForgetPassword());
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('profile_forgot_password'.tr,
                              style: TextStyle(
                                  fontSize: 14.0, fontWeight: FontWeight.w600)),
                          Icon(
                            Icons.arrow_forward,
                            color: kPrimaryColor,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                    15.0.heightbox,
                    GetBuilder<AuthController>(builder: (
                      authProvider,
                    ) {
                      return PrimaryTextField(
                        controller: newPasswordController,
                        hintText: 'profile_new_password'.tr,
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
                    15.0.heightbox,
                    GetBuilder<AuthController>(builder: (
                      authProvider,
                    ) {
                      return PrimaryTextField(
                        controller: confirmpasswordcontroller,
                        hintText: 'profile_confirm_password'.tr,
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
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: defaultPadding(vertical: 10),
            child: PrimaryButton(
                buttonText: 'profile_save_password'.tr,
                onPressFunction: () {
                  // context.routeoffall(const PasswordConfirmScreen());
                  Navigator.pop(context);
                }),
          ),
        ),
      ),
    );
  }
}
