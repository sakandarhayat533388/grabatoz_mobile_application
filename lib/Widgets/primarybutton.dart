import 'package:graba2z/Utils/appextensions.dart';
import 'package:get/get.dart' hide ContextExtensionss;
import 'package:graba2z/Controllers/theme_controller.dart';

import '../Utils/packages.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.buttonText,
    this.onPressFunction,
    this.buttonColor,
    this.textColor,
    this.borderColor,
    this.height,
    this.width,
    this.fontSize,
  });

  final Color? buttonColor;
  final Color? borderColor;
  final Color? textColor;
  final String buttonText;
  final VoidCallback? onPressFunction;
  final double? height;
  final double? width;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressFunction,
      child: Container(
        width: width ?? context.width * 0.8,
        height: height ?? 45,
        decoration: BoxDecoration(
          boxShadow: defaultBoxShadow,
          border: Border.all(color: borderColor ?? Colors.transparent),
          borderRadius: BorderRadius.circular(60),
          color: buttonColor ?? (Get.isRegistered<AppThemeController>() ? Get.find<AppThemeController>().primaryButtonBg : kPrimaryColor),
        ),
        child: Center(
          child: Text(
            buttonText.toUpperCase(),
            style: TextStyle(
                color: textColor ?? (Get.isRegistered<AppThemeController>() ? Get.find<AppThemeController>().primaryButtonText : kdefwhiteColor),
                fontSize: fontSize ?? 14,
                fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
