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
  other('other');

  const IQAFeedback(this.value);
  final String value;
}
