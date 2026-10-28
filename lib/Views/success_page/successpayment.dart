// ignore_for_file: use_build_context_synchronously

import 'package:get/get.dart';
import 'package:graba2z/Controllers/loyalty_controller.dart';
import 'package:graba2z/Utils/appextensions.dart';
import 'package:graba2z/Views/Home/home.dart';
import '../../Utils/packages.dart';

class SuccessPayment extends StatelessWidget {
  final bool appDiscountApplied;
  final double appDiscountAmount;
  final String appDiscountName;
  // Grabian Points + Referrals outcome of this order, as reported by the
  // order endpoint (the authority — never the quote values).
  final int loyaltyPointsEarned;
  final int loyaltyPointsRedeemed;
  final double loyaltyDiscountAmount;
  final double referralDiscountAmount;
  final String loyaltyPointsName;

  const SuccessPayment({
    super.key,
    this.appDiscountApplied = false,
    this.appDiscountAmount = 0.0,
    this.appDiscountName = '',
    this.loyaltyPointsEarned = 0,
    this.loyaltyPointsRedeemed = 0,
    this.loyaltyDiscountAmount = 0.0,
    this.referralDiscountAmount = 0.0,
    this.loyaltyPointsName = '',
  });

  @override
  Widget build(BuildContext context) {
    // Points programme name comes from the API (never hardcoded); the
    // payment flow passes it in, with the controller as a fallback.
    String pointsName = loyaltyPointsName;
    if (pointsName.isEmpty && Get.isRegistered<LoyaltyController>()) {
      pointsName = Get.find<LoyaltyController>().pointsName;
    }

    void showBackDialog(BuildContext context) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: kdefwhiteColor),
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'payment_are_you_sure'.tr,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('payment_exit_app'.tr),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Container(
                        width: 100,
                        decoration: BoxDecoration(
                          color: kPrimaryColor,
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: TextButton(
                          onPressed: () {
                            SystemNavigator.pop();
                          },
                          child: Text(
                            'payment_yes'.tr,
                            style: TextStyle(
                                color: kdefwhiteColor,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      Container(
                        width: 100,
                        decoration: BoxDecoration(
                          color: kdefwhiteColor,
                          borderRadius: BorderRadius.circular(60),
                          border: Border.all(color: kdefgreyColor),
                        ),
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('payment_no'.tr,
                              style: TextStyle(
                                  color: kmediumblackColor,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          return;
        }
        showBackDialog(context);
        return;
      },
      child: Scaffold(
        appBar:
            CustomAppBar(titleText: 'payment_confirmation'.tr, showLeading: false),
        body: SafeArea(
          child: Padding(
            padding: defaultPadding(),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24)),
                      child: Center(
                        child: Image.asset("assets/images/success.png",
                            fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  20.0.heightbox,
                  Text(
                    'payment_order_successful'.tr,
                    style: TextStyle(
                      fontSize: 28,
                      color: kdefblackColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  10.0.heightbox,
                  Text(
                    textAlign: TextAlign.center,
                    'payment_order_placed'.tr,
                    style: const TextStyle(
                        fontSize: 15,
                        color: kdefblackColor,
                        fontWeight: FontWeight.w500),
                  ),
                  if (appDiscountApplied && appDiscountAmount > 0) ...[
                    16.0.heightbox,
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kPrimaryColor),
                      ),
                      child: Text(
                        '${appDiscountName.isNotEmpty ? appDiscountName : 'payment_first_app_order_discount'.tr} ${'payment_applied'.tr}: AED ${appDiscountAmount.toStringAsFixed(2)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF166534),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  if (loyaltyPointsEarned > 0 && pointsName.isNotEmpty) ...[
                    12.0.heightbox,
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kPrimaryColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.stars,
                              size: 16, color: Color(0xFF166534)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'loyalty_earned_body'.trParams({
                                'points': '$loyaltyPointsEarned',
                                'name': pointsName,
                              }),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF166534),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (loyaltyDiscountAmount > 0 ||
                      referralDiscountAmount > 0) ...[
                    12.0.heightbox,
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: kdefwhiteColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kPrimaryColor),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (loyaltyDiscountAmount > 0)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    'loyalty_redeem_line'.trParams({
                                          'name': pointsName.isNotEmpty
                                              ? pointsName
                                              : 'loyalty_title'.tr,
                                        }) +
                                        (loyaltyPointsRedeemed > 0
                                            ? ' ($loyaltyPointsRedeemed)'
                                            : ''),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: kdefblackColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '- AED ${loyaltyDiscountAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF166534),
                                  ),
                                ),
                              ],
                            ),
                          if (loyaltyDiscountAmount > 0 &&
                              referralDiscountAmount > 0)
                            const Divider(height: 16),
                          if (referralDiscountAmount > 0)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    'referral_reward_line'.tr,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: kdefblackColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '- AED ${referralDiscountAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF166534),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: defaultPadding(vertical: 10),
            child: PrimaryButton(
              buttonText: 'payment_continue_shopping'.tr,
              onPressFunction: () async {
                showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) {
                      return const Center(
                          child:
                              CircularProgressIndicator(color: kPrimaryColor));
                    });

                await Future.delayed(const Duration(seconds: 2));

                Navigator.of(context).pop();

                final navigationProvider =
                    Get.put(BottomNavigationController());

                navigationProvider.setTabIndex(0);

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const Home()),
                  (route) => false,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
