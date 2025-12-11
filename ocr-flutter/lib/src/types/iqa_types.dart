import '../constants/iqa_feedback.dart';

/// IQA Result
/// Represents the Image Quality Assessment result for document scanning
class IQAResult {
  final String documentSide;
  final IQAFeedback feedback;
  final String message;
  final double timestamp;

  IQAResult({
    required this.documentSide,
    required this.feedback,
    required this.message,
    required this.timestamp,
  });

  factory IQAResult.fromMap(Map<String, dynamic> map) {
    return IQAResult(
      documentSide: map['documentSide'] as String,
      feedback: IQAFeedback.values.firstWhere(
        (e) => e.value == map['feedback'],
        orElse: () => IQAFeedback.other,
      ),
      message: map['message'] as String,
      timestamp: (map['timestamp'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'documentSide': documentSide,
      'feedback': feedback.value,
      'message': message,
      'timestamp': timestamp,
    };
  }
}

/// IQA Banner Style
class IQABannerStyle {
  final String? backgroundColor;
  final String? iconColor;
  final String? titleColor;
  final String? descriptionColor;
  final double? fontSize;

  IQABannerStyle({
    this.backgroundColor,
    this.iconColor,
    this.titleColor,
    this.descriptionColor,
    this.fontSize,
  });

  Map<String, dynamic> toMap() {
    return {
      'backgroundColor': backgroundColor,
      'iconColor': iconColor,
      'titleColor': titleColor,
      'descriptionColor': descriptionColor,
      'fontSize': fontSize,
    };
  }
}

/// IQA Button Style
class IQAButtonStyle {
  final String? backgroundColor;
  final String? textColor;
  final double? fontSize;

  IQAButtonStyle({
    this.backgroundColor,
    this.textColor,
    this.fontSize,
  });

  Map<String, dynamic> toMap() {
    return {
      'backgroundColor': backgroundColor,
      'textColor': textColor,
      'fontSize': fontSize,
    };
  }
}

/// IQA Progress Bar Style
class IQAProgressBarStyle {
  final String? backgroundColor;
  final String? progressColor;
  final String? completionColor;
  final String? textColor;
  final double? fontSize;

  IQAProgressBarStyle({
    this.backgroundColor,
    this.progressColor,
    this.completionColor,
    this.textColor,
    this.fontSize,
  });

  Map<String, dynamic> toMap() {
    return {
      'backgroundColor': backgroundColor,
      'progressColor': progressColor,
      'completionColor': completionColor,
      'textColor': textColor,
      'fontSize': fontSize,
    };
  }
}

/// IQA Image Style
class IQAImageStyle {
  final String? backgroundColor;
  final String? borderColor;
  final double? cornerRadius;
  final double? borderWidth;

  IQAImageStyle({
    this.backgroundColor,
    this.borderColor,
    this.cornerRadius,
    this.borderWidth,
  });

  Map<String, dynamic> toMap() {
    return {
      'backgroundColor': backgroundColor,
      'borderColor': borderColor,
      'cornerRadius': cornerRadius,
      'borderWidth': borderWidth,
    };
  }
}

/// IQA Result Area Positioning
class IQAResultAreaPositioning {
  final String? target;
  final double? horizontalPadding;
  final double? verticalOffset;

  IQAResultAreaPositioning({
    this.target,
    this.horizontalPadding,
    this.verticalOffset,
  });

  Map<String, dynamic> toMap() {
    return {
      'target': target,
      'horizontalPadding': horizontalPadding,
      'verticalOffset': verticalOffset,
    };
  }
}

/// IQA Screen Style
/// Configuration for the Image Quality Assessment screen appearance
class IQAScreenStyle {
  final String? backgroundColor;
  final String? titleTextColor;
  final double? titleFontSize;
  final IQABannerStyle? successBanner;
  final IQABannerStyle? failureBanner;
  final IQABannerStyle? reasonBanner;
  final IQAButtonStyle? successButton;
  final IQAButtonStyle? retakeButton;
  final IQAProgressBarStyle? progressBar;
  final int? dismissAfterSuccessInSeconds;
  final IQAImageStyle? overlayImageStyle;
  final IQAImageStyle? ocrImageStyle;
  final IQAResultAreaPositioning? resultAreaPositioning;

  IQAScreenStyle({
    this.backgroundColor,
    this.titleTextColor,
    this.titleFontSize,
    this.successBanner,
    this.failureBanner,
    this.reasonBanner,
    this.successButton,
    this.retakeButton,
    this.progressBar,
    this.dismissAfterSuccessInSeconds,
    this.overlayImageStyle,
    this.ocrImageStyle,
    this.resultAreaPositioning,
  });

  Map<String, dynamic> toMap() {
    return {
      'backgroundColor': backgroundColor,
      'titleTextColor': titleTextColor,
      'titleFontSize': titleFontSize,
      'successBanner': successBanner?.toMap(),
      'failureBanner': failureBanner?.toMap(),
      'reasonBanner': reasonBanner?.toMap(),
      'successButton': successButton?.toMap(),
      'retakeButton': retakeButton?.toMap(),
      'progressBar': progressBar?.toMap(),
      'dismissAfterSuccessInSeconds': dismissAfterSuccessInSeconds,
      'overlayImageStyle': overlayImageStyle?.toMap(),
      'ocrImageStyle': ocrImageStyle?.toMap(),
      'resultAreaPositioning': resultAreaPositioning?.toMap(),
    };
  }
}
