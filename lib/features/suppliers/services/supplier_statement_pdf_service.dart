import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/supplier_account.dart';

class SupplierStatementPdfService {
  static final _date = DateFormat('dd MMM yyyy, hh:mm a');
  static final _money = NumberFormat('#,##0.00');
  static String _rs(double amount) => 'Rs ${_money.format(amount)}';

  Future<Uint8List> generate(SupplierAccount account) async {
    final document = pw.Document();
    final entries = account.runningEntries;
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'DIGIKHATA',
              style: pw.TextStyle(
                color: PdfColors.green800,
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              'SUPPLIER ACCOUNT STATEMENT',
              style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 10),
            ),
            pw.SizedBox(height: 10),
            pw.Divider(color: PdfColors.green800),
          ],
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (_) => [
          pw.SizedBox(height: 12),
          pw.Text(
            account.supplier.name,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          if (account.supplier.phone.isNotEmpty)
            pw.Text('Phone: ${account.supplier.phone}'),
          if (account.supplier.address?.isNotEmpty == true)
            pw.Text('Address: ${account.supplier.address}'),
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            headers: ['Purchases (Udhar)', 'Payments (Jama)', 'Amount payable'],
            data: [
              [_rs(account.purchased), _rs(account.paid), _rs(account.payable)],
            ],
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
            cellPadding: const pw.EdgeInsets.all(9),
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'Transaction history',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (entries.isEmpty)
            pw.Text('No supplier transactions recorded.')
          else
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Type', 'Amount', 'Running balance'],
              data: entries
                  .map(
                    (item) => [
                      _date.format(item.entry.createdAt.toLocal()),
                      item.entry.isPurchase
                          ? 'Udhar / Purchase'
                          : 'Jama / Payment',
                      _rs(item.entry.amount),
                      _rs(item.balance),
                    ],
                  )
                  .toList(),
              cellPadding: const pw.EdgeInsets.all(7),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
            ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Positive payable means money owed to the supplier. '
            'Negative payable means an advance paid to the supplier.',
            style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 9),
          ),
        ],
      ),
    );
    return document.save();
  }

  Future<void> preview(SupplierAccount account) async {
    final bytes = await generate(account);
    await Printing.layoutPdf(
      name: 'DigiKhata_Supplier_Statement.pdf',
      onLayout: (_) => bytes,
    );
  }

  Future<void> share(SupplierAccount account) async {
    final bytes = await generate(account);
    final directory = await getTemporaryDirectory();
    final safeName = account.supplier.name.replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]'),
      '_',
    );
    final fileName = 'DigiKhata_Supplier_$safeName.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf', name: fileName)],
        subject: 'DigiKhata supplier statement – ${account.supplier.name}',
      ),
    );
  }
}
