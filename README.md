# Dialer App

A full-featured Flutter replacement dialer for Android with PIN protection for selected contacts.

## Features

- **Full dialpad** — tap to dial any number with letter sub-labels
- **Recents** — full call history with call type icons (missed, incoming, outgoing)
- **Contacts** — alphabetical list with search, grouped by letter
- **Contact detail** — tap a contact to see all numbers, call directly, or toggle PIN lock per number
- **In-call screen** — mute, speaker, hold, DTMF keypad, hang up, call timer
- **PIN protection** — any number can be PIN-locked; entering it from the dialer, recents, or contacts will prompt for PIN first
- **Settings** — set/change/remove PIN, manage protected numbers list, set app as default dialer
- **Default dialer** — registers with Android Telecom so it can be set as the system default phone app

## How to set as default dialer

1. Install the APK
2. Open the app — it will prompt you to set it as default
3. Or go to **Settings → Default dialer → Set default**
4. Android will show a system dialog — choose **Dialer** and confirm

Once set as default, all outgoing calls from the native phone icon on your home screen will open this app's dialpad, where PIN checks happen before the call is placed.

## PIN-protecting a number

1. Go to **Settings → Set PIN** and create your PIN
2. Open any contact → tap the 🔓 icon next to a phone number to protect it
3. From now on, dialing that number from anywhere in the app shows a PIN prompt

## Building

### Locally
```bash
flutter pub get
flutter build apk --debug   # quick test
flutter build apk --release # production
```

APK output: `build/app/outputs/flutter-apk/`

### GitHub Actions
Push to `main` or trigger **Build APK** manually from the Actions tab.
Download `dialer-debug` or `dialer-release` from the Artifacts section.

## Android requirements

- Minimum SDK: 26 (Android 8.0) — required for `InCallService` API
- Target SDK: 34
- Permissions required: `CALL_PHONE`, `READ_CONTACTS`, `READ_CALL_LOG`, `WRITE_CALL_LOG`, `MANAGE_OWN_CALLS`, `MODIFY_AUDIO_SETTINGS`, `READ_PHONE_STATE`

## Project structure

```
lib/
  main.dart
  providers/
    pin_provider.dart          # PIN hash + protected numbers list
    contacts_provider.dart     # flutter_contacts wrapper
    call_log_provider.dart     # call_log wrapper
  screens/
    main_screen.dart           # bottom nav shell
    dialpad_screen.dart        # keypad + call button
    recents_screen.dart        # call history
    contacts_screen.dart       # contact list + search
    contact_detail_screen.dart # numbers, email, lock toggle
    in_call_screen.dart        # mute/speaker/hold/DTMF/hang-up
    settings_screen.dart       # PIN + default dialer management
  services/
    call_service.dart          # MethodChannel bridge to Android Telecom
  widgets/
    pin_entry_dialog.dart      # reusable PIN prompt

android/app/src/main/kotlin/com/example/dialer_app/
  MainActivity.kt             # MethodChannel handler + placeCall
  DialerInCallService.kt      # InCallService to receive/control calls
```
