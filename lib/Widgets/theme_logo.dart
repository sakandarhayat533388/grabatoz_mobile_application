import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:graba2z/Controllers/theme_controller.dart';

class ThemeLogo extends StatelessWidget {
  final double? width;
  final String fallbackAsset;

  const ThemeLogo({super.key, this.width, required this.fallbackAsset});

  @override
  Widget build(BuildContext context) {
    AppThemeController? ctrl =
        Get.isRegistered<AppThemeController>()
            ? Get.find<AppThemeController>()
            : null;
    final double w = width ?? ctrl?.logoWidth ?? 132;
    final String url = ctrl?.logoUrl ?? '';
    Widget fallback = Image.asset(fallbackAsset, width: w, fit: BoxFit.contain);
    if (url.isEmpty) {
      return fallback;
    }
    if (url.toLowerCase().endsWith('.svg')) {
      return SvgPicture.network(
        url,
        width: w,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => fallback,
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      width: w,
      fit: BoxFit.contain,
      errorWidget: (_, __, ___) => fallback,
      placeholder: (_, __) => fallback,
    );
  }
}
