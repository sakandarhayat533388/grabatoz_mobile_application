import 'package:graba2z/Utils/appextensions.dart';

import '../Utils/packages.dart';

class PrimaryTextField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputFormatter? inputFormatter;
  final String hintText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obsecure;
  final Widget? suffix;
  final void Function(String)? onChanged;
  final Color? backgroundColor;
  final Color? bordercolor;
  final int? maxLength;
  final Color? hinttextColor;
  final Color? textColor;
  final Color? cursorColor;
  final double? height;
  final double? width;
  final VoidCallback? ontap;

  const PrimaryTextField({
    super.key,
    this.controller,
    this.obsecure = false,
    required this.hintText,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.suffix,
    this.focusNode,
    this.onChanged,
    this.backgroundColor,
    this.bordercolor,
    this.maxLength,
    this.hinttextColor,
    this.textColor,
    this.height,
    this.width,
    this.inputFormatter,
    this.ontap,
    this.cursorColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 55,
      width: width ?? context.width * 0.85,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: backgroundColor ?? kPrimaryColor,
        boxShadow: defaultBoxShadow,
        borderRadius: BorderRadius.circular(60),
        border: Border.all(color: bordercolor ?? kdefwhiteColor, width: 1),
      ),
      child: Center(
        child: GestureDetector(
          onTap: ontap,
          child: TextFormField(
            focusNode: focusNode,
            onChanged: onChanged,
            obscureText: obsecure,
            cursorColor: cursorColor ?? kdefwhiteColor,
            cursorHeight: 20,
            controller: controller,
            keyboardType: keyboardType,
            textAlignVertical: TextAlignVertical.center,
            style: TextStyle(
              color: textColor ?? kdefwhiteColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            inputFormatters: [
              if (maxLength != null)
                LengthLimitingTextInputFormatter(maxLength),
              if (keyboardType == TextInputType.phone)
                FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              isDense: true,
              suffixIcon: suffix,
              suffixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              hintText: hintText,
              hintStyle: TextStyle(
                  color: hinttextColor ?? Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            validator: (value) {
              if (keyboardType == TextInputType.number &&
                  (value?.length ?? 0) != 10) {
                return "Phone number must be exactly 10 digits";
              }
              return validator?.call(value);
            },
          ),
        ),
      ),
    );
  }
}
