import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfGeneratorService {
  static Future<Uint8List> generatePostEventReport({
    required String eventTitle,
    required String organizerName,
    required String objectives,
    required String venue,
    required String impact,
    required String reflection,
    required double cost,
    required double unusedCashReturned,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Post-Event Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              _buildSection('Event Title:', eventTitle),
              _buildSection('Organizer:', organizerName),
              pw.Divider(),

              _buildSection('Objectives:', objectives),
              _buildSection('Venue:', venue),
              _buildSection('Program Impact:', impact),
              _buildSection('Post-Program Reflection:', reflection),
              pw.Divider(),

              pw.Header(
                level: 1,
                child: pw.Text(
                  'Financial Summary',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              _buildSection('Total Cost:', 'RM ${cost.toStringAsFixed(2)}'),
              _buildSection(
                'Unused Cash Returned:',
                'RM ${unusedCashReturned.toStringAsFixed(2)}',
              ),

              pw.Spacer(),
              pw.Text(
                'Generated automatically by RazakEvent System on ${DateTime.now().toLocal().toString().split('.')[0]}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> generateCertificate({
    required String userName,
    required String eventTitle,
    required String role,
    required DateTime date,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(40),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blue900, width: 10),
            ),
            child: pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'CERTIFICATE OF APPRECIATION',
                    style: pw.TextStyle(
                      fontSize: 32,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'This certificate is proudly presented to',
                    style: const pw.TextStyle(fontSize: 18),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    userName.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 40,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    role.toLowerCase() == 'participant'
                        ? 'for active participation as a'
                        : (role.toLowerCase().contains('crew') ||
                              role.toLowerCase().contains('director') ||
                              role.toLowerCase().contains('organizer'))
                        ? 'for outstanding contribution as a'
                        : 'for achieving',
                    style: const pw.TextStyle(fontSize: 16),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    role.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey700,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    (role.toLowerCase().contains('crew') ||
                            role.toLowerCase().contains('director') ||
                            role.toLowerCase().contains('organizer'))
                        ? 'in the successful execution of'
                        : 'in the following event:',
                    style: const pw.TextStyle(fontSize: 16),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    eventTitle,
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.SizedBox(height: 40),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        children: [
                          pw.Container(
                            width: 150,
                            height: 2,
                            color: PdfColors.black,
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            'Head of Kolej Tun Razak',
                            style: const pw.TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Text(
                            date.toString().split(' ')[0],
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Container(
                            width: 150,
                            height: 2,
                            color: PdfColors.black,
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            'Date',
                            style: const pw.TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSection(String title, String content) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
          ),
          pw.SizedBox(height: 4),
          pw.Text(content, style: const pw.TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
