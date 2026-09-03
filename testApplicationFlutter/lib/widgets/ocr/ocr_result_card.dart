import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ocr_flutter/ocr_flutter.dart';

class OCRResultCard extends StatelessWidget {
  final OCRResponse? ocrResponse;
  final HologramResponse? hologramResponse;
  final OCRAndDocumentLivenessResponse? livenessResponse;

  const OCRResultCard({
    super.key,
    this.ocrResponse,
    this.hologramResponse,
    this.livenessResponse,
  });

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy HH:mm:ss').format(date);
  }

  String _formatFieldName(String fieldName) {
    return fieldName
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => ' ${match.group(1)}',
        )
        .trim()
        .replaceFirstMapped(
          RegExp(r'^.'),
          (match) => match.group(0)!.toUpperCase(),
        );
  }

  Widget? _renderField(String key, dynamic value) {
    if (value == null || value == '') return null;

    String displayValue;
    if (value is bool) {
      displayValue = value ? 'Yes' : 'No';
    } else {
      displayValue = value.toString();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              '${_formatFieldName(key)}:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF495057),
              ),
            ),
          ),
          Expanded(
            child: Text(
              displayValue,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF212529),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (ocrResponse == null) return const Color(0xFF6C757D);
    return const Color(0xFF28A745);
  }

  String _getStatusText() {
    if (ocrResponse == null) return 'No Data';
    return 'Success';
  }

  String _getDocumentType() {
    if (ocrResponse == null) return 'Unknown';
    if (ocrResponse!.responseType == 'idCard') return 'ID Card';
    if (ocrResponse!.responseType == 'driverLicense') return 'Driver License';
    return ocrResponse!.responseType ?? 'Unknown';
  }

  Widget _buildOCRResultCard(BuildContext context) {
    if (ocrResponse == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFE9ECEF),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'OCR Result',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF212529),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${_getDocumentType()} • ${_formatDate(DateTime.now())}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6C757D),
                  ),
                ),
                if (ocrResponse!.transactionID != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Transaction ID: ${ocrResponse!.transactionID ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6C757D),
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (ocrResponse!.responseType == 'idCard' &&
              ocrResponse!.idCardResponse != null)
            _buildIDCardSection(ocrResponse!.idCardResponse!)
          else if (ocrResponse!.responseType == 'driverLicense' &&
              ocrResponse!.driverLicenseResponse != null)
            _buildDriverLicenseSection(ocrResponse!.driverLicenseResponse!)
          else
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  'Raw Response Data: ${ocrResponse.toString()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIDCardSection(IDCardOCRResponse idCard) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Extracted Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212529),
            ),
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Personal Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF495057),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 1,
                color: const Color(0xFFE9ECEF),
              ),
              const SizedBox(height: 12),
              _renderField('firstName', idCard.firstName) ?? const SizedBox.shrink(),
              _renderField('lastName', idCard.lastName) ?? const SizedBox.shrink(),
              _renderField('identityNo', idCard.identityNo) ?? const SizedBox.shrink(),
              _renderField('birthDate', idCard.birthDate) ?? const SizedBox.shrink(),
              _renderField('gender', idCard.gender) ?? const SizedBox.shrink(),
              _renderField('nationality', idCard.nationality) ?? const SizedBox.shrink(),
            ],
          ),
          if (idCard.fatherName != null || idCard.motherName != null) ...[
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Family Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF495057),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 1,
                  color: const Color(0xFFE9ECEF),
                ),
                const SizedBox(height: 12),
                _renderField('fatherName', idCard.fatherName) ?? const SizedBox.shrink(),
                _renderField('motherName', idCard.motherName) ?? const SizedBox.shrink(),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Document Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF495057),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 1,
                color: const Color(0xFFE9ECEF),
              ),
              const SizedBox(height: 12),
              _renderField('documentType', idCard.documentType) ?? const SizedBox.shrink(),
              _renderField('documentID', idCard.documentID) ?? const SizedBox.shrink(),
              _renderField('documentIssuer', idCard.documentIssuer) ?? const SizedBox.shrink(),
              _renderField('expiryDate', idCard.expiryDate) ?? const SizedBox.shrink(),
              _renderField('isOCRDocumentExpired', idCard.isOCRDocumentExpired) ?? const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Document Features',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF495057),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 1,
                color: const Color(0xFFE9ECEF),
              ),
              const SizedBox(height: 12),
              if (idCard.faceImage != null)
                _renderField('faceImage', 'Available (Base64)') ?? const SizedBox.shrink(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDriverLicenseSection(DriverLicenseOCRResponse driverLicense) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Extracted Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212529),
            ),
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Personal Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF495057),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 1,
                color: const Color(0xFFE9ECEF),
              ),
              const SizedBox(height: 12),
              _renderField('firstName', driverLicense.firstName) ?? const SizedBox.shrink(),
              _renderField('lastName', driverLicense.lastName) ?? const SizedBox.shrink(),
              _renderField('identityNo', driverLicense.identityNo) ?? const SizedBox.shrink(),
              _renderField('birthDate', driverLicense.birthDate) ?? const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Document Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF495057),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 1,
                color: const Color(0xFFE9ECEF),
              ),
              const SizedBox(height: 12),
              _renderField('documentType', driverLicense.documentType) ?? const SizedBox.shrink(),
              _renderField('licenseID', driverLicense.ocrQRLicenceID) ?? const SizedBox.shrink(),
              _renderField('licenseType', driverLicense.ocrLicenceType) ?? const SizedBox.shrink(),
              _renderField('expiryDate', driverLicense.expiryDate) ?? const SizedBox.shrink(),
              _renderField('issueDate', driverLicense.issueDate) ?? const SizedBox.shrink(),
              _renderField('city', driverLicense.city) ?? const SizedBox.shrink(),
              _renderField('district', driverLicense.district) ?? const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Document Features',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF495057),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 1,
                color: const Color(0xFFE9ECEF),
              ),
              const SizedBox(height: 12),
              if (driverLicense.faceImage != null)
                _renderField('faceImage', 'Available (Base64)') ?? const SizedBox.shrink(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHologramResultCard(BuildContext context) {
    if (hologramResponse == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFE9ECEF),
                  width: 1,
                ),
              ),
            ),
            child: const Text(
              'Hologram Results',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF212529),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _renderField('transactionID', hologramResponse!.transactionID) ?? const SizedBox.shrink(),
                _renderField('hologramExists', hologramResponse!.hologramExists) ?? const SizedBox.shrink(),
                _renderField('idMatch', hologramResponse!.ocrIdAndHologramIdMatch) ?? const SizedBox.shrink(),
                _renderField('faceMatch', hologramResponse!.ocrFaceAndHologramFaceMatch) ?? const SizedBox.shrink(),
                if (hologramResponse!.hologramFaceImage != null)
                  _renderField('hologramFaceImage', 'Available (Base64)') ?? const SizedBox.shrink(),
                if (hologramResponse!.error != null)
                  _renderField('error', hologramResponse!.error) ?? const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivenessResultCard(BuildContext context) {
    if (livenessResponse == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFE9ECEF),
                  width: 1,
                ),
              ),
            ),
            child: const Text(
              'Document Liveness Results',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF212529),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _renderField('failed', livenessResponse!.isFailed) ?? const SizedBox.shrink(),
                if (livenessResponse!.ocrData?.ocrResponse != null)
                  _renderField('ocrData', 'Available') ?? const SizedBox.shrink(),
                if (livenessResponse!.documentLivenessDataFront?.documentLivenessResponse != null)
                  _renderField('frontLiveness', livenessResponse!.documentLivenessDataFront!.documentLivenessResponse!.aggregateDocumentLivenessProbability) ?? const SizedBox.shrink(),
                if (livenessResponse!.documentLivenessDataBack?.documentLivenessResponse != null)
                  _renderField('backLiveness', livenessResponse!.documentLivenessDataBack!.documentLivenessResponse!.aggregateDocumentLivenessProbability) ?? const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildOCRResultCard(context),
        if (hologramResponse != null) ...[
          const SizedBox(height: 16),
          _buildHologramResultCard(context),
        ],
        if (livenessResponse != null) ...[
          const SizedBox(height: 16),
          _buildLivenessResultCard(context),
        ],
      ],
    );
  }
}
