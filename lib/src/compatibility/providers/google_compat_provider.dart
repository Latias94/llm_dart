import 'package:llm_dart_google/llm_dart_google.dart' as modern_google;

import '../../../core/capability.dart';
import '../../../core/config.dart';
import '../../../core/web_search.dart';
import '../../../models/chat_models.dart';
import '../../../models/tool_models.dart';
import '../../../providers/google/config.dart';
import '../chat_route_compatibility.dart';
import '../compat_transport.dart';
import '../legacy_chat_adapter.dart';
import 'compat_provider_support.dart';
import 'google_config_adapter.dart';
import 'google/provider_compat.dart';

ChatCapability buildCompatGoogleProvider(LLMConfig config) {
  final legacyConfig = createLegacyGoogleConfig(config);
  final model = modern_google.Google(
    apiKey: config.apiKey!,
    baseUrl: config.baseUrl,
    transport: createCompatTransport(config),
  ).chatModel(config.model);

  return CompatGoogleProvider(
    originalConfig: config,
    legacyConfig: legacyConfig,
    adapter: GoogleLegacyChatCapabilityAdapter(
      model: model,
      config: config,
      providerOptions: modern_google.GoogleGenerateTextOptions(
        candidateCount: legacyConfig.candidateCount,
        thinkingBudgetTokens: legacyConfig.thinkingBudgetTokens,
        thinkingLevel: _mapGoogleThinkingLevel(legacyConfig.reasoningEffort),
        includeThoughts: legacyConfig.includeThoughts,
        responseModalities: _mapGoogleResponseModalities(legacyConfig),
        safetySettings: _mapGoogleSafetySettings(
          legacyConfig.safetySettings,
        ),
        tools: _buildGoogleNativeTools(legacyConfig),
      ),
    ),
  );
}

final class CompatGoogleProvider extends GoogleProvider {
  final LLMConfig _originalConfig;
  final LegacyChatCapabilityAdapter _adapter;

  CompatGoogleProvider({
    required LLMConfig originalConfig,
    required GoogleConfig legacyConfig,
    required LegacyChatCapabilityAdapter adapter,
  })  : _originalConfig = originalConfig,
        _adapter = adapter,
        super(legacyConfig);

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    TransportCancellation? cancelToken,
  }) {
    return chatWithTools(messages, null, cancelToken: cancelToken);
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    TransportCancellation? cancelToken,
  }) {
    return executeCompatChat(
      originalConfig: _originalConfig,
      messages: messages,
      tools: tools,
      canUseBridge: canUseGoogleChatBridge,
      bridge: () => _adapter.chatWithTools(
        messages,
        tools,
        cancelToken: cancelToken,
      ),
      fallback: () => super.chatWithTools(
        messages,
        tools,
        cancelToken: cancelToken,
      ),
    );
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    TransportCancellation? cancelToken,
  }) {
    return executeCompatChatStream(
      originalConfig: _originalConfig,
      messages: messages,
      tools: tools,
      canUseBridge: canUseGoogleChatBridge,
      bridge: () => _adapter.chatStream(
        messages,
        tools: tools,
        cancelToken: cancelToken,
      ),
      fallback: () => super.chatStream(
        messages,
        tools: tools,
        cancelToken: cancelToken,
      ),
    );
  }
}

modern_google.GoogleThinkingLevel? _mapGoogleThinkingLevel(
  ReasoningEffort? effort,
) {
  return switch (effort) {
    ReasoningEffort.minimal => modern_google.GoogleThinkingLevel.minimal,
    ReasoningEffort.low => modern_google.GoogleThinkingLevel.low,
    ReasoningEffort.medium => modern_google.GoogleThinkingLevel.medium,
    ReasoningEffort.high => modern_google.GoogleThinkingLevel.high,
    _ => null,
  };
}

List<modern_google.GoogleResponseModality>? _mapGoogleResponseModalities(
  GoogleConfig config,
) {
  final rawValues = config.responseModalities;
  final mapped = <modern_google.GoogleResponseModality>[];

  if (rawValues != null) {
    for (final rawValue in rawValues) {
      switch (rawValue.toString().toUpperCase()) {
        case 'TEXT':
          mapped.add(modern_google.GoogleResponseModality.text);
          break;
        case 'IMAGE':
          mapped.add(modern_google.GoogleResponseModality.image);
          break;
        default:
          break;
      }
    }
  } else if (config.enableImageGeneration == true) {
    mapped.addAll(const [
      modern_google.GoogleResponseModality.text,
      modern_google.GoogleResponseModality.image,
    ]);
  }

  return mapped.isEmpty ? null : mapped;
}

List<modern_google.GoogleSafetySetting>? _mapGoogleSafetySettings(
  List<SafetySetting>? settings,
) {
  if (settings == null || settings.isEmpty) {
    return null;
  }

  return settings
      .map(
        (setting) => modern_google.GoogleSafetySetting(
          category: modern_google.GoogleHarmCategory.values.firstWhere(
            (value) => value.value == setting.category.value,
            orElse: () => modern_google.GoogleHarmCategory.unspecified,
          ),
          threshold: modern_google.GoogleHarmBlockThreshold.values.firstWhere(
            (value) => value.value == setting.threshold.value,
            orElse: () => modern_google.GoogleHarmBlockThreshold.unspecified,
          ),
        ),
      )
      .toList(growable: false);
}

List<modern_google.GoogleNativeTool>? _buildGoogleNativeTools(
  GoogleConfig config,
) {
  if (!config.webSearchEnabled) {
    return null;
  }

  final timeRangeFilter = _buildGoogleTimeRangeFilter(config.webSearchConfig);

  return [
    modern_google.GoogleTools.googleSearch(
      timeRangeFilter: timeRangeFilter,
    ),
  ];
}

modern_google.GoogleTimeRangeFilter? _buildGoogleTimeRangeFilter(
  WebSearchConfig? config,
) {
  if (config == null || config.fromDate == null || config.toDate == null) {
    return null;
  }

  final startTime = DateTime.tryParse(config.fromDate!);
  final endTime = DateTime.tryParse(config.toDate!);
  if (startTime == null || endTime == null) {
    return null;
  }

  return modern_google.GoogleTimeRangeFilter(
    startTime: startTime,
    endTime: endTime,
  );
}
