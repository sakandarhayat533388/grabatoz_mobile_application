import 'package:get/get.dart';
import 'package:graba2z/Controllers/addtocart.dart';
import 'package:graba2z/Controllers/home_controller.dart';
import 'package:graba2z/Utils/packages.dart';
import 'package:graba2z/Views/Home/home.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  bool _isCentered = false;
  bool _showShapes = false;
  HomeController _homeController = Get.put(HomeController());
  @override
  void initState() {
    super.initState();
    // Trigger animations with delays

    Future.delayed(const Duration(seconds: 0), () {
      setState(() {
        _isCentered = true;
      });

      // Trigger the shapes animation after the logo animation
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          _showShapes = true;
        });
      });
    });
    Future.delayed(const Duration(seconds: 4), () {
      _navigateToHome();
    });
    final authProvider = Get.put(AuthController());

    authProvider.loadUserData();
    final cartNotifier = Get.put(CartNotifier());

    // Load cart data before running the app
    _loadUserIdAndCart(cartNotifier);
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(seconds: 2),
        pageBuilder: (context, animation, secondaryAnimation) => const Home(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Fade transition
          return FadeTransition(
            opacity: animation.drive(
              Tween<double>(begin: 0.0, end: 1.0).chain(
                CurveTween(
                  curve: Curves.easeInOut,
                ),
              ),
            ),
            child: child,
          );
        },
      ),
    );
  }

  /// **New method to load `userId` from `SharedPreferences`**
  Future<void> _loadUserIdAndCart(CartNotifier cartNotifier) async {
    final prefs = await SharedPreferences.getInstance();
    String? storedUserId =
        prefs.getString('userId'); // Get user ID from shared prefs

    String? userId = storedUserId?.toString();
    cartNotifier.loadCartFromPrefs(userId); // Pass userId to load cart
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final logoSize = screenWidth * 0.6;
    final logoLeft = (screenWidth - logoSize) / 2;
    final logoBottom =
        _isCentered ? (screenHeight / 2) - (logoSize / 2) : -logoSize;

    return Scaffold(
      body: Stack(
        children: [
          // Animated logo
          AnimatedPositioned(
            duration: const Duration(seconds: 1),
            curve: Curves.easeInOut,
            bottom: logoBottom,
            left: logoLeft,
            child: Image.asset(
              AppImages.logoicon,
              width: logoSize,
              height: logoSize,
            ),
          ),

          // Animated top-left elliptical shape
          AnimatedPositioned(
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
            top: _showShapes ? -screenWidth * 0.35 : -screenWidth * 0.6,
            left: _showShapes ? -screenWidth * 0.4 : -screenWidth * 0.8,
            child: Container(
              width: screenWidth * 0.8,
              height: screenWidth * 0.8,
              decoration: BoxDecoration(
                color: kPrimaryColor,
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(300),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black,
                    spreadRadius: 0,
                    blurRadius: 0,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
            ),
          ),

          // Animated bottom-right elliptical shape
          AnimatedPositioned(
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
            bottom: _showShapes ? -screenHeight * 0.24 : -screenHeight * 0.5,
            right: _showShapes ? -screenWidth * 0.42 : -screenWidth * 0.8,
            child: Container(
              width: screenWidth * 1.1,
              height: screenHeight * 0.4,
              decoration: BoxDecoration(
                color: kPrimaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(screenWidth * 0.8),
                  topRight: Radius.circular(screenWidth * 0.7),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black,
                    spreadRadius: 0,
                    blurRadius: 0,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.05),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: screenWidth * 0.2),
                      child: Text(
                        'auth_splash_onestop'.tr,
                        style: TextStyle(
                            fontSize: screenWidth * 0.03,
                            fontWeight: FontWeight.bold,
                            color: kdefwhiteColor),
                      ),
                    ),
                    // SizedBox(height: screenHeight * 0.01),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'auth_splash_techshop'.tr,
                          style: TextStyle(
                            fontSize: screenWidth * 0.03,
                            color: kdefwhiteColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
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
