import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:graba2z/Utils/image_helper.dart';
import 'package:graba2z/Utils/packages.dart';
import 'package:intl/intl.dart';
import 'package:graba2z/Views/Home/Screens/Settings/Modules/Order%20History/invoice_preview_screen.dart';

class OrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailScreen({super.key, required this.order});

  String formatPlacedDate(String dateStr) {
    try {
      DateTime parsed = DateTime.parse(dateStr);
      return DateFormat('EEEE, MMMM d, yyyy').format(parsed);
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildPaymentStatusBadge(String status) {
    Color bg;
    Color fg;
    String text;

    switch (status.toLowerCase()) {
      case 'delivered':
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF059669);
        text = 'Paid';
        break;
      case 'cancelled':
      case 'deleted':
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFDC2626);
        text = 'Cancelled';
        break;
      default:
        bg = const Color(0xFFFFFBEB);
        fg = const Color(0xFFD97706);
        text = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: kmediumblackColor,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kdefblackColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderItems = List<Map<String, dynamic>>.from(order['orderItems']);
    final status = order['status'] ?? 'Pending';
    final paymentMethod = order['paymentMethod'] ?? 'card';
    final totalPrice = order['totalPrice']?.toString() ?? '0';

    // Parse and calculate prices safely
    double subtotal = 0;
    for (final item in orderItems) {
      final double price =
          double.tryParse(item['price']?.toString() ?? '0') ?? 0;
      final int qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
      subtotal += price * qty;
    }

    double totalVal = double.tryParse(totalPrice) ?? subtotal;
    double shippingFee = totalVal - subtotal;
    if (shippingFee < 0) {
      shippingFee = 0;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        titleText: 'Order Details',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Placed Date Subtitle Header
              Text(
                "Placed on ${formatPlacedDate(order['createdAt'] ?? '')}",
                style: const TextStyle(
                  fontSize: 14,
                  color: kmediumblackColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              // Order Items Header
              Row(
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    color: kdefgreenColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Order Items",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kdefblackColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Product Items List
              ...orderItems.map((item) {
                final product =
                    Map<String, dynamic>.from(item['product'] ?? {});

                // Safe name and image extraction
                String productName =
                    item['name'] ?? product['name'] ?? 'Order Item';
                String productImage = item['image'] ?? product['image'] ?? '';

                double itemPrice =
                    double.tryParse(item['price']?.toString() ?? '0') ?? 0;
                String itemPriceFormatted = itemPrice.toStringAsFixed(2);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Image
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.15)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.network(
                            ImageHelper.getUrl(productImage),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.shopping_bag_outlined,
                              color: kmediumblackColor,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Details (Name + Qty)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              productName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: kdefblackColor,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Qty: ${item['quantity']}",
                              style: const TextStyle(
                                fontSize: 13,
                                color: kmediumblackColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            "AED",
                            style: TextStyle(
                              fontSize: 11,
                              color: kmediumblackColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            itemPriceFormatted,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: kdefblackColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),

              // Payment Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Payment Summary",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kdefblackColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Subtotal",
                          style: TextStyle(
                            fontSize: 14,
                            color: kmediumblackColor,
                          ),
                        ),
                        Text(
                          "AED ${subtotal.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: kdefblackColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Shipping Fee",
                          style: TextStyle(
                            fontSize: 14,
                            color: kmediumblackColor,
                          ),
                        ),
                        Text(
                          shippingFee > 0
                              ? "AED ${shippingFee.toStringAsFixed(2)}"
                              : "AED 0",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: kdefblackColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(
                        height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: kdefblackColor,
                          ),
                        ),
                        Text(
                          "AED ${totalVal.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: kdefgreenColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.payment_rounded,
                                size: 18,
                                color: kmediumblackColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                paymentMethod.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: kdefblackColor,
                                ),
                              ),
                            ],
                          ),
                          _buildPaymentStatusBadge(status),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Order Additional Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Delivery Details",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kdefblackColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _infoRow("Tracking ID",
                        "#${order['_id']?.toString().substring((order['_id']?.toString().length ?? 6) - 6) ?? ''}"),
                    _infoRow("Delivery Type",
                        "${order['deliveryType'] ?? 'Standard'}"),
                    _infoRow(
                        "Customer Note",
                        order['customerNotes'] != null &&
                                order['customerNotes']
                                    .toString()
                                    .trim()
                                    .isNotEmpty
                            ? "${order['customerNotes']}"
                            : "N/A"),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, -2),
              blurRadius: 8,
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () {
            Get.to(() => InvoicePreviewScreen(order: order));
          },
          icon: const Icon(Icons.print_outlined, color: Colors.white),
          label: const Text(
            "Print / Download Invoice",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: kdefgreenColor,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }
}
