// ignore_for_file: constant_identifier_names
//
// Lokale Unity-Ads-Fallbacks fuer Debug- und Release-Builds.
//
// Prioritaet:
// 1) `--dart-define`
// 2) diese lokale Datei
//
// So kann lokal auch ein normales `flutter run` oder `flutter build`
// funktionieren, ohne dass Startparameter vergessen werden.
//
// Nutzung:
// - Trage unten eure echten Unity-Werte ein.
// - Leere Strings bedeuten: kein lokaler Fallback vorhanden.
// - Wenn ein `--dart-define` gesetzt ist, ueberschreibt es den lokalen Wert.
//
// Typische lokale Befehle:
// - `flutter run -d android`
// - `flutter run -d ios`
// - `flutter build appbundle`
// - `flutter build ipa`

// Android Debug
const String UNITY_ADS_LOCAL_ANDROID_GAME_ID_DEBUG = '6076109';
const String UNITY_ADS_LOCAL_ANDROID_INTERSTITIAL_PLACEMENT_ID_DEBUG =
    'Interstitial_Android';

// Android Release
const String UNITY_ADS_LOCAL_ANDROID_GAME_ID_RELEASE = '6076109';
const String UNITY_ADS_LOCAL_ANDROID_INTERSTITIAL_PLACEMENT_ID_RELEASE =
    'Interstitial_Android';

// iOS Debug
const String UNITY_ADS_LOCAL_IOS_GAME_ID_DEBUG = '6076108';
const String UNITY_ADS_LOCAL_IOS_INTERSTITIAL_PLACEMENT_ID_DEBUG =
    'Interstitial_iOS';

// iOS Release
const String UNITY_ADS_LOCAL_IOS_GAME_ID_RELEASE = '6076108';
const String UNITY_ADS_LOCAL_IOS_INTERSTITIAL_PLACEMENT_ID_RELEASE =
    'Interstitial_iOS';
