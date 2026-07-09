import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/product.dart';
import '../models/user.dart';

class ReceiptGenerator {
  static Future<void> printReceipt({
    required List<CartItem> items,
    required double subtotal,
    required double totalDiscount,
    required double total,
    required double cashAmount,
    required double change,
    required User? cashier,
    required String paymentMethod,
    String? printerName,
  }) async {
    final pdf = pw.Document();

    // Load font
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(72 * PdfPageFormat.mm, double.infinity),
        margin: const pw.EdgeInsets.only(left: 5, right: 5, top: 0, bottom: 2),
        build: (pw.Context context) {
          final textStyle = pw.TextStyle(
            font: font,
            fontSize: 10,
            height: 0.95,
          );

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'TOKO FAISAL',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 16,
                        height: 0.95,
                      ),
                    ),
                    pw.Text(
                      'Sembako & Kebutuhan Harian',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 9,
                        height: 0.95,
                      ),
                    ),
                    pw.Text(
                      'Jl. Contoh Alamat No. 123, Kota',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 9,
                        height: 0.95,
                      ),
                    ),
                    pw.Divider(
                      borderStyle: pw.BorderStyle.dashed,
                      height: 2,
                      thickness: 1,
                    ),
                  ],
                ),
              ),

              // Meta info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Tgl: ${_formatDate(DateTime.now())}',
                    style: pw.TextStyle(font: font, fontSize: 9, height: 0.95),
                  ),
                  pw.Text(
                    'Kasir: ${cashier?.username ?? 'Admin'}',
                    style: pw.TextStyle(font: font, fontSize: 9, height: 0.95),
                  ),
                ],
              ),
              pw.Divider(
                borderStyle: pw.BorderStyle.dashed,
                height: 2,
                thickness: 1,
              ),

              // Items
              ...items.map((item) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      item.product.name,
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 10,
                        height: 0.95,
                      ),
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          '${item.quantity} ${item.selectedUnit} x ${_formatPrice(item.baseUnitPrice)}',
                          style: textStyle,
                        ),
                        pw.Text(
                          _formatPrice(item.baseUnitPrice * item.quantity),
                          style: textStyle,
                        ),
                      ],
                    ),
                    if (item.unitPriceAfterDiscount < item.baseUnitPrice)
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            '  Diskon',
                            style: pw.TextStyle(
                              font: font,
                              fontSize: 9,
                              height: 0.95,
                            ),
                          ),
                          pw.Text(
                            '-${_formatPrice((item.baseUnitPrice - item.unitPriceAfterDiscount) * item.quantity)}',
                            style: pw.TextStyle(
                              font: font,
                              fontSize: 9,
                              height: 0.95,
                            ),
                          ),
                        ],
                      ),
                  ],
                );
              }),

              pw.Divider(
                borderStyle: pw.BorderStyle.dashed,
                height: 2,
                thickness: 1,
              ),

              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal', style: textStyle),
                  pw.Text(_formatPrice(subtotal), style: textStyle),
                ],
              ),
              if (totalDiscount > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Diskon', style: textStyle),
                    pw.Text(
                      '-${_formatPrice(totalDiscount)}',
                      style: textStyle,
                    ),
                  ],
                ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 12,
                      height: 0.95,
                    ),
                  ),
                  pw.Text(
                    _formatPrice(total),
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 12,
                      height: 0.95,
                    ),
                  ),
                ],
              ),
              pw.Divider(
                borderStyle: pw.BorderStyle.dashed,
                height: 2,
                thickness: 1,
              ),

              // Payment
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Bayar ($paymentMethod)', style: textStyle),
                  pw.Text(_formatPrice(cashAmount), style: textStyle),
                ],
              ),
              if (change > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Kembali', style: textStyle),
                    pw.Text(_formatPrice(change), style: textStyle),
                  ],
                ),

              pw.Divider(
                borderStyle: pw.BorderStyle.dashed,
                height: 2,
                thickness: 1,
              ),
              pw.Center(
                child: pw.Text(
                  'Terima Kasih',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 11,
                    height: 0.95,
                  ),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'Barang yang sudah dibeli\ntidak dapat ditukar/dikembalikan',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(font: font, fontSize: 8.5, height: 0.95),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Print
    if (printerName != null &&
        printerName.isNotEmpty &&
        printerName != 'Tidak Ada Printer (Preview)') {
      try {
        final printers = await Printing.listPrinters();
        Printer? targetPrinter;
        for (final p in printers) {
          if (p.name == printerName) {
            targetPrinter = p;
            break;
          }
        }
        if (targetPrinter != null) {
          await Printing.directPrintPdf(
            printer: targetPrinter,
            onLayout: (PdfPageFormat format) async => pdf.save(),
            name: 'Struk_Toko_Faisal_${DateTime.now().millisecondsSinceEpoch}',
          );
          return;
        }
      } catch (e) {
        print('Direct print failed: $e');
      }
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Struk_Toko_Faisal_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  static String _formatPrice(double price) {
    final parts = price.toInt().toString().split('').reversed.toList();
    final result = <String>[];
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && i % 3 == 0) result.add('.');
      result.add(parts[i]);
    }
    return 'Rp ${result.reversed.join()}';
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
