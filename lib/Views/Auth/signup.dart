// ignore_for_file: use_build_context_synchronously

import 'package:get/get.dart';
import 'package:graba2z/Api/Services/apiservices.dart';
import 'package:graba2z/Services/referral_api.dart';
import 'package:graba2z/Utils/appextensions.dart';
import 'package:graba2z/Views/Auth/otp_view.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import '../../Utils/packages.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  TextEditingController firstnamecontroller = TextEditingController();
  TextEditingController lastnamecontroller = TextEditingController();
  TextEditingController emailcontroller = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  final TextEditingController referralCodeController =
      TextEditingController();
  String? _referralMessage;
  bool _referralValid = false;
  bool _referralChecking = false;
  final formKey = GlobalKey<FormState>();
  bool _isCurvedContainerVisible = false; // For curved container
  bool _isBodyVisible = false; // For the form and content
  @override
  void initState() {
    super.initState();
    firstnamecontroller = TextEditingController();
    lastnamecontroller = TextEditingController();
    emailcontroller = TextEditingController();
    passwordController = TextEditingController();
    phoneController = TextEditingController();
    addressController = TextEditingController();

    // Referral code prefill — the screen may be opened with a code
    // (deep link / navigation argument): a bare String, or a Map with a
    // 'refCode' / 'referralCode' key.
    try {
      final args = Get.arguments;
      String? prefilled;
      if (args is String) {
        prefilled = args;
      } else if (args is Map) {
        prefilled = (args['refCode'] ?? args['referralCode'])?.toString();
      }
      if (prefilled != null && prefilled.trim().isNotEmpty) {
        referralCodeController.text = prefilled.trim();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _validateReferralCode();
        });
      }
    } catch (_) {}

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
    firstnamecontroller.dispose();
    lastnamecontroller.dispose();
    emailcontroller.dispose();
    passwordController.dispose();
    phoneController.dispose();
    addressController.dispose();
    referralCodeController.dispose();

    super.dispose();
  }

  /// Validates the entered referral code against
  /// GET /api/referrals/validate/<code> (HTTP is always 200 — the
  /// `valid` field is the truth, not the status code).
  Future<void> _validateReferralCode() async {
    final code = referralCodeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _referralMessage = null;
        _referralValid = false;
      });
      return;
    }
    setState(() {
      _referralChecking = true;
      _referralMessage = null;
    });
    try {
      final v = await ReferralApi.validate(code);
      if (!mounted) return;
      setState(() {
        _referralValid = v.valid;
        if (v.valid) {
          _referralMessage =
              'referral_invited_by'.trParams({'name': v.firstName ?? ''});
        } else {
          final reason = v.reason ?? '';
          if (reason == 'programme_disabled') {
            _referralMessage = 'referral_invalid_programme_disabled'.tr;
          } else if (reason == 'empty') {
            _referralMessage = 'referral_invalid_empty'.tr;
          } else {
            _referralMessage = 'referral_invalid_unknown_code'.tr;
          }
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _referralValid = false;
        _referralMessage = 'referral_invalid_unknown_code'.tr;
      });
    } finally {
      if (mounted) {
        setState(() {
          _referralChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    // void showBackDialog(BuildContext context) {
    //   showDialog(
    //     context: context,
    //     builder: (BuildContext context) {
    //       return Dialog(
    //         shape: RoundedRectangleBorder(
    //           borderRadius: BorderRadius.circular(16),
    //         ),
    //         child: Container(
    //           decoration: BoxDecoration(
    //               borderRadius: BorderRadius.circular(12),
    //               color: kdefwhiteColor),
    //           padding: const EdgeInsets.all(18),
    //           child: Column(
    //             mainAxisSize: MainAxisSize.min,
    //             children: <Widget>[
    //               const Row(
    //                 children: [
    //                   Icon(Icons.warning, color: Colors.red),
    //                   SizedBox(width: 8),
    //                   Text(
    //                     'Are you sure?',
    //                     style: TextStyle(
    //                       fontSize: 22,
    //                       fontWeight: FontWeight.bold,
    //                       color: kPrimaryColor,
    //                     ),
    //                   ),
    //                 ],
    //               ),
    //               const SizedBox(height: 10),
    //               const Text('Do you want to exit the App?'),
    //               const SizedBox(height: 20),
    //               Row(
    //                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    //                 children: <Widget>[
    //                   Container(
    //                     width: 100,
    //                     decoration: BoxDecoration(
    //                       color: kPrimaryColor,
    //                       borderRadius: BorderRadius.circular(60),
    //                     ),
    //                     child: TextButton(
    //                       onPressed: () {
    //                         SystemNavigator.pop();
    //                       },
    //                       child: const Text(
    //                         'Yes',
    //                         style: TextStyle(
    //                             color: kdefwhiteColor,
    //                             fontWeight: FontWeight.bold),
    //                       ),
    //                     ),
    //                   ),
    //                   Container(
    //                     width: 100,
    //                     decoration: BoxDecoration(
    //                       color: kdefwhiteColor,
    //                       borderRadius: BorderRadius.circular(60),
    //                       border: Border.all(color: kdefgreyColor),
    //                     ),
    //                     child: TextButton(
    //                       onPressed: () {
    //                         Navigator.of(context).pop(); // Close the dialog
    //                       },
    //                       child: const Text('No',
    //                           style: TextStyle(
    //                               color: kmediumblackColor,
    //                               fontWeight: FontWeight.bold)),
    //                     ),
    //                   ),
    //                 ],
    //               ),
    //             ],
    //           ),
    //         ),
    //       );
    //     },
    //   );
    // }

    return Scaffold(
        appBar: CustomAppBar(
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
              width: MediaQuery.of(context).size.width,
              color: kPrimaryColor,
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    50.0.heightbox,
                    Text('auth_signup_title'.tr,
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
                            authProvider,
                          ) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                PrimaryTextField(
                                  onChanged: authProvider.validatefirstname,
                                  hintText: 'auth_name_hint'.tr,
                                  controller: firstnamecontroller,
                                ),
                                if (authProvider.firstnamemessage != null)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 8.0, left: 5),
                                    child: Text(
                                      authProvider.firstnamemessage!,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                              ],
                            );
                          }),
                          // 25.0.heightbox,
                          // GetBuilder<AuthController>(builder: (
                          //   authProvider,
                          // ) {
                          //   return Column(
                          //     crossAxisAlignment: CrossAxisAlignment.start,
                          //     children: [
                          //       PrimaryTextField(
                          //         onChanged: authProvider.validatelastname,
                          //         hintText: 'Last Name',
                          //         controller: lastnamecontroller,
                          //       ),
                          //       if (authProvider.lastnamemessage != null)
                          //         Padding(
                          //           padding: const EdgeInsets.only(
                          //               top: 8.0, left: 5),
                          //           child: Text(
                          //             authProvider.lastnamemessage!,
                          //             style: const TextStyle(color: Colors.red),
                          //           ),
                          //         ),
                          //     ],
                          //   );
                          // }),
                          25.0.heightbox,
                          GetBuilder<AuthController>(builder: (
                            authProvider,
                          ) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                PrimaryTextField(
                                  controller: emailcontroller,
                                  onChanged: authProvider.validateSignupEmail,
                                  suffix: authProvider.isEmailValid
                                      ? const Icon(
                                          Icons.check,
                                          color: kdefwhiteColor,
                                        )
                                      : null,
                                  hintText: 'auth_email_hint'.tr,
                                ),
                                if (authProvider.emailErrorMessage != null)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 8.0, left: 5),
                                    child: Text(
                                      authProvider.emailErrorMessage!,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                              ],
                            );
                          }),
                          25.0.heightbox,
                          GetBuilder<AuthController>(builder: (
                            authProvider,
                          ) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                PrimaryTextField(
                                  controller: passwordController,
                                  onChanged:
                                      authProvider.validateSignupPassword,
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
                                  hintText: 'auth_password_hint'.tr,
                                ),
                                if (authProvider.passwordErrorMessage != null)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 8.0, left: 5),
                                    child: Text(
                                      authProvider.passwordErrorMessage!,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                              ],
                            );
                          }),
                          25.0.heightbox,

                          // Referral code (optional) — PrimaryTextField has
                          // no label/title and no onFieldSubmitted param, so
                          // the label is a Text above the field and
                          // validation runs from the Verify button below it.
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 5, bottom: 8),
                                child: Text(
                                  'referral_code_field'.tr,
                                  style: const TextStyle(
                                      color: kdefwhiteColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              PrimaryTextField(
                                controller: referralCodeController,
                                hintText: 'referral_code_hint'.tr,
                                onChanged: (_) {
                                  // Editing the code invalidates any
                                  // previous validation result.
                                  if (_referralMessage != null ||
                                      _referralValid) {
                                    setState(() {
                                      _referralMessage = null;
                                      _referralValid = false;
                                    });
                                  }
                                },
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 8.0, left: 5),
                                child: Row(
                                  children: [
                                    TextButton(
                                      onPressed: _referralChecking
                                          ? null
                                          : _validateReferralCode,
                                      style: TextButton.styleFrom(
                                        foregroundColor: kSecondaryColor,
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text('referral_verify'.tr,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                    if (_referralChecking) ...[
                                      const SizedBox(width: 10),
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: kdefwhiteColor,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (_referralMessage != null)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 8.0, left: 5),
                                  child: Text(
                                    _referralMessage!,
                                    style: TextStyle(
                                        color: _referralValid
                                            ? Colors.green
                                            : Colors.red),
                                  ),
                                ),
                            ],
                          ),
                          25.0.heightbox,

                          // GetBuilder<AuthController>(
                          //   builder: (
                          //     authProvider,
                          //   ) {
                          //     return Column(
                          //       crossAxisAlignment: CrossAxisAlignment.start,
                          //       children: [
                          //         Container(
                          //           height: 55,
                          //           width: Get.width *
                          //               0.85, // Slightly wider for better UX
                          //           padding: const EdgeInsets.symmetric(
                          //               horizontal: 16),
                          //           decoration: BoxDecoration(
                          //             color: kPrimaryColor,
                          //             boxShadow: defaultBoxShadow,
                          //             borderRadius: BorderRadius.circular(60),
                          //             border: Border.all(
                          //                 color: kdefwhiteColor, width: 1),
                          //           ),
                          //           child: Center(
                          //             child: IntlPhoneField(
                          //               pickerDialogStyle: PickerDialogStyle(),
                          //               cursorColor: kdefwhiteColor,
                          //               controller: phoneController,
                          //               style: const TextStyle(
                          //                   color: kdefwhiteColor),
                          //               dropdownIcon: const Icon(
                          //                   Icons.arrow_drop_down,
                          //                   color: kdefwhiteColor),
                          //               decoration: const InputDecoration(
                          //                 counterText: '',
                          //                 counterStyle:
                          //                     TextStyle(color: kdefwhiteColor),
                          //                 contentPadding: EdgeInsets.symmetric(
                          //                     vertical: 11),
                          //                 iconColor: kdefwhiteColor,
                          //                 prefixIconColor: kdefwhiteColor,
                          //                 suffixIconColor: kdefwhiteColor,
                          //                 hintText: 'Phone Number',
                          //                 border: InputBorder.none,
                          //                 hintStyle: TextStyle(
                          //                   color: Colors.white70,
                          //                   fontSize: 14,
                          //                   fontWeight: FontWeight.w600,
                          //                 ),
                          //               ),
                          //               initialCountryCode: 'AE',
                          //               dropdownTextStyle: const TextStyle(
                          //                 color: kdefwhiteColor,
                          //               ),
                          //               onChanged: (phone) {
                          //                 authProvider.validatephonenumber(
                          //                     phone.completeNumber);
                          //               },
                          //             ),
                          //           ),
                          //         ),
                          //         if (authProvider.phoneNumberErrorMessage !=
                          //             null)
                          //           Padding(
                          //             padding: const EdgeInsets.only(
                          //                 top: 8.0, left: 5),
                          //             child: Text(
                          //               authProvider.phoneNumberErrorMessage!,
                          //               style:
                          //                   const TextStyle(color: kredColor),
                          //             ),
                          //           ),
                          //       ],
                          //     );
                          //   },
                          // ),

                          // Consumer<AuthProvider>(
                          //     builder: (cont, authProvider, _) {
                          //   return Column(
                          //     crossAxisAlignment: CrossAxisAlignment.start,
                          //     children: [
                          //       PrimaryTextField(
                          //         maxLength: 10,
                          //         keyboardType: TextInputType.phone,
                          //         hintText: "Phone Number",
                          //         controller: phoneController,
                          //         onChanged: authProvider.validatephonenumber,
                          //       ),
                          //       if (authProvider.phoneNumberErrorMessage !=
                          //           null)
                          //         Padding(
                          //           padding: const EdgeInsets.only(
                          //               top: 8.0, left: 5),
                          //           child: Text(
                          //             authProvider.phoneNumberErrorMessage!,
                          //             style: const TextStyle(color: Colors.red),
                          //           ),
                          //         ),
                          //     ],
                          //   );
                          // }),
                          /*       25.0.heightbox,
                          GetBuilder<AuthController>(builder: (
                            authProvider,
                          ) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                PrimaryTextField(
                                  hintText: "Address",
                                  controller: addressController,
                                  onChanged: authProvider.validateaddress,
                                ),
                                if (authProvider.addressErrorMessage != null)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 8.0, left: 5),
                                    child: Text(
                                      authProvider.addressErrorMessage!,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                              ],
                            );
                          }),
                     */
                        ],
                      ),
                    ),
                    40.0.heightbox,
                    GetBuilder<AuthController>(
                      builder: (authProvider) {
                        return PrimaryButton(
                          buttonColor: kdefwhiteColor,
                          textColor: kSecondaryColor,
                          buttonText: 'auth_signup_title'.tr,
                          onPressFunction: () async {
                            final firstname = firstnamecontroller.text.trim();
                            final email = emailcontroller.text.trim();
                            final password = passwordController.text.trim();
                            // final lastName = lastnamecontroller.text.trim();
                            // final phoneNumber = phoneController.text.trim();
                            // final address = addressController.text.trim();

                            authProvider.validatefirstname(firstname);
                            authProvider.validateSignupEmail(email);
                            authProvider.validateSignupPassword(password);
                            // authProvider.validatelastname(lastName);
                            // authProvider.validatephonenumber(phoneNumber);
                            // authProvider.validateaddress(address);

                            if (authProvider.firstnamemessage == null &&
                                authProvider.emailErrorMessage == null &&
                                authProvider.passwordErrorMessage == null) {
                              if (formKey.currentState!.validate()) {
                                formKey.currentState!.save();

                                try {
                                  EasyLoading.show(status: 'auth_signing_up'.tr);

                                  // TODO(backend): 'referralCode' field name
                                  // assumed — confirm with backend (plan
                                  // open question 2). Passed through to
                                  // AuthController.signUp, which includes it
                                  // in the register payload when non-empty.
                                  final referralCode =
                                      referralCodeController.text.trim();

                                  await authProvider.signUp(
                                    firstname,
                                    email,
                                    password,
                                    referralCode:
                                        referralCode.isEmpty ? null : referralCode,
                                  );

                                  await Future.delayed(
                                      const Duration(seconds: 1));
                                  EasyLoading.dismiss();

                                  // context.routeoffall(const Login());
                                } catch (error) {
                                  EasyLoading.dismiss();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(error.toString())),
                                  );
                                }
                              }
                            }
                          },
                        );
                      },
                    ),
                    20.0.heightbox,
                    GestureDetector(
                      onTap: () {
                        context.route(const Login());
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'auth_already_have_account'.tr + ' ',
                            style: TextStyle(
                                color: kdefwhiteColor,
                                fontSize: 14.0,
                                fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'auth_login_title'.tr,
                            style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.w600,
                                color: kSecondaryColor),
                          ),
                        ],
                      ),
                    ),
                    90.0.heightbox,
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
