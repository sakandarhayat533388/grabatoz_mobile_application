import 'package:get/get.dart';
import 'package:graba2z/Controllers/addtocart.dart';
import 'package:graba2z/Utils/appextensions.dart';
import 'package:graba2z/Views/Auth/signup.dart';
import 'package:graba2z/Views/Home/Screens/Favorite%20Product/favproduct_screen.dart';
import 'package:graba2z/Views/Home/Screens/Settings/accountsettings.dart';
import 'package:graba2z/Views/Home/Screens/Shop%20Screen/Shop.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:graba2z/Api/Services/apiservices.dart';
import 'package:graba2z/Api/Models/popup_settings_model.dart';
import 'package:graba2z/Utils/image_helper.dart';
import 'package:graba2z/Utils/popup_helper.dart';
import '../../Utils/packages.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();

    initConnectivity();

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    final cartNotifier = Get.find<CartNotifier>();

    // Load cart data before running the app
    _loadUserIdAndCart(cartNotifier);
    final authProvider = Get.find<AuthController>();
    authProvider.loadUserData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PopupHelper.showIfNeeded(context, 'home');
    });
  }

  Future<void> _loadUserIdAndCart(CartNotifier cartNotifier) async {
    final prefs = await SharedPreferences.getInstance();
    String? storedUserId =
        prefs.getString('userId'); // Get user ID from shared prefs

    String? userId = storedUserId?.toString();
    cartNotifier.loadCartFromPrefs(userId); // Pass userId to load cart
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> initConnectivity() async {
    late List<ConnectivityResult> result;

    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException {
      return;
    }

    if (!mounted) {
      return Future.value(null);
    }

    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> result) async {
    setState(() {
      _connectionStatus = result;
    });
    // ignore: avoid_print
    print('Connectivity changed: $_connectionStatus');
  }

  bool get isOffline => _connectionStatus.contains(ConnectivityResult.none);



  void showBackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12), color: kdefwhiteColor),
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'home_exit_title'.tr,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: kdefblackColor,
                      ),
                    ),
                  ],
                ),
                10.0.heightbox,
                Text('home_exit_msg'.tr),
                20.0.heightbox,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Container(
                      width: 100,
                      decoration: BoxDecoration(
                        color: kPrimaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextButton(
                        onPressed: () {
                          SystemNavigator.pop();
                        },
                        child: Text(
                          'home_yes'.tr,
                          style: TextStyle(
                              color: kdefwhiteColor,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Container(
                      width: 100,
                      decoration: BoxDecoration(
                        color: kdefwhiteColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kdefgreyColor),
                      ),
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'home_no'.tr,
                          style: TextStyle(
                              color: kmediumblackColor,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final navigationProvider = Get.put(BottomNavigationController());
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          return;
        }
        showBackDialog(context);
        return;
      },
      child: Scaffold(
        bottomNavigationBar: SafeArea(
          child: Theme(
            data: Theme.of(context).copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: defaultStyledContainer(
              margin: EdgeInsets.zero,
              padding: EdgeInsets.zero,
              backgroundColor: kPrimaryColor,
              child: BottomNavigationBar(
                currentIndex: navigationProvider.tabIndex,
                onTap: (index) {
                  if (index == 4) {
                    _launchWhatsApp();
                  } else {
                    navigationProvider.setTabIndex(index);
                  }
                },
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                selectedLabelStyle: const TextStyle(
                    color: kSecondaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
                selectedItemColor: kSecondaryColor,
                unselectedItemColor: kdefwhiteColor,
                unselectedLabelStyle: const TextStyle(
                  color: kdefwhiteColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
                elevation: 8.0,
                items: [
                  BottomNavigationBarItem(
                    icon: ImageIcon(
                      AssetImage("assets/icons/home.png"),
                      size: 20,
                    ),
                    label: 'home'.tr,
                  ),
                  BottomNavigationBarItem(
                    icon: ImageIcon(
                      AssetImage("assets/icons/favor.png"),
                      size: 20,
                    ),
                    label: 'home_wishlist_tab'.tr,
                  ),
                  BottomNavigationBarItem(
                    icon: ImageIcon(
                      AssetImage("assets/icons/shop.png"),
                      size: 20,
                    ),
                    label: 'home_shop_tab'.tr,
                  ),
                  BottomNavigationBarItem(
                    icon: ImageIcon(
                      AssetImage("assets/icons/profile.png"),
                      size: 20,
                    ),
                    label: 'profile'.tr,
                  ),
                  BottomNavigationBarItem(
                    icon: ImageIcon(
                      AssetImage("assets/icons/chat.png"),
                      size: 20,
                    ),
                    label: 'home_chat_tab'.tr,
                  ),
                ],
              ),
            ),
          ),
        ),
        body: isOffline
            ? const NoconnectionScreen()
            : PageView(
                physics: NeverScrollableScrollPhysics(),
                controller: navigationProvider.pageController,
                onPageChanged: (index) {
                  setState(() {});
                  if (index == 4) {
                    _launchWhatsApp(); // Open WhatsApp when Chat is selected
                  } else {
                    navigationProvider.setTabIndex(index);
                  }
                },
                children: [
                  HomeScreenView(),
                  Favorite(),
                  Shop(
                    id: '2',
                    parentType: '',
                    displayTitle: 'shop_all_products'.tr,
                  ),
                  Settings(),
                  SizedBox(), // Empty placeholder for WhatsApp
                ],
              ),
      ),
    );
  }
}



void _launchWhatsApp() async {
  const phoneNumber = "+971505033860";
  final whatsappUrl = "https://wa.me/$phoneNumber";

  if (await launchUrl(Uri.parse(whatsappUrl))) {
    await launchUrl(Uri.parse(whatsappUrl));
  } else {
    throw "Could not launch WhatsApp";
  }
}
