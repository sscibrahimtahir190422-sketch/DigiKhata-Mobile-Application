import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/transaction_reciept.dart';

class TransactionPdfService {
  TransactionPdfService();

  static const PdfColor _primaryGreen = PdfColor(0.08, 0.49, 0.39);
  static const PdfColor _lightGreen = PdfColor(0.91, 0.97, 0.94);
  static const PdfColor _darkText = PdfColor(0.12, 0.16, 0.14);
  static const PdfColor _mutedText = PdfColor(0.42, 0.46, 0.44);
  static const PdfColor _borderColor = PdfColor(0.87, 0.90, 0.88);

  Future<Uint8List> generateReceipt(TransactionReceipt receipt) async {
    final document = pw.Document();

    final date = receipt.transactionDate.toLocal();
    final formattedDate =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';

    final formattedTime =
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';

    final isCredit = receipt.isCredit;
    final transactionLabel = isCredit ? 'Credit Added' : 'Payment Received';

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(24),
                decoration: const pw.BoxDecoration(
                  color: _primaryGreen,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'DIGIKHATA',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Customer Transaction Receipt',
                      style: const pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 12,
                      ),
                    ),
                    pw.SizedBox(height: 18),
                    pw.Text(
                      receipt.shopName,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 15,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: const pw.BoxDecoration(
                  color: _lightGreen,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      transactionLabel.toUpperCase(),
                      style: pw.TextStyle(
                        color: _primaryGreen,
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      receipt.formattedAmount,
                      style: pw.TextStyle(
                        color: _darkText,
                        fontSize: 30,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Transaction recorded successfully',
                      style: const pw.TextStyle(
                        color: _mutedText,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),
              _sectionTitle('CUSTOMER DETAILS'),
              pw.SizedBox(height: 10),
              _detailRow('Customer name', receipt.customerName),
              _detailRow(
                'Phone number',
                receipt.customerPhone.isEmpty
                    ? 'Not provided'
                    : receipt.customerPhone,
              ),
              pw.SizedBox(height: 22),
              _sectionTitle('TRANSACTION DETAILS'),
              pw.SizedBox(height: 10),
              _detailRow('Transaction type', transactionLabel),
              _detailRow('Date', formattedDate),
              _detailRow('Time', formattedTime),
              if (receipt.description?.trim().isNotEmpty ?? false)
                _detailRow('Description', receipt.description!.trim()),
              _detailRow('Reference ID', receipt.transactionId),
              pw.SizedBox(height: 24),
              pw.Container(
                padding: const pw.EdgeInsets.all(18),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _borderColor),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(10),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        'Balance after transaction',
                        style: pw.TextStyle(
                          color: _darkText,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Text(
                      receipt.formattedBalance,
                      style: pw.TextStyle(
                        color: _primaryGreen,
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Spacer(),
              pw.Divider(color: _borderColor),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'Thank you for your business!',
                  style: pw.TextStyle(
                    color: _primaryGreen,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Center(
                child: pw.Text(
                  'Generated by DigiKhata',
                  style: const pw.TextStyle(color: _mutedText, fontSize: 9),
                ),
              ),
            ],
          );
        },
      ),
    );

    return document.save();
  }

  Future<void> previewReceipt(TransactionReceipt receipt) async {
    final bytes = await generateReceipt(receipt);

    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'DigiKhata_Receipt_${receipt.transactionId}.pdf',
    );
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        color: _primaryGreen,
        fontSize: 11,
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }

  pw.Widget _detailRow(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 9),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _borderColor, width: 0.5),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 135,
            child: pw.Text(
              label,
              style: const pw.TextStyle(color: _mutedText, fontSize: 10),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                color: _darkText,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
