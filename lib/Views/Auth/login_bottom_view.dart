// ignore_for_file: use_build_context_synchronously

import 'dart:developer';

import 'package:get/get.dart';
import 'package:graba2z/Api/Services/apiservices.dart';
import 'package:graba2z/Utils/appextensions.dart';
import 'package:graba2z/Views/Auth/signup.dart';
import '../../Utils/packages.dart';
import '../Home/home.dart';

class LoginViewBottom extends StatefulWidget {
  const LoginViewBottom({super.key});

  @override
  State<LoginViewBottom> createState() => _LoginViewBottomState();
}

class _LoginViewBottomState extends State<LoginViewBottom> {
  late TextEditingController emailController;
  late TextEditingController passwordController;
  final formKey = GlobalKey<FormState>();

  bool _isCurvedContainerVisible = false; // For curved container
  bool _isBodyVisible = false; // For the form and content

  AuthController _authControllera = Get.put(AuthController());
  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    _authControllera.loginemailErrorMessage.value = '';
    _authControllera.loginpassworderrorMessage.value = '';
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              // crossAxisAlignment: CrossAxisAlignment.c,
              children: [
                // 10.0.heightbox,
                // //app logo
                // Image.asset(
                //   'assets/images/logoicon.png',
                //   color: kdefwhiteColor,
                //   width: 150,
                // ),
                20.0.heightbox,
                const Text('Login',
                    style: TextStyle(
                        fontSize: 34.0,
                        fontWeight: FontWeight.bold,
                        color: kdefwhiteColor)),
                50.0.heightbox,
                Form(
                  key: formKey,
                  child: Column(
                    children: [
                      GetBuilder<AuthController>(builder: (
                        emailvalidate,
                      ) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PrimaryTextField(
                              onChanged: emailvalidate.validateLoginEmail,
                              controller: emailController,
                              // suffix: emailvalidate.isEmailValid
                              //     ? const Icon(
                              //         Icons.check,
                              //         size: 18,
                              //         color: kdefwhiteColor,
                              //       )
                              //     : null,
                              hintText: 'Email Address',
                            ),
                            if (emailvalidate
                                .loginemailErrorMessage.value.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 8.0, left: 5),
                                child: Text(
                                  emailvalidate.loginemailErrorMessage.value,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                          ],
                        );
                      }),
                      20.0.heightbox,
                      GetBuilder<AuthController>(builder: (
                        authProvider,
                      ) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PrimaryTextField(
                              controller: passwordController,
                              onChanged: authProvider.validateLoginPassword,
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
                              hintText: 'Password',
                            ),
                            if (authProvider
                                .loginpassworderrorMessage.value.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 8.0, left: 5),
                                child: Text(
                                  authProvider.loginpassworderrorMessage.value!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                20.0.heightbox,
                GestureDetector(
                  onTap: () {
                    context.route(const ForgetPassword());
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('Forget your Password?  ',
                          style: TextStyle(
                              color: kdefwhiteColor,
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600)),
                      Icon(
                        Icons.arrow_forward,
                        color: kdefwhiteColor,
                        size: 20,
                      ),
                    ],
                  ),
                ),
                20.0.heightbox,
                GetBuilder<AuthController>(
                  builder: (authProvider) {
                    final apiservice = Get.find<ApiServiceController>();

                    return PrimaryButton(
                      buttonColor: kdefwhiteColor,
                      textColor: kSecondaryColor,
                      buttonText: "Log In",
                      onPressFunction: () async {
                        final email = emailController.text.trim();
                        final password = passwordController.text.trim();

                        authProvider.validateLoginPassword(password);
                        authProvider.validateLoginEmail(email);
                        log("${authProvider.loginemailErrorMessage.isNotEmpty}");

                        if (emailController.text.isNotEmpty &&
                            passwordController.text.isNotEmpty) {
                          // if (formKey.currentState!.validate()) {
                          formKey.currentState!.save();
                          print(email);
                          print(password);

                          try {
                            EasyLoading.show(status: 'Logging in...');
                            await authProvider.login(email, password, true);
                          } catch (error) {
                            EasyLoading.dismiss();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  error
                                      .toString()
                                      .replaceAll('Exception: ', ''),
                                ),
                              ),
                            );
                          }
                          // }
                        }
                      },
                    );
                  },
                ),
                30.0.heightbox,
                GestureDetector(
                  onTap: () {
                    context.route(const SignUp());
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Don\'t have an account?',
                          style: TextStyle(
                              color: kdefwhiteColor,
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600)),
                      Text(' Sign Up',
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w600,
                            color: kSecondaryColor,
                          )),
                    ],
                  ),
                ),
                20.0.heightbox,

                70.0.heightbox,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
