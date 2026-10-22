import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TamaraInfoScreen extends StatelessWidget {
  final double price;
  const TamaraInfoScreen({super.key, required this.price});

  @override
  Widget build(BuildContext context) {
    final two = (price / 2.0);
    final three = (price / 3.0);
    final four = (price / 4.0);
    final full = price;

    TextStyle label = const TextStyle(fontSize: 12, color: Color(0xFF374151));
    TextStyle bold = const TextStyle(fontSize: 12, color: Color(0xFF111827), fontWeight: FontWeight.w600);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Page content
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Close icon that scrolls with content
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            tooltip: 'payment_close_tooltip'.tr,
                            onPressed: () => Get.back(),
                            icon: const Icon(Icons.close, color: Colors.black87, size: 24),
                          ),
                        ],
                      ),
                      const SizedBox(height: 0),
                      // Tamara pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFBC7B8), Color(0xFFD299F3)],
                          ),
                        ),
                        child: const Text(
                          'tamara',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                          children: [
                            TextSpan(
                              text: 'payment_tamara_headline1'.tr,
                              style: TextStyle(color: Colors.black),
                            ),
                            const TextSpan(text: '\n'),
                            TextSpan(
                              text: 'payment_tamara_headline2'.tr,
                              style: TextStyle(
                                foreground: Paint()
                                  ..shader = const LinearGradient(
                                    colors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
                                  ).createShader(const Rect.fromLTWH(0, 0, 220, 40)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Payment options
                      _optionRow(context, 'Ð ${two.toStringAsFixed(2)}', 'payment_per_month'.tr, 'payment_no_fees'.tr, 'payment_2_payments'.tr),
                      const SizedBox(height: 8),
                      _optionRow(context, 'Ð ${three.toStringAsFixed(2)}', 'payment_per_month'.tr, 'payment_no_fees'.tr, 'payment_3_payments'.tr),
                      const SizedBox(height: 8),
                      _optionRow(context, 'Ð ${four.toStringAsFixed(2)}', 'payment_per_month'.tr, 'payment_no_fees'.tr, 'payment_4_payments'.tr),
                      const SizedBox(height: 8),
                      _optionRow(context, 'Ð ${full.toStringAsFixed(2)}', '', 'payment_no_fees'.tr, 'payment_pay_in_full'.tr),

                      const SizedBox(height: 20),
                      // How it works
                      Text('payment_how_it_works'.tr, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            _HowItWorksItem(
                              n: 1,
                              title: 'payment_tamara_step1_title'.tr,
                              desc: 'payment_tamara_step1_desc'.tr,
                            ),
                            SizedBox(height: 10),
                            SizedBox(height: 10),
                            _HowItWorksItem(
                              n: 2,
                              title: 'payment_tamara_step2_title'.tr,
                              desc: 'payment_tamara_step2_desc'.tr,
                            ),
                            SizedBox(height: 10),
                            SizedBox(height: 10),
                            _HowItWorksItem(
                              n: 3,
                              title: 'payment_tamara_step3_title'.tr,
                              desc: 'payment_tamara_step3_desc'.tr,
                            ),
                            SizedBox(height: 10),
                            SizedBox(height: 10),
                            _HowItWorksItem(
                              n: 4,
                              title: 'payment_tamara_step4_title'.tr,
                              desc: 'payment_tamara_step4_desc'.tr,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Why Tamara
                      Text('payment_why_tamara'.tr, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _WhyIcon(icon: Icons.shield_outlined, color: Colors.green, text: 'payment_buyer_protection'.tr),
                          _WhyIcon(icon: Icons.verified, color: Colors.blue, text: 'payment_sharia_compliant'.tr),
                          _WhyIcon(icon: Icons.close, color: Colors.purple, text: 'payment_no_late_fees'.tr),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Disclaimer
                      Text.rich(
                        TextSpan(
                          style: label,
                          children: [
                            TextSpan(
                              text:
                                  'payment_tamara_disclaimer'.tr,
                            ),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: InkWell(
                                onTap: () {},
                                child: Text(
                                  'payment_terms_conditions'.tr,
                                  style: TextStyle(
                                    decoration: TextDecoration.underline,
                                    color: Color(0xFF7C3AED),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Payment badges (visual only)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _badge('Pay'),
                          const SizedBox(width: 8),
                          _badge('MC', bg: const LinearGradient(colors: [Colors.orange, Colors.red]), color: Colors.white),
                          const SizedBox(width: 8),
                          _badge('VISA', solid: Colors.blue, color: Colors.white),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionRow(BuildContext context, String amount, String suffix, String sub, String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                children: [
                  Text(amount, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                  if (suffix.isNotEmpty)
                    Text(' $suffix', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 14, color: Colors.green),
                  SizedBox(width: 4),
                  Text('payment_no_fees'.tr, style: TextStyle(fontSize: 11, color: Colors.green)),
                ],
              ),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(tag, style: const TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  static Widget _howItWorksStep(int n, String title, String desc) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(999)),
            child: Text('$n', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF4B5563))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF111827))),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFF374151))),
            ]),
          ),
        ],
      ),
    );
  }

  static Widget _badge(String text, {LinearGradient? bg, Color? solid, Color color = Colors.black}) {
    final decoration = bg != null
        ? BoxDecoration(gradient: bg, borderRadius: BorderRadius.circular(4))
        : BoxDecoration(color: solid ?? Colors.transparent, borderRadius: BorderRadius.circular(4), border: solid == null ? Border.all(color: Colors.black54) : null);
    return Container(
      width: 32,
      height: 24,
      alignment: Alignment.center,
      decoration: decoration,
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }
}

class _WhyIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _WhyIcon({required this.icon, required this.color, required this.text});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 6),
        Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563))),
      ],
    );
  }
}

class _HowItWorksItem extends StatelessWidget {
  final int n;
  final String title;
  final String desc;
  const _HowItWorksItem({required this.n, required this.title, required this.desc});
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(999)),
          child: Text('$n', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF4B5563))),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF111827))),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFF374151))),
            ],
          ),
        ),
      ],
    );
  }
}
