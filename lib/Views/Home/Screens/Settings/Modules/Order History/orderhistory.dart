import 'package:get/get.dart';
import 'package:graba2z/Views/Home/Screens/Settings/Modules/Order%20History/orderhistorytabs.dart';
import '../../../../../../Controllers/orderController.dart';
import '../../../../../../Utils/packages.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        titleText: 'orders_my_orders'.tr,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ActiveOrdersTab(),
        ),
      ),
    );
  }
}

// import 'package:get/get.dart';
// import 'package:graba2z/Views/Home/Screens/Settings/Modules/Order%20History/orderhistorytabs.dart';
// import '../../../../../../Controllers/orderController.dart';
// import '../../../../../../Utils/packages.dart';

// class OrderHistoryScreen extends StatelessWidget {
//   const OrderHistoryScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return
//     DefaultTabController(
//       length: 3,
//       child: Scaffold(
//         appBar: CustomAppBar(
//           titleText: "My Orders",
//         ),
//         body: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Container(
//               padding: EdgeInsets.symmetric(vertical: 10),
//               color: kPrimaryColor.withValues(alpha: 0.2),
//               child: GetBuilder<OrderController>(builder: (
//                 orderProvider,
//               ) {
//                 return TabBar(
//                   labelPadding:
//                       EdgeInsets.symmetric(horizontal: 8, vertical: 0),
//                   overlayColor:
//                       const WidgetStatePropertyAll(Colors.transparent),
//                   dividerColor: Colors.transparent,
//                   indicatorColor: Colors.transparent,
//                   indicator: BoxDecoration(
//                     borderRadius: BorderRadius.circular(60),
//                     color: kPrimaryColor,
//                   ),
//                   labelColor: kdefwhiteColor,
//                   labelStyle: const TextStyle(
//                     fontSize: 12,
//                     fontFamily: "Montserrat",
//                     fontWeight: FontWeight.bold,
//                   ),
//                   unselectedLabelStyle: const TextStyle(
//                       fontSize: 10,
//                       fontWeight: FontWeight.w600,
//                       fontFamily: "Montserrat"),
//                   unselectedLabelColor: kPrimaryColor,
//                   tabs: [
//                     Center(
//                       child: Tab(
//                         text: 'Pending (${orderProvider.activeOrders.length})',
//                       ),
//                     ),
//                     Center(
//                       child: Tab(
//                         text:
//                             'Completed (${orderProvider.completedOrders.length})',
//                       ),
//                     ),
//                     Center(
//                       child: Tab(
//                         text:
//                             'Cancelled (${orderProvider.cancelledOrders.length})',
//                       ),
//                     ),
//                   ],
//                 );
//               }),
//             ),
//             const Expanded(
//               child: TabBarView(
//                 children: [
//                   ActiveOrdersTab(),
//                   CompletedOrdersTab(),
//                   CancelledOrderTab(),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
