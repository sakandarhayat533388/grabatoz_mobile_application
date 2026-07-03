import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle, ByteData;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

double resolveOrderItemBasePrice(Map<String, dynamic> item) {
  if (item['basePrice'] != null) {
    return double.tryParse(item['basePrice'].toString()) ?? 0;
  }
  if (item['product'] is Map && item['product']['basePrice'] != null) {
    return double.tryParse(item['product']['basePrice'].toString()) ?? 0;
  }
  if (item['originalPrice'] != null) {
    return double.tryParse(item['originalPrice'].toString()) ?? 0;
  }
  return double.tryParse(item['price']?.toString() ?? '0') ?? 0;
}

Map<String, dynamic> getInvoiceBreakdown(Map<String, dynamic> order) {
  final orderItems = List<Map<String, dynamic>>.from(order['orderItems'] ?? []);

  final regularItems = orderItems.where((item) {
    final isProtection = item['isProtection'] == true;
    final name = item['name']?.toString() ?? '';
    return !isProtection && !name.toLowerCase().contains('for ');
  }).toList();

  double subtotal = 0;
  for (final item in regularItems) {
    final double price = double.tryParse(item['price']?.toString() ?? '0') ?? 0;
    final int qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
    subtotal += price * qty;
  }

  final protectionItems = orderItems.where((item) {
    final isProtection = item['isProtection'] == true;
    final name = item['name']?.toString() ?? '';
    return isProtection || name.toLowerCase().contains('for ');
  }).toList();

  double protectionSubtotal = 0;
  for (final item in protectionItems) {
    final double price = double.tryParse(item['price']?.toString() ?? '0') ?? 0;
    final int qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
    protectionSubtotal += price * qty;
  }

  final double totalPrice =
      double.tryParse(order['totalPrice']?.toString() ?? '0') ??
          (subtotal + protectionSubtotal);
  final double shippingPrice =
      double.tryParse(order['shippingPrice']?.toString() ?? '0') ?? 0;
  final double discountAmount =
      double.tryParse(order['discountAmount']?.toString() ?? '0') ?? 0;
  final String couponCode = order['couponCode']?.toString() ?? '';

  final String paymentMethod = order['paymentMethod']?.toString() ?? 'card';
  final bool isCOD = paymentMethod.toLowerCase() == 'cod';

  final double codFee =
      double.tryParse(order['codFee']?.toString() ?? '0') ?? 0;
  final double codShippingFee =
      double.tryParse(order['codShippingFee']?.toString() ?? '0') ?? 0;

  // Custom fallback to match user VAT rounding (e.g. 5% of totalPrice)
  final double tax = double.tryParse(order['taxPrice']?.toString() ?? '') ??
      (totalPrice * 0.05);

  return {
    'subtotal': subtotal,
    'protectionSubtotal': protectionSubtotal,
    'shipping': shippingPrice,
    'tax': tax,
    'total': totalPrice,
    'couponCode': couponCode,
    'couponDiscount': discountAmount,
    'codFee': codFee,
    'codShippingFee': codShippingFee,
    'isCOD': isCOD,
    'displayTotal': totalPrice,
  };
}

// Vector drawings for PDF decoration without external unicode fonts
pw.Widget _buildCrownExcelLogo() {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      pw.Container(
        width: 40,
        height: 40,
        decoration: pw.BoxDecoration(
          shape: pw.BoxShape.circle,
          border: pw.Border.all(color: PdfColors.black, width: 3.5),
        ),
        alignment: pw.Alignment.center,
        child: pw.Stack(
          alignment: pw.Alignment.center,
          children: [
            pw.Container(
              width: 18,
              height: 2.5,
              color: PdfColors.black,
            ),
            pw.Transform.translate(
              offset: const PdfPoint(0, 5),
              child: pw.Container(
                width: 14,
                height: 2.5,
                color: PdfColors.black,
              ),
            ),
            pw.Transform.translate(
              offset: const PdfPoint(0, -5),
              child: pw.Container(
                width: 14,
                height: 2.5,
                color: PdfColors.black,
              ),
            ),
          ],
        ),
      ),
      pw.SizedBox(width: 8),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            "Crown",
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
          pw.Text(
            "Excel",
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
        ],
      ),
    ],
  );
}

pw.Widget _buildCircularContactIcon(PdfColor bg, String type) {
  return pw.Container(
    width: 13,
    height: 13,
    decoration: pw.BoxDecoration(
      color: bg,
      shape: pw.BoxShape.circle,
    ),
    alignment: pw.Alignment.center,
    child: pw.CustomPaint(
      size: const PdfPoint(8, 8),
      painter: (PdfGraphics g, PdfPoint size) {
        g.setColor(PdfColors.white);
        g.setLineWidth(0.6);
        if (type == 'email') {
          g.drawRect(0.5, 1.5, 7, 5);
          g.moveTo(0.5, 6.5);
          g.lineTo(4, 3.5);
          g.lineTo(7.5, 6.5);
          g.strokePath();
        } else if (type == 'globe') {
          g.drawEllipse(4, 4, 3, 3);
          g.moveTo(1, 4); g.lineTo(7, 4);
          g.moveTo(4, 1); g.lineTo(4, 7);
          g.strokePath();
        } else if (type == 'phone') {
          g.setLineWidth(0.9);
          g.moveTo(2, 6);
          g.lineTo(2, 3);
          g.lineTo(3.5, 3);
          g.lineTo(5.5, 5);
          g.lineTo(5.5, 6);
          g.closePath();
          g.strokePath();
        }
      },
    ),
  );
}

pw.Widget _buildCircularMetadataIcon(PdfColor bg, String type) {
  return pw.Container(
    width: 13,
    height: 13,
    decoration: pw.BoxDecoration(
      color: bg,
      shape: pw.BoxShape.circle,
    ),
    alignment: pw.Alignment.center,
    child: pw.CustomPaint(
      size: const PdfPoint(8, 8),
      painter: (PdfGraphics g, PdfPoint size) {
        g.setColor(PdfColors.white);
        g.setLineWidth(0.6);
        if (type == 'calendar') {
          g.drawRect(1, 1, 6, 6);
          g.moveTo(1, 5); g.lineTo(7, 5);
          g.moveTo(3, 1); g.lineTo(3, 7);
          g.moveTo(5, 1); g.lineTo(5, 7);
          g.strokePath();
        } else if (type == 'tag') {
          g.moveTo(1.5, 1.5);
          g.lineTo(5, 1.5);
          g.lineTo(6.5, 3.5);
          g.lineTo(5, 5.5);
          g.lineTo(1.5, 5.5);
          g.closePath();
          g.fillPath();
        }
      },
    ),
  );
}

pw.Widget _buildCircularClipboardIcon() {
  return pw.Container(
    width: 13,
    height: 13,
    decoration: pw.BoxDecoration(
      color: PdfColor.fromHex('#F59E0B'),
      shape: pw.BoxShape.circle,
    ),
    alignment: pw.Alignment.center,
    child: pw.CustomPaint(
      size: const PdfPoint(8, 9),
      painter: (PdfGraphics g, PdfPoint size) {
        g.setColor(PdfColors.white);
        g.drawRect(1, 1, 6, 7);
        g.fillPath();
        g.setColor(PdfColors.grey400);
        g.drawRect(2.5, 7, 3, 1.5);
        g.fillPath();
      },
    ),
  );
}

pw.Widget _buildCircularBoxIcon() {
  return pw.Container(
    width: 13,
    height: 13,
    decoration: pw.BoxDecoration(
      color: PdfColor.fromHex('#F97316'),
      shape: pw.BoxShape.circle,
    ),
    alignment: pw.Alignment.center,
    child: pw.CustomPaint(
      size: const PdfPoint(8, 8),
      painter: (PdfGraphics g, PdfPoint size) {
        g.setColor(PdfColors.white);
        g.drawRect(0.5, 0.5, 7, 7);
        g.fillPath();
        g.setColor(PdfColor.fromHex('#F97316'));
        g.setLineWidth(0.4);
        g.moveTo(0.5, 4); g.lineTo(7.5, 4);
        g.moveTo(4, 4); g.lineTo(4, 7.5);
        g.strokePath();
      },
    ),
  );
}

pw.Widget _buildCircularCreditCardIcon() {
  return pw.Container(
    width: 13,
    height: 13,
    decoration: pw.BoxDecoration(
      color: PdfColor.fromHex('#3B82F6'),
      shape: pw.BoxShape.circle,
    ),
    alignment: pw.Alignment.center,
    child: pw.CustomPaint(
      size: const PdfPoint(9, 7),
      painter: (PdfGraphics g, PdfPoint size) {
        g.setColor(PdfColors.white);
        g.drawRect(0.5, 0.5, 8, 6);
        g.fillPath();
        g.setColor(PdfColor.fromHex('#3B82F6'));
        g.drawRect(0.5, 4.5, 8, 1.2);
        g.fillPath();
      },
    ),
  );
}

pw.Widget _buildCircularShoppingBagIcon() {
  return pw.Container(
    width: 13,
    height: 13,
    decoration: pw.BoxDecoration(
      color: PdfColor.fromHex('#22C55E'),
      shape: pw.BoxShape.circle,
    ),
    alignment: pw.Alignment.center,
    child: pw.CustomPaint(
      size: const PdfPoint(8, 10),
      painter: (PdfGraphics g, PdfPoint size) {
        g.setColor(PdfColors.white);
        g.drawRect(1, 1, 6, 6);
        g.fillPath();
        g.setColor(PdfColors.white);
        g.setLineWidth(0.6);
        g.drawEllipse(4, 7, 2, 2);
        g.strokePath();
      },
    ),
  );
}

pw.Widget _buildCircularShieldIcon() {
  return pw.Container(
    width: 13,
    height: 13,
    decoration: pw.BoxDecoration(
      color: PdfColor.fromHex('#2563EB'),
      shape: pw.BoxShape.circle,
    ),
    alignment: pw.Alignment.center,
    child: pw.CustomPaint(
      size: const PdfPoint(8, 10),
      painter: (PdfGraphics g, PdfPoint size) {
        g.setColor(PdfColors.white);
        g.moveTo(1, 8.5);
        g.lineTo(7, 8.5);
        g.lineTo(7, 4.5);
        g.lineTo(4, 1);
        g.lineTo(1, 4.5);
        g.closePath();
        g.fillPath();
      },
    ),
  );
}

pw.Widget _buildCircularMoneyBagIcon() {
  return pw.Container(
    width: 13,
    height: 13,
    decoration: pw.BoxDecoration(
      color: PdfColor.fromHex('#EAB308'),
      shape: pw.BoxShape.circle,
    ),
    alignment: pw.Alignment.center,
    child: pw.Text("\$", style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
  );
}

pw.Widget _buildPillBadge(String text, PdfColor bg, PdfColor fg) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: pw.BoxDecoration(
      color: bg,
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
    ),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        color: fg,
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
      ),
    ),
  );
}
pw.Widget _pdfAddressText(String label, String? value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.RichText(
      text: pw.TextSpan(
        text: "$label: ",
        style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black),
        children: [
          pw.TextSpan(
            text: value ?? 'N/A',
            style: pw.TextStyle(fontWeight: pw.FontWeight.normal),
          ),
        ],
      ),
    ),
  );
}

Future<Uint8List> generateInvoicePdfBytes(Map<String, dynamic> order) async {
  final pdf = pw.Document();

  pw.MemoryImage? grabatozLogo;
  try {
    final ByteData logoData = await rootBundle.load('assets/images/logo_cropped.png');
    grabatozLogo = pw.MemoryImage(logoData.buffer.asUint8List());
  } catch (e) {
    print("Error loading asset logo: $e");
  }

  pw.MemoryImage? crownExcelLogo;
  try {
    final ByteData logoData =
        await rootBundle.load('assets/images/crown_excel_logo.png');
    crownExcelLogo = pw.MemoryImage(logoData.buffer.asUint8List());
  } catch (e) {
    print("Error loading asset crown logo: $e");
  }

  final orderItems = List<Map<String, dynamic>>.from(order['orderItems'] ?? []);

  final regularItems = orderItems.where((item) {
    final isProtection = item['isProtection'] == true;
    final name = item['name']?.toString() ?? '';
    return !isProtection && !name.toLowerCase().contains('for ');
  }).toList();

  final protectionItems = orderItems.where((item) {
    final isProtection = item['isProtection'] == true;
    final name = item['name']?.toString() ?? '';
    return isProtection || name.toLowerCase().contains('for ');
  }).toList();

  final invoice = getInvoiceBreakdown(order);
  final double subtotal = invoice['subtotal'];
  final double total = invoice['total'];
  final double shipping = invoice['shipping'];
  final double tax = invoice['tax'];
  final double couponDiscount = invoice['couponDiscount'];
  final String couponCode = invoice['couponCode'];
  final double codFee = invoice['codFee'];
  final double codShippingFee = invoice['codShippingFee'];
  final bool isCOD = invoice['isCOD'];
  final double displayTotal = invoice['displayTotal'];
  final status = order['status'] ?? 'New';
  final paymentMethod = order['paymentMethod'] ?? 'card';

  double baseSubtotal = 0;
  for (final item in regularItems) {
    final double basePrice = resolveOrderItemBasePrice(item);
    final int qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
    baseSubtotal += basePrice * qty;
  }

  final double derivedDiscount =
      baseSubtotal > subtotal ? (baseSubtotal - subtotal) : 0;

  final String orderDate = order['createdAt'] != null
      ? DateFormat('M/d/yyyy').format(DateTime.parse(order['createdAt']))
      : 'N/A';

  final tableHeaders = ['Product', 'Qty', 'Price', 'Total'];

  // Status mapping for badge color
  final bool isDelivered =
      status.toLowerCase() == 'delivered' || status.toLowerCase() == 'paid';
  final bool isCancelled =
      status.toLowerCase() == 'cancelled' || status.toLowerCase() == 'deleted';

  PdfColor statusTextColor = PdfColor.fromHex('#16A34A');
  if (isCancelled) {
    statusTextColor = PdfColor.fromHex('#16A34A');
  } else if (!isDelivered) {
    statusTextColor = PdfColor.fromHex('#B45309');
  }

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      build: (pw.Context context) {
        return [
          // Header section
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Left side: Crown Excel Logo & TRN
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (crownExcelLogo != null)
                    pw.Image(crownExcelLogo,
                        width: 110, height: 40, fit: pw.BoxFit.contain)
                  else
                    _buildCrownExcelLogo(),
                  pw.SizedBox(height: 6),
                  pw.Text("TRN: 100349772200003",
                      style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              // Right side: Graba2z Logo & Brand Subtitle
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  if (grabatozLogo != null)
                    pw.Image(grabatozLogo,
                        width: 130, height: 40, fit: pw.BoxFit.contain)
                  else
                    pw.Text("GRABA2Z",
                        style: pw.TextStyle(
                            fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text("A Brand By Crown Excel",
                      style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 16),
          pw.Divider(thickness: 1, color: PdfColor.fromHex('#E5E7EB')),
          pw.SizedBox(height: 12),

          // Contact Details & VAT Invoice Section
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Left: Contact Details
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("CONTACT DETAILS",
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text("We Are Here For You",
                      style: pw.TextStyle(
                          fontSize: 8,
                          fontStyle: pw.FontStyle.italic,
                          color: PdfColors.grey700)),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    children: [
                      _buildCircularContactIcon(PdfColor.fromHex('#C084FC'), 'email'),
                      pw.SizedBox(width: 6),
                      pw.Text("Email: orders@grabatoz.com",
                          style: const pw.TextStyle(fontSize: 8.5)),
                    ],
                  ),
                  pw.SizedBox(height: 3),
                  pw.Row(
                    children: [
                      _buildCircularContactIcon(PdfColor.fromHex('#60A5FA'), 'globe'),
                      pw.SizedBox(width: 6),
                      pw.Text("Website: www.grabatoz.com",
                          style: const pw.TextStyle(fontSize: 8.5)),
                    ],
                  ),
                  pw.SizedBox(height: 3),
                  pw.Row(
                    children: [
                      _buildCircularContactIcon(PdfColor.fromHex('#F472B6'), 'phone'),
                      pw.SizedBox(width: 6),
                      pw.Text("Phone: +971 50 860 4360",
                          style: const pw.TextStyle(fontSize: 8.5)),
                    ],
                  ),
                ],
              ),
              // Right: VAT Invoice metadata
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text("VAT INVOICE",
                      style: pw.TextStyle(
                          fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 6),
                  pw.Text(
                      "Order: #${order['_id']?.toString().substring((order['_id']?.toString().length ?? 6) - 6) ?? ''}",
                      style: pw.TextStyle(
                          fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      _buildCircularMetadataIcon(PdfColor.fromHex('#60A5FA'), 'calendar'),
                      pw.SizedBox(width: 4),
                      pw.Text("Date: $orderDate",
                          style: const pw.TextStyle(fontSize: 8.5)),
                    ],
                  ),
                  pw.SizedBox(height: 3),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      _buildCircularMetadataIcon(PdfColor.fromHex('#FACC15'), 'tag'),
                      pw.SizedBox(width: 4),
                      pw.Text("Status: ",
                          style: const pw.TextStyle(fontSize: 8.5)),
                      pw.Text(status,
                          style: pw.TextStyle(
                              fontSize: 8.5,
                              fontWeight: pw.FontWeight.bold,
                              color: statusTextColor)),
                    ],
                  ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 20),

          // Main content surrounded by left vertical green line
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border(
                left: pw.BorderSide(
                  color: PdfColor.fromHex('#84cc16'),
                  width: 3.5,
                ),
              ),
            ),
            padding: const pw.EdgeInsets.only(left: 14),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Order Summary Header
                pw.Row(
                  children: [
                    _buildCircularClipboardIcon(),
                    pw.SizedBox(width: 6),
                    pw.Text("ORDER SUMMARY",
                        style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#16A34A'))),
                  ],
                ),
                pw.SizedBox(height: 8),

                // Shipping & Billing Address Grid
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                              color: PdfColor.fromHex('#DCFCE7'), width: 1.5),
                          borderRadius:
                              const pw.BorderRadius.all(pw.Radius.circular(6)),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(
                              children: [
                                _buildCircularBoxIcon(),
                                pw.SizedBox(width: 4),
                                pw.Text("SHIPPING ADDRESS",
                                    style: pw.TextStyle(
                                        fontSize: 9,
                                        fontWeight: pw.FontWeight.bold,
                                        color: PdfColor.fromHex('#16A34A'))),
                              ],
                            ),
                            pw.SizedBox(height: 6),
                            _pdfAddressText(
                                "Name", order['shippingAddress']?['name']),
                            _pdfAddressText(
                                "Email", order['shippingAddress']?['email']),
                            _pdfAddressText(
                                "Phone", order['shippingAddress']?['phone']),
                            _pdfAddressText("Address",
                                order['shippingAddress']?['address']),
                            _pdfAddressText(
                                "City", order['shippingAddress']?['city']),
                            _pdfAddressText(
                                "State", order['shippingAddress']?['state']),
                            _pdfAddressText("Zip Code",
                                order['shippingAddress']?['zipCode']),
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                              color: PdfColor.fromHex('#DCFCE7'), width: 1.5),
                          borderRadius:
                              const pw.BorderRadius.all(pw.Radius.circular(6)),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(
                              children: [
                                _buildCircularCreditCardIcon(),
                                pw.SizedBox(width: 4),
                                pw.Text("BILLING ADDRESS",
                                    style: pw.TextStyle(
                                        fontSize: 9,
                                        fontWeight: pw.FontWeight.bold,
                                        color: PdfColor.fromHex('#16A34A'))),
                              ],
                            ),
                            pw.SizedBox(height: 6),
                            _pdfAddressText(
                                "Name",
                                order['billingAddress']?['name'] ??
                                    order['shippingAddress']?['name']),
                            _pdfAddressText(
                                "Email",
                                order['billingAddress']?['email'] ??
                                    order['shippingAddress']?['email']),
                            _pdfAddressText(
                                "Phone",
                                order['billingAddress']?['phone'] ??
                                    order['shippingAddress']?['phone']),
                            _pdfAddressText(
                                "Address",
                                order['billingAddress']?['address'] ??
                                    order['shippingAddress']?['address']),
                            _pdfAddressText(
                                "City",
                                order['billingAddress']?['city'] ??
                                    order['shippingAddress']?['city']),
                            _pdfAddressText(
                                "State",
                                order['billingAddress']?['state'] ??
                                    order['shippingAddress']?['state']),
                            _pdfAddressText(
                                "Zip Code",
                                order['billingAddress']?['zipCode'] ??
                                    order['shippingAddress']?['zipCode']),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 12),

                // Order Items Section
                pw.Row(
                  children: [
                    _buildCircularShoppingBagIcon(),
                    pw.SizedBox(width: 6),
                    pw.Text("ORDER ITEMS",
                        style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#16A34A'))),
                  ],
                ),
                pw.SizedBox(height: 6),

                // Regular Items Table
                pw.TableHelper.fromTextArray(
                  headers: tableHeaders,
                  headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 8),
                  headerDecoration:
                      pw.BoxDecoration(color: PdfColor.fromHex('#F0FDF4')),
                  cellStyle: const pw.TextStyle(fontSize: 7.5),
                  cellAlignment: pw.Alignment.center,
                  cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4.5),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(4.5),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1.5),
                    3: const pw.FlexColumnWidth(1.5),
                  },
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.center,
                    2: pw.Alignment.centerRight,
                    3: pw.Alignment.centerRight,
                  },
                  border: pw.TableBorder.all(
                      color: PdfColor.fromHex('#DCFCE7'), width: 0.5),
                  data: regularItems.map((item) {
                    final double basePrice = resolveOrderItemBasePrice(item);
                    final double price =
                        double.tryParse(item['price']?.toString() ?? '0') ??
                            basePrice;
                    final double totalVal = price *
                        (int.tryParse(item['quantity']?.toString() ?? '0') ??
                            0);

                    String productName = item['name'] ?? 'Order Item';
                    if (item['selectedColorData']?['color'] != null) {
                      productName +=
                          "\nColor: ${item['selectedColorData']['color']}";
                    }

                    return [
                      productName,
                      "${item['quantity'] ?? 0}",
                      "AED ${price.toStringAsFixed(2)}",
                      "AED ${totalVal.toStringAsFixed(2)}",
                    ];
                  }).toList(),
                ),

                pw.SizedBox(height: 10),

                // Protection Plans Section (if exists)
                if (protectionItems.isNotEmpty) ...[
                  pw.Row(
                    children: [
                      _buildCircularShieldIcon(),
                      pw.SizedBox(width: 6),
                      pw.Text("PROTECTION PLANS",
                          style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex('#1D4ED8'))),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.TableHelper.fromTextArray(
                    headers: ['Protection', 'Qty', 'Price', 'Total'],
                    headerStyle: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 8,
                        color: PdfColor.fromHex('#1D4ED8')),
                    headerDecoration:
                        pw.BoxDecoration(color: PdfColor.fromHex('#EFF6FF')),
                    cellStyle: const pw.TextStyle(fontSize: 7.5),
                    cellAlignment: pw.Alignment.center,
                    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4.5),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(4.5),
                      1: const pw.FlexColumnWidth(1),
                      2: const pw.FlexColumnWidth(1.5),
                      3: const pw.FlexColumnWidth(1.5),
                    },
                    cellAlignments: {
                      0: pw.Alignment.centerLeft,
                      1: pw.Alignment.center,
                      2: pw.Alignment.centerRight,
                      3: pw.Alignment.centerRight,
                    },
                    border: pw.TableBorder.all(
                        color: PdfColor.fromHex('#BFDBFE'), width: 0.5),
                    data: protectionItems.map((item) {
                      final double price =
                          double.tryParse(item['price']?.toString() ?? '0') ??
                              0;
                      final double totalVal = price *
                          (int.tryParse(item['quantity']?.toString() ?? '0') ??
                              0);

                      return [
                        item['name'] ?? 'Protection Plan',
                        "${item['quantity'] ?? 0}",
                        "AED ${price.toStringAsFixed(2)}",
                        "AED ${totalVal.toStringAsFixed(2)}",
                      ];
                    }).toList(),
                  ),
                  pw.SizedBox(height: 10),
                ],

                // Total Amount Summary Box
                pw.Row(
                  children: [
                    _buildCircularMoneyBagIcon(),
                    pw.SizedBox(width: 6),
                    pw.Text("TOTAL AMOUNT",
                        style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#16A34A'))),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F0FDF4'),
                    border: pw.Border.all(
                        color: PdfColor.fromHex('#DCFCE7'), width: 1.5),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    children: [
                      if (baseSubtotal > 0 && derivedDiscount > 0) ...[
                        _pdfSummaryRow("Base Price",
                            "AED ${baseSubtotal.toStringAsFixed(2)}",
                            isLineThrough: true),
                        pw.SizedBox(height: 6),
                      ],
                      _pdfSummaryRow("Subtotal",
                          "AED ${(subtotal + couponDiscount).toStringAsFixed(2)}"),
                      if (derivedDiscount > 0) ...[
                        pw.SizedBox(height: 6),
                        _pdfSummaryRow("Offer Discount",
                            "-AED ${derivedDiscount.toStringAsFixed(2)}",
                            isGreen: true),
                      ],
                      if (couponDiscount > 0) ...[
                        pw.SizedBox(height: 6),
                        _pdfSummaryRow(
                          couponCode.isNotEmpty
                              ? "Coupon ($couponCode)"
                              : "Coupon Discount",
                          "-AED ${couponDiscount.toStringAsFixed(2)}",
                          isGreen: true,
                        ),
                      ],
                      pw.SizedBox(height: 6),
                      _pdfSummaryRow(
                          "Shipping",
                          shipping == 0
                              ? "Free"
                              : "AED ${shipping.toStringAsFixed(2)}"),
                      if (isCOD && codFee > 0) ...[
                        pw.SizedBox(height: 6),
                        _pdfSummaryRow("COD Handling Fee",
                            "AED ${codFee.toStringAsFixed(2)}"),
                      ],
                      if (isCOD && codShippingFee > 0) ...[
                        pw.SizedBox(height: 6),
                        _pdfSummaryRow("COD Shipping Fee",
                            "AED ${codShippingFee.toStringAsFixed(2)}"),
                      ],
                      pw.SizedBox(height: 6),
                      _pdfSummaryRow(
                          "VAT (Included):", "AED ${tax.toStringAsFixed(2)}"),
                      pw.SizedBox(height: 8),
                      pw.Divider(
                          thickness: 0.5, color: PdfColor.fromHex('#DCFCE7')),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text("Total:",
                              style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.Text("AED ${displayTotal.toStringAsFixed(2)}",
                              style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColor.fromHex('#16A34A'))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 12),

          // Bottom Payment Status and Method Bar
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#FEFCE8'),
              border:
                  pw.Border.all(color: PdfColor.fromHex('#FEF08A'), width: 1),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Row(
              children: [
                _buildCircularCreditCardIcon(),
                pw.SizedBox(width: 4),
                pw.Text("Payment Status: ",
                    style: pw.TextStyle(
                        fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                _buildPillBadge(
                  isDelivered ? "✓ Paid" : "✗ Unpaid",
                  isDelivered
                      ? PdfColor.fromHex('#dcfce7')
                      : PdfColor.fromHex('#fee2e2'),
                  isDelivered
                      ? PdfColor.fromHex('#16a34a')
                      : PdfColor.fromHex('#b91c1c'),
                ),
                pw.SizedBox(width: 24),
                _buildCircularMoneyBagIcon(),
                pw.SizedBox(width: 4),
                pw.Text("Payment Method: ",
                    style: pw.TextStyle(
                        fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                _buildPillBadge(
                  paymentMethod.toLowerCase() == 'cod'
                      ? "Cash on Delivery"
                      : "Pay by Card",
                  PdfColor.fromHex('#dbeafe'),
                  PdfColor.fromHex('#1d4ed8'),
                ),
              ],
            ),
          ),
        ];
      },
    ),
  );

  return pdf.save();
}

Future<void> generateAndPrintInvoice(Map<String, dynamic> order) async {
  final bytes = await generateInvoicePdfBytes(order);
  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => bytes,
    name: 'invoice_${order['_id']}.pdf',
  );
}

pw.Widget _pdfSummaryRow(String label, String value,
    {bool isLineThrough = false, bool isGreen = false}) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
      pw.Text(
        value,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          decoration: isLineThrough ? pw.TextDecoration.lineThrough : null,
          color: isGreen ? PdfColor.fromHex('#16A34A') : null,
        ),
      ),
    ],
  );
}
