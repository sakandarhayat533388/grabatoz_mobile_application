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
                    const Text('Change password',
                        style: TextStyle(
                            fontSize: 22.0,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryColor)),
                    10.0.heightbox,
                    const Text('Make a secure password for future log in.',
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
                      hintText: 'Old Password',
                    ),
                    15.0.heightbox,
                    GestureDetector(
                      onTap: () {
                        // context.route(const ForgetPassword());
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('Forget your Password?  ',
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
                        hintText: "New Password",
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
                        hintText: "Confirm Password",
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
                buttonText: "Save password",
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
