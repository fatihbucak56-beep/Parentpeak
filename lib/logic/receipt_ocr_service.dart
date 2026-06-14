import 'package:image_picker/image_picker.dart';

class ReceiptOcrUnsupportedException implements Exception {
  const ReceiptOcrUnsupportedException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ReceiptOcrService {
  ReceiptOcrService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<List<String>> extractLinesFromImage(ImageSource source) async {
    final image = await _picker.pickImage(source: source);
    if (image == null) return const [];

    throw const ReceiptOcrUnsupportedException(
      'OCR ist auf diesem Build aktuell deaktiviert. Bitte Positionen manuell erfassen.',
    );
  }
}
