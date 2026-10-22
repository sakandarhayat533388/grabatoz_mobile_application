import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:graba2z/Controllers/addtocart.dart';
import 'package:graba2z/Controllers/first_user_discount_controller.dart';
import 'package:graba2z/Utils/guest_checkout_storage.dart';
import 'package:graba2z/Views/Home/Screens/Cart/cancel_page.dart';
import 'package:graba2z/Views/success_page/successpayment.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  final String? userId;
  final bool appDiscountApplied;
  final double appDiscountAmount;
  final String appDiscountName;

  const WebViewScreen({
    Key? key,
    required this.url,
    this.userId,
    this.appDiscountApplied = false,
    this.appDiscountAmount = 0.0,
    this.appDiscountName = '',
  }) : super(key: key);

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  InAppWebViewController? webViewController;
  double progress = 0;
  bool _handledTerminalUrl = false;

  Future<void> _handlePaymentSuccess() async {
    if (_handledTerminalUrl) return;
    _handledTerminalUrl = true;
    if (Get.isRegistered<CartNotifier>()) {
      await Get.find<CartNotifier>().clearCartDataInPrefs(widget.userId);
    }
    await clearGuestCheckoutData();
    if (Get.isRegistered<FirstUserDiscountController>()) {
      await Get.find<FirstUserDiscountController>().refreshAfterOrder();
    }
    Get.offAll(() => SuccessPayment(
          appDiscountApplied: widget.appDiscountApplied,
          appDiscountAmount: widget.appDiscountAmount,
          appDiscountName: widget.appDiscountName,
        ));
  }

  void _handlePaymentCancel() {
    if (_handledTerminalUrl) return;
    _handledTerminalUrl = true;
    log('get back to shopping');
    Get.offAll(() => const CancelPagePayment());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('checkout_payment'.tr),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (progress < 1.0) LinearProgressIndicator(value: progress),
            Expanded(
              child: InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(widget.url)),
                onWebViewCreated: (controller) {
                  webViewController = controller;
                },
                onProgressChanged: (controller, progressValue) {
                  if (!mounted) return;
                  setState(() {
                    progress = progressValue / 100;
                  });
                },
                onLoadStop: (controller, url) {
                  if (url == null) return;
                  final currentUrl = url.toString();
                  if (currentUrl.contains("payment/success")) {
                    _handlePaymentSuccess();
                  } else if (currentUrl.contains("payment/cancel")) {
                    _handlePaymentCancel();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
