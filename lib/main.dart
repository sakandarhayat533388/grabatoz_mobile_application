import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:graba2z/Controllers/language_controller.dart';
import 'package:graba2z/Controllers/loyalty_controller.dart';
import 'package:graba2z/Controllers/referral_controller.dart';
import 'package:graba2z/Controllers/theme_controller.dart';
import 'package:graba2z/Services/push_notification_service.dart';
import 'package:graba2z/Utils/app_translations.dart';
import 'package:graba2z/Api/Services/apiservices.dart';
import 'package:graba2z/Controllers/addtocart.dart';
import 'package:graba2z/Controllers/bannerProductController.dart';
import 'package:graba2z/Controllers/deliveryController.dart';
import 'package:graba2z/Controllers/favController.dart';
import 'package:graba2z/Controllers/first_user_discount_controller.dart';
import 'package:graba2z/Controllers/menuController.dart';
import 'package:graba2z/Controllers/orderController.dart';
import 'package:graba2z/Controllers/payment_charges_controller.dart';
import 'package:graba2z/Controllers/country_controller.dart';
import 'package:graba2z/Controllers/paymentprovider.dart';
import 'package:graba2z/Controllers/searchController.dart';
import 'package:graba2z/Utils/packages.dart';
import 'package:graba2z/Controllers/notification_controller.dart';
import "package:get/get.dart";
import 'package:graba2z/Services/notification_permission_preloader.dart';

import 'dart:async';
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
  // Country/currency selection — registered before any UI builds.
  Get.put(CountryController(), permanent: true);
  // App language — load the saved choice before any UI builds.
  Get.put(LanguageController(), permanent: true);
  Get.find<LanguageController>().currentLang.value =
      await LanguageController.loadLanguageCode();
  // Grabian Points + Referrals — registered permanently at launch so their
  // settings are cached before any screen reads them.
  Get.put<LoyaltyController>(LoyaltyController(), permanent: true);
  Get.put<ReferralController>(ReferralController(), permanent: true);
  // Website Appearance theme — registered permanently; cached palette is
  // applied before the first frame so chrome paints branded immediately.
  Get.put<AppThemeController>(AppThemeController(), permanent: true);
  await Get.find<AppThemeController>().loadFromCache();
  // Fire-and-forget settings fetch (controllers also load in onInit; these
  // guarded calls are a belt-and-braces kick-off and must never block or
  // crash startup).
  try {
    Get.find<LoyaltyController>().loadSettings();
  } catch (_) {}
  try {
    Get.find<ReferralController>().loadSettings();
  } catch (_) {}
  final prefs = await SharedPreferences.getInstance();
  String? userId = prefs.getString('userId')?.toString();
  HttpOverrides.global = MyHttpOverrides();

  // Preload effective notification permission before any UI is built
  await NotificationPermissionPreloader.preload();

  AwesomeNotifications().initialize(
      'resource://drawable/ic_notification',
      [
        NotificationChannel(
          channelGroupKey: 'basic_channel_group',
          channelKey: 'basic_channel',
          channelName: 'Basic notifications',
          channelDescription: 'Notification channel for Cart',
          defaultColor: kPrimaryColor,
          ledColor: kdefwhiteColor,
        ),
        // FCM push channels — one per server sound id (see spec).
        NotificationChannel(
          channelGroupKey: 'push_channel_group',
          channelKey: 'push_default',
          channelName: 'Push notifications',
          channelDescription: 'Offers, order updates and announcements',
          defaultColor: kPrimaryColor,
          ledColor: kdefwhiteColor,
          importance: NotificationImportance.High,
        ),
        NotificationChannel(
          channelGroupKey: 'push_channel_group',
          channelKey: 'push_chime',
          channelName: 'Push notifications (chime)',
          channelDescription: 'Push sound: chime',
          defaultColor: kPrimaryColor,
          ledColor: kdefwhiteColor,
          importance: NotificationImportance.High,
          soundSource: 'resource://raw/chime',
        ),
        NotificationChannel(
          channelGroupKey: 'push_channel_group',
          channelKey: 'push_ding',
          channelName: 'Push notifications (ding)',
          channelDescription: 'Push sound: ding',
          defaultColor: kPrimaryColor,
          ledColor: kdefwhiteColor,
          importance: NotificationImportance.High,
          soundSource: 'resource://raw/ding',
        ),
        NotificationChannel(
          channelGroupKey: 'push_channel_group',
          channelKey: 'push_cash',
          channelName: 'Push notifications (cash)',
          channelDescription: 'Push sound: cash',
          defaultColor: kPrimaryColor,
          ledColor: kdefwhiteColor,
          importance: NotificationImportance.High,
          soundSource: 'resource://raw/cash',
        ),
        NotificationChannel(
          channelGroupKey: 'push_channel_group',
          channelKey: 'push_alert',
          channelName: 'Push notifications (alert)',
          channelDescription: 'Push sound: alert',
          defaultColor: kPrimaryColor,
          ledColor: kdefwhiteColor,
          importance: NotificationImportance.High,
          soundSource: 'resource://raw/alert',
        ),
        NotificationChannel(
          channelGroupKey: 'push_channel_group',
          channelKey: 'push_silent',
          channelName: 'Push notifications (silent)',
          channelDescription: 'Silent push notifications',
          defaultColor: kPrimaryColor,
          ledColor: kdefwhiteColor,
          importance: NotificationImportance.Low,
          playSound: false,
          enableVibration: false,
          enableLights: false,
        ),
      ],
      // Channel groups are only visual and are not required
      channelGroups: [
        NotificationChannelGroup(
            channelGroupKey: 'basic_channel_group',
            channelGroupName: 'Basic group'),
        NotificationChannelGroup(
            channelGroupKey: 'push_channel_group',
            channelGroupName: 'Push notifications')
      ],
      debug: true);
  bool isAllowedToSendNotifications =
      await AwesomeNotifications().isNotificationAllowed();
  if (!isAllowedToSendNotifications) {
    AwesomeNotifications().requestPermissionToSendNotifications();
  }
  runApp(MyApp(userId: userId)); // Pass userId to MyApp
  configEasyLoading();
  // FCM push: initialize Firebase only when the platform config files
  // (google-services.json / GoogleService-Info.plist) are present.
  // The app must keep working without them.
  // Fire-and-forget AFTER runApp: on a fresh install the FCM token is
  // created over the network and can take seconds (or stall) — awaiting
  // it before runApp left the app stuck on the white launch screen
  // until it was killed and relaunched (token then served from cache).
  unawaited(_initFcmPush());
  // Theme refresh — fire-and-forget after runApp; never blocks startup.
  try {
    unawaited(Get.find<AppThemeController>().refresh());
  } catch (_) {}
}

/// FCM startup, run after the first frame (see the call site in main).
Future<void> _initFcmPush() async {
  try {
    await Firebase.initializeApp();
    PushNotificationService.firebaseReady = true;
    await PushNotificationService.instance.init();
  } catch (e) {
    debugPrint('FCM disabled — Firebase.initializeApp failed: $e');
  }
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
      translations: AppTranslations(),
      locale: Get.find<LanguageController>().locale,
      fallbackLocale: const Locale('en', 'US'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('ar', 'AE'),
      ],
      theme: ThemeData(
        scaffoldBackgroundColor: Get.isRegistered<AppThemeController>() ? Get.find<AppThemeController>().pageBackground : kdefwhiteColor,
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
