import 'package:graba2z/Utils/packages.dart';
import 'package:get/get.dart';
import 'package:graba2z/Controllers/theme_controller.dart';

Color get kPrimaryColor => Get.isRegistered<AppThemeController>() ? Get.find<AppThemeController>().brand : const Color(0xFF84CC16);
const Color kSecondaryColor = Color(0xFF333333);

const Color kmediumblackColor = Color(0xFF828588);
const Color klightblackColor = Color(0xFFB8BCBF);
const Color kdefgreyColor = Color(0xFFF1F1F1);
const Color kdefblackColor = Color(0xFF000000);
const Color kdefwhiteColor = Color(0xFFFFFFFF);
const Color kredColor = Color(0xFFFF311C);
const Color kdefgreenColor = Color(0xFF16A34A);

final ColorScheme kColorScheme = ColorScheme(
  primary: kPrimaryColor,
  secondary: kSecondaryColor,
  surface: kdefwhiteColor,
  error: kredColor,
  onPrimary: kdefwhiteColor,
  onSecondary: kdefwhiteColor,
  onSurface: kdefblackColor,
  onError: kdefwhiteColor,
  brightness: Brightness.light,
);

final ColorScheme kDarkColorScheme = ColorScheme(
  primary: kPrimaryColor,
  secondary: kSecondaryColor,
  surface: kdefblackColor,
  error: kredColor,
  onPrimary: kdefwhiteColor,
  onSecondary: kdefwhiteColor,
  onSurface: kdefwhiteColor,
  onError: kdefwhiteColor,
  brightness: Brightness.dark,
);

EdgeInsets defaultPadding({double vertical = 0.0, double horizontal = 15.0}) {
  return EdgeInsets.symmetric(vertical: vertical, horizontal: horizontal);
}

BorderRadius defaultBorderRadious = BorderRadius.circular(10);
const Duration defaultDuration = Duration(milliseconds: 300);
// Define defaultBoxShadow as a reusable shadow
List<BoxShadow> defaultBoxShadow = [
  BoxShadow(
    color: Colors.black.withValues(alpha: .1), // Shadow color
    offset: Offset(0, 4), // Horizontal and vertical offset
    blurRadius: 10, // Blur radius
    spreadRadius: 0, // Spread radius to control the spread of the shadow
  ),
];

void hideKeyboard(BuildContext context) {
  FocusScope.of(context).unfocus();
}

Widget defaultStyledContainer({
  required Widget child,
  EdgeInsetsGeometry margin = const EdgeInsets.all(8),
  EdgeInsetsGeometry padding = const EdgeInsets.all(12),
  Color? backgroundColor,
  // Color? borderColor,
  double? height,
  double? width,
  BoxConstraints? constraints, // ✅ Add this
  BorderRadius? borderRadius,
  List<BoxShadow>? boxShadow,
  Color? borderColor,
}) {
  return Container(
      height: height,
      width: width,
      constraints: constraints, // ✅ Apply if provided
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? kdefwhiteColor,
        borderRadius: borderRadius ?? defaultBorderRadious,
        boxShadow: boxShadow ?? defaultBoxShadow,
        border: Border.all(color: borderColor ?? Colors.transparent),
      ),
      child: child);
}

void configEasyLoading() {
  EasyLoading.instance
    ..indicatorType = EasyLoadingIndicatorType.circle
    ..loadingStyle = EasyLoadingStyle.dark
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..progressColor = Colors.yellow
    ..backgroundColor = kPrimaryColor
    ..indicatorColor = Colors.yellow
    ..textColor = kdefwhiteColor
    ..maskColor = Colors.blue.withValues(alpha: .5)
    ..userInteractions = false
    ..dismissOnTap = false;
}
