// ignore_for_file: use_build_context_synchronously

import 'package:get/get.dart';
import 'package:graba2z/Utils/appextensions.dart';
import 'package:graba2z/Utils/guest_checkout_storage.dart';
import 'package:graba2z/Views/Auth/signup.dart';
import '../../Utils/packages.dart';
import '../Home/home.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  late TextEditingController emailController;
  late TextEditingController passwordController;
  final formKey = GlobalKey<FormState>();

  bool _isCurvedContainerVisible = false; // For curved container
  bool _isBodyVisible = false; // For the form and content
  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();

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

  Future<void> clearGuestFlag() async {
    await clearGuestCheckoutData();
  }

  void _handleBackNavigation() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    Get.offAll(() => const Home());
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

    return Scaffold(
      appBar: CustomAppBar(
        leadingWidget: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: _handleBackNavigation,
        ),
        titleWidget: Image.asset(
          AppImages.logoicon,
          width: 100,
          height: 100,
          color: kdefwhiteColor,
        ),
      ),
      body: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeInOut,
            bottom: _isCurvedContainerVisible ? 0 : -screenHeight,
            child: CurvedBottomContainer(
              height: Get.height,
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  // crossAxisAlignment: CrossAxisAlignment.c,
                  children: [
                    50.0.heightbox,
                    //app logo
                    // Image.asset(
                    //   'assets/images/logoicon.png',
                    //   color: kdefwhiteColor,
                    //   width: 150,
                    // ),
                    // 50.0.heightbox,
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
                                    padding: const EdgeInsets.only(
                                        top: 8.0, left: 5),
                                    child: Text(
                                      emailvalidate
                                          .loginemailErrorMessage.value,
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
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                PrimaryTextField(
                                  controller: passwordController,
                                  onChanged: authProvider.validateLoginPassword,
                                  obsecure: authProvider.isPasswordObscure,
                                  suffix: GestureDetector(
                                    child: Icon(
                                      authProvider.isPasswordObscure
                                          ? Icons.lock
                                          : Icons.lock_open,
                                      color: kdefgreyColor,
                                    ),
                                    onTap: () {
                                      authProvider.togglePasswordVisibility();
                                    },
                                  ),
                                  hintText: 'Password',
                                ),
                                if (authProvider
                                    .loginpassworderrorMessage.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 8.0, left: 5),
                                    child: Text(
                                      authProvider
                                          .loginpassworderrorMessage.value,
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
                    40.0.heightbox,
                    GetBuilder<AuthController>(
                      builder: (authProvider) {
                        return PrimaryButton(
                          buttonColor: kdefwhiteColor,
                          textColor: kSecondaryColor,
                          buttonText: "Log In",
                          onPressFunction: () async {
                            final email = emailController.text.trim();
                            final password = passwordController.text.trim();
                            await clearGuestFlag();

                            authProvider.validateLoginPassword(password);
                            authProvider.validateLoginEmail(email);

                            if (emailController.text.isNotEmpty &&
                                passwordController.text.isNotEmpty) {
                              if (formKey.currentState!.validate()) {
                                formKey.currentState!.save();
                                print(email);
                                print(password);

                                try {
                                  EasyLoading.show(status: 'Logging in...');
                                  await authProvider.login(
                                      email, password, false);
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
                              }
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
        ],
      ),
    );
  }
}

class CurvedBottomContainer extends StatelessWidget {
  final double height;
  final double width;
  final Color color;
  final bool animate;

  const CurvedBottomContainer({
    required this.height,
    required this.width,
    required this.color,
    required this.animate,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: BottomCurvedClipper(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOut,
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: color,
        ),
      ),
    );
  }
}

class BottomCurvedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(
        0, size.height - 80); // Start at bottom-left corner (lower here)
    path.quadraticBezierTo(
        size.width / 2, size.height + 30, size.width, size.height - 80);
    path.lineTo(size.width, 0); // Line to top-right corner
    path.close(); // Close the path

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}
