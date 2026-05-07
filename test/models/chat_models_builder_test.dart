import 'package:llm_dart/models/chat_models.dart';
import 'package:llm_dart/models/tool_models.dart';
import 'package:test/test.dart';

void main() {
  group('MessageBuilder provider extensions', () {
    test('provider extension can project universal tools into provider blocks',
        () {
      final tool = Tool.function(
        name: 'lookup',
        description: 'Lookup a value',
        parameters: const ParametersSchema(
          schemaType: 'object',
          properties: {},
          required: [],
        ),
      );

      final builder = MessageBuilder.system()
        ..text('System instructions')
        ..tools([tool])
        ..addBlock(const _ProviderMarkerBlock())
        ..addProviderExtension(const _ToolProjectionExtension());

      final message = builder.build();

      expect(message.content, equals('System instructions'));
      expect(message.hasExtension('test-provider'), isTrue);

      final extension =
          message.getExtension<Map<String, dynamic>>('test-provider')!;
      final contentBlocks = extension['contentBlocks'] as List<dynamic>;

      expect(contentBlocks, hasLength(2));
      expect(contentBlocks.first, {'type': 'marker'});
      expect(contentBlocks.last, {
        'type': 'tools',
        'tools': [tool.toJson()],
      });
    });

    test('duplicate provider extension registration uses the latest extension',
        () {
      final builder = MessageBuilder.system()
        ..addBlock(const _ProviderMarkerBlock())
        ..addProviderExtension(const _StaticBlockExtension('first'))
        ..addProviderExtension(const _StaticBlockExtension('second'));

      final message = builder.build();
      final extension =
          message.getExtension<Map<String, dynamic>>('test-provider')!;
      final contentBlocks = extension['contentBlocks'] as List<dynamic>;

      expect(contentBlocks, hasLength(2));
      expect(contentBlocks.last, {'type': 'static', 'value': 'second'});
    });
  });
}

final class _ProviderMarkerBlock implements ContentBlock {
  const _ProviderMarkerBlock();

  @override
  String get displayText => '';

  @override
  String get providerId => 'test-provider';

  @override
  Map<String, dynamic> toJson() => {'type': 'marker'};
}

final class _ToolProjectionExtension extends MessageProviderExtension {
  const _ToolProjectionExtension();

  @override
  String get providerId => 'test-provider';

  @override
  Iterable<ContentBlock> buildContentBlocks(
    MessageProviderExtensionContext context,
  ) {
    return [
      for (final toolsBlock in context.universalBlocksOfType<ToolsBlock>())
        _ProjectedToolsBlock(toolsBlock.tools),
    ];
  }
}

final class _StaticBlockExtension extends MessageProviderExtension {
  final String value;

  const _StaticBlockExtension(this.value);

  @override
  String get providerId => 'test-provider';

  @override
  Object get extensionId => _StaticBlockExtension;

  @override
  Iterable<ContentBlock> buildContentBlocks(
    MessageProviderExtensionContext context,
  ) =>
      [_StaticBlock(value)];
}

final class _ProjectedToolsBlock implements ContentBlock {
  final List<Tool> tools;

  const _ProjectedToolsBlock(this.tools);

  @override
  String get displayText => '';

  @override
  String get providerId => 'test-provider';

  @override
  Map<String, dynamic> toJson() => {
        'type': 'tools',
        'tools': tools.map((tool) => tool.toJson()).toList(),
      };
}

final class _StaticBlock implements ContentBlock {
  final String value;

  const _StaticBlock(this.value);

  @override
  String get displayText => '';

  @override
  String get providerId => 'test-provider';

  @override
  Map<String, dynamic> toJson() => {
        'type': 'static',
        'value': value,
      };
}
