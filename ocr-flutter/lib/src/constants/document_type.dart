/// OCR Document Types
enum OCRDocumentType {
  idCard('ID_CARD'),
  passport('PASSPORT'),
  driverLicense('DRIVER_LICENSE');

  const OCRDocumentType(this.value);
  final String value;
}
