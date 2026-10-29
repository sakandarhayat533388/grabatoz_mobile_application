import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:graba2z/Models/app_theme.dart';
import 'package:graba2z/Services/theme_api.dart';

class AppThemeController extends GetxController {
  final Rx<AppTheme> theme = AppTheme.defaults().obs;

  static const String cacheKey = 'app_theme_json';

  Future<void> loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(cacheKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          theme.value = AppTheme.fromJson(Map<String, dynamic>.from(decoded));
        }
      }
    } catch (_) {}
  }

  Future<void> refresh() async {
    try {
      final json = await ThemeApi.fetchThemeJson();
      if (json != null) {
        theme.value = AppTheme.fromJson(json);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(cacheKey, jsonEncode(json));
      }
    } catch (_) {}
  }

  AppTheme get _effective =>
      theme.value.enabled ? theme.value : AppTheme.defaults();

  Color _pick(String? hex, Color fallback) => parseHexColor(hex) ?? fallback;

  Color get brand =>
      parseHexColor(_effective.brandScale['500']) ??
      parseHexColor(_effective.brandPrimary) ??
      const Color(0xFF84CC16);

  Color get brandPressed =>
      _pick(_effective.brandScale['600'], const Color(0xFF65A30D));

  Color get primaryButtonBg =>
      _pick(_effective.buttons['primaryBackground'], brand);

  Color get primaryButtonHover =>
      _pick(_effective.buttons['primaryHoverBackground'], brandPressed);

  Color get primaryButtonText =>
      _pick(_effective.buttons['primaryText'], Colors.white);

  Color get priceColor =>
      _pick(_effective.page['price'], const Color(0xFFDC2626));

  Color get oldPriceColor =>
      _pick(_effective.page['oldPrice'], const Color(0xFF9CA3AF));

  Color get badgeBg =>
      _pick(_effective.header['badgeBackground'], const Color(0xFFEF4444));

  Color get badgeText => _pick(_effective.header['badgeText'], Colors.white);

  Color get pageBackground =>
      _pick(_effective.page['background'], Colors.white);

  Color get surfaceColor =>
      _pick(_effective.page['surface'], const Color(0xFFF9FAFB));

  Color get pageText => _pick(_effective.page['text'], const Color(0xFF374151));

  Color get headingColor =>
      _pick(_effective.page['heading'], const Color(0xFF111827));

  Color get mutedColor =>
      _pick(_effective.page['muted'], const Color(0xFF6B7280));

  Color get borderColor =>
      _pick(_effective.page['border'], const Color(0xFFE5E7EB));

  Color get headerBg => _pick(_effective.header['background'], Colors.white);

  Color get headerText =>
      _pick(_effective.header['text'], const Color(0xFF374151));

  Color get headerIcon =>
      _pick(_effective.header['icon'], const Color(0xFF374151));

  bool get isEnabled => theme.value.enabled;

  String get logoUrl {
    final raw = _effective.logos['headerMobile'] ?? '';
    if (raw.isEmpty) return '';
    if (raw.startsWith('http')) return raw;
    if (raw.startsWith('/')) return 'https://api.grabatoz.ae$raw';
    return raw;
  }

  double get logoWidth => _effective.logoWidths['headerMobile'] ?? 132;
}
