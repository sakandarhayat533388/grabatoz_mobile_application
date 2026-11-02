import 'package:flutter/material.dart';

/// Parses a hex color string into a [Color].
///
/// - Trims whitespace; null / empty returns null.
/// - Strips a leading '#'.
/// - 6 hex digits -> `Color(0xFF000000 | value)`.
/// - 3 hex digits -> expands each nibble (abc -> aabbcc).
/// - Anything else / invalid returns null.
Color? parseHexColor(String? hex) {
  if (hex == null) return null;
  var value = hex.trim();
  if (value.isEmpty) return null;
  if (value.startsWith('#')) {
    value = value.substring(1);
  }
  if (value.length == 3) {
    final buffer = StringBuffer();
    for (var i = 0; i < value.length; i++) {
      buffer.write(value[i]);
      buffer.write(value[i]);
    }
    value = buffer.toString();
  }
  if (value.length != 6) return null;
  final parsed = int.tryParse(value, radix: 16);
  if (parsed == null) return null;
  return Color(0xFF000000 | parsed);
}

class AppTheme {
  final bool enabled;
  final String brandPrimary;
  final Map<String, String> brandScale;
  final Map<String, String> header;
  final Map<String, String> navbar;
  final Map<String, String> footer;
  final Map<String, String> buttons;
  final Map<String, String> page;
  final Map<String, String> logos;
  final Map<String, double> logoWidths;

  const AppTheme({
    required this.enabled,
    required this.brandPrimary,
    required this.brandScale,
    required this.header,
    required this.navbar,
    required this.footer,
    required this.buttons,
    required this.page,
    required this.logos,
    required this.logoWidths,
  });

  static Map<String, String> _strMap(dynamic value) {
    if (value is! Map) return <String, String>{};
    final result = <String, String>{};
    value.forEach((key, v) {
      if (v == null) return;
      result[key.toString()] = v.toString();
    });
    return result;
  }

  factory AppTheme.fromJson(Map<String, dynamic> json) {
    final logos = <String, String>{};
    final logoWidths = <String, double>{};
    final rawLogos = json['logos'];
    if (rawLogos is Map) {
      rawLogos.forEach((key, value) {
        if (value == null) return;
        final k = key.toString();
        if (k.endsWith('Width')) {
          double? width;
          if (value is num) {
            width = value.toDouble();
          } else if (value is String) {
            width = double.tryParse(value);
          }
          if (width != null) {
            logoWidths[k.substring(0, k.length - 'Width'.length)] = width;
            return;
          }
        }
        if (value is String) {
          logos[k] = value;
        } else if (value is! num) {
          logos[k] = value.toString();
        }
      });
    }

    return AppTheme(
      enabled: json['enabled'] is bool ? json['enabled'] as bool : true,
      brandPrimary: json['brandPrimary'] is String
          ? json['brandPrimary'] as String
          : '',
      brandScale: _strMap(json['brandScale']),
      header: _strMap(json['header']),
      navbar: _strMap(json['navbar']),
      footer: _strMap(json['footer']),
      buttons: _strMap(json['buttons']),
      page: _strMap(json['page']),
      logos: logos,
      logoWidths: logoWidths,
    );
  }

  static AppTheme defaults() {
    return AppTheme(
      enabled: true,
      brandPrimary: '#84cc16',
      brandScale: const {
        '50': '#f7fee7',
        '100': '#ecfccb',
        '200': '#d9f99d',
        '300': '#bef264',
        '400': '#a3e635',
        '500': '#84cc16',
        '600': '#65a30d',
        '700': '#4d7c0f',
        '800': '#3f6212',
        '900': '#365314',
        '950': '#1a2e05',
      },
      header: const {
        'background': '#ffffff',
        'text': '#374151',
        'icon': '#374151',
        'border': '#000000',
        'searchButtonBackground': '#84cc16',
        'searchButtonHoverBackground': '#65a30d',
        'searchButtonText': '#ffffff',
        'badgeBackground': '#ef4444',
        'badgeText': '#ffffff',
      },
      navbar: const {
        'background': '#84cc16',
        'text': '#ffffff',
        'hoverBackground': '#65a30d',
        'hoverText': '#ffffff',
        'activeIndicator': '#ffffff',
        'buttonBackground': '#ffffff',
        'buttonText': '#84cc16',
        'dropdownBackground': '#ffffff',
        'dropdownText': '#374151',
        'dropdownHoverBackground': '#f3f4f6',
        'dropdownHoverText': '#111827',
      },
      footer: const {
        'background': '#1f1f39',
        'text': '#ffffff',
        'heading': '#ffffff',
        'link': '#ffffff',
        'linkHover': '#a3e635',
        'border': '#e5e7eb',
        'bottomBarBackground': '#1f1f39',
        'bottomBarText': '#ffffff',
        'mobileBackground': '#ffffff',
        'mobileText': '#374151',
        'mobileHeading': '#111827',
        'mobileLinkHover': '#f97316',
      },
      buttons: const {
        'primaryBackground': '#84cc16',
        'primaryHoverBackground': '#65a30d',
        'primaryText': '#ffffff',
        'secondaryBackground': '#ea580c',
        'secondaryHoverBackground': '#c2410c',
        'secondaryText': '#ffffff',
        'secondaryBorder': '#ea580c',
      },
      page: const {
        'background': '#ffffff',
        'surface': '#f9fafb',
        'text': '#374151',
        'heading': '#111827',
        'muted': '#6b7280',
        'link': '#65a30d',
        'linkHover': '#4d7c0f',
        'border': '#e5e7eb',
        'price': '#dc2626',
        'oldPrice': '#9ca3af',
      },
      logos: const {
        'headerDesktop': '/admin-logo.svg',
        'headerMobile': '/admin-logo.svg',
        'footer': '/logo.png',
        'favicon': '/favicon.png',
        'altText': 'GrabAtoZ',
      },
      logoWidths: const {
        'headerDesktop': 176,
        'headerMobile': 132,
        'footer': 128,
      },
    );
  }
}
