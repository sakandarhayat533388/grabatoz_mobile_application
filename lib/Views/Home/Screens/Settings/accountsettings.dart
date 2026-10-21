// ignore_for_file: use_build_context_synchronously

import 'dart:developer';

import 'package:get/get.dart';
import 'package:graba2z/Utils/appextensions.dart';
import 'package:graba2z/Views/Home/Screens/Cart/cart.dart';
import 'package:graba2z/Views/Home/Screens/Favorite%20Product/favproduct_screen.dart';
import 'package:graba2z/Views/Home/Screens/Settings/Modules/Notification%20Toggle/notificationtoggle.dart';
import 'package:graba2z/Views/Home/Screens/Settings/Modules/Order%20History/track_order_view.dart';
import 'package:graba2z/Views/Home/Screens/banner%20redirect/bannerredirect.dart';
import 'package:graba2z/Views/Home/home.dart';
import 'package:graba2z/Widgets/secondarybutton.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:graba2z/Services/notification_permission_preloader.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../../Controllers/addtocart.dart';
import '../../../../Utils/packages.dart';
import '../../../../Widgets/footertile.dart';
import '../../../../Widgets/socialicon.dart';
import '../../../Auth/signup.dart';
import 'Modules/profile_menu_screen.dart';
import 'package:graba2z/Controllers/country_controller.dart';
import 'package:graba2z/Controllers/language_controller.dart';
import 'package:graba2z/Widgets/country_selector.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  // Optional: call this instead of Navigator.push to ensure preloaded state
  static Future<void> open(BuildContext context) async {
    await NotificationPermissionPreloader.preload();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const Settings()),
    );
  }

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final ScrollController _scrollController = ScrollController();

  getUserData() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    name = sp.getString('userName') ?? '';
    email = sp.getString('userEmail') ?? '';
    print('its initstae ${sp.getString('token')}');
    setState(() {});
  }

  String name = '';
  String email = '';
  Future<bool>? _notifInitialFuture;

  @override
  void initState() {
    super.initState();
    getUserData();
    _authController.loadUserData();

    // Kick preloading early; uses cache for instant first frame
    NotificationPermissionPreloader.preload();
    // Preload effective notification state (userPref AND OS permission)
    _notifInitialFuture = _loadInitialNotificationEffective();
  }

  Future<void> _launchURL(String url) async {
    if (url.isEmpty) {
      print('URL is empty, cannot launch.');
      Get.snackbar("Error", "Link is not available.",
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    try {
      if (await canLaunchUrlString(url)) {
        await launchUrlString(url);
      } else {
        print('Could not launch $url (canLaunchUrlString returned false).');
        Get.snackbar("Error", "Could not open link.",
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      print('Exception trying to launch $url: $e');
      Get.snackbar("Error", "Error opening link.",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _scrollToTop() {
    // Renamed and updated method
    _scrollController.animateTo(
      0.0, // Scroll to the top of the scroll view
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<bool> _loadInitialNotificationEffective() async {
    final prefs = await SharedPreferences.getInstance();
    final userPref = prefs.getBool('notification_enabled') ?? false;
    final osAllowed = await AwesomeNotifications().isNotificationAllowed();
    return userPref && osAllowed;
  }

  AuthController _authController = Get.put(AuthController());

  @override
  Widget build(BuildContext context) {
    final navigationProvider = Get.put(BottomNavigationController());
    return Scaffold(
      appBar: CustomAppBar(
        titleText: "Settings",
        showLeading: true,
        leadingWidget: Builder(
          builder: (context) {
            return IconButton(
              onPressed: () {
                navigationProvider.setTabIndex(0);
              },
              icon: const Icon(Icons.arrow_back_ios, size: 20),
            );
          },
        ),
        actionicon: GetBuilder<CartNotifier>(
          builder: (
            cartNotifier,
          ) {
            return Stack(
              alignment: Alignment.topRight,
              children: [
                // The cart icon
                GestureDetector(
                  onTap: () {
                    context.route(Cart());
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 5.0),
                    child: Image.asset(
                      "assets/icons/addcart.png",
                      color: kdefwhiteColor,
                      width: 28,
                      height: 28,
                    ),
                  ),
                ),

                // The dynamic badge showing cart count
                if (cartNotifier.cartOtherInfoList.isNotEmpty) ...[
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: const BoxDecoration(
                        color: kredColor,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        cartNotifier.cartOtherInfoList.length.toString(),
                        style: const TextStyle(
                          color: kdefwhiteColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: defaultPadding(),
                child: defaultStyledContainer(
                  margin: const EdgeInsets.only(top: 15),
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      const CircleAvatar(
                          radius: 20,
                          child: Icon(
                            Icons.person,
                            size: 25,
                          )),
                      20.0.widthbox,
                      Expanded(
                        child: GetBuilder<AuthController>(builder: (
                          authProvider,
                        ) {
                          if (authProvider.userID.isNotEmpty) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "$name",
                                  style: Get.textTheme.headlineSmall!.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: kSecondaryColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                Text(
                                  email,
                                  style: Get.textTheme.bodyLarge!.copyWith(
                                    color: kSecondaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            );
                          } else {
                            // If not logged in, show Guest User info and a login button
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Guest",
                                  style: Get.textTheme.headlineSmall!.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: kSecondaryColor),
                                ),

                                const SizedBox(height: 5),
                                // Spacer between text and button
                                SecondaryButton(
                                  buttonColor: kPrimaryColor,
                                  textColor: kdefwhiteColor,
                                  onPressFunction: () {
                                    // Navigate to Login screen
                                    context.route(Login());
                                  },
                                  buttonText: "Login",
                                ),
                              ],
                            );
                          }
                        }),
                      )
                    ],
                  ),
                ),
              ),
              20.0.heightbox,
              Padding(
                padding: defaultPadding(),
                child: defaultStyledContainer(
                  padding: EdgeInsets.zero,
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      GetBuilder<AuthController>(builder: (authprovider) {
                        if (authprovider.userID.value.isNotEmpty) {
                          return Column(
                            children: [
                              ListTile(
                                minLeadingWidth: 0,
                                onTap: () => Get.to(() => const ProfileMenuScreen()),
                                leading: Image.asset("assets/icons/profile.png",
                                    color: kSecondaryColor,
                                    width: 20,
                                    height: 20),
                                title: const Text('Your Profile',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  color: kSecondaryColor,
                                  size: 16,
                                ),
                              ),
                              Divider(
                                height: 0,
                                color: Colors.grey.withValues(alpha: .2),
                              ),
                            ],
                          );
                        } else {
                          return Container();
                        }
                      }),

                      //wishlist
                      GetBuilder<AuthController>(builder: (
                        authprovider,
                      ) {
                        if (authprovider.userID.isNotEmpty) {
                          return Column(
                            children: [
                              ListTile(
                                minLeadingWidth: 0,
                                onTap: () {
                                  context.route(const OrderHistoryScreen());
                                },
                                leading: Image.asset("assets/icons/myorder.png",
                                    color: kSecondaryColor,
                                    width: 20,
                                    height: 20),
                                title: Text('Order History',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    )),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  color: kSecondaryColor,
                                  size: 16,
                                ),
                              ),
                              Divider(
                                height: 0,
                                color: Colors.grey.withValues(alpha: .2),
                              ),
                            ],
                          );
                        } else {
                          return Container();
                        }
                      }),
                      GetBuilder<AuthController>(builder: (
                        authprovider,
                      ) {
                        return Column(
                          children: [
                            ListTile(
                              minLeadingWidth: 0,
                              onTap: () {
                                context.route(TrackOrderScreen());
                              },
                              leading: Icon(Icons.local_shipping),
                              title: Text('Track Order',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  )),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                color: kSecondaryColor,
                                size: 16,
                              ),
                            ),
                            Divider(
                              height: 0,
                              color: Colors.grey.withValues(alpha: .2),
                            ),
                          ],
                        );
                      }),
                      GetBuilder<AuthController>(builder: (
                        authprovider,
                      ) {
                        if (authprovider.userID.isNotEmpty) {
                          return ListTile(
                            minLeadingWidth: 0,
                            onTap: () {
                              context.route(const Favorite());
                            },
                            leading: Image.asset("assets/icons/favor.png",
                                color: kSecondaryColor, width: 20, height: 20),
                            title: const Text('My WishList',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600)),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: kSecondaryColor,
                            ),
                          );
                        } else {
                          return Container();
                        }
                      }),
                      Divider(
                        height: 0,
                        color: Colors.grey.withValues(alpha: .2),
                      ),
                      10.0.heightbox,

                      // Render immediately using cached/preloaded state (no FutureBuilder)
                      NotificationTile(
                        initialValue:
                            NotificationPermissionPreloader.effectiveOrFalse,
                        key: ValueKey(
                            NotificationPermissionPreloader.effectiveOrFalse),
                      ),

                      Divider(
                        height: 0,
                        color: Colors.grey.withValues(alpha: .2),
                      ),

                      // Country / Currency — visible to guests too
                      Obx(() {
                        final cc = Get.isRegistered<CountryController>()
                            ? Get.find<CountryController>()
                            : null;
                        final selected = cc?.selectedCountry.value;
                        return ListTile(
                          minLeadingWidth: 0,
                          onTap: () => showCountrySelector(context),
                          leading: selected == null
                              ? const Icon(Icons.public_outlined,
                                  color: kSecondaryColor, size: 20)
                              : CountryFlag(selected.flagSvg,
                                  width: 32, height: 22),
                          title: const Text('Country / Currency',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600)),
                          subtitle: selected == null
                              ? null
                              : Text(
                                  '${selected.name} (${selected.currencyCode})',
                                  style: const TextStyle(fontSize: 11),
                                ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: kSecondaryColor,
                          ),
                        );
                      }),
                      Divider(
                        height: 0,
                        color: Colors.grey.withValues(alpha: .2),
                      ),

                      // Language — visible to guests too
                      Obx(() {
                        final lc = Get.isRegistered<LanguageController>()
                            ? Get.find<LanguageController>()
                            : null;
                        final isAr = lc?.isArabic ?? false;
                        return ListTile(
                          minLeadingWidth: 0,
                          onTap: () => showLanguageSelector(context),
                          leading: const Icon(Icons.language_outlined,
                              color: kSecondaryColor, size: 20),
                          title: Text('language'.tr,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            isAr ? 'العربية' : 'English',
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: kSecondaryColor,
                          ),
                        );
                      }),
                      Divider(
                        height: 0,
                        color: Colors.grey.withValues(alpha: .2),
                      ),

                      ListTile(
                        minLeadingWidth: 0,
                        onTap: () async {
                          await launchUrl(
                            Uri.parse(
                              'https://graba2z.ae/about',
                            ),
                          );
                          // context.route(const AboutUsScreen());
                        },
                        leading: Image.asset("assets/icons/info.png",
                            color: kSecondaryColor, width: 20, height: 20),
                        title: const Text('About Us',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: kSecondaryColor,
                        ),
                      ),
                      Divider(
                        height: 0,
                        color: Colors.grey.withValues(alpha: .2),
                      ),
                      ListTile(
                        minLeadingWidth: 0,
                        onTap: () async {
                          await launchUrl(
                            Uri.parse("https://graba2z.ae/privacy-policy"),
                          );
                          // context.route(const PrivacyPolicyScreen());
                        },
                        leading: Image.asset("assets/icons/policy.png",
                            color: kSecondaryColor, width: 20, height: 20),
                        title: const Text('Privacy Policy',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: kSecondaryColor,
                        ),
                      ),
                      Divider(
                        height: 0,
                        color: Colors.grey.withValues(alpha: .2),
                      ),
                      ListTile(
                        minLeadingWidth: 0,
                        onTap: () async {
                          await launchUrl(
                            Uri.parse("https://graba2z.ae/terms-conditions/"),
                          );
                          // context.route(const TermsAndConditionsScreen());
                        },
                        leading: Image.asset("assets/icons/terms.png",
                            color: kSecondaryColor, width: 20, height: 20),
                        title: const Text('Terms & Conditions',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          color: kSecondaryColor,
                          size: 16,
                        ),
                      ),
                      Divider(
                        height: 0,
                        color: Colors.grey.withValues(alpha: .2),
                      ),
                      // Divider(
                      //   height: 0,
                      //   color: Colors.grey.withValues(alpha: .2),
                      // ),
                      // ListTile(
                      //   minLeadingWidth: 0,
                      //   onTap: () async {
                      //     const url = 'https://grabatoz.ae/contact-grabatoz/';

                      //     final Uri uri = Uri.parse(url);

                      //     // Check if the URL can be launched
                      //     if (await canLaunchUrl(uri)) {
                      //       await launchUrl(uri); // Launch the URL
                      //     } else {
                      //       // Handle the case where the URL can't be launched
                      //       print('Could not launch $url');
                      //     }
                      //   },
                      //   leading: Image.asset("assets/icons/contact.png",
                      //       color: kSecondaryColor, width: 20, height: 20),
                      //   title: const Text('Contact Us',
                      //       style: TextStyle(
                      //           fontSize: 12, fontWeight: FontWeight.w600)),
                      //   trailing: const Icon(
                      //     Icons.arrow_forward_ios,
                      //     color: kSecondaryColor,
                      //     size: 16,
                      //   ),
                      // ),
                      // Divider(
                      //   height: 0,
                      //   color: Colors.grey.withValues(alpha: .2),
                      // ),
                      GetBuilder<AuthController>(
                        builder: (
                          authprovider,
                        ) {
                          if (authprovider.userID.isNotEmpty) {
                            return ListTile(
                              minLeadingWidth: 0,
                              onTap: () {
                                showModalBottomSheet(
                                  backgroundColor: kdefwhiteColor,
                                  context: context,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(12)),
                                  ),
                                  builder: (BuildContext context) {
                                    return SafeArea(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text(
                                              'Logout',
                                              style: TextStyle(
                                                fontSize: 20,
                                                color: kPrimaryColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Divider(
                                                color: kdefgreyColor.withValues(
                                                    alpha: .2)),
                                            const Text(
                                              'Are you sure you want to log out?',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: kmediumblackColor,
                                              ),
                                            ),
                                            16.0.heightbox,
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                Expanded(
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 12.0,
                                                          horizontal: 32.0),
                                                      decoration: BoxDecoration(
                                                        border: Border.all(
                                                            color:
                                                                kPrimaryColor),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                      child: const Center(
                                                        child: Text(
                                                          'Cancel',
                                                          style: TextStyle(
                                                              color:
                                                                  kPrimaryColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                15.0.widthbox,
                                                Expanded(
                                                  child: GestureDetector(
                                                    onTap: () async {
                                                      final authProvider =
                                                          Get.find<
                                                              AuthController>();
                                                      Navigator.pop(context);
                                                      authProvider.logout();

                                                      // Clear SharedPreferences
                                                      final prefs =
                                                          await SharedPreferences
                                                              .getInstance();
                                                      await prefs
                                                          .remove('userId');

                                                      // Reset the bottom navigation index (assuming you have a provider for it)
                                                      final bottomNavProvider =
                                                          Get.find<
                                                              BottomNavigationController>();
                                                      bottomNavProvider
                                                          .setTabIndex(0);

                                                      // // Navigate to Login screen and clear all previous screens
                                                      Navigator
                                                          .pushAndRemoveUntil(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                const Home()),
                                                        (Route<dynamic>
                                                                route) =>
                                                            false,
                                                      );
                                                    },
                                                    child: Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 12.0,
                                                          horizontal: 32.0),
                                                      decoration: BoxDecoration(
                                                        color: kPrimaryColor,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                      child: const Center(
                                                        child: Text(
                                                          'Yes, Logout',
                                                          style: TextStyle(
                                                              color:
                                                                  kdefwhiteColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            10.0.heightbox,
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                              leading: Image.asset("assets/icons/logout.png",
                                  color: kSecondaryColor,
                                  width: 20,
                                  height: 20),
                              title: const Text('Logout',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: kSecondaryColor,
                              ),
                            );
                          } else {
                            return Container();
                            // return ListTile(
                            //   minLeadingWidth: 0,
                            //   onTap: () {
                            //     // Navigate to Login screen
                            //     context.route(Login());
                            //   },
                            //   leading: Image.asset("assets/icons/login.png",
                            //       color: kSecondaryColor, width: 20, height: 20),
                            //   title: const Text('Login',
                            //       style: TextStyle(
                            //           fontSize: 12, fontWeight: FontWeight.w600)),
                            //   trailing: const Icon(
                            //     Icons.arrow_forward_ios,
                            //     size: 16,
                            //     color: kSecondaryColor,
                            //   ),
                            // );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              20.0.heightbox,
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 17.0),
                child: Column(
                  children: [
                    // const Text(
                    //   "Core Service Aspects",
                    //   style: TextStyle(
                    //     fontSize: 16,
                    //     fontWeight: FontWeight.bold,
                    //     color: kSecondaryColor,
                    //   ),
                    //   textAlign: TextAlign.center,
                    // ),
                    // const SizedBox(height: 20),

                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    //   children: const [
                    //     ServiceCard(
                    //       image: "assets/images/wallet.png",
                    //       title: "Secure Payment Method",
                    //       subtitle: "Available Different secure Payment Methods",
                    //     ),
                    //     ServiceCard(
                    //       image: "assets/images/delivery.png",
                    //       title: "Extreme Fast Delivery",
                    //       subtitle: "Fast and convenient From door to door delivery",
                    //     ),
                    //   ],
                    // ),
                    // SizedBox(height: 20), SizedBox(height: 20),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    //   children: const [
                    //     ServiceCard(
                    //       image: "assets/images/heart.png",
                    //       title: "Quality & Savings",
                    //       subtitle: "Comprehensive quality control and affordable price",
                    //     ),
                    //     ServiceCard(
                    //       image: "assets/images/headphone1.png",
                    //       title: "Professional Support",
                    //       subtitle: "Efficient customer support from passionate team",
                    //     ),
                    //   ],
                    // ),
                    // 40.0.heightbox,
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 0.0, vertical: 0.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FooterTile(
                            title: "Categories",
                            children: [
                              ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  visualDensity: VisualDensity(vertical: -4),
                                  title: Text(
                                    "Accessories & Components",
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => bannerProduct(
                                                  brandname:
                                                      "Accessories",
                                                  displayTitle:
                                                      "Accessories & Components",
                                                )));
                                  }),
                              ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  visualDensity: VisualDensity(vertical: -4),
                                  title: Text(
                                    "All in one",
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => bannerProduct(
                                                  brandname: "All in one",
                                                  displayTitle: "All in one",
                                                )));
                                  }),
                              ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  visualDensity: VisualDensity(vertical: -4),
                                  title: Text(
                                    "Desktop",
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => bannerProduct(
                                                  brandname: "Desktop",
                                                  displayTitle: "Desktop",
                                                )));
                                  }),
                              ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  visualDensity: VisualDensity(vertical: -4),
                                  title: Text(
                                    "Laptops",
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => bannerProduct(
                                                  brandname: "Laptops",
                                                  displayTitle: "Laptops",
                                                )));
                                  }),
                              ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  visualDensity: VisualDensity(vertical: -4),
                                  title: Text(
                                    "Mobiles",
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => bannerProduct(
                                                  brandname: "Mobiles",
                                                  displayTitle: "Mobiles",
                                                )));
                                  }),
                              ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  visualDensity: VisualDensity(vertical: -4),
                                  title: Text(
                                    "Monitors",
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => bannerProduct(
                                                  brandname: "Monitors",
                                                  displayTitle: "Monitors",
                                                )));
                                  }),
                              ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  visualDensity: VisualDensity(vertical: -4),
                                  title: Text(
                                    "Networking",
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => bannerProduct(
                                                  brandname: "Networking",
                                                  displayTitle: "Networking",
                                                )));
                                  }),
                              ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  visualDensity: VisualDensity(vertical: -4),
                                  title: Text(
                                    "Printers & Copier",
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => bannerProduct(
                                                  brandname:
                                                      "Print",
                                                  displayTitle:
                                                      "Printers & Copier",
                                                )));
                                  }),
                              ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  visualDensity: VisualDensity(vertical: -4),
                                  title: Text(
                                    "Projector",
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => bannerProduct(
                                                  brandname: "Projector",
                                                  displayTitle: "Projector",
                                                )));
                                  }),
                              ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  visualDensity: VisualDensity(vertical: -4),
                                  title: Text(
                                    "Routers & Switches",
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => bannerProduct(
                                                  displayTitle:
                                                      "Routers & Switches",
                                                  brandname:
                                                      "Routers & Switches",
                                                )));
                                  }),
                            ],
                          ),
                          Divider(height: 1, color: Color(0xFFEEEEEE)),
                          FooterTile(
                            title: "Legal",
                            children: [
                              ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                visualDensity: VisualDensity(vertical: -4),
                                title: Text(
                                  "About Us",
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500),
                                ),
                                onTap: () =>
                                    _launchURL("https://www.grabatoz.ae/about"),
                              ),
                              ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                visualDensity: VisualDensity(vertical: -4),
                                title: Text(
                                  "Contact Us",
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500),
                                ),
                                onTap: () => _launchURL(
                                    "https://www.grabatoz.ae/contact"),
                              ),
                              ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                visualDensity: VisualDensity(vertical: -4),
                                title: Text(
                                  "Blog",
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500),
                                ),
                                onTap: () =>
                                    _launchURL("https://blog.grabatoz.ae/"),
                              ),
                              ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                visualDensity: VisualDensity(vertical: -4),
                                title: Text(
                                  "Shop",
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500),
                                ),
                                onTap:
                                    _scrollToTop, // Updated onTap to call _scrollToTop
                              ),
                              ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                visualDensity: VisualDensity(vertical: -4),
                                title: Text(
                                  "Login",
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500),
                                ),
                                onTap: () => Get.to(() => Login()),
                              ),
                              ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                visualDensity: VisualDensity(vertical: -4),
                                title: Text(
                                  "Register",
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500),
                                ),
                                onTap: () => Get.to(() => SignUp()),
                              ),
                            ],
                          ),
                          Divider(height: 1, color: Color(0xFFEEEEEE)),
                          FooterTile(
                            title: "Support",
                            children: [
                              ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                visualDensity: VisualDensity(vertical: -4),
                                title: Text(
                                  "Refund and Return",
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500),
                                ),
                                onTap: () => _launchURL(
                                    "https://www.grabatoz.ae/refund-return"),
                              ),
                              ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                visualDensity: VisualDensity(vertical: -4),
                                title: Text(
                                  "Cookies Policy",
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500),
                                ),
                                onTap: () => _launchURL(
                                    "https://www.grabatoz.ae/cookies-policy"),
                              ),
                              ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                visualDensity: VisualDensity(vertical: -4),
                                title: Text(
                                  "Terms & Conditions",
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500),
                                ),
                                onTap: () => _launchURL(
                                    "https://www.grabatoz.ae/terms-conditions"),
                              ),
                              ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                visualDensity: VisualDensity(vertical: -4),
                                title: Text(
                                  "Privacy Policy",
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500),
                                ),
                                onTap: () => _launchURL(
                                    "https://www.grabatoz.ae/privacy-policy"),
                              ),
                              ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                visualDensity: VisualDensity(vertical: -4),
                                title: Text(
                                  "Disclaimer Policy",
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500),
                                ),
                                onTap: () => _launchURL(
                                    "https://www.grabatoz.ae/disclaimer-policy"),
                              ),
                              ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                visualDensity: VisualDensity(vertical: -4),
                                title: Text(
                                  "Track Order",
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500),
                                ),
                                onTap: () => Get.to(() => TrackOrderScreen()),
                              ),
                              ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                visualDensity: VisualDensity(vertical: -4),
                                title: Text(
                                  "Wishlist",
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500),
                                ),
                                onTap: () => Get.to(() => Favorite()),
                              ),
                              ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                visualDensity: VisualDensity(vertical: -4),
                                title: Text(
                                  "Cart",
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500),
                                ),
                                onTap: () => Get.to(() => Cart()),
                              ),
                            ],
                          ),
                          Divider(height: 1, color: Color(0xFFEEEEEE)),
                          FooterTile(
                            title: "Connect",
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      SocialIcon(
                                          assetPath:
                                              "assets/icons/facebook.png",
                                          url:
                                              "https://www.facebook.com/grabatozae/"),
                                      SocialIcon(
                                          assetPath: "assets/icons/twitter.png",
                                          url: "https://x.com/GrabAtoz"),
                                      SocialIcon(
                                          assetPath:
                                              "assets/icons/instagram.png",
                                          url:
                                              "https://www.instagram.com/grabatoz/"),
                                      SocialIcon(
                                          assetPath:
                                              "assets/icons/linkedin.png",
                                          url:
                                              "https://www.linkedin.com/company/grabatozae"),
                                      SocialIcon(
                                          assetPath:
                                              "assets/icons/pinterest.png",
                                          url:
                                              "https://www.pinterest.com/grabatoz/"),
                                      SocialIcon(
                                          assetPath: "assets/icons/tiktok.png",
                                          url:
                                              "https://www.tiktok.com/@grabatoz"),
                                      SocialIcon(
                                          assetPath: "assets/icons/youtube.png",
                                          url:
                                              "https://www.youtube.com/@grabAtoZ"),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// GestureDetector(
//   onTap: () async {
//     final SharedPreferences pref =
//         await SharedPreferences.getInstance();
//     pref.remove('userID').then((_) {
//       context.routeoffall('/login');
//     });
//   },
//   child: Container(
//     decoration: BoxDecoration(
//         color: context.colorScheme.brightness == Brightness.dark
//             ? kdarkmodeColor
//             : kdefwhiteColor,
//         border: Border.all(color: kdarkgreyColor),
//         borderRadius: BorderRadius.circular(10)),
//     child: ListTile(
//       leading: const Icon(
//         Icons.logout_rounded,
//       ),
//       title: Text(
//         'Logout',
//         style: context.textTheme.bodyLarge!.copyWith(),
//       ),
//       trailing: const Icon(Icons.arrow_forward_ios),
//     ),
//   ),
// ),

/// Bottom-sheet language switcher (English / العربية).
///
/// Follows the same visual style as [showCountrySelector]. Selecting a
/// language persists it via [LanguageController] and applies it immediately
/// (including the RTL layout flip for Arabic).
Future<void> showLanguageSelector(BuildContext context) {
  if (!Get.isRegistered<LanguageController>()) return Future.value();
  final LanguageController lc = Get.find<LanguageController>();

  return Get.bottomSheet(
    Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'select_language'.tr,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'language_hint'.tr,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          Obx(() {
            final isAr = lc.isArabic;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _languageOption(
                  lc,
                  code: LanguageController.englishCode,
                  nativeLabel: 'English',
                  englishLabel: 'English',
                  selected: !isAr,
                ),
                const SizedBox(height: 8),
                _languageOption(
                  lc,
                  code: LanguageController.arabicCode,
                  nativeLabel: 'العربية',
                  englishLabel: 'Arabic',
                  selected: isAr,
                ),
              ],
            );
          }),
        ],
      ),
    ),
    isScrollControlled: true,
  );
}

Widget _languageOption(
  LanguageController lc, {
  required String code,
  required String nativeLabel,
  required String englishLabel,
  required bool selected,
}) {
  return Material(
    color: selected
        ? Colors.green.withValues(alpha: 0.08)
        : Colors.grey.withValues(alpha: 0.07),
    borderRadius: BorderRadius.circular(12),
    child: ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Icon(
        Icons.language_outlined,
        color: selected ? Colors.green : Colors.grey.shade500,
      ),
      title: Text(nativeLabel,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: nativeLabel == englishLabel
          ? null
          : Text(
              englishLabel,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
      trailing: Icon(
        selected ? Icons.check_circle : Icons.radio_button_unchecked,
        color: selected ? Colors.green : Colors.grey.shade400,
        size: 24,
      ),
      onTap: () async {
        await lc.setLanguage(code);
        Get.back();
      },
    ),
  );
}
