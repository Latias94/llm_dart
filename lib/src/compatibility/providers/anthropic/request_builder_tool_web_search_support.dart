part of 'request_builder.dart';

Map<String, dynamic> _convertAnthropicWebSearchTool(
  AnthropicConfig config,
) {
  final webSearchConfig = config.webSearchConfig;

  final toolDef = <String, dynamic>{
    'type': webSearchConfig?.mode ?? 'web_search_20250305',
    'name': 'web_search',
  };

  if (webSearchConfig != null) {
    if (webSearchConfig.maxUses != null) {
      toolDef['max_uses'] = webSearchConfig.maxUses;
    }
    if (webSearchConfig.allowedDomains != null &&
        webSearchConfig.allowedDomains!.isNotEmpty) {
      toolDef['allowed_domains'] = webSearchConfig.allowedDomains;
    }
    if (webSearchConfig.blockedDomains != null &&
        webSearchConfig.blockedDomains!.isNotEmpty) {
      toolDef['blocked_domains'] = webSearchConfig.blockedDomains;
    }
    if (webSearchConfig.location != null) {
      toolDef['user_location'] = {
        'type': 'approximate',
        'city': webSearchConfig.location!.city,
        'region': webSearchConfig.location!.region,
        'country': webSearchConfig.location!.country,
        if (webSearchConfig.location!.timezone != null)
          'timezone': webSearchConfig.location!.timezone,
      };
    }
  }

  return toolDef;
}
