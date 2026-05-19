import 'google_options.dart';

List<GoogleSafetySetting> resolveGoogleImageSafetySettings({
  required GoogleImageOptions? options,
  required GoogleImageModelSettings settings,
}) {
  return options?.safetySettings ?? settings.safetySettings;
}
