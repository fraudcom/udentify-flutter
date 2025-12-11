/// OCR Document Sides
enum OCRDocumentSide {
  bothSides('bothSides'),
  frontSide('frontSide'),
  backSide('backSide');

  const OCRDocumentSide(this.value);
  final String value;
}
