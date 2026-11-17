import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/business_report.dart';

class BusinessReportPdfService {
  final _date = DateFormat('dd MMM yyyy');
  final _currency = NumberFormat('#,##0.00');
  String _rs(double v) => 'Rs ${_currency.format(v)}';

  Future<Uint8List> generate(BusinessReport report) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (_) => pw.Text(
          'DIGIKHATA  |  BUSINESS REPORT',
          style: pw.TextStyle(
            color: PdfColors.green800,
            fontWeight: pw.FontWeight.bold,
            fontSize: 18,
          ),
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 9),
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 22),
          pw.Text(
            '${_date.format(report.start)} – ${_date.format(report.end)}',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            headers: ['Metric', 'Value'],
            data: [
              ['Period credit', _rs(report.credit)],
              ['Period payments', _rs(report.payments)],
              ['Net account movement', _rs(report.netActivity)],
              ['All-time outstanding', _rs(report.outstanding)],
              ['Active customers', '${report.customerCount}'],
              ['Active inventory products', '${report.productCount}'],
              ['Stock cost value', _rs(report.inventoryCostValue)],
              ['Active suppliers', '${report.supplierCount}'],
              ['Supplier payables', _rs(report.supplierPayable)],
            ],
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
            cellPadding: const pw.EdgeInsets.all(9),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Daily credit and payment activity',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (report.daily.isEmpty)
            pw.Text('No transactions in this date range.')
          else
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Credit', 'Payments'],
              data: report.daily
                  .map(
                    (e) => [
                      _date.format(e.day),
                      _rs(e.credit),
                      _rs(e.payments),
                    ],
                  )
                  .toList(),
              cellPadding: const pw.EdgeInsets.all(7),
            ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Period credit reflects recorded credit entries, not total cash sales. '
            'Outstanding is the net of all recorded credits and payments.',
            style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 9),
          ),
        ],
      ),
    );
    return doc.save();
  }

  Future<void> preview(BusinessReport report) async {
    final data = await generate(report);
    await Printing.layoutPdf(
      name: 'DigiKhata_Business_Report.pdf',
      onLayout: (_) => data,
    );
  }

  Future<void> share(BusinessReport report) async {
    final data = await generate(report);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/DigiKhata_Business_Report.pdf');
    await file.writeAsBytes(data, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            file.path,
            mimeType: 'application/pdf',
            name: 'DigiKhata_Business_Report.pdf',
          ),
        ],
        subject: 'DigiKhata Business Report',
      ),
    );
  }
}
