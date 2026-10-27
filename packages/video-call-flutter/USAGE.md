# video-call-flutter: usage guide

How to run an Udentify video call from a Flutter app: permissions, starting and ending a call,
the events you receive, controlling the microphone, LiveKYC redos and styling. For installing the
plugin and its native SDKs see the [README](README.md).

The plugin is a thin bridge over the native Udentify SDKs. It passes your values to the SDK and
reports what the SDK emits; the call screen, the media connection and the agent hand-off are the
SDK's. Where a native SDK offers no control, the plugin offers none either (see
[section 7](#7-controlling-the-call)).

**Contents**

1. [How the API is shaped](#1-how-the-api-is-shaped)
2. [Quick start](#2-quick-start)
3. [Permissions](#3-permissions)
4. [Credentials](#4-credentials)
5. [Call lifecycle and status values](#5-call-lifecycle-and-status-values)
6. [Event reference](#6-event-reference)
7. [Controlling the call](#7-controlling-the-call)
8. [Ending the call](#8-ending-the-call)
9. [LiveKYC: in-call OCR / Face / NFC repeats](#9-livekyc-in-call-ocr--face--nfc-repeats)
10. [UI configuration](#10-ui-configuration)
11. [Errors](#11-errors)
12. [Platform notes](#12-platform-notes)
13. [Troubleshooting](#13-troubleshooting)
14. [API reference](#14-api-reference)

---

## 1. How the API is shaped

- Every call is a static method on `VideoCallFlutter`. There is one call at a time.
- The native SDK draws the whole call screen, full screen, on top of your app. There is no widget to
  embed, so buttons in your own UI are not reachable during a call: drive the call from events and
  end it with `cancelVideoCall()`.
- Events arrive through static setters (`setOnStatusChanged`, `setOnError`, ...). **Register them
  before `startVideoCall`.** Each setter holds one callback; setting it again replaces the previous one.
- Operations return a `VideoCallResult` (`success`, `status`, `error`) instead of throwing.

## 2. Quick start

```dart
import 'package:video_call_flutter/video_call_flutter.dart';

Future<void> runCall() async {
  // 1. Events first.
  VideoCallFlutter.setOnStatusChanged((status) => print('status: $status'));
  VideoCallFlutter.setOnError((error) => print('error: ${error.type} ${error.message}'));
  VideoCallFlutter.setOnVideoCallEnded((success) => print('ended, success=$success'));

  // 2. Permissions.
  var permissions = await VideoCallFlutter.checkPermissions();
  if (!permissions.hasCameraPermission || !permissions.hasRecordAudioPermission) {
    await VideoCallFlutter.requestPermissions();
    permissions = await VideoCallFlutter.checkPermissions();
  }

  // 3. Start. The transaction comes from your backend.
  final result = await VideoCallFlutter.startVideoCall(
    VideoCallCredentials(
      serverURL: 'https://your-server.com',
      wssURL: 'wss://your-server.com/ws',
      userID: 'user-123',
      transactionID: transactionIdFromYourBackend,
      clientName: 'Flutter Client',
    ),
  );
  if (!result.success) {
    print('did not start: ${result.error?.type} ${result.error?.message}');
  }
}

// Later, from an event handler or your own UI once the call screen is gone:
//   await VideoCallFlutter.cancelVideoCall();   // ends the agent's session too
```

## 3. Permissions

`checkPermissions()` returns a `VideoCallPermissionStatus`: `hasCameraPermission`,
`hasPhoneStatePermission`, `hasInternetPermission`, `hasRecordAudioPermission`.
`requestPermissions()` returns `"granted"` or `"denied"`, or `"error"` if the request itself failed (for example a second request while one is pending).

- **Android** requests camera, phone state and microphone at runtime. `INTERNET` is install-time
  and is never requested. A request that is dismissed counts as denied. Only one request can be in
  flight; a second one comes back as `"error"`.
- **iOS** asks for camera and microphone. Add `NSCameraUsageDescription` and
  `NSMicrophoneUsageDescription` to `Info.plist`.
- **Ask when the user starts the call, not at launch** (Apple's guidance). The
  SDK does not ask for you: the iOS SDK does not request camera or microphone at all, and starting a call without
  them fails at once with `cameraPermissionRequired` and dismisses the call screen. iOS shows each system prompt
  **once**; after a refusal `requestPermissions()` returns `"denied"` without a prompt, and only Settings can
  change it. So, before `startVideoCall`: check; request only if something is missing; if it is still missing, do
  not start the call and tell the user to enable camera and microphone in Settings.

  ```dart
  var p = await VideoCallFlutter.checkPermissions();
  if (!(p.hasCameraPermission && p.hasRecordAudioPermission)) {
    await VideoCallFlutter.requestPermissions();
    p = await VideoCallFlutter.checkPermissions();
  }
  if (!(p.hasCameraPermission && p.hasRecordAudioPermission)) {
    // explain, point to Settings, and stop
    return;
  }
  await VideoCallFlutter.startVideoCall(credentials);
  ```
- The SDK checks again when the call starts. If a permission is missing it reports a typed error
  (`cameraPermissionDenied`, `microphonePermissionDenied`, ...) so you can prompt or send the user
  to Settings.

## 4. Credentials

`VideoCallCredentials`:

| Field | Meaning |
|---|---|
| `serverURL`, `wssURL` | The video call service and its WebSocket |
| `userID`, `transactionID`, `clientName` | Identify the customer and the transaction |
| `idleTimeout` | Seconds, as a string. Default `"30"`. Note: the iOS SDK's own default is 100, so leaving this unset means 30 on both platforms |
| `cameraFeedFrameRate` | Optional frames per second for the call camera. Leave `null` to keep each SDK's own default (they differ per platform). A request, not a guarantee: the SDK clamps a rate the sensor cannot deliver, and non-positive values are ignored |
| `observationMode` | What the operator sees while a LiveKYC step runs: `cameraFeed` (default, needs no screen-capture permission), `screenShare` (**beta**, untested end to end) or `progressOnly`. See [section 9](#9-livekyc-in-call-ocr--face--nfc-repeats) |
| `liveKYCOptions` | iOS only; its presence turns LiveKYC on. See section 9 |
| `logLevel` | iOS only: how much the SDK writes to its own log (a `VideoCallLogLevel`: `verbose`, `debug`, `info`, `warning`, `error`). Leave `null` for the SDK's default, `info`. The Android SDK has no such setting |

## 5. Call lifecycle and status values

`setOnStatusChanged` and `getVideoCallStatus()` report a `VideoCallStatus`.

| Status | Meaning |
|---|---|
| `idle` | No call |
| `connecting`, `connected` | The call is starting / running |
| `disconnected` | The call screen went away without a definitive result |
| `completed` | The call ended normally |
| `failed` | An SDK error ended the call |
| `initiating`, `tokenFetching`, `tokenFetched`, `reconnecting` | The SDK's own user states. Reported by **iOS only** |

An SDK error moves the call to `failed` and is also delivered through `setOnError`. The one
exception is the informational `ERR_LIVEKYC_SCREEN_RECORDING_PERMISSION_DENIED`: it is reported
through `setOnError` and the call keeps running (camera only, screen sharing off).
`setOnVideoCallEnded(success)` fires when the call ends. On Android it tells a normal end (`true`) from an end
after an error (`false`); on iOS it fires only when the agent ends the session, with `true`.

## 6. Event reference

Register with the static `setOn...` methods. All callbacks run on the main isolate.

| Setter | Fires when | Payload | Platform |
|---|---|---|---|
| `setOnStatusChanged` | The call status changes | `VideoCallStatus` | both |
| `setOnError` | The SDK reports an error | `VideoCallError` (`type`, `code`, `message`, `details`) | both |
| `setOnUserStateChanged` | The SDK's user state changes | `VideoCallStatus` | both |
| `setOnParticipantStateChanged` | The agent or a supervisor connects, sends video, pauses, leaves | `VideoCallParticipantState` (`participantType`, `state`); `participantType` is `null` when it cannot be determined | both |
| `setOnVideoCallEnded` | The call ended | `bool success` | both |
| `setOnVideoCallDismissed` | The call screen was dismissed without a definitive result | none | iOS |
| `setOnMicrophoneStateChanged` | Any microphone change: the in-call button, the agent's mute signal, automatic mutes (app backgrounded, a phone call answered) and the matching unmutes | `bool enabled` | both |
| `setOnPhoneCallStateChanged` | A device phone call overlaps the call | `incoming`, `outgoing`, `connected`, `ended`. Informational: the call stays connected | both |
| `setOnScreenLocked` / `setOnScreenUnlocked` | The device screen locks / unlocks during the call | none | both |
| `setOnRepeatStarted` / `setOnRepeatResult` / `setOnRepeatEnded` | LiveKYC repeats, see section 9 | role / outcome | both |
| `setOnNfcProgress` | Chip read progress, `0`-`99` | `int` | iOS |

## 7. Controlling the call

**Microphone.** `setMicrophoneEnabled(bool)` asks the SDK to mute or unmute. `true` means the
request was accepted, not applied: follow `setOnMicrophoneStateChanged` for the real state. `false`
means there was no connected call. `isMicrophoneEnabled()` reads the SDK's current state. On iOS the
plugin also re-reads the state when the connection is re-established, because the SDK only reports
actual changes and does not restore state after a reconnect.

**Camera.** Neither native SDK exposes camera control to the host: users switch the camera with the
SDK's own in-call button. The plugin has no camera methods. `toggleCamera()`, `switchCamera()` and
`toggleMicrophone()` were removed in this version; use
`setMicrophoneEnabled` for the microphone.

## 8. Ending the call

| Method | What it does |
|---|---|
| `cancelVideoCall()` | Cancels the transaction **on the server**, then dismisses the call. This is what ends the agent's session. Fails with `NO_ACTIVE_CALL` (read it from `result.error?.code`) when no call is running. A second cancel while one is in flight is refused (`ALREADY_IN_PROGRESS`), because the server does not treat a duplicate cancel as idempotent |
| `endVideoCall()` | Ends the call **locally** only. The agent sees a dropped connection until the server's idle timeout. Kept as it always behaved, so existing integrations do not change |
| `dismissVideoCall()` | Same as `endVideoCall()` |

Use `cancelVideoCall()` when the user hangs up. When the server confirms the cancel, the call
screen is dismissed. On Android the SDK closes the call screen even when the server cancel fails: the call is over
either way, and a failed cancel is reported as `CANCEL_VIDEO_CALL_FAILED` in `error.code` (the agent's session may then still be open on
the server). The status is `completed` when the SDK reported the end of the call (the usual case after a confirmed
cancel) and `disconnected` otherwise.

**iOS: the call screen is presented full screen** from whichever view controller is on top of the app (a modal another plugin left open does not block it), and a second `startVideoCall` while a call is on screen fails with `ALREADY_IN_PROGRESS`. The call screen ends by being dismissed, whatever ended it (the agent, a lost
connection, the idle timeout, a call that could not start, `endVideoCall()`, a confirmed cancel). Show your next
screen from `setOnVideoCallDismissed`, not from `setOnVideoCallEnded`: the ended event fires only when the agent
ends the session, while the dismissed event fires every time, once the screen is actually gone.

### Adding your own end-call button

Neither SDK draws an end-call button, and the plugin does not add one: it only exposes the methods above. If your
users should be able to hang up themselves, your app adds the button. A Flutter widget cannot draw over the call
screen (it is a separate native screen), so the button is a small piece of **native code in your app**, driven from
Dart. The pattern is the same on both platforms:

1. A `MethodChannel` of your own with `show`, `hide` (Dart to native) and `onPressed` (native to Dart).
2. `show()` when `startVideoCall` succeeds. `hide()` when the call ends, whatever ended it: the status
   (`disconnected`, `completed`, `failed`), `setOnVideoCallEnded`, `setOnVideoCallDismissed` and `setOnError`.
   `hide()` must be safe to call twice.
3. In `onPressed`, call `cancelVideoCall()`, and `endVideoCall()` if the cancel is not confirmed. Guard against a
   second tap while one is running.
4. While a [LiveKYC repeat](#9-livekyc-in-call-ocr--face--nfc-repeats) is on screen the SDK's capture screen
   takes over, so `hide()` on `setOnRepeatStarted` and `show()` again on `setOnRepeatEnded` (if the call is still
   running). Use *ended*, not *result*: a repeat the operator cancels produces no result, and the call would be left
   without its button.

How to draw it, per platform:

- **Android.** In your `FlutterFragmentActivity`, add an `ImageButton` to the window's **decor view**
  (`window.decorView as ViewGroup`), not to the content view the call fragment is added to. Siblings are drawn by
  elevation, and the SDK's call layout sets its own (its root has `android:elevation="100dp"` in 26.3.0928), so a
  button next to it in the content view is covered unless it guesses a bigger number, and that number belongs to the
  SDK. A child of the decor view is compared with the whole content subtree as one, so nothing inside the call
  screen can draw over it. Take the top and side margins from the raw window insets (`view.rootWindowInsets`: system
  bars and cut-out, recomputed on every layout), so it clears the status bar whether or not the window is
  edge-to-edge. Remove it in `hide` and in `onDestroy`. Avoid `TYPE_APPLICATION_OVERLAY`: it needs the
  `SYSTEM_ALERT_WINDOW` permission.
- **iOS.** Put the button in a **window of its own**: a `UIWindow` on the active `UIWindowScene`, at
  `windowLevel = .normal + 1`, with a clear root view controller, shown with `isHidden = false` (not
  `makeKeyAndVisible()`, so it never becomes the key window). Override `hitTest` to return `nil` when the hit is
  the root view, so every touch outside the button reaches the call screen. Constrain the button to the root view's
  `safeAreaLayoutGuide`. A separate window is the right place because the call screen is presented by the SDK: its views
  are not yours to depend on, and nothing the SDK adds can cover the button. Do not embed the call controller in
  your own container view controller; the SDK documentation says to present it.

The test app has a complete working version: `lib/services/call_overlay.dart` (the Dart side),
`android/app/src/main/kotlin/com/fraud/fraudflutter/MainActivity.kt` and `ios/Runner/AppDelegate.swift`
(the native side), and `_onEndCallPressed` in `lib/pages/video_call_test_page.dart`.

## 9. LiveKYC: in-call OCR / Face / NFC repeats

During a call the operator can ask the customer to redo a capture (a document scan, a face check, an NFC chip read) without leaving the call. The plugins only pass your configuration to the native SDKs and report what they emit; the capture itself is the SDK's.

**It is off by default**, and turning it on differs per platform:

| | Android | iOS |
|---|---|---|
| Switch | Opt each capture package in with its `setRepeatConfig` **before** starting the call | Pass `liveKYCOptions` (or `observationMode`) in `VideoCallCredentials` |
| Configured by | `OcrFlutter.setRepeatConfig`, `LivenessFlutter.setRepeatConfig`, `NfcFlutter().setRepeatConfig` | `VideoCallLiveKYCOptions` |

`setRepeatConfig` returns `false` on iOS, and `liveKYCOptions` is ignored on Android. On iOS, `VideoCallLiveKYCOptions` also takes `ocrLogLevel`, `hologramLogLevel`, `faceLogLevel` and `nfcLogLevel` (the SDK's own logging per step; its defaults are `warning`, `warning`, `warning` and `info`). Pass `null` to `setRepeatConfig` to opt back out. Install only the capture packages you need: a package that is not installed simply refuses its repeat.

**iOS options.** Every field of `VideoCallLiveKYCOptions` is optional and only what you set is sent to the SDK:

| Field | Type | What it sets |
|---|---|---|
| `observationMode` | `VideoCallObservationMode` | What the operator sees during a step (see below) |
| `userID` | `String` | Your identifier for the customer. Needed for face registration and authentication and for active or hybrid liveness; falls back to the credentials' `userID` |
| `listName` | `String` | Needed for face identification |
| `ocrDocumentType` | `VideoCallOCRDocumentType`: `idCard`, `passport`, `driveLicence` | The document the OCR step scans |
| `ocrCountry` | `String` | Issuing country as an ISO code such as `TUR` or `DEU`. The OCR step does not run without one and the SDK's default is Turkey, so set it unless your documents are Turkish |
| `ocrDocumentSide` | `VideoCallOCRDocumentSide`: `bothSides`, `frontSide`, `backSide` | Which side the OCR step scans |
| `ocrManualCapture`, `ocrDocumentLivenessEnabled` | `bool` | Manual shutter, and the SDK's document-liveness check, in the OCR step |
| `faceMethod` | `VideoCallFaceMethod`: `registration`, `authentication`, `imageUpload`, `selfie`, `identification` | The face operation |
| `selfieOperation` | `VideoCallFaceMethod` | The face operation the selfie step performs |
| `faceLivenessMode` | `VideoCallFaceLivenessMode`: `passive`, `active`, `hybrid` | Which liveness check the face step runs |
| `nfcChipAnticloneMode` | `VideoCallNFCChipAnticloneMode`: `none`, `auto`, `requireCA`, `requireAA` | How the NFC step authenticates the chip |
| `nfcIsPassiveAuthenticationEnabled`, `nfcIsFastModeEnabled` | `bool` | The NFC step's passive authentication and fast mode |
| `nfcRequestTimeout` | `double` | Seconds before the chip read times out |
| `nfcTableName` | `String` | The `.strings` table for the NFC step's text |
| `hologramNoFlashDuration`, `hologramFlashDuration`, `hologramTotalDuration`, `hologramBitrate`, `hologramRequestTimeout` | `double` | The hologram step's recording lengths (seconds), bitrate and request timeout |
| `ocrLogLevel`, `hologramLogLevel`, `faceLogLevel`, `nfcLogLevel` | `VideoCallLogLevel` | The SDK's logging per step (described above) |

```dart
// Android: before startVideoCall
await OcrFlutter.setRepeatConfig(OCRRepeatConfig(
  serverURL: serverURL, userID: userID, transactionID: transactionID,
  country: 'TUR', documentSide: OCRRepeatDocumentSide.front));
await LivenessFlutter.setRepeatConfig(FaceRepeatConfig(
  serverURL: serverURL, userID: userID, transactionID: transactionID,
  method: FaceRepeatMethod.activeLiveness, isAuthenticate: false,
  activeLivenessOpacity: 0)); // 0 shows the camera; the SDK default hides it
await NfcFlutter().setRepeatConfig(NfcRepeatConfig(
  serverURL: serverURL, transactionID: transactionID));
// The Android NFC repeat uses the SDK's default chip authentication mode (`auto`).

// iOS: with the call
VideoCallCredentials(/* ... */, liveKYCOptions: VideoCallLiveKYCOptions(ocrCountry: 'TUR'));
```

**Events** (all platforms): `setOnRepeatStarted(role)` when a repeat is about to take over the call screen (not fired when refused), `setOnRepeatResult(role)` when a repeat produced a result (never on cancel or failure, and carries nothing for OCR), and `setOnRepeatEnded(event)` once per repeat that started, whatever ended it. Prefer `setOnRepeatEnded`; on a completed repeat the result callback arrives first. `setOnNfcProgress(percent)` reports the chip read on **iOS only** (`0`-`99`, never 100: a finished read is a completed NFC repeat). The iOS SDK draws no UI for the chip read, so show your own view.

Things that fail quietly if you miss them:
- **OCR country**: the SDK's default is Turkey. Set `country` / `ocrCountry` unless your documents are Turkish.
- **OCR side (Android)**: omitted, a repeat always re-scans the front, even if the operator asked for the back.
- **Face `isAuthenticate` (Android)**: `true` authenticates an existing user, `false` registers a new one. A wrong value silently runs the other operation.
- **Face opacity (Android)**: the SDK draws an opaque backdrop over its own camera preview unless `activeLivenessOpacity` is set.
- **NFC needs OCR first**: an NFC repeat derives its chip key from the OCR repeat that ran earlier in the same call, and is refused without one.
- **Observation mode** (`observationMode`, passed straight to the SDK; omit it for the SDK's default). It controls the operator's view during a repeat only.

  | Value | What the operator sees |
  |---|---|
  | `cameraFeed` *(default)* | The camera only, not the capture screen's instructions, masks or errors. Needs no screen capture, so no consent dialog and no recording notification |
  | `screenShare` | The customer's screen, so the capture UI and its error states are visible. **Beta** |
  | `progressOnly` | Legacy: a separate screen track. Prefer one of the above |

  An NFC repeat publishes no video under `cameraFeed`: NFC opens no camera, so the operator sees nothing until the step ends. That is expected. `screenShare` asks the customer for screen-capture consent at the first repeat of a call and keeps it for the rest; on Android the relay pauses while the app is in the background.

> The Android LiveKYC path was verified to compile against the 26.3.0928 SDK; it has not been exercised in a live call with an operator.

## 10. UI configuration (the styler)

`VideoCallFlutter.setVideoCallConfig(VideoCallConfig(...))`, called **before** `startVideoCall` (it can also be
called during a call on Android). Every field is optional, and **what you do not set keeps the SDK's own look** on
both platforms; the plugin adds no defaults of its own. Only the fields you set are sent to the native side.

```dart
await VideoCallFlutter.setVideoCallConfig(const VideoCallConfig(
  backgroundColor: '#101820',
  pipViewStyle: VideoCallPipViewStyle(
    borderColor: '#FFFFFF',
    cornerRadius: 12,
    horizontalPosition: VideoCallHorizontalPosition(VideoCallHorizontalPositionType.right, offset: 16),
  ),
  muteButtonStyle: VideoCallMuteButtonStyle(mutedColor: '#FF3B30', size: 56),
  instructionLabelStyle: VideoCallInstructionLabelStyle(fontSize: 22, textColor: '#FFFFFF'),
));
```

| Element | Fields | iOS | Android |
|---|---|---|---|
| Call background | `backgroundColor` | yes | yes |
| Waiting-screen label | `instructionLabelStyle` (`fontSize`, `fontWeight`, `fontFamily`, `textColor`, `textAlign`, `numberOfLines`, `lineHeightMultiple`, `leading`, `trailing`, `verticalPosition`); shorthand `textColor` | yes | yes |
| Picture-in-picture | `pipViewStyle` (`width`, `height`, `horizontalPosition`, `verticalPosition`, `horizontalAnchors`, `verticalAnchors`, `backgroundColor`, `borderColor`, `borderWidth`, `cornerRadius`); shorthand `pipViewBorderColor` | yes | yes |
| Mute button | `muteButtonStyle` (`size`, `mutedColor`, `unmutedColor`, `horizontalPosition`, `verticalPosition`) | yes | yes |
| Camera switch button | `cameraSwitchButtonStyle` (`size`, `color`, `horizontalPosition`, `verticalPosition`) | yes | yes |
| Torch button | `flashButtonStyle` (`visible`, `size`, `color`, positions) | no such button | yes, hidden unless `visible: true` |
| Hide an element | `visible: false` on the PiP, mute or camera-switch style | no (the SDK offers no way) | yes |
| Strings table, request timeout | `tableName`, `requestTimeout` | yes | no (the Android SDK has neither) |

- **Types**, all exported by `package:video_call_flutter/video_call_flutter.dart`: the styles are
  `VideoCallPipViewStyle`, `VideoCallMuteButtonStyle`, `VideoCallCameraSwitchButtonStyle`, `VideoCallFlashButtonStyle`
  and `VideoCallInstructionLabelStyle`. Positions are `VideoCallHorizontalPosition` (`left`, `right`, `center`, `custom`)
  and `VideoCallVerticalPosition` (`top`, `bottom`, `center`, `custom`); anchors are `VideoCallHorizontalAnchors` and
  `VideoCallVerticalAnchors`. `fontWeight` takes a `VideoCallFontWeight` (`regular`, `medium`, `semibold`, `bold`) and
  `textAlign` a `VideoCallTextAlign` (`left`, `center`, `right`).
- **Colors** are `#RGB`, `#RRGGBB` or `#AARRGGBB`.
- **Sizes and insets** are dp (Android) / points (iOS).
- **Positions.** `left` / `right` / `top` / `bottom` take an `offset` in from that edge. `center` on the
  horizontal axis takes a signed `offset` (positive towards the trailing edge). `custom` takes `x` or `y` from the
  leading/top edge. Name an edge without an offset and the element sits flush against it. Set only one of the two
  axes and the other keeps the SDK's placement.
- **Top and bottom positions are measured from the call view's own edge, not the safe area**. The iOS call screen is full screen, and an edge-to-edge Android window draws
  under the system bars too, so there the top edge is the top of the display and a `top` offset starts under the
  status bar / notch. Add the inset yourself. Read it from the Flutter view, which reports 0 when the window
  already starts below the status bar, so one value is right on both platforms:

  ```dart
  // Not MediaQuery.of(context): inside a Scaffold with an app bar that inset has already been consumed.
  final inset = MediaQueryData.fromView(View.of(context)).padding.top;
  pipViewStyle: VideoCallPipViewStyle(
    verticalPosition: VideoCallVerticalPosition(VideoCallVerticalPositionType.top, offset: inset + 16),
  ),
  ```
- **Anchors** stretch the PiP between two insets instead of using a fixed size, and win over `width` / `height`.
- **Styling a button.** On iOS the parts you leave out keep the SDK's values. On Android, styling a button moves it
  into the call layout at the same default place iOS uses (camera switch bottom-left 16, mute bottom-center, both 50
  and 20 from the bottom; torch bottom-right 16) and then applies what you set. A button you do not style is left
  exactly as the SDK draws it.
- On Android the styler works on the SDK's inflated views by resource name, because the SDK only supports build-time
  XML overrides. A future SDK that renames those views loses the styling but never fails the call.
- The call screen's texts come from the SDK's own localization on both platforms.

### Moving to one `VideoCallConfig` for both platforms

Earlier releases styled the Android call screen only through build-time XML resources and applied a few
`VideoCallConfig` fields on iOS alone. One `VideoCallConfig` now styles both, so a styling setup can be reduced to one place:

1. **Put the look in `VideoCallConfig`** (see the table above) and call `setVideoCallConfig` before `startVideoCall`.
   The same colors, sizes and positions give the same screen on iOS and Android.
2. **iOS shows the SDK's look for anything you do not set**: background, picture-in-picture frame, button styles and
   instruction font. To keep an earlier look, set those values.
3. **`backgroundColor`, `textColor` and `pipViewBorderColor` now also work on Android.** They already worked on iOS.
4. **Android XML overrides still work** for whatever you do not style in `VideoCallConfig`. An element you do style is
   set at runtime and wins over an XML override of the same element, so you can delete the XML for it.
5. **The waiting-screen texts** (`notificationLabelDefault`, `notificationLabelCountdown`, `notificationLabelTokenFetch`) are not
   `VideoCallConfig` fields any more (neither SDK has such an API). On Android override the three
   `udentify_vc_notification_label_*` strings in your `strings.xml`.
6. **Top and bottom offsets are measured from the call view's edge**, not the safe area, on both platforms: add the
   status-bar inset to a `top` offset as shown above.
7. **Hiding an element** (`visible: false`) works on Android only; the iOS SDK offers no way to hide the picture-in-picture
   view or the buttons.

## 11. Errors

`VideoCallError` has a `type`, the code the native layer sent (`code`), a `message` and optional `details`.
`type` is a `VideoCallErrorType`:

| Type | Meaning |
|---|---|
| `credentialsMissing` | A required credential is missing |
| `serverTimeout`, `transactionNotFound`, `transactionFailed`, `transactionExpired`, `transactionAlreadyCompleted` | The server rejected the transaction |
| `sdkNotAvailable` | The Udentify AARs / frameworks are not integrated |
| `sdk` | An error reported by the SDK itself; read `message` |
| `cameraPermissionRequired`, `cameraPermissionDenied`, `microphonePermissionRequired`, `microphonePermissionDenied` | A permission the SDK needs is missing; prompt or send the user to Settings |
| `unknown` | Anything else: a code the plugin raises itself (see below), or one the enum does not list |

`code` is the code exactly as the native layer sent it, so it is the way to tell apart the failures `type` calls `unknown`:

| `code` | When |
|---|---|
| `NO_ACTIVE_CALL` | `cancelVideoCall()` with no call running |
| `ALREADY_IN_PROGRESS` | `cancelVideoCall()` while another cancel is running (both platforms); `startVideoCall()` while a call is on screen (iOS) |
| `START_VIDEO_CALL_FAILED`, `END_VIDEO_CALL_FAILED`, `CANCEL_VIDEO_CALL_FAILED` | The operation failed or the server refused it; read `message` and `details` |
| `MISSING_PARAMETER` (Android), `MISSING_PARAMETERS` (iOS), `INVALID_ARGUMENTS` | A required argument is missing or malformed; the plugin rejects it before it calls the SDK |
| `NO_ACTIVITY`, `NO_CONTEXT` (Android) | The host activity must be a `FlutterFragmentActivity`, or there is no context |
| `NO_VIEW_CONTROLLER`, `FRAMEWORK_NOT_AVAILABLE` (iOS) | There is no view controller to present from, or the SDK frameworks are not integrated |
| the SDK's own `ERR_*` names | Also in `type` when it is one the enum lists |

```dart
final result = await VideoCallFlutter.cancelVideoCall();
if (!result.success && result.error?.code == 'NO_ACTIVE_CALL') {
  // nothing to cancel
}
```

Operations that fail return a `VideoCallResult` with `success == false` and an `error`; a failed
start returns `status: failed` and the reason rather than looking like a start.

## 12. Platform notes

- **Orientation.** The Android call screen supports portrait only; lock the activity to portrait.
- **Minimums.** Android `minSdk` 21. iOS 13.0.
- **iOS video engine.** The LiveKit Swift SDK is compiled into `UdentifyVC`, so the plugin depends on
  `LiveKitWebRTC 144.7559.03` only. Do not add `LiveKitClient`.
- **Android video engine.** `io.livekit:livekit-android:2.13.0` (declared by the plugin).
- **iOS background audio (optional).** Add `audio` to `UIBackgroundModes` in `Info.plist` if you want the SDK's
  documented background handling: it mutes the microphone and suspends call audio while the app is in the background and
  restores them when it becomes active. Without it iOS may suspend the app when it leaves the screen, which can drop the
  call connection or force a reconnect.
- **LiveKYC and orientation (iOS).** The LiveKYC call and module screens are designed for portrait; include portrait in the
  supported orientations and keep the screens that host the call in portrait.
- **Backgrounding and phone calls.** The SDK mutes and unmutes itself and reports it through
  `setOnMicrophoneStateChanged`; `setOnPhoneCallStateChanged` and `setOnScreenLocked` are for
  information only.
- **Several Flutter engines (add-to-app, background tasks).** The SDKs are process-wide, so one engine drives a capture or call at a time; run the flows from the engine that shows the UI. Another engine registering these plugins, such as a headless engine for a background task, is harmless: it does not reset the styling the app configured or take over the MRZ progress events (both are claimed by the engine that has an activity or starts the scan). Those engines have no activity or screen, so a flow started from one fails with `NO_ACTIVITY` / `NO_VIEW_CONTROLLER`. On iOS the screen goes on the window that holds a `FlutterViewController`, which with two Flutter views on screen at once may not be the caller's.
- **Screen sharing.** `observationMode: screenShare` is beta and untested. On Android 14+ the system
  offers "Share one app" by default.

## 13. Troubleshooting

- **`sdkNotAvailable` or a class-not-found crash on Android:** the AARs must be on the app's
  classpath (see the README's Android setup).
- **Status callbacks never fire:** register them before `startVideoCall`.
- **Permission errors:** check `checkPermissions()` first and use `requestPermissions()`.
- **iOS: "no such module" or duplicate symbols after an upgrade:** remove `LiveKitClient` from the
  Podfile, keep the `https://github.com/livekit/podspecs.git` source, run `pod install`, and clear
  Xcode's `ModuleCache.noindex`.
- **The agent still sees you after the call screen closed:** you used `endVideoCall()`; use
  `cancelVideoCall()`.
- **Hot reload after changing the plugin:** use a full restart.

## 14. API reference

**Methods on `VideoCallFlutter`**: `startVideoCall`, `endVideoCall`, `cancelVideoCall`,
`dismissVideoCall`, `getVideoCallStatus`, `checkPermissions`, `requestPermissions`,
`setMicrophoneEnabled`, `isMicrophoneEnabled`, `setVideoCallConfig`, the `setOn...` setters in
[section 6](#6-event-reference).

**Models**: `VideoCallCredentials`, `VideoCallResult`, `VideoCallError`, `VideoCallPermissionStatus`,
`VideoCallConfig`, `VideoCallParticipantState`, `VideoCallRepeatEndedEvent`,
`VideoCallLiveKYCOptions`.

**Enums**: `VideoCallStatus`, `VideoCallErrorType`, `VideoCallPhoneCallState`,
`VideoCallObservationMode`, `VideoCallRepeatRole` (`ocr`, `face`, `nfc`, `hologram`),
`VideoCallRepeatOutcome`, and the LiveKYC option enums (`VideoCallOCRDocumentType`,
`VideoCallOCRDocumentSide`, `VideoCallFaceMethod`, `VideoCallFaceLivenessMode`,
`VideoCallNFCChipAnticloneMode`).
