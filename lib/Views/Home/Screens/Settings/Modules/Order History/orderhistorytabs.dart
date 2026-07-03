import 'package:get/get.dart';
import 'package:graba2z/Controllers/orderController.dart';
import 'package:graba2z/Views/Home/Screens/Settings/Modules/Order%20History/order_details_view.dart';
import 'package:graba2z/Views/Home/Screens/Settings/Modules/Order%20History/ordercard.dart';
import 'package:graba2z/Views/Home/Screens/Settings/Modules/Order%20History/invoice_preview_screen.dart';
import 'package:graba2z/Widgets/secondarybutton.dart';
import '../../../../../../Utils/packages.dart';

class ActiveOrdersTab extends StatefulWidget {
  const ActiveOrdersTab({super.key});

  @override
  ActiveOrdersTabState createState() => ActiveOrdersTabState();
}

class ActiveOrdersTabState extends State<ActiveOrdersTab> {
  late Future<void> _fetchOrdersFuture;
  OrderController _orderController = Get.put(OrderController());
  @override
  void initState() {
    super.initState();
    _fetchOrdersFuture =
        _orderController.getAllOrders(); // Load orders when the page starts
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => _orderController.isloading.value
        ? _buildShimmerLoading()
        : _orderController.activeOrders.isNotEmpty
            ? ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _orderController.activeOrders.length,
                itemBuilder: (context, index) {
                  final order = _orderController.activeOrders[index];
                  DateTime parsedDate = DateTime.parse(order['createdAt']);
                  String formattedDate =
                      "${parsedDate.month}/${parsedDate.day}/${parsedDate.year}";
                  return OrderCard(
                    orderId: order['_id'],
                    createdDate: formattedDate,
                    orderItems: order['orderItems'],
                    totalPrice: order['totalPrice'].toString(),
                    status: order['status'],
                    onViewDetails: () {
                      Get.to(() => OrderDetailScreen(order: order));
                    },
                    onDownloadInvoice: () {
                      Get.to(() => InvoicePreviewScreen(order: order));
                    },
                  );
                },
              )
            : Center(
                child: Text('No Order Found'),
              ));
  }

  // Shimmer loading widget
  Widget _buildShimmerLoading() {
    return ListView.builder(
      itemCount: 3,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
      },
    );
  }
}

// class CompletedOrdersTab extends StatefulWidget {
//   const CompletedOrdersTab({super.key});

//   @override
//   CompletedOrdersTabState createState() => CompletedOrdersTabState();
// }

// class CompletedOrdersTabState extends State<CompletedOrdersTab> {
//   late Future<void> _fetchOrdersFuture;

//   @override
//   void initState() {
//     super.initState();
//     _fetchOrdersFuture = _fetchOrders();
//   }

//   Future<void> _fetchOrders() async {
//     final prefs = await SharedPreferences.getInstance();
//     String? userId = prefs.getString('userId')?.toString();

//     if (userId != null) {
//       final orderProvider = Get.find<OrderController>();
//       // await orderProvider.fetchOrders(userId);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<void>(
//       future: _fetchOrdersFuture,
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return _buildShimmerLoading();
//         } else if (snapshot.hasError) {
//           return const Center(child: Text('Error fetching order history'));
//         } else {
//           return GetBuilder<OrderController>(
//             builder: (
//               orderProvider,
//             ) {
//               return orderProvider.completedOrders.isNotEmpty
//                   ? ListView.builder(
//                       itemCount: orderProvider.completedOrders.length,
//                       itemBuilder: (context, index) {
//                         final order = orderProvider.completedOrders[index];
//                         return Text('completed');
//                       },
//                     )
//                   : const Center(child: Text("No completed orders found"));
//             },
//           );
//         }
//       },
//     );
//   }

//   Widget _buildShimmerLoading() {
//     return ListView.builder(
//       itemCount: 5,
//       itemBuilder: (context, index) {
//         return Shimmer.fromColors(
//           baseColor: Colors.grey[300]!,
//           highlightColor: Colors.grey[100]!,
//           child: Padding(
//             padding:
//                 const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
//             child: Container(
//               height: 200,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// class CancelledOrderTab extends StatefulWidget {
//   const CancelledOrderTab({super.key});

//   @override
//   State<CancelledOrderTab> createState() => _CancelledOrderTabState();
// }

// class _CancelledOrderTabState extends State<CancelledOrderTab> {
//   late Future<void> _fetchOrdersFuture;

//   @override
//   void initState() {
//     super.initState();
//     _fetchOrdersFuture = _fetchOrders();
//   }

//   Future<void> _fetchOrders() async {
//     final prefs = await SharedPreferences.getInstance();
//     String? userId = prefs.getString('userId')?.toString();

//     if (userId != null) {
//       final orderProvider = Get.find<OrderController>();
//       // await orderProvider.fetchOrders(userId);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<void>(
//       future: _fetchOrdersFuture,
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return _buildShimmerLoading(); // Show shimmer while waiting for user ID
//         } else if (snapshot.hasError) {
//           return const Center(child: Text('Error fetching user ID'));
//         } else {
//           return GetBuilder<OrderController>(
//             builder: (
//               orderProvider,
//             ) {
//               return orderProvider.cancelledOrders.isNotEmpty
//                   ? ListView.builder(
//                       itemCount: orderProvider.cancelledOrders.length,
//                       itemBuilder: (context, index) {
//                         final order = orderProvider.cancelledOrders[index];
//                         return Text('Cancelled');
//                         // return OrderCard(
//                         //   order: order,
//                         //   actionButton: GestureDetector(
//                         //     onTap: () {},
//                         //     child: Container(),
//                         //   ),
//                         //   bottomtext: 'Cancelled',
//                         //   bottomWidget: SecondaryButton(
//                         //       buttonText: "Details",
//                         //       onPressFunction: () {
//                         //         // context.route(OrderDetailsScreen(order: order));
//                         //       }),
//                         // );
//                       },
//                     )
//                   : const Center(child: Text("No cancelled orders found"));
//             },
//           );
//         }
//       },
//     );
//   }

//   Widget _buildShimmerLoading() {
//     return ListView.builder(
//       itemCount: 5,
//       itemBuilder: (context, index) {
//         return Shimmer.fromColors(
//           baseColor: Colors.grey[300]!,
//           highlightColor: Colors.grey[100]!,
//           child: Padding(
//             padding:
//                 const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
//             child: Container(
//               height: 200,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
