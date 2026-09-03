//
//  CustomOCRSettings.swift
//  ocr_flutter
//
//  Created for OCR custom bundle configuration and UI customization
//

import Foundation
import UdentifyOCR
import UdentifyCommons

class CustomOCRSettings: NSObject, OCRSettings {
  private let localizationBundle: Bundle
  private let uiConfig: [String: Any]?

  init(localizationBundle: Bundle, uiConfig: [String: Any]? = nil) {
    self.localizationBundle = localizationBundle
    self.uiConfig = uiConfig
    super.init()
  }

  var configs: OCRConfigs {
    let bgStyle = getReviewBackgroundStyle()
    return OCRConfigs(
      placeholderContainerStyle: getPlaceholderContainerStyle(),
      placeholderTemplate: getPlaceholderTemplate(),
      detectionAccuracy: getDetectionAccuracy(),
      buttonBackColor: getButtonBackColor(),
      maskLayerColor: getMaskLayerColor(),
      footerViewStyle: getFooterViewStyle(),
      buttonUseStyle: getButtonUseStyle(),
      buttonRetakeStyle: getButtonRetakeStyle(),
      orientation: getOrientation(),
      bundle: localizationBundle,
      tableName: getTableName(),
      blurCoefficient: getBlurCoefficient(),
      requestTimeout: getRequestTimeout(),
      backButtonEnabled: getBackButtonEnabled(),
      reviewScreenEnabled: getReviewScreenEnabled(),
      footerViewHidden: getFooterViewHidden(),
      titleLabelStyle: getTitleLabelStyle(),
      instructionLabelStyle: getInstructionLabelStyle(),
      reviewTitleLabelStyle: getReviewTitleLabelStyle(),
      reviewInstructionLabelStyle: getReviewInstructionLabelStyle(),
      reviewBackgroundColor: bgStyle != nil ? nil : getReviewBackgroundColor(),
      reviewBackgroundStyle: bgStyle,
      progressBarStyle: getProgressBarStyle(),
      documentDetectionConfig: getDocumentDetectionConfig(),
      isIQAServiceEnabled: getIQAServiceEnabled(),
      iqaScreenStyle: getIQAScreenStyle(),
      rawPhotoCropRatio: getRawPhotoCropRatio()
    )
  }
  
  private func getPlaceholderContainerStyle() -> UdentifyCommons.UdentifyViewStyle {
    // OCRUIConfig.placeholderContainerStyle (Dart) serializes as a nested
    // map, not flat top-level keys — read it from there.
    let styleConfig = uiConfig?["placeholderContainerStyle"] as? [String: Any]
    let backgroundColor = parseColor(styleConfig?["backgroundColor"] as? String) ?? .purple.withAlphaComponent(0.6)
    let borderColor = parseColor(styleConfig?["borderColor"] as? String) ?? .white
    let cornerRadius = styleConfig?["cornerRadius"] as? CGFloat ?? 8.0
    let borderWidth = styleConfig?["borderWidth"] as? CGFloat ?? 2.0

    return UdentifyCommons.UdentifyViewStyle(
                backgroundColor: backgroundColor,
                borderColor: borderColor,
                cornerRadius: cornerRadius,
                borderWidth: borderWidth,
                horizontalSizing: .fixed(width: 120, horizontalPosition: .right(offset: 16)),
                verticalSizing: .fixed(height: 135, verticalPosition: .bottom(offset: 0))
            )
  }
  
  private func getPlaceholderTemplate() -> PlaceholderTemplate {
    guard let templateString = uiConfig?["placeholderTemplate"] as? String else {
      return .defaultStyle
    }
    
    switch templateString.lowercased() {
    case "hidden":
      return .hidden
    case "defaultstyle", "default":
      return .defaultStyle
    case "countryspecificstyle", "countryspecific":
      return .countrySpecificStyle
    default:
      return .defaultStyle
    }
  }
  
  private func getDetectionAccuracy() -> Int {
    let accuracy = uiConfig?["detectionAccuracy"] as? Int ?? 10
    return min(max(accuracy, 0), 200)
  }
  
  private func getButtonBackColor() -> UIColor {
    return parseColor(uiConfig?["buttonBackColor"] as? String) ?? .white
  }
  
  private func getMaskLayerColor() -> UIColor {
    return parseColor(uiConfig?["maskLayerColor"] as? String) ?? .clear
  }
  
  private func getFooterViewStyle() -> UdentifyCommons.UdentifyButtonStyle {
    return buttonStyle(
      configKey: "footerViewStyle",
      defaultBackgroundColor: .purple.withAlphaComponent(0.6)
    )
  }

  private func getButtonUseStyle() -> UdentifyCommons.UdentifyButtonStyle {
    return buttonStyle(
      configKey: "buttonUseStyle",
      defaultBackgroundColor: .purple
    )
  }

  private func getButtonRetakeStyle() -> UdentifyCommons.UdentifyButtonStyle {
    return buttonStyle(
      configKey: "buttonRetakeStyle",
      defaultBackgroundColor: .purple
    )
  }

  /// Builds a button style from an `OCRButtonStyle` (Dart) map nested under `configKey`
  /// in `uiConfig`, e.g. `uiConfig["footerViewStyle"]["backgroundColor"]`.
  private func buttonStyle(
    configKey: String,
    defaultBackgroundColor: UIColor
  ) -> UdentifyCommons.UdentifyButtonStyle {
    let style = uiConfig?[configKey] as? [String: Any]
    let fontSize = style?["fontSize"] as? CGFloat ?? 20.0

    return UdentifyCommons.UdentifyButtonStyle(
      backgroundColor: parseColor(style?["backgroundColor"] as? String) ?? defaultBackgroundColor,
      borderColor: parseColor(style?["borderColor"] as? String) ?? .clear,
      cornerRadius: style?["cornerRadius"] as? CGFloat ?? 8,
      borderWidth: style?["borderWidth"] as? CGFloat ?? 0,
      contentAlignment: .center,
      height: style?["height"] as? CGFloat ?? 70.0,
      leading: style?["leading"] as? CGFloat ?? 20,
      trailing: style?["trailing"] as? CGFloat ?? 20,
      font: parseFont(family: style?["fontFamily"] as? String, size: fontSize, bold: style?["fontBold"] as? Bool),
      textColor: parseColor(style?["textColor"] as? String) ?? .white,
      textAlignment: parseTextAlignment(style?["textAlignment"] as? String, default: .center),
      lineBreakMode: .byTruncatingTail,
      numberOfLines: style?["numberOfLines"] as? Int ?? 1
    )
  }
  
  private func getTableName() -> String? {
    return uiConfig?["tableName"] as? String
  }
  
  private func getOrientation() -> OCROrientation {
    guard let orientationString = uiConfig?["orientation"] as? String else {
      return .horizontal
    }

    switch orientationString.lowercased() {
    case "vertical":
      return .vertical
    case "horizontal":
      return .horizontal
    default:
      return .horizontal
    }
  }
  
  private func getBlurCoefficient() -> Double {
    let coefficient = uiConfig?["blurCoefficient"] as? Double ?? 0.0
    return min(max(coefficient, -1.0), 1.0)
  }
  
  private func getRequestTimeout() -> Double {
    return uiConfig?["requestTimeout"] as? Double ?? 30.0
  }
  
  private func getBackButtonEnabled() -> Bool {
    return uiConfig?["backButtonEnabled"] as? Bool ?? true
  }
  
  private func getReviewScreenEnabled() -> Bool {
    return uiConfig?["reviewScreenEnabled"] as? Bool ?? true
  }

  private func getReviewBackgroundColor() -> UIColor? {
    return parseColor(uiConfig?["reviewBackgroundColor"] as? String)
  }

  private func getReviewBackgroundStyle() -> UdentifyCommons.UdentifyImageStyle? {
    guard let styleConfig = uiConfig?["reviewBackgroundStyle"] as? [String: Any],
          let imageBase64 = styleConfig["imageBase64"] as? String,
          let imageData = Data(base64Encoded: imageBase64, options: .ignoreUnknownCharacters),
          let image = UIImage(data: imageData) else {
      return nil
    }

    let contentMode: UIView.ContentMode
    switch (styleConfig["contentMode"] as? String)?.lowercased() {
    case "scaletofill":
      contentMode = .scaleToFill
    case "scaleaspectfill":
      contentMode = .scaleAspectFill
    case "scaleaspectfit":
      contentMode = .scaleAspectFit
    default:
      contentMode = .scaleAspectFill
    }

    let opacity = CGFloat((styleConfig["opacity"] as? NSNumber)?.doubleValue ?? 1.0)
    let borderColor = parseColor(styleConfig["borderColor"] as? String) ?? .clear
    let borderWidth = CGFloat((styleConfig["borderWidth"] as? NSNumber)?.doubleValue ?? 0)
    let cornerRadius = CGFloat((styleConfig["cornerRadius"] as? NSNumber)?.doubleValue ?? 0)

    return UdentifyCommons.UdentifyImageStyle(
      image: image,
      contentMode: contentMode,
      opacity: opacity,
      borderColor: borderColor,
      borderWidth: borderWidth,
      horizontalSizing: .anchors(leading: 0, trailing: 0),
      verticalSizing: .anchors(top: 0, bottom: 0),
      cornerRadius: cornerRadius
    )
  }

  private func getFooterViewHidden() -> Bool {
    return uiConfig?["footerViewHidden"] as? Bool ?? false
  }
  
  private func getTitleLabelStyle() -> UdentifyCommons.UdentifyTextStyle? {
    guard getFooterViewHidden() else { return nil }
    return textStyle(configKey: "titleLabelStyle", defaultTextColor: .white, defaultFontSize: 24.0, defaultAlignment: .center)
  }

  private func getInstructionLabelStyle() -> UdentifyCommons.UdentifyTextStyle? {
    guard getFooterViewHidden() else { return nil }
    return textStyle(configKey: "instructionLabelStyle", defaultTextColor: .white, defaultFontSize: 16.0, defaultAlignment: .center)
  }

  private func getReviewTitleLabelStyle() -> UdentifyCommons.UdentifyTextStyle {
    return textStyle(configKey: "reviewTitleLabelStyle", defaultTextColor: .label, defaultFontSize: 24.0, defaultAlignment: .left)
  }

  private func getReviewInstructionLabelStyle() -> UdentifyCommons.UdentifyTextStyle {
    return textStyle(configKey: "reviewInstructionLabelStyle", defaultTextColor: .label, defaultFontSize: 16.0, defaultAlignment: .left)
  }

  /// Builds a text style from an `OCRTextStyle` (Dart) map nested under `configKey`
  /// in `uiConfig`, e.g. `uiConfig["titleLabelStyle"]["textColor"]`.
  private func textStyle(
    configKey: String,
    defaultTextColor: UIColor,
    defaultFontSize: CGFloat,
    defaultAlignment: NSTextAlignment
  ) -> UdentifyCommons.UdentifyTextStyle {
    let style = uiConfig?[configKey] as? [String: Any]
    let fontSize = style?["fontSize"] as? CGFloat ?? defaultFontSize

    return UdentifyCommons.UdentifyTextStyle(
      font: parseFont(family: style?["fontFamily"] as? String, size: fontSize, bold: style?["fontBold"] as? Bool),
      textColor: parseColor(style?["textColor"] as? String) ?? defaultTextColor,
      textAlignment: parseTextAlignment(style?["textAlignment"] as? String, default: defaultAlignment),
      lineBreakMode: .byWordWrapping,
      numberOfLines: style?["numberOfLines"] as? Int ?? 0,
      leading: style?["leading"] as? CGFloat ?? 20,
      trailing: style?["trailing"] as? CGFloat ?? 20
    )
  }

  private func getProgressBarStyle() -> UdentifyCommons.UdentifyProgressBarStyle {
    let style = uiConfig?["progressBarStyle"] as? [String: Any]
    let textStyleConfig = style?["textStyle"] as? [String: Any]
    let fontSize = textStyleConfig?["fontSize"] as? CGFloat ?? 24.0

    let progressTextStyle = UdentifyTextStyle(
      font: parseFont(family: textStyleConfig?["fontFamily"] as? String, size: fontSize, bold: textStyleConfig?["fontBold"] as? Bool),
      textColor: parseColor(textStyleConfig?["textColor"] as? String) ?? .white,
      textAlignment: parseTextAlignment(textStyleConfig?["textAlignment"] as? String, default: .center),
      lineBreakMode: .byWordWrapping,
      numberOfLines: textStyleConfig?["numberOfLines"] as? Int ?? 1,
      leading: textStyleConfig?["leading"] as? CGFloat ?? 20,
      trailing: textStyleConfig?["trailing"] as? CGFloat ?? 20
    )

    return UdentifyCommons.UdentifyProgressBarStyle(
      backgroundColor: parseColor(style?["backgroundColor"] as? String) ?? .purple.withAlphaComponent(0.7),
      progressColor: parseColor(style?["progressColor"] as? String) ?? .green,
      completionColor: parseColor(style?["completionColor"] as? String) ?? .green,
      textStyle: progressTextStyle,
      cornerRadius: style?["cornerRadius"] as? CGFloat ?? 8.0
    )
  }
  
  private func getIQAServiceEnabled() -> Bool {
    return uiConfig?["iqaEnabled"] as? Bool ?? true
  }

  private func getRawPhotoCropRatio() -> Double? {
    return uiConfig?["rawPhotoCropRatio"] as? Double ?? 0.35
  }

  /// OCRUIConfig.documentDetectionConfig (Dart) — colors the document's
  /// detection border while scanning. iOS only; no Android counterpart.
  /// Returns nil (framework default) when unconfigured, matching every
  /// other optional style object here.
  private func getDocumentDetectionConfig() -> UdentifyOCR.OCRDocumentDetectionConfig? {
    guard let config = uiConfig?["documentDetectionConfig"] as? [String: Any] else {
      return nil
    }
    let borderColorOnSuccess = parseColor(config["borderColorOnSuccess"] as? String) ?? .green
    let borderColorOnFailure = parseColor(config["borderColorOnFailure"] as? String) ?? .red

    return UdentifyOCR.OCRDocumentDetectionConfig(
      borderColorOnSuccess: borderColorOnSuccess,
      borderColorOnFailure: borderColorOnFailure
    )
  }

  private func getIQAScreenStyle() -> UdentifyOCR.IQAScreenStyle {
    guard let iqaConfig = uiConfig?["iqaScreenStyle"] as? [String: Any] else {
      return UdentifyOCR.IQAScreenStyle()
    }
    
    return UdentifyOCR.IQAScreenStyle(
      backgroundColor: parseColor(iqaConfig["backgroundColor"] as? String),
      backgroundStyle: nil,
      overlayImageStyle: getIQAOverlayImageStyle(iqaConfig),
      ocrImageStyle: getIQAOcrImageStyle(iqaConfig),
      resultAreaPositioning: getIQAResultAreaPositioning(iqaConfig),
      frontOverlayImage: nil,
      backOverlayImage: nil,
      titleLabelStyle: getIQATitleLabelStyle(iqaConfig),
      failureBannerStyle: getIQAFailureBannerStyle(iqaConfig),
      reasonBannerStyle: getIQAReasonBannerStyle(iqaConfig),
      successBannerStyle: getIQASuccessBannerStyle(iqaConfig),
      successButtonStyle: getIQASuccessButtonStyle(iqaConfig),
      retakeButtonStyle: getIQARetakeButtonStyle(iqaConfig),
      progressBarStyle: getIQAProgressBarStyle(iqaConfig),
      dismissAfterSuccessInSeconds: iqaConfig["dismissAfterSuccessInSeconds"] as? TimeInterval
    )
  }
  
  private func getIQAOverlayImageStyle(_ iqaConfig: [String: Any]) -> UdentifyCommons.UdentifyViewStyle {
    guard let overlayStyle = iqaConfig["overlayImageStyle"] as? [String: Any] else {
      return UdentifyCommons.UdentifyViewStyle(
        backgroundColor: .clear,
        borderColor: .clear,
        cornerRadius: 12,
        borderWidth: 0,
        horizontalSizing: .anchors(leading: 45, trailing: 45),
        verticalSizing: .fixed(height: 350, verticalPosition: .top(offset: 140))
      )
    }
    
    let backgroundColor = parseColor(overlayStyle["backgroundColor"] as? String) ?? .clear
    let borderColor = parseColor(overlayStyle["borderColor"] as? String) ?? .clear
    let cornerRadius = overlayStyle["cornerRadius"] as? CGFloat ?? 12.0
    let borderWidth = overlayStyle["borderWidth"] as? CGFloat ?? 0.0
    
    return UdentifyCommons.UdentifyViewStyle(
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      cornerRadius: cornerRadius,
      borderWidth: borderWidth,
      horizontalSizing: .anchors(leading: 45, trailing: 45),
      verticalSizing: .fixed(height: 350, verticalPosition: .top(offset: 140))
    )
  }
  
  private func getIQAOcrImageStyle(_ iqaConfig: [String: Any]) -> UdentifyCommons.UdentifyViewStyle {
    guard let ocrImageStyle = iqaConfig["ocrImageStyle"] as? [String: Any] else {
      return UdentifyCommons.UdentifyViewStyle(
        backgroundColor: .clear,
        borderColor: .white,
        cornerRadius: 12,
        borderWidth: 2,
        horizontalSizing: .anchors(leading: 30, trailing: 30),
        verticalSizing: .fixed(height: 200, verticalPosition: .top(offset: 100))
      )
    }
    
    let backgroundColor = parseColor(ocrImageStyle["backgroundColor"] as? String) ?? .clear
    let borderColor = parseColor(ocrImageStyle["borderColor"] as? String) ?? .white
    let cornerRadius = ocrImageStyle["cornerRadius"] as? CGFloat ?? 12.0
    let borderWidth = ocrImageStyle["borderWidth"] as? CGFloat ?? 2.0
    
    return UdentifyCommons.UdentifyViewStyle(
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      cornerRadius: cornerRadius,
      borderWidth: borderWidth,
      horizontalSizing: .anchors(leading: 30, trailing: 30),
      verticalSizing: .fixed(height: 200, verticalPosition: .top(offset: 100))
    )
  }
  
  private func getIQAResultAreaPositioning(_ iqaConfig: [String: Any]) -> UdentifyOCR.IQAPositionedArea {
    guard let positioning = iqaConfig["resultAreaPositioning"] as? [String: Any] else {
      return UdentifyOCR.IQAPositionedArea(
        target: .ocrPhoto,
        horizontal: .anchors(leading: 0, trailing: 0),
        vertical: .fixed(height: 0, verticalPosition: .bottom(offset: 50)),
        useSafeArea: false
      )
    }
    
    let targetString = positioning["target"] as? String ?? "ocrPhoto"
    let target: UdentifyOCR.IQAReferenceTarget
    switch targetString.lowercased() {
    case "container":
      target = .container
    case "containernosafe area", "containernosafearea":
      target = .containerNoSafeArea
    case "overlayimage":
      target = .overlayImage
    case "ocrphoto":
      target = .ocrPhoto
    case "footerview":
      target = .footerView
    default:
      target = .ocrPhoto
    }
    
    let horizontalPadding = positioning["horizontalPadding"] as? CGFloat ?? 0
    let verticalOffset = positioning["verticalOffset"] as? CGFloat ?? 50
    
    return UdentifyOCR.IQAPositionedArea(
      target: target,
      horizontal: .anchors(leading: horizontalPadding, trailing: horizontalPadding),
      vertical: .fixed(height: 0, verticalPosition: .bottom(offset: verticalOffset)),
      useSafeArea: false
    )
  }
  
  private func getIQATitleLabelStyle(_ iqaConfig: [String: Any]) -> UdentifyCommons.UdentifyTextStyle {
    let textColor = parseColor(iqaConfig["titleTextColor"] as? String) ?? .white
    let fontSize = iqaConfig["titleFontSize"] as? CGFloat ?? 19.0
    
    return UdentifyCommons.UdentifyTextStyle(
      font: UIFont.boldSystemFont(ofSize: fontSize),
      textColor: textColor,
      textAlignment: .center,
      lineBreakMode: .byWordWrapping,
      numberOfLines: 2,
      leading: 20,
      trailing: 20,
      verticalPosition: .top(offset: 50)
    )
  }
  
  private func getIQABannerStyle(
    _ iqaConfig: [String: Any],
    key: String,
    defaultBgColor: UIColor,
    defaultIconColor: UIColor,
    defaultTitleColor: UIColor,
    defaultDescColor: UIColor
  ) -> UdentifyOCR.IQABannerStyle {
    guard let bannerConfig = iqaConfig[key] as? [String: Any] else {
      return createDefaultIQABannerStyle(
        bgColor: defaultBgColor,
        iconColor: defaultIconColor,
        titleColor: defaultTitleColor,
        descColor: defaultDescColor
      )
    }
    
    let backgroundColor = parseColor(bannerConfig["backgroundColor"] as? String) ?? defaultBgColor
    let iconColor = parseColor(bannerConfig["iconColor"] as? String) ?? defaultIconColor
    let titleColor = parseColor(bannerConfig["titleColor"] as? String) ?? defaultTitleColor
    let descColor = parseColor(bannerConfig["descriptionColor"] as? String) ?? defaultDescColor
    let fontSize = bannerConfig["fontSize"] as? CGFloat ?? 16.0
    
    let titleStyle = UdentifyCommons.UdentifyTextStyle(
      font: UIFont.boldSystemFont(ofSize: fontSize),
      textColor: titleColor,
      textAlignment: .left,
      lineBreakMode: .byWordWrapping,
      numberOfLines: 0,
      lineHeightMultiple: 0.8, leading: 0,
      trailing: 0
    )
    
    let descStyle = UdentifyCommons.UdentifyTextStyle(
      font: UIFont.systemFont(ofSize: fontSize - 2),
      textColor: descColor,
      textAlignment: .left,
      lineBreakMode: .byWordWrapping,
      numberOfLines: 0,
      lineHeightMultiple: 0.8, leading: 0,
      trailing: 0
    )
    
    return UdentifyOCR.IQABannerStyle(
      backgroundColor: backgroundColor,
      borderColor: .clear,
      iconColor: iconColor,
      cornerRadius: 10,
      borderWidth: 0,
      verticalPadding: 12,
      horizontalPadding: 16,
      iconSize: CGSize(width: 30, height: 30),
      titleLabelStyle: titleStyle,
      descriptionLabelStyle: descStyle
    )
  }
  
  private func createDefaultIQABannerStyle(
    bgColor: UIColor,
    iconColor: UIColor,
    titleColor: UIColor,
    descColor: UIColor
  ) -> UdentifyOCR.IQABannerStyle {
    let titleStyle = UdentifyCommons.UdentifyTextStyle(
      font: UIFont.boldSystemFont(ofSize: 16),
      textColor: titleColor,
      textAlignment: .left,
      lineBreakMode: .byWordWrapping,
      numberOfLines: 0,
      lineHeightMultiple: 0.8, leading: 0,
      trailing: 0
    )
    
    let descStyle = UdentifyCommons.UdentifyTextStyle(
      font: UIFont.systemFont(ofSize: 14),
      textColor: descColor,
      textAlignment: .left,
      lineBreakMode: .byWordWrapping,
      numberOfLines: 0,
      lineHeightMultiple: 0.8, leading: 0,
      trailing: 0
    )
    
    return UdentifyOCR.IQABannerStyle(
      backgroundColor: bgColor,
      borderColor: .clear,
      iconColor: iconColor,
      cornerRadius: 10,
      borderWidth: 0,
      verticalPadding: 12,
      horizontalPadding: 16,
      iconSize: CGSize(width: 30, height: 30),
      titleLabelStyle: titleStyle,
      descriptionLabelStyle: descStyle
    )
  }
  
  private func getIQAFailureBannerStyle(_ iqaConfig: [String: Any]) -> UdentifyOCR.IQABannerStyle {
    return getIQABannerStyle(
      iqaConfig,
      key: "failureBanner",
      defaultBgColor: UIColor(red: 0.98, green: 0.88, blue: 0.9, alpha: 1),
      defaultIconColor: UIColor(red: 0.95, green: 0.33, blue: 0.34, alpha: 1),
      defaultTitleColor: UIColor(red: 0.69, green: 0.14, blue: 0.23, alpha: 1),
      defaultDescColor: UIColor(red: 0.69, green: 0.14, blue: 0.23, alpha: 1)
    )
  }
  
  private func getIQAReasonBannerStyle(_ iqaConfig: [String: Any]) -> UdentifyOCR.IQABannerStyle {
    return getIQABannerStyle(
      iqaConfig,
      key: "reasonBanner",
      defaultBgColor: UIColor(red: 0.98, green: 0.94, blue: 0.85, alpha: 1),
      defaultIconColor: UIColor(red: 0.96, green: 0.83, blue: 0.06, alpha: 1),
      defaultTitleColor: UIColor(red: 0.45, green: 0.32, blue: 0.05, alpha: 1),
      defaultDescColor: UIColor(red: 0.45, green: 0.32, blue: 0.05, alpha: 1)
    )
  }
  
  private func getIQASuccessBannerStyle(_ iqaConfig: [String: Any]) -> UdentifyOCR.IQABannerStyle {
    return getIQABannerStyle(
      iqaConfig,
      key: "successBanner",
      defaultBgColor: UIColor(red: 0xDC/255.0, green: 0xEB/255.0, blue: 0xF0/255.0, alpha: 1.0),
      defaultIconColor: UIColor(red: 0x4C/255.0, green: 0xD9/255.0, blue: 0x64/255.0, alpha: 1.0),
      defaultTitleColor: UIColor(red: 0x2B/255.0, green: 0xAC/255.0, blue: 0x72/255.0, alpha: 1.0),
      defaultDescColor: UIColor(red: 0x2B/255.0, green: 0xAC/255.0, blue: 0x72/255.0, alpha: 1.0)
    )
  }
  
  private func getIQASuccessButtonStyle(_ iqaConfig: [String: Any]) -> UdentifyCommons.UdentifyButtonStyle {
    guard let buttonConfig = iqaConfig["successButton"] as? [String: Any] else {
      return UdentifyCommons.UdentifyButtonStyle(
        backgroundColor: UIColor(red: 0.3, green: 0.85, blue: 0.39, alpha: 1),
        borderColor: .clear,
        cornerRadius: 8,
        borderWidth: 0,
        contentAlignment: .center,
        height: 70,
        leading: 20,
        trailing: 20,
        font: UIFont.boldSystemFont(ofSize: 20),
        textColor: .white,
        textAlignment: .center,
        lineBreakMode: .byWordWrapping,
        numberOfLines: 0
      )
    }
    
    let backgroundColor = parseColor(buttonConfig["backgroundColor"] as? String) ?? UIColor(red: 0.3, green: 0.85, blue: 0.39, alpha: 1)
    let textColor = parseColor(buttonConfig["textColor"] as? String) ?? .white
    let fontSize = buttonConfig["fontSize"] as? CGFloat ?? 20.0
    
    return UdentifyCommons.UdentifyButtonStyle(
      backgroundColor: backgroundColor,
      borderColor: .clear,
      cornerRadius: 8,
      borderWidth: 0,
      contentAlignment: .center,
      height: 70,
      leading: 20,
      trailing: 20,
      font: UIFont.boldSystemFont(ofSize: fontSize),
      textColor: textColor,
      textAlignment: .center,
      lineBreakMode: .byWordWrapping,
      numberOfLines: 0
    )
  }
  
  private func getIQARetakeButtonStyle(_ iqaConfig: [String: Any]) -> UdentifyCommons.UdentifyButtonStyle {
    guard let buttonConfig = iqaConfig["retakeButton"] as? [String: Any] else {
      return UdentifyCommons.UdentifyButtonStyle(
        backgroundColor: UIColor(red: 1, green: 0.23, blue: 0.19, alpha: 1),
        borderColor: .clear,
        cornerRadius: 8,
        borderWidth: 0,
        contentAlignment: .center,
        height: 70,
        leading: 20,
        trailing: 20,
        font: UIFont.boldSystemFont(ofSize: 20),
        textColor: .white,
        textAlignment: .center,
        lineBreakMode: .byWordWrapping,
        numberOfLines: 0
      )
    }
    
    let backgroundColor = parseColor(buttonConfig["backgroundColor"] as? String) ?? UIColor(red: 1, green: 0.23, blue: 0.19, alpha: 1)
    let textColor = parseColor(buttonConfig["textColor"] as? String) ?? .white
    let fontSize = buttonConfig["fontSize"] as? CGFloat ?? 20.0
    
    return UdentifyCommons.UdentifyButtonStyle(
      backgroundColor: backgroundColor,
      borderColor: .clear,
      cornerRadius: 8,
      borderWidth: 0,
      contentAlignment: .center,
      height: 70,
      leading: 20,
      trailing: 20,
      font: UIFont.boldSystemFont(ofSize: fontSize),
      textColor: textColor,
      textAlignment: .center,
      lineBreakMode: .byWordWrapping,
      numberOfLines: 0
    )
  }
  
  private func getIQAProgressBarStyle(_ iqaConfig: [String: Any]) -> UdentifyCommons.UdentifyProgressBarStyle? {
    guard let progressConfig = iqaConfig["progressBar"] as? [String: Any] else {
      return UdentifyCommons.UdentifyProgressBarStyle(
        backgroundColor: .lightGray,
        progressColor: UIColor(red: 0.3, green: 0.85, blue: 0.39, alpha: 1),
        completionColor: UIColor(red: 0.3, green: 0.85, blue: 0.39, alpha: 1),
        textStyle: UdentifyCommons.UdentifyTextStyle(
          font: UIFont.boldSystemFont(ofSize: 20),
          textColor: .white,
          textAlignment: .center,
          lineBreakMode: .byWordWrapping,
          numberOfLines: 0,
          leading: 20,
          trailing: 20
        ),
        cornerRadius: 8
      )
    }
    
    let backgroundColor = parseColor(progressConfig["backgroundColor"] as? String) ?? .lightGray
    let progressColor = parseColor(progressConfig["progressColor"] as? String) ?? UIColor(red: 0.3, green: 0.85, blue: 0.39, alpha: 1)
    let completionColor = parseColor(progressConfig["completionColor"] as? String) ?? UIColor(red: 0.3, green: 0.85, blue: 0.39, alpha: 1)
    let textColor = parseColor(progressConfig["textColor"] as? String) ?? .white
    let fontSize = progressConfig["fontSize"] as? CGFloat ?? 20.0
    
    let textStyle = UdentifyCommons.UdentifyTextStyle(
      font: UIFont.boldSystemFont(ofSize: fontSize),
      textColor: textColor,
      textAlignment: .center,
      lineBreakMode: .byWordWrapping,
      numberOfLines: 0,
      leading: 20,
      trailing: 20
    )
    
    return UdentifyCommons.UdentifyProgressBarStyle(
      backgroundColor: backgroundColor,
      progressColor: progressColor,
      completionColor: completionColor,
      textStyle: textStyle,
      cornerRadius: 8
    )
  }
  
  /// Resolves an `OCRTextStyle`/`OCRButtonStyle` (Dart) `fontFamily`/`fontSize`/`fontBold`
  /// triple to a `UIFont`. Falls back to the system font when `fontFamily` is nil or the
  /// named font isn't installed; `bold` defaults to true to match the SDK's previous
  /// always-bold behavior when not specified.
  private func parseFont(family: String?, size: CGFloat, bold: Bool?) -> UIFont {
    if let family = family, let customFont = UIFont(name: family, size: size) {
      return customFont
    }
    return (bold ?? true) ? UIFont.boldSystemFont(ofSize: size) : UIFont.systemFont(ofSize: size)
  }

  /// Resolves an `OCRTextStyle`/`OCRButtonStyle` (Dart) `textAlignment` string
  /// ("left" | "center" | "right") to `NSTextAlignment`, falling back to `default`.
  private func parseTextAlignment(_ value: String?, default defaultAlignment: NSTextAlignment) -> NSTextAlignment {
    switch value?.lowercased() {
    case "left":
      return .left
    case "center":
      return .center
    case "right":
      return .right
    default:
      return defaultAlignment
    }
  }

  private func parseColor(_ colorString: String?) -> UIColor? {
    guard let colorString = colorString else { return nil }
    
    switch colorString.lowercased() {
    case "purple":
      return .purple
    case "blue":
      return .blue
    case "green":
      return .green
    case "red":
      return .red
    case "black":
      return .black
    case "white":
      return .white
    case "gray", "grey":
      return .gray
    case "clear":
      return .clear
    case "label":
      return .label
    default:
      if colorString.hasPrefix("#") {
        return UIColor(hex: colorString)
      }
      return nil
    }
  }
}

extension UIColor {
  convenience init?(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let a, r, g, b: UInt64
    switch hex.count {
    case 3:
      (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6:
      (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8:
      (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
      return nil
    }
    
    self.init(
      red: Double(r) / 255,
      green: Double(g) / 255,
      blue: Double(b) / 255,
      alpha: Double(a) / 255
    )
  }
}
