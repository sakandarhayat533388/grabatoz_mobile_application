import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:graba2z/Configs/config.dart';
import 'package:graba2z/Utils/packages.dart';
import 'package:http/http.dart' as http;

class TrackOrderScreen extends StatefulWidget {
  const TrackOrderScreen({Key? key}) : super(key: key);

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  final emailController = TextEditingController();
  final orderIdController = TextEditingController();
  String currentStatus = ""; // Change based on API response
  String orderIdFromJson = ""; // Change based on API response
  String createdDate = ""; // Change based on API response
  String totalAmount = ""; // Change based on API response
  String shippingName = ""; // Change based on API response
  String shippingAddress = ""; // Change based on API response
  String shippingCity = ""; // Change based on API response
  String shippingPhone = ""; // Change based on API response
  List orderItems = [];

  final List<String> steps = [
    "Order Placed",
    "Order Confirmed",
    "Processing",
    "Shipped",
    "Delivered"
  ];

  String _localizedStep(String step) {
    switch (step) {
      case 'Order Placed':
        return 'orders_step_placed'.tr;
      case 'Order Confirmed':
        return 'orders_step_confirmed'.tr;
      case 'Processing':
        return 'orders_step_processing'.tr;
      case 'Shipped':
        return 'orders_step_shipped'.tr;
      case 'Delivered':
        return 'orders_step_delivered'.tr;
      default:
        return step;
    }
  }

  int getCurrentStep() {
    return steps.indexOf(currentStatus);
  }

  bool isloading = false;
  Future<void> trackOrder(String email, String orderId) async {
    try {
      // Get token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      isloading = true;
      // API endpoint
      setState(() {});
      String url = Configss.trackOrders;

      // Headers
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // Body
      final body = jsonEncode({
        'email': email,
        'orderId': orderId,
      });

      // POST Request
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );
      isloading = false;
      setState(() {});
      // Response Handling
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        currentStatus = data['status'].toString();
        orderIdFromJson = data['_id'].toString();
        createdDate = data['createdAt'].toString();
        totalAmount = data['totalPrice'].toString();
        orderItems = data['orderItems'];
        if (data['deliveryType'] == 'pickup') {
        } else {
          shippingName = data['shippingAddress']['name'].toString();
          shippingAddress = data['shippingAddress']['address'].toString();
          shippingCity = data['shippingAddress']['city'].toString();
          shippingPhone = data['shippingAddress']['city'].toString();
        }
        setState(() {});
        print("Order Tracked: $data");
      } else {
        final data = jsonDecode(response.body);
        EasyLoading.showError('${data['message']}');
        print("Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Exception: $e");
      isloading = false;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        titleText: 'orders_track_title'.tr,
        showLeading: true,
        actionicon: const SizedBox.shrink(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Text(
                'orders_track_hint'.tr,
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'profile_email'.tr,
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: kPrimaryColor, width: 1.5),
                  ),
                  labelStyle: const TextStyle(color: kSecondaryColor),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: orderIdController,
                decoration: InputDecoration(
                  labelText: 'orders_order_id'.tr,
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: kPrimaryColor, width: 1.5),
                  ),
                  labelStyle: TextStyle(color: kSecondaryColor),
                ),
              ),
              const SizedBox(height: 16),
              isloading
                  ? SizedBox(
                      height: 40,
                      width: 30,
                      child: Center(
                        child: CircularProgressIndicator(color: kPrimaryColor),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: () {
                        if (emailController.text.isNotEmpty &&
                            orderIdController.text.isNotEmpty) {
                          FocusScope.of(context).unfocus();
                          trackOrder(emailController.text.toString(),
                              orderIdController.text.toString());
                        }
                      },
                      icon: const Icon(Icons.search, color: kdefwhiteColor),
                      label: Text(
                        'settings_track_order'.tr,
                        style: TextStyle(color: kdefwhiteColor),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
              currentStatus.isNotEmpty
                  ? Column(
                      children: [
                        const SizedBox(height: 30),
                        _buildOrderDetails(),
                        const SizedBox(height: 30),
                        _buildOrderStepper(),
                      ],
                    )
                  : Text('')
            ],
          ),
        ),
      ),
    );
  }

  formatDate(String createdAt) {
    DateTime parsedDate = DateTime.parse(createdAt);
    String formattedDate =
        "${parsedDate.month}/${parsedDate.day}/${parsedDate.year}";
    return formattedDate;
  }

  Widget _buildOrderDetails() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('orders_details_title'.tr,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            _InfoRow('orders_order_id'.tr, orderIdFromJson),
            _InfoRow('orders_order_date'.tr, formatDate(createdDate)),
            _InfoRow('orders_total_amount'.tr, "${totalAmount} AED"),
            SizedBox(height: 16),
            Text('orders_shipping_address'.tr,
                style: TextStyle(fontWeight: FontWeight.bold)),
            shippingAddress.isEmpty
                ? Text('orders_na'.tr)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shippingName),
                      Text(shippingAddress),
                      Text(shippingCity),
                      Text('orders_phone_label'.trParams({'phone': shippingPhone})),
                    ],
                  )
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStepper() {
    int currentStep = getCurrentStep();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('orders_progress'.tr,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(steps.length, (index) {
              Color color =
                  index <= currentStep ? kPrimaryColor : kdefgreyColor.withOpacity(0.3);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: color,
                      child: Icon(
                        index < currentStep
                            ? Icons.check
                            : index == currentStep
                                ? Icons.timelapse
                                : Icons.radio_button_unchecked,
                        color: kdefwhiteColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _localizedStep(steps[index]),
                      style: TextStyle(
                        fontSize: 12,
                        color: index <= currentStep
                            ? kmediumblackColor
                            : kdefgreyColor,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.local_shipping_outlined, color: kPrimaryColor),
            const SizedBox(width: 8),
            Text(
              'orders_current_status'.trParams({'status': _localizedStep(currentStatus)}),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        SizedBox(
          height: 10,
        ),
        // Product List
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: orderItems.length,
          itemBuilder: (context, index) {
            final item = orderItems[index];
            final product = item['product'];
            return Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    product['image'],
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(
                  product['name'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14),
                ),
                subtitle:
                    Text('${'orders_qty'.trParams({'qty': '${item['quantity']}'})}  •  AED${item['price']}'),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
