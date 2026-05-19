import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_image_options.dart';
import 'google_model_settings.dart';

GoogleImageModelSettings resolveGoogleImageModelSettings(
  ProviderModelOptions settings,
) {
  return resolveProviderModelOptions<GoogleImageModelSettings>(
    settings,
    parameterName: 'settings',
    expectedTypeName: 'GoogleImageModelSettings',
    usageContext: 'Google image models',
  );
}

GoogleImageOptions? resolveGoogleImageProviderOptions(
  CallOptions callOptions,
) {
  return resolveProviderInvocationOptions<GoogleImageOptions>(
    callOptions.providerOptions,
    parameterName: 'request.callOptions.providerOptions',
    expectedTypeName: 'GoogleImageOptions',
    usageContext: 'Google image models',
  );
}
