import 'package:get/get.dart';
import 'package:graba2z/Controllers/addtocart.dart';
import 'package:graba2z/Utils/appextensions.dart';
import 'package:graba2z/Views/Auth/signup.dart';
import 'package:graba2z/Views/Home/Screens/Favorite%20Product/favproduct_screen.dart';
import 'package:graba2z/Views/Home/Screens/Settings/accountsettings.dart';
import 'package:graba2z/Views/Home/Screens/Shop%20Screen/Shop.dart';
import 'package:url_launcher/url_launcher.dart';
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
      _showFirstOpenDiscountPopup();
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

  Future<void> _showFirstOpenDiscountPopup() async {
    final prefs = await SharedPreferences.getInstance();
    const popupShownKey = 'first_open_discount_popup_shown';
    const bannerAsset = 'assets/images/popupimage.png';
    final hasShownPopup = prefs.getBool(popupShownKey) ?? false;

    if (hasShownPopup || !mounted) {
      return;
    }

    await prefs.setBool(popupShownKey, true);

    if (!mounted) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final media = MediaQuery.of(context);
        final dialogWidth =
            (media.size.width - 32).clamp(280.0, 420.0).toDouble();
        final bannerHeight = (dialogWidth / 1.11)
            .clamp(210.0, media.size.height * 0.62)
            .toDouble();

        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: SizedBox(
            width: dialogWidth,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Material(
                color: kdefwhiteColor,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: bannerHeight,
                          child: Image.asset(
                            bannerAsset,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _DiscountPopupFallback(
                                height: bannerHeight,
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: kdefblackColor.withValues(alpha: 0.42),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              constraints: const BoxConstraints.tightFor(
                                width: 36,
                                height: 36,
                              ),
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.close,
                                color: kdefwhiteColor,
                                size: 20,
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: kSecondaryColor,
                                side: BorderSide(
                                  color:
                                      kSecondaryColor.withValues(alpha: 0.18),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text(
                                'Later',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: kPrimaryColor,
                                foregroundColor: kdefwhiteColor,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                                Get.to(() => const SignUp());
                              },
                              child: const Text(
                                'Register Now',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

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
                const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'Are you sure?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: kdefblackColor,
                      ),
                    ),
                  ],
                ),
                10.0.heightbox,
                const Text('Do you want to exit the App?'),
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
                        child: const Text(
                          'Yes',
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
                        child: const Text(
                          'No',
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
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: ImageIcon(
                      AssetImage("assets/icons/favor.png"),
                      size: 20,
                    ),
                    label: 'WishList',
                  ),
                  BottomNavigationBarItem(
                    icon: ImageIcon(
                      AssetImage("assets/icons/shop.png"),
                      size: 20,
                    ),
                    label: 'Shop',
                  ),
                  BottomNavigationBarItem(
                    icon: ImageIcon(
                      AssetImage("assets/icons/profile.png"),
                      size: 20,
                    ),
                    label: 'Profile',
                  ),
                  BottomNavigationBarItem(
                    icon: ImageIcon(
                      AssetImage("assets/icons/chat.png"),
                      size: 20,
                    ),
                    label: 'Chat',
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
                    displayTitle: 'All Products',
                  ),
                  Settings(),
                  SizedBox(), // Empty placeholder for WhatsApp
                ],
              ),
      ),
    );
  }
}

class _DiscountPopupFallback extends StatelessWidget {
  const _DiscountPopupFallback({
    required this.height,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    final compact = height < 260;

    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0C3E16),
            Color(0xFF176728),
            Color(0xFF0B2D12),
          ],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            left: -42,
            bottom: -54,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kPrimaryColor.withValues(alpha: 0.16),
              ),
            ),
          ),
          Positioned(
            right: -36,
            top: 46,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kdefwhiteColor.withValues(alpha: 0.08),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, compact ? 16 : 22, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  AppImages.logoicon,
                  width: compact ? 128 : 164,
                  height: compact ? 42 : 54,
                  color: kdefwhiteColor,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: compact ? 6 : 10),
                Text(
                  'GET EXCLUSIVE DISCOUNTS!',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    color: const Color(0xFFFFE100),
                    fontSize: compact ? 22 : 27,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: compact ? 6 : 8),
                Text(
                  'Shop faster, easier & smarter with the Graba2z App.',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    color: kdefwhiteColor,
                    fontSize: compact ? 12 : 14,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Transform.rotate(
                        angle: -0.08,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 10 : 12,
                            vertical: compact ? 9 : 11,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6130B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: kdefwhiteColor.withValues(alpha: 0.75),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: kdefblackColor.withValues(alpha: 0.22),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'APP EXCLUSIVE',
                                maxLines: 1,
                                style: TextStyle(
                                  color: const Color(0xFFFFE100),
                                  fontSize: compact ? 10 : 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'DISCOUNTS',
                                maxLines: 1,
                                style: TextStyle(
                                  color: kdefwhiteColor,
                                  fontSize: compact ? 20 : 25,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'AWAITS YOU!',
                                maxLines: 1,
                                style: TextStyle(
                                  color: const Color(0xFFFFE100),
                                  fontSize: compact ? 11 : 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: Image.asset(
                        'assets/images/headphone.png',
                        height: compact ? 86 : 112,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
