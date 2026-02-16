import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

void main() {
  group('AnthropicProviderTools', () {
    test('webSearch creates ProviderTool with stable id', () {
      final tool = AnthropicProviderTools.webSearch(
        toolType: 'web_search_20250305',
        options: const AnthropicWebSearchToolOptions(maxUses: 2),
      );

      expect(tool.id, equals('anthropic.web_search_20250305'));
      expect(tool.options['max_uses'], equals(2));
      expect(tool.options['enabled'], isTrue);
    });

    test('webFetch creates ProviderTool with stable id', () {
      final tool = AnthropicProviderTools.webFetch(
        toolType: 'web_fetch_20250910',
        options: const AnthropicWebFetchToolOptions(maxContentTokens: 64),
      );

      expect(tool.id, equals('anthropic.web_fetch_20250910'));
      expect(tool.options['max_content_tokens'], equals(64));
      expect(tool.options['enabled'], isTrue);
    });

    test('bash creates ProviderTool with stable id', () {
      final tool = AnthropicProviderTools.bash(toolType: 'bash_20250124');

      expect(tool.id, equals('anthropic.bash_20250124'));
      expect(tool.name, equals('bash'));
      expect(tool.options['enabled'], isTrue);
    });

    test('computer creates ProviderTool with stable id + options', () {
      final tool = AnthropicProviderTools.computer(
        toolType: 'computer_20250124',
        options: const AnthropicComputerToolOptions(
          displayWidthPx: 1920,
          displayHeightPx: 1080,
          displayNumber: 0,
        ),
      );

      expect(tool.id, equals('anthropic.computer_20250124'));
      expect(tool.name, equals('computer'));
      expect(tool.options['display_width_px'], equals(1920));
      expect(tool.options['display_height_px'], equals(1080));
      expect(tool.options['display_number'], equals(0));
      expect(tool.options['enabled'], isTrue);
    });

    test('textEditor picks stable request name based on toolType', () {
      final newer = AnthropicProviderTools.textEditor(
        toolType: 'text_editor_20250728',
      );
      expect(newer.id, equals('anthropic.text_editor_20250728'));
      expect(newer.name, equals('str_replace_based_edit_tool'));

      final older = AnthropicProviderTools.textEditor(
        toolType: 'text_editor_20250124',
      );
      expect(older.id, equals('anthropic.text_editor_20250124'));
      expect(older.name, equals('str_replace_editor'));
    });
  });
}
