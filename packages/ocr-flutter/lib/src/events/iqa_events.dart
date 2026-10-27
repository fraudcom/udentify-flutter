import '../types/iqa_types.dart';

/// IQA event listeners.
///
/// Deprecated no-ops kept for source compatibility. IQA results are delivered through
/// `OcrFlutter.setOnIQAResultCallback`; these functions never registered anything.

/// Adds a listener for IQA result events
/// 
/// Returns a function that can be called to remove the listener
/// 
/// Example:
/// ```dart
/// final removeListener = addIQAResultListener((result) {
///   print('IQA Result: ${result.feedback.value}');
/// });
/// 
/// removeListener();
/// ```
@Deprecated('No-op. Use OcrFlutter.setOnIQAResultCallback instead.')
Function addIQAResultListener(Function(IQAResult) callback) {
  return () {
    // Remove listener implementation
  };
}

/// Removes all IQA result listeners
/// 
/// This clears all registered IQA event listeners
@Deprecated('No-op. Use OcrFlutter.clearOCRCallbacks instead.')
void removeAllIQAResultListeners() {
}
