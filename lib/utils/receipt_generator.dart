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
  }) async {
    final pdf = pw.Document();
    
    // Load font
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(12),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text('TOKO FAISAL', style: pw.TextStyle(font: fontBold, fontSize: 18)),
                    pw.SizedBox(height: 2),
                    pw.Text('Sembako & Kebutuhan Harian', style: pw.TextStyle(font: font, fontSize: 10)),
                    pw.Text('Jl. Contoh Alamat No. 123, Kota', style: pw.TextStyle(font: font, fontSize: 10)),
                    pw.SizedBox(height: 8),
                    pw.Divider(borderStyle: pw.BorderStyle.dashed),
                  ],
                ),
              ),
              
              // Meta info
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Tgl: ${_formatDate(DateTime.now())}', style: pw.TextStyle(font: font, fontSize: 10)),
                  pw.Text('Kasir: ${cashier?.username ?? 'Admin'}', style: pw.TextStyle(font: font, fontSize: 10)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 6),

              // Items
              ...items.map((item) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(item.product.name, style: pw.TextStyle(font: font, fontSize: 11)),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('${item.quantity} x ${_formatPrice(item.product.price)}', style: pw.TextStyle(font: font, fontSize: 11)),
                        pw.Text(_formatPrice(item.product.price * item.quantity), style: pw.TextStyle(font: font, fontSize: 11)),
                      ],
                    ),
                    if (item.unitPriceAfterDiscount < item.product.price)
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('  Diskon', style: pw.TextStyle(font: font, fontSize: 10)),
                          pw.Text('-${_formatPrice((item.product.price - item.unitPriceAfterDiscount) * item.quantity)}', style: pw.TextStyle(font: font, fontSize: 10)),
                        ],
                      ),
                    pw.SizedBox(height: 4),
                  ],
                );
              }),
              
              pw.SizedBox(height: 4),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 6),

              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal', style: pw.TextStyle(font: font, fontSize: 11)),
                  pw.Text(_formatPrice(subtotal), style: pw.TextStyle(font: font, fontSize: 11)),
                ],
              ),
              if (totalDiscount > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Diskon', style: pw.TextStyle(font: font, fontSize: 11)),
                    pw.Text('-${_formatPrice(totalDiscount)}', style: pw.TextStyle(font: font, fontSize: 11)),
                  ],
                ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL', style: pw.TextStyle(font: fontBold, fontSize: 13)),
                  pw.Text(_formatPrice(total), style: pw.TextStyle(font: fontBold, fontSize: 13)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 6),

              // Payment
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Bayar ($paymentMethod)', style: pw.TextStyle(font: font, fontSize: 11)),
                  pw.Text(_formatPrice(cashAmount), style: pw.TextStyle(font: font, fontSize: 11)),
                ],
              ),
              if (change > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Kembali', style: pw.TextStyle(font: font, fontSize: 11)),
                    pw.Text(_formatPrice(change), style: pw.TextStyle(font: font, fontSize: 11)),
                  ],
                ),
                
              pw.SizedBox(height: 12),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text('Terima Kasih', style: pw.TextStyle(font: fontBold, fontSize: 12)),
              ),
              pw.Center(
                child: pw.Text('Barang yang sudah dibeli\ntidak dapat ditukar/dikembalikan', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: font, fontSize: 9)),
              ),
            ],
          );
        },
      ),
    );

    // Print
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
