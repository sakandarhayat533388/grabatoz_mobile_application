import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:graba2z/Controllers/theme_controller.dart';

/// Website logo from the theme API, with the bundled asset as fallback.
///
/// The remote file is fetched and validated by hand instead of using
/// SvgPicture.network: a wrong URL there returns a 404 JSON body, and the
/// SVG parser throws an *unhandled* "Invalid SVG data" exception that
/// pauses the debugger and pollutes the console. Here every failure —
/// network, non-200, non-SVG content, parse — quietly falls back to the
/// bundled logo. A broken logo must never break the app.
class ThemeLogo extends StatefulWidget {
  final double? width;
  final String fallbackAsset;

  const ThemeLogo({super.key, this.width, required this.fallbackAsset});

  @override
  State<ThemeLogo> createState() => _ThemeLogoState();
}

class _ThemeLogoState extends State<ThemeLogo> {
  String? _svgText;
  bool _svgFailed = false;
  String _requestedUrl = '';

  AppThemeController? get _ctrl => Get.isRegistered<AppThemeController>()
      ? Get.find<AppThemeController>()
      : null;

  @override
  void initState() {
    super.initState();
    _maybeLoadSvg();
  }

  void _maybeLoadSvg() {
    final url = _ctrl?.logoUrl ?? '';
    if (url.isEmpty || !url.toLowerCase().endsWith('.svg')) return;
    _requestedUrl = url;
    _loadSvg(url);
  }

  Future<void> _loadSvg(String url) async {
    try {
      final res =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        throw Exception('logo HTTP ${res.statusCode}');
      }
      final text = utf8.decode(res.bodyBytes, allowMalformed: true);
      final head = text.trimLeft().toLowerCase();
      // A real SVG starts with <?xml or <svg; a 404 JSON/HTML body does not
      // contain an <svg tag near the top. Anything else is not a logo.
      final probe = head.length > 512 ? head.substring(0, 512) : head;
      if (!probe.contains('<svg')) {
        throw Exception('logo response is not SVG');
      }
      if (!mounted || _requestedUrl != url) return;
      setState(() => _svgText = text);
    } catch (_) {
      if (!mounted) return;
      setState(() => _svgFailed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _ctrl;
    final double w = widget.width ?? ctrl?.logoWidth ?? 132;
    final String url = ctrl?.logoUrl ?? '';
    final Widget fallback =
        Image.asset(widget.fallbackAsset, width: w, fit: BoxFit.contain);
    if (url.isEmpty) return fallback;

    if (url.toLowerCase().endsWith('.svg')) {
      // If the theme URL changed since initState, (re)load for the new one.
      if (url != _requestedUrl) {
        _requestedUrl = url;
        _svgText = null;
        _svgFailed = false;
        _loadSvg(url);
      }
      if (_svgFailed) return fallback;
      final svg = _svgText;
      if (svg == null) return fallback; // still loading: show bundled logo
      return SvgPicture.string(
        svg,
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
