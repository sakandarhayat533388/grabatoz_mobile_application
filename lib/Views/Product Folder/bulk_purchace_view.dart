import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:graba2z/Utils/packages.dart';
import 'package:graba2z/Views/Product%20Folder/request_form.dart';

class BulkPurchaceView extends StatefulWidget {
  const BulkPurchaceView({super.key});

  @override
  State<BulkPurchaceView> createState() => _BulkPurchaceViewState();
}

class _BulkPurchaceViewState extends State<BulkPurchaceView> {
  final List<Map<String, String>> steps = [
    {'step': 'product_bulk_step1', 'desc': 'product_bulk_step1_desc'},
    {'step': 'product_bulk_step2', 'desc': 'product_bulk_step2_desc'},
    {'step': 'product_bulk_step3', 'desc': 'product_bulk_step3_desc'},
    {'step': 'product_bulk_step4', 'desc': 'product_bulk_step4_desc'},
    {'step': 'product_bulk_step5', 'desc': 'product_bulk_step5_desc'},
    {'step': 'product_bulk_step6', 'desc': 'product_bulk_step6_desc'},
  ];
  final List<Map<String, String>> purchase = [
    {
      'step': 'product_bulk_trusted_title',
      'desc': 'product_bulk_trusted_desc'
    },
    {
      'step': 'product_bulk_sellers_title',
      'desc': 'product_bulk_sellers_desc'
    },
    {
      'step': 'product_bulk_trends_title',
      'desc': 'product_bulk_trends_desc'
    },
    {
      'step': 'product_bulk_range_title',
      'desc': 'product_bulk_range_desc'
    },
    {
      'step': 'product_bulk_qty_title',
      'desc': 'product_bulk_qty_desc'
    },
    {
      'step': 'product_bulk_users_title',
      'desc': 'product_bulk_users_desc'
    },
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Image.asset(
          AppImages.logoicon,
          height: 40,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 10,
                ),
                Text(
                  'product_bulk_hero_title'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: kPrimaryColor),
                ),
                SizedBox(
                  height: 10,
                ),
                Container(
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withValues(alpha: 0.3),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Text(
                          'product_bulk_headline'.tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 21, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          'product_bulk_headline_sub'.tr,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'product_bulk_welcome'.tr,
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset('assets/images/bulkP.jpeg'),
                ),
                SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'product_bulk_benefits_title'.tr,
                    // textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'product_bulk_benefits_desc'.tr,
                    // textAlign: TextAlign.center,
                  ),
                ),
                // Container(
                //   height: 55,
                //   width: 200,
                //   margin: EdgeInsets.symmetric(horizontal: 8),
                //   decoration: BoxDecoration(
                //       color: kPrimaryColor,
                //       borderRadius: BorderRadius.circular(8)),
                //   child: Center(
                //     child: Text(
                //       'Contact Sales',
                //       style: TextStyle(
                //           color: Colors.white,
                //           fontSize: 16,
                //           fontWeight: FontWeight.w600),
                //     ),
                //   ),
                // ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      'product_bulk_journey_title'.tr,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                GridView.builder(
                  itemCount: steps.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.6,
                  ),
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: Color(0xff8BC34A), width: 1.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            steps[index]['step']!.tr,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            steps[index]['desc']!.tr,
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                SizedBox(
                  height: 10,
                ),
                Text(
                  'product_bulk_why_title'.tr,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: 10,
                ),
                ListView.builder(
                  itemCount: purchase.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return Container(
                        margin: EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: Color(0xff8BC34A), width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: ListTile(
                          title: Text(
                            purchase[index]['step']!.tr,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(
                            purchase[index]['desc']!.tr,
                            style: const TextStyle(fontSize: 12),
                            // textAlign: TextAlign.center,
                          ),
                        ));
                  },
                ),
                SizedBox(
                  height: 15,
                ),
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) {
                        return RequestForm();
                      },
                    );
                  },
                  child: Container(
                    height: 55,
                    width: double.infinity,
                    // width: 200,
                    // margin: EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                        color: kPrimaryColor,
                        borderRadius: BorderRadius.circular(8)),
                    child: Center(
                      child: Text(
                        'product_bulk_contact_sales'.tr,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 60,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
