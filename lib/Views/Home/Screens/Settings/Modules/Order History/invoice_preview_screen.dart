import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';
import 'package:graba2z/Utils/invoice_generator.dart';
import 'package:graba2z/Utils/packages.dart';

class InvoicePreviewScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const InvoicePreviewScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        titleText: 'orders_invoice_preview'.tr,
      ),
      body: PdfPreview(
        build: (format) => generateInvoicePdfBytes(order),
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: false,
        canChangeOrientation: false,
        pdfFileName: "invoice_${order['_id'] ?? 'order'}.pdf",
        loadingWidget: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(kdefgreenColor),
          ),
        ),
      ),
    );
  }
}
