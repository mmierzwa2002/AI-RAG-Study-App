import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Ekstrakcja tekstu z PDF-a przy użyciu syncfusion_flutter_pdf.
class PdfTextService {
  String extractText(Uint8List bytes) {
    final document = PdfDocument(inputBytes: bytes);
    try {
      return PdfTextExtractor(document).extractText();
    } finally {
      document.dispose();
    }
  }
}
