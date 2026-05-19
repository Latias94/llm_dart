import 'google_image_options.dart';
import 'google_model_settings.dart';
import 'google_safety_settings.dart';

List<GoogleSafetySetting> resolveGoogleImageSafetySettings({
  required GoogleImageOptions? options,
  required GoogleImageModelSettings settings,
}) {
  return options?.safetySettings ?? settings.safetySettings;
}
