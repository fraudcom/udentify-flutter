/// IQA Feedback Types
/// Represents the quality assessment feedback for document images
enum IQAFeedback {
  success('success'),
  blurDetected('blurDetected'),
  glareDetected('glareDetected'),
  hologramGlare('hologramGlare'),
  cardNotDetected('cardNotDetected'),
  cardClassificationMismatch('cardClassificationMismatch'),
  cardNotIntact('cardNotIntact'),
  faceNotDetected('faceNotDetected'),
  multipleDocumentsDetected('multipleDocumentsDetected'),
  chipNotDetected('chipNotDetected'),
  signatureNotDetected('signatureNotDetected'),
  modelFailed('modelFailed'),
  hiddenPhotoNotDetected('hiddenPhotoNotDetected'),
  photoCheatDetected('photoCheatDetected'),
  other('other');

  const IQAFeedback(this.value);
  final String value;
}
