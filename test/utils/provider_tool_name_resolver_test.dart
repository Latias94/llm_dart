import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'package:test/test.dart';

void main() {
  group('resolveProviderToolName', () {
    test('returns raw tool name when no provider tools configured', () {
      expect(
        resolveProviderToolName(
          providerId: 'openai',
          rawToolName: 'web_search',
          providerTools: null,
        ),
        equals('web_search'),
      );
    });

    test('prefers ProviderTool.name when tool id matches exactly', () {
      expect(
        resolveProviderToolName(
          providerId: 'openai',
          rawToolName: 'web_search',
          providerTools: const [
            ProviderTool(id: 'openai.web_search', name: 'search'),
          ],
        ),
        equals('search'),
      );
    });

    test('matches preview tools by prefix (openai.web_search_preview)', () {
      expect(
        resolveProviderToolName(
          providerId: 'openai',
          rawToolName: 'web_search',
          providerTools: const [
            ProviderTool(id: 'openai.web_search_preview', name: 'web_search'),
          ],
        ),
        equals('web_search'),
      );
    });

    test('matches versioned tool ids by underscore prefix', () {
      expect(
        resolveProviderToolName(
          providerId: 'anthropic',
          rawToolName: 'web_search_20250305',
          providerTools: const [
            ProviderTool(
              id: 'anthropic.web_search_20250305',
              name: 'web_search',
            ),
          ],
        ),
        equals('web_search'),
      );
    });
  });
}
