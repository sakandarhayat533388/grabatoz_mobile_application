import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TabbyInfoScreen extends StatefulWidget {
  final double price;
  const TabbyInfoScreen({super.key, required this.price});

  @override
  State<TabbyInfoScreen> createState() => _TabbyInfoScreenState();
}

class _TabbyInfoScreenState extends State<TabbyInfoScreen> {
  // No scroll gating; CTA is always visible after the Tabby section.

  static const String _logoUrl = 'https://res.cloudinary.com/dyfhsu5v6/image/upload/v1759294149/tabby-logo-1_oqkdwm.png';
  static const String _heroUrl = 'https://redlearning.org/wp-content/uploads/2024/04/red-learning-flexible-payment-options-with-tabby.jpg';

  @override
  void initState() {
    super.initState();
    // Warm cache after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      precacheImage(const CachedNetworkImageProvider(_logoUrl), context);
      precacheImage(const CachedNetworkImageProvider(_heroUrl), context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final four = widget.price > 0 ? (widget.price / 4.0) : 0.0;
    final six = widget.price > 0 ? (widget.price / 6.0) : 0.0;
    final eight = widget.price > 0 ? (widget.price / 8.0) : 0.0;
    final twelve = widget.price > 0 ? (widget.price / 12.0) : 0.0;

    final radius = 28.0; // used for hero rounded bottom

    return Scaffold(
      backgroundColor: Colors.white,
      // No AppBar; close button is inside scrollable content
      body: SafeArea(
        child: SingleChildScrollView(
          // no controller
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header row (logo left, close right) that scrolls with the page
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 5),
                child: Row(
                  children: [
                    CachedNetworkImage(
                      imageUrl: _logoUrl,
                      height: 38,
                      fadeInDuration: const Duration(milliseconds: 150),
                      placeholder: (_, __) => const SizedBox(height: 38, width: 120),
                      errorWidget: (_, __, ___) => const SizedBox(height: 38, width: 120),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'payment_close_tooltip'.tr,
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close, color: Colors.black87, size: 24),
                    ),
                  ],
                ),
              ),
              // Gradient hero (rounded-b-3xl)
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF7C3AED), Color(0xFFEC4899), Color(0xFF6D28D9)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(radius),
                    bottomRight: Radius.circular(radius),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: _heroUrl,
                        height: 170,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        fadeInDuration: const Duration(milliseconds: 200),
                        placeholder: (context, url) => Container(
                          height: 170,
                          color: const Color(0xFFF3F4F6),
                          alignment: Alignment.center,
                          child: const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 170,
                          color: const Color(0xFFF3F4F6),
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'payment_tabby_headline'.tr,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 24),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'payment_tabby_sub'.tr,
                      style: TextStyle(color: Color(0xFFE9D5FF), fontSize: 14),
                    ),
                  ],
                ),
              ),
              // Options (bg-gray-50 + divide-y)
              Container(
                color: const Color(0xFFF9FAFB),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  children: [
                    _optionTile('payment_4_payments'.tr, '𝐃 ${four.toStringAsFixed(2)}', 'payment_per_month'.tr, 'payment_no_interest_fees'.tr, highlight: true),
                    _divider(),
                    _optionTile('payment_6_payments'.tr, '𝐃 ${six.toStringAsFixed(2)}', 'payment_per_month'.tr, 'payment_monthly_fee_note'.trParams({'amount': '13.05'})),
                    _divider(),
                    _optionTile('payment_8_payments'.tr, '𝐃 ${eight.toStringAsFixed(2)}', 'payment_per_month'.tr, 'payment_monthly_fee_note'.trParams({'amount': '17.61'})),
                    _divider(),
                    _optionTile('payment_12_payments'.tr, '𝐃 ${twelve.toStringAsFixed(2)}', 'payment_per_month'.tr, 'payment_monthly_fee_note'.trParams({'amount': '22.18'})),
                  ],
                ),
              ),
              // How it works
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Text('payment_how_it_works'.tr, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _HowStep(n: 1, text: 'payment_tabby_step1'.tr),
                    SizedBox(height: 12),
                    _HowStep(n: 2, text: 'payment_tabby_step2'.tr),
                    SizedBox(height: 12),
                    _HowStep(n: 3, text: 'payment_tabby_step3'.tr),
                    SizedBox(height: 12),
                    _HowStep(n: 4, text: 'payment_tabby_step4'.tr),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),

              // Trust badges
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                child: Column(
                  children: [
                    _BadgeTile(
                      iconBg: Color(0xFFF3E8FF),
                      iconColor: Color(0xFF7C3AED),
                      title: 'payment_trusted_millions'.tr,
                      subtitle: 'payment_trusted_sub'.tr,
                      icon: Icons.groups_rounded,
                    ),
                    SizedBox(height: 12),
                    _BadgeTile(
                      iconBg: Color(0xFFE6F5EA),
                      iconColor: Color(0xFF16A34A),
                      title: 'payment_shop_safely'.tr,
                      subtitle: 'payment_buyer_protection_included'.tr,
                      icon: Icons.shield_outlined,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
              SizedBox(height: 12,),
              // Inline CTA always visible; same width as content (matches padding of badges)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Get.back(),
                    child: Text('payment_continue_shopping'.tr, style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              SizedBox(height: 5,),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
              SizedBox(height: 7,),

              // Payment chips under the CTA, aligned to same content width
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _chip('MC', gradient: const LinearGradient(colors: [Colors.orange, Colors.red]), color: Colors.white),
                    const SizedBox(width: 8),
                    _chip('VISA', solid: Colors.blue, color: Colors.white),
                    const SizedBox(width: 8),
                    _chip('Pay', solid: Colors.black, color: Colors.white),
                    const SizedBox(width: 8),
                    _chip('GPay', solid: const Color(0xFFF3F4F6), color: const Color(0xFF374151)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _divider() => const Divider(height: 1, color: Color(0xFFE5E7EB));
  static Widget _optionTile(String title, String amount, String suffix, String note, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: const Color(0xFFF9FAFB),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF111827))),
            Row(
              children: [
                Text(amount, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                const SizedBox(width: 4),
                Text(suffix, style: const TextStyle(color: Color(0xFF6B7280))),
              ],
            )
          ]),
          const SizedBox(height: 2),
          Text(
            note,
            style: TextStyle(
              fontSize: 12,
              color: highlight ? const Color(0xFF16A34A) : const Color(0xFF6B7280),
              fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _chip(String text, {LinearGradient? gradient, Color? solid, Color color = Colors.black}) {
    final decoration = gradient != null
        ? BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(8))
        : BoxDecoration(color: solid ?? Colors.white, borderRadius: BorderRadius.circular(8));
    return Container(
      width: 40,
      height: 26,
      alignment: Alignment.center,
      decoration: decoration,
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }
}

class _HowStep extends StatelessWidget {
  final int n;
  final String text;
  const _HowStep({required this.n, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(999)),
          child: Text('$n', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF374151))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF374151)))),
      ],
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final IconData icon;
  const _BadgeTile({required this.iconBg, required this.iconColor, required this.title, required this.subtitle, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)]),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(999)),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF111827))),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ]),
          ),
        ],
      ),
    );
  }
}
