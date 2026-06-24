import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:graba2z/Api/Services/apiservices.dart';
import 'package:graba2z/Controllers/addtocart.dart';
import 'package:graba2z/Controllers/bannerProductController.dart';
import 'package:graba2z/Controllers/deliveryController.dart';
import 'package:graba2z/Controllers/favController.dart';
import 'package:graba2z/Controllers/first_user_discount_controller.dart';
import 'package:graba2z/Controllers/menuController.dart';
import 'package:graba2z/Controllers/orderController.dart';
import 'package:graba2z/Controllers/payment_charges_controller.dart';
import 'package:graba2z/Controllers/paymentprovider.dart';
import 'package:graba2z/Controllers/searchController.dart';
import 'package:graba2z/Utils/packages.dart';
import 'package:graba2z/Controllers/notification_controller.dart';
import "package:get/get.dart";
import 'package:graba2z/Services/notification_permission_preloader.dart';

import 'dart:io';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  String? userId = prefs.getString('userId')?.toString();
  HttpOverrides.global = MyHttpOverrides();

  // Preload effective notification permission before any UI is built
  await NotificationPermissionPreloader.preload();

  AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelGroupKey: 'basic_channel_group',
          channelKey: 'basic_channel',
          channelName: 'Basic notifications',
          channelDescription: 'Notification channel for Cart',
          defaultColor: kPrimaryColor,
          ledColor: kdefwhiteColor,
        )
      ],
      // Channel groups are only visual and are not required
      channelGroups: [
        NotificationChannelGroup(
            channelGroupKey: 'basic_channel_group',
            channelGroupName: 'Basic group')
      ],
      debug: true);
  bool isAllowedToSendNotifications =
      await AwesomeNotifications().isNotificationAllowed();
  if (!isAllowedToSendNotifications) {
    AwesomeNotifications().requestPermissionToSendNotifications();
  }
  runApp(MyApp(userId: userId)); // Pass userId to MyApp
  configEasyLoading();
}

// void main() {
//   HttpOverrides.global = MyHttpOverrides();  // 👈 Add this line
//   runApp(MyApp());
// }

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.userId});

  final String? userId;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _didLoadFirstUserDiscountStatus = false;

  @override
  void initState() {
    super.initState();
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: NotificationController.onActionReceivedMethod,
      onNotificationCreatedMethod:
          NotificationController.onNotificationCreatedMethod,
      onNotificationDisplayedMethod:
          NotificationController.onNotificationDisplayedMethod,
      onDismissActionReceivedMethod:
          NotificationController.onDismissActionReceivedMethod,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Initialize GetX controllers
    Get.put(ThemeController());
    Get.put(AuthController());
    final firstUserDiscountController = Get.put(FirstUserDiscountController());
    Get.put(BottomNavigationController());
    Get.put(FavoriteController());
    Get.put(ApiServiceController());
    Get.put(CartNotifier());
    Get.put(SearchScController());
    Get.put(DeliveryController());
    Get.put(PaymentChargesController());
    Get.put(PaymentMethodController());
    Get.put(FocusController());
    Get.put(OrderController());
    Get.put(menuController());
    Get.put(bannerProductController());
    if ((widget.userId ?? '').isNotEmpty && !_didLoadFirstUserDiscountStatus) {
      _didLoadFirstUserDiscountStatus = true;
      firstUserDiscountController.markAuthSessionPresent();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        firstUserDiscountController.loadStatus();
      });
    }
    // Get.put(AddressLabelController());
    // Get.put(PaymentMethodProvider(widget.userId ?? 'guest_user'));

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Graba2z',
      theme: ThemeData(
        scaffoldBackgroundColor: kdefwhiteColor,
        fontFamily: "Montserrat",
        primaryColor: kPrimaryColor,
        colorScheme: Get.find<ThemeController>().currentColorScheme,
        useMaterial3: true,
        fontFamilyFallback: const ['Montserrat-Bold'],
      ).copyWith(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
          },
        ),
      ),
      home: SplashScreen(),
      builder: EasyLoading.init(),
    );
  }
}
