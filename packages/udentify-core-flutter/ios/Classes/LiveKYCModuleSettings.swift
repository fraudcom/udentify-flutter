//  LiveKYCModuleSettings.swift
//  udentify_core_flutter
//  Rendezvous for the module settings LiveKYC asks the host to install.

import Foundation

/// Carries the SDK's `LiveKYCSettings` closures across a plugin boundary. Each module plugin
/// (OCR, liveness, NFC) publishes its installer here and the video call plugin, the only one
/// linking `UdentifyLiveKYC`, forwards them. This keeps the module plugins independently
/// installable: an OCR-only app never pulls in `UdentifyVC`. A `nil` slot means that plugin is
/// not installed.
public enum UdentifyLiveKYCModuleSettings {

    /// Sets `OCRSettingsProvider.currentSettings`. Published by `ocr_flutter`, invoked from
    /// `LiveKYCSettings.ocr`.
    public static var installOCRSettings: (() -> Void)?

    /// Sets `ApiSettingsProvider.currentSettings`. Published by `liveness_flutter`, invoked from
    /// `LiveKYCSettings.face`.
    public static var installFaceSettings: (() -> Void)?

    /// The NFC step has no settings object of its own; the slot exists because the SDK exposes
    /// the closure, and stays `nil` unless something needs it.
    public static var installNFCSettings: (() -> Void)?

    /// The bundle the in-call NFC screen reads its text from, published by `nfc_flutter`. NFC
    /// takes its bundle as a field on `VCLiveKYCOptions` rather than through a settings provider,
    /// so this is read once when a call starts.
    public static var nfcLocalizationBundle: (() -> Bundle?)?
}
