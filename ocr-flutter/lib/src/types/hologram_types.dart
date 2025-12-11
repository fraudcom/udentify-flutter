/// Hologram Response
class HologramResponse {
  final String? transactionID;
  final String? idNumber;
  final String? hologramFaceImage;
  final bool? hologramExists;
  final bool? ocrIdAndHologramIdMatch;
  final bool? ocrFaceAndHologramFaceMatch;
  final String? error;
  final bool? success;
  final double? timestamp;

  HologramResponse({
    this.transactionID,
    this.idNumber,
    this.hologramFaceImage,
    this.hologramExists,
    this.ocrIdAndHologramIdMatch,
    this.ocrFaceAndHologramFaceMatch,
    this.error,
    this.success,
    this.timestamp,
  });

  factory HologramResponse.fromMap(Map<String, dynamic> map) {
    return HologramResponse(
      transactionID: map['transactionID'],
      idNumber: map['idNumber'],
      hologramFaceImage: map['hologramFaceImage'],
      hologramExists: map['hologramExists'],
      ocrIdAndHologramIdMatch: map['ocrIdAndHologramIdMatch'],
      ocrFaceAndHologramFaceMatch: map['ocrFaceAndHologramFaceMatch'],
      error: map['error'],
      success: map['success'] as bool?,
      timestamp: (map['timestamp'] as num?)?.toDouble(),
    );
  }
}
