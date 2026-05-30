import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class VistaPdfPage extends StatelessWidget {
  final Map<String, dynamic> data;
  const VistaPdfPage({super.key, required this.data});

  Future<Uint8List> _generarPdf(PdfPageFormat format) async {
    final pdf = pw.Document();

    final List stays = data['stays'];
    final List clientes = data['clients'];

    final rows = List.generate(stays.length, (i) {
      final stay = stays[i];
      final clientesStay = clientes[i] as List;

      return [
        stay['number'].toString(),
        stay['mode'].toString(),
        stay['date_in'].toString(),
        stay['date_out'].toString(),
        stay['pay_method'].toString(),
        stay['tarifa'].toString(),

        clientesStay.map((c) => c['name'].toString()).join('\n'),

        clientesStay.map((c) => c['phone'].toString()).join('\n'),

        // 'Bs ${stay['total']}',
      ];
    });

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),

        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'HOTEL XYZ',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.Text(
                DateTime.now().toString(),
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),

          pw.SizedBox(height: 10),

          pw.Text(
            'Reporte de Estancias',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),

          pw.SizedBox(height: 20),

          pw.Table.fromTextArray(
            border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey700),

            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),

            cellStyle: const pw.TextStyle(fontSize: 9),

            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),

            cellAlignment: pw.Alignment.centerLeft,

            headers: [
              'Hab',
              'Tipo',
              'Check-In',
              'Check-Out',
              'Noches',
              'Estado',
              'Clientes',
              'Teléfonos',
              'Total',
            ],

            data: rows,
          ),

          // pw.SizedBox(height: 20),

          // pw.Align(
          //   alignment: pw.Alignment.centerRight,
          //   child: pw.Container(
          //     padding: const pw.EdgeInsets.all(10),

          //     decoration: pw.BoxDecoration(border: pw.Border.all()),

          //     child: pw.Column(
          //       crossAxisAlignment: pw.CrossAxisAlignment.start,
          //       children: [
          //         pw.Text(
          //           'Resumen',
          //           style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          //         ),

          //         pw.SizedBox(height: 5),

          //         pw.Text('Total estancias: ${stays.length}'),

          //         pw.Text(
          //           'Total huéspedes: ${clientes.fold<int>(0, (sum, item) => sum + (item as List).length)}',
          //         ),

          //         pw.Text(
          //           'Ingresos: Bs ${stays.fold<num>(0, (sum, item) => sum + item['total'])}',
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
        ],
      ),
    );

    return Uint8List.fromList(await pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Vista PDF")),
      body: PdfPreview(build: (format) => _generarPdf(format)),
    );
  }
}
