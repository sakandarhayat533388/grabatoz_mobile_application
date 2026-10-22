// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:graba2z/Utils/appcolors.dart';
import 'package:graba2z/Utils/appextensions.dart';
import 'package:graba2z/Utils/packages.dart';
import 'package:graba2z/Views/Home/home.dart';

class CancelPagePayment extends StatelessWidget {
  const CancelPagePayment({super.key});

  @override
  Widget build(BuildContext context) {
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
                          child: Icon(
                        Icons.cancel_outlined,
                        color: Colors.red,
                        size: 35,
                      )
                          // fit: BoxFit.cover),             
                          //child: Image.asset("assets/images/success.png",
                          // fit: BoxFit.cover),
                          ),
                    ),
                  ),
                  20.0.heightbox,
                  Text(
                    'payment_cancelled'.tr,
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
