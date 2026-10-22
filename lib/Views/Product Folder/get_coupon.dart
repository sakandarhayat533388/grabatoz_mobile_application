import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:graba2z/Configs/config.dart';
import 'package:http/http.dart' as http;

// Simple ISO -> dd/MM/yyyy formatter
String _formatDate(String iso) {
  if (iso.isEmpty) return '';
  try {
    final d = DateTime.parse(iso).toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  } catch (_) {
    return iso;
  }
}

class Coupon {
  final int percent;
  final String code;
  final String title;
  final String giftLabel;
  final String description;
  final String minText;
  final String validText;
  final String scopeText;

  const Coupon({
    required this.percent,
    required this.code,
    required this.title,
    required this.giftLabel,
    required this.description,
    required this.minText,
    required this.validText,
    required this.scopeText,
  });

  factory Coupon.fromMap(Map<String, dynamic> m) {
    int pct = 0;
    // Prefer new API fields: percentage via discountValue when discountType == 'percentage'
    if ((m['discountType'] ?? '').toString().toLowerCase() == 'percentage') {
      final dv = m['discountValue'];
      if (dv is num) pct = dv.toInt();
      if (dv is String) pct = int.tryParse(dv) ?? 0;
    } else {
      // Fallbacks
      final dynamic pctRaw = m['discount'] ?? m['percent'] ?? m['percentage'];
      if (pctRaw is num) pct = pctRaw.toInt();
      if (pctRaw is String) pct = int.tryParse(pctRaw) ?? 0;
    }

    final String code = (m['code'] ?? m['couponCode'] ?? m['name'] ?? '').toString();

    final String desc = (m['description'] ??
            m['details'] ??
            m['note'] ??
            'product_coupon_default_desc'.tr)
        .toString();

    // Min order amount -> "Min: AED 1000"
    String minText = '';
    final dynamic minRaw = m['minOrderAmount'] ?? m['minPurchase'] ?? m['minAmount'] ?? m['minimumOrderValue'];
    if (minRaw != null && minRaw.toString().isNotEmpty) {
      final num? min = (minRaw is num) ? minRaw : num.tryParse(minRaw.toString());
      if (min != null && min > 0) minText = 'product_coupon_min_amount'.trParams({'amount': min.toStringAsFixed(0)});
    }
    if (minText.isEmpty) minText = 'product_coupon_min_none'.tr;

    // Valid From/Until -> "Valid: 01/10/2025 - 24/10/2025"
    String validText = '';
    final String fromIso = (m['validFrom'] ?? '').toString();
    final String untilIso = (m['validUntil'] ?? m['validTo'] ?? '').toString();
    final String fromFmt = fromIso.isNotEmpty ? _formatDate(fromIso) : '';
    final String untilFmt = untilIso.isNotEmpty ? _formatDate(untilIso) : '';
    if (fromFmt.isNotEmpty && untilFmt.isNotEmpty) {
      validText = 'product_coupon_valid_range'.trParams({'from': fromFmt, 'until': untilFmt});
    } else if (untilFmt.isNotEmpty) {
      validText = 'product_coupon_valid_till'.trParams({'until': untilFmt});
    } else {
      validText = 'product_coupon_valid_none'.tr;
    }

    // Scope/categories
    String scopeText = 'product_coupon_all_categories'.tr;
    final cats = m['categories'];
    if (cats is List && cats.isNotEmpty) {
      // Try to join category names; fallback to IDs/strings; else generic
      final names = <String>[];
      for (final c in cats) {
        if (c is Map && c['name'] != null && c['name'].toString().isNotEmpty) {
          names.add(c['name'].toString());
        } else if (c is String && c.isNotEmpty) {
          names.add(c);
        }
      }
      scopeText = names.isNotEmpty ? names.join(', ') : 'product_coupon_selected_categories'.tr;
    }

    return Coupon(
      percent: pct,
      code: code,
      title: 'product_coupon_promo_code'.tr,
      giftLabel: 'product_coupon_gift_label'.tr,
      description: desc,
      minText: minText,
      validText: validText,
      scopeText: scopeText,
    );
  }
}

Future<List<Coupon>> _fetchCoupons() async {
  try {
    final res = await http.get(Uri.parse(Configss.getCoupon));
    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      List<dynamic> list;
      if (decoded is List) {
        list = decoded;
      } else if (decoded is Map && decoded['coupons'] is List) {
        list = decoded['coupons'] as List;
      } else {
        list = const [];
      }
      return list
          .whereType<Map>()
          .map((m) => Coupon.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    }
  } catch (_) {}
  return const <Coupon>[];
}

Future<void> showCouponBottomSheet(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      final media = MediaQuery.of(context);
      final maxH = media.size.height * 0.8;
      return Center(
        child: Container(
          width: double.infinity,                     // ADD: fill available width
          constraints: BoxConstraints(maxHeight: maxH, maxWidth: 800),
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 20,
                offset: Offset(0, 10),
              )
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'product_coupons_title'.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: FutureBuilder<List<Coupon>>(
                        future: _fetchCoupons(),
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snap.hasError) {
                            return Center(child: Text('product_coupons_load_failed'.tr));
                          }
                          final items = snap.data ?? const <Coupon>[];
                          if (items.isEmpty) {
                            return Center(child: Text('product_coupons_empty'.tr));
                          }
                          return SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              children: [
                                for (int i = 0; i < items.length; i++) ...[
                                  _CouponCard(coupon: items[i], index: i),
                                  if (i != items.length - 1) const SizedBox(height: 12),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'product_close'.tr,
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _CouponCard extends StatefulWidget {
  final Coupon coupon;
  final int index;
  const _CouponCard({required this.coupon, required this.index});
  @override
  State<_CouponCard> createState() => _CouponCardState();
}

class _CouponCardState extends State<_CouponCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _opacity = CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic);
    _offset = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutBack));
    Future.delayed(Duration(milliseconds: widget.index * 90), () {
      if (mounted) _ac.forward();
    });
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.coupon;
    return AnimatedBuilder(
      animation: _ac,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: SlideTransition(position: _offset, child: child),
        );
      },
      child: _buildCoupon(context, c),
    );
  }

  Widget _buildCoupon(BuildContext context, Coupon c) {
    final yellow300 = const Color(0xFFFDE68A);
    final yellow200 = const Color(0xFFFef08a);
    final yellow100 = const Color(0xFFFEF9C3);
    final yellowBorder = const Color.fromARGB(255, 255, 213, 0);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE047), // left strip exact color
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                  border: Border(
                    top: BorderSide(color: yellowBorder, width: 2),
                    left: BorderSide(color: yellowBorder, width: 2),
                    bottom: BorderSide(color: yellowBorder, width: 2),
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          'product_coupon_discount_label'.tr,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: Colors.grey.shade800,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        width: 16,
                        height: 28,
                        decoration: BoxDecoration(
                          color: yellow200,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _bar(Colors.grey.shade800),
                            _bar(Colors.grey.shade500),
                            _bar(Colors.grey.shade800),
                            _bar(Colors.grey.shade500),
                            _bar(Colors.grey.shade800),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      Container(
                        // constraints: const BoxConstraints(minHeight: 110), // optional: keep/remove
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [yellow100, yellow200],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                          border: Border(
                            top: BorderSide(color: yellowBorder, width: 2),
                            right: BorderSide(color: yellowBorder, width: 2),
                            bottom: BorderSide(color: yellowBorder, width: 2),
                          ),
                          boxShadow: const [
                            BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 4)),
                          ],
                        ),
                        // Add inner horizontal padding to avoid notch overlap on text
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        // REPLACE LayoutBuilder with direct MediaQuery-based logic
                        child: Builder(
                          builder: (context) {
                            final double screenW = MediaQuery.of(context).size.width;
                            final bool wide = screenW > 380; // was constraints.maxWidth > 320
                            final TextAlign t = wide ? TextAlign.right : TextAlign.center;
                            final CrossAxisAlignment x = wide ? CrossAxisAlignment.end : CrossAxisAlignment.center;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Header: "GIFT COUPON" left, "% 7" right
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      c.giftLabel.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.percent, size: 16, color: Color(0xFF92400E)),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${c.percent}',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF92400E),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    'product_coupon_promo_code'.tr,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.center,
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: yellowBorder, width: 1),
                                        ),
                                        child: Text(
                                          c.code.toUpperCase(),
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 3,
                                            color: Color(0xFF92400E),
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          await Clipboard.setData(ClipboardData(text: c.code));
                                          if (!mounted) return;
                                          // ScaffoldMessenger.of(context).showSnackBar(
                                          //   const SnackBar(content: Text('Coupon code copied')),
                                          // );
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                          backgroundColor: const Color(0xFFFDE047),
                                          side: BorderSide(color: yellowBorder, width: 1),
                                          minimumSize: const Size(0, 0),
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          shape: RoundedRectangleBorder( // match promo code radius
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                        ),
                                        child: Text(
                                          'product_coupon_copy'.tr,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Description + Min/Valid/Category (force LEFT aligned)
                                Align(
                                  alignment: Alignment.centerLeft, // CHANGED
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start, // CHANGED
                                    children: [
                                      Text(
                                        c.description,
                                        textAlign: TextAlign.left, // CHANGED
                                        softWrap: true,
                                        overflow: TextOverflow.visible,
                                        style: const TextStyle(fontSize: 8, color: Colors.black87, height: 1.2),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        c.minText,
                                        textAlign: TextAlign.left, // CHANGED
                                        style: const TextStyle(fontSize: 10, color: Colors.black54,fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        c.validText,
                                        textAlign: TextAlign.left, // CHANGED
                                        style: const TextStyle(fontSize: 10, color: Colors.black54,fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        c.scopeText,
                                        textAlign: TextAlign.left, // CHANGED
                                        style: const TextStyle(fontSize: 10, color: Colors.black87, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      // Half-cut notches: only inner halves remain visible due to ClipRRect
                      Positioned(
                        left: -12, // half of 24px diameter => half-cut
                        top: 0,
                        bottom: 0,
                        child: Center(child: _notch(yellowBorder)),
                      ),
                      Positioned(
                        right: -12, // half of 24px diameter => half-cut
                        top: 0,
                        bottom: 0,
                        child: Center(child: _notch(yellowBorder)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bar(Color c) => Container(height: 2, width: double.infinity, color: c);
  Widget _notch(Color border) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 2),
      ),
    );
  }
}
