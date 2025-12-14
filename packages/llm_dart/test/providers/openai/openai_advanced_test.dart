import 'dart:typed_data';

import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai;
import 'package:test/test.dart';

void main() {
  group('OpenAI Advanced Features Tests', () {
    late openai.OpenAIProvider provider;

    setUp(() {
      provider = openai.OpenAIProvider(
        openai.OpenAIConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.openai.com/v1',
        ),
      );
    });

    group('File Models Tests', () {
      test('FilePurpose enum should work correctly', () {
        expect(FilePurpose.assistants.value, equals('assistants'));
        expect(FilePurpose.fineTune.value, equals('fine-tune'));
        expect(FilePurpose.vision.value, equals('vision'));
        expect(FilePurpose.batch.value, equals('batch'));
        expect(FilePurpose.userData.value, equals('user_data'));

        expect(FilePurpose.fromString('assistants'),
            equals(FilePurpose.assistants));
        expect(
            FilePurpose.fromString('fine-tune'), equals(FilePurpose.fineTune));
      });

      test('FileStatus enum should work correctly', () {
        expect(FileStatus.uploaded.value, equals('uploaded'));
        expect(FileStatus.processed.value, equals('processed'));
        expect(FileStatus.error.value, equals('error'));

        expect(FileStatus.fromString('uploaded'), equals(FileStatus.uploaded));
        expect(
            FileStatus.fromString('processed'), equals(FileStatus.processed));
      });

      test('FileObject should serialize/deserialize correctly', () {
        final file = FileObject(
          id: 'file-123',
          sizeBytes: 1024,
          createdAt: DateTime.fromMillisecondsSinceEpoch(1234567890 * 1000),
          filename: 'test.txt',
          purpose: FilePurpose.assistants,
          status: FileStatus.uploaded,
          statusDetails: 'File uploaded successfully',
        );

        final json = file.toOpenAIJson();
        expect(json['id'], equals('file-123'));
        expect(json['bytes'], equals(1024));
        expect(json['purpose'], equals('assistants'));
        expect(json['status'], equals('uploaded'));

        final fromJson = FileObject.fromOpenAI(json);
        expect(fromJson.id, equals(file.id));
        expect(fromJson.sizeBytes, equals(file.sizeBytes));
        expect(fromJson.purpose, equals(file.purpose));
        expect(fromJson.status, equals(file.status));
      });

      test('FileUploadRequest should work correctly', () {
        final fileData = Uint8List.fromList([1, 2, 3, 4, 5]);
        final request = FileUploadRequest(
          file: fileData,
          filename: 'test.txt',
          purpose: FilePurpose.assistants,
        );

        final json = request.toOpenAIJson();
        expect(json['filename'], equals('test.txt'));
        expect(json['purpose'], equals('assistants'));
      });
    });

    group('Moderation Models Tests', () {
      test('ModerationRequest should serialize correctly', () {
        final request = ModerationRequest(
          input: 'Test content',
          model: 'text-moderation-latest',
        );

        final json = request.toJson();
        expect(json['input'], equals('Test content'));
        expect(json['model'], equals('text-moderation-latest'));
      });

      test('ModerationCategories should work correctly', () {
        final categories = ModerationCategories(
          hate: false,
          hateThreatening: false,
          harassment: false,
          harassmentThreatening: false,
          selfHarm: false,
          selfHarmIntent: false,
          selfHarmInstructions: false,
          sexual: false,
          sexualMinors: false,
          violence: false,
          violenceGraphic: false,
        );

        final json = categories.toJson();
        expect(json['hate'], equals(false));
        expect(json['hate/threatening'], equals(false));
        expect(json['harassment'], equals(false));

        final fromJson = ModerationCategories.fromJson(json);
        expect(fromJson.hate, equals(categories.hate));
        expect(fromJson.harassment, equals(categories.harassment));
      });
    });

    group('Assistant Models Tests', () {
      test('AssistantToolType enum should work correctly', () {
        expect(AssistantToolType.codeInterpreter.value,
            equals('code_interpreter'));
        expect(AssistantToolType.fileSearch.value, equals('file_search'));
        expect(AssistantToolType.function.value, equals('function'));

        expect(
          AssistantToolType.fromString('code_interpreter'),
          equals(AssistantToolType.codeInterpreter),
        );
        expect(
          AssistantToolType.fromString('file_search'),
          equals(AssistantToolType.fileSearch),
        );
      });

      test('CodeInterpreterTool should serialize correctly', () {
        const tool = CodeInterpreterTool();
        final json = tool.toJson();
        expect(json['type'], equals('code_interpreter'));
      });

      test('FileSearchTool should serialize correctly', () {
        const tool = FileSearchTool(maxNumResults: 10);
        final json = tool.toJson();
        expect(json['type'], equals('file_search'));
        expect(json['file_search']['max_num_results'], equals(10));
      });

      test('CreateAssistantRequest should serialize correctly', () {
        final request = CreateAssistantRequest(
          model: 'gpt-4',
          name: 'Test Assistant',
          description: 'A test assistant',
          instructions: 'You are a helpful assistant',
          tools: [const CodeInterpreterTool()],
          metadata: {'test': 'value'},
        );

        final json = request.toJson();
        expect(json['model'], equals('gpt-4'));
        expect(json['name'], equals('Test Assistant'));
        expect(json['description'], equals('A test assistant'));
        expect(json['instructions'], equals('You are a helpful assistant'));
        expect(json['tools'], hasLength(1));
        expect(json['metadata'], equals({'test': 'value'}));
      });
    });

    group('Provider Capabilities Tests', () {
      test('OpenAI provider should support all expected capabilities', () {
        final capabilities = provider.supportedCapabilities;

        expect(capabilities.contains(LLMCapability.chat), isTrue);
        expect(capabilities.contains(LLMCapability.embedding), isTrue);
        expect(capabilities.contains(LLMCapability.textToSpeech), isTrue);
        expect(capabilities.contains(LLMCapability.speechToText), isTrue);
        expect(capabilities.contains(LLMCapability.modelListing), isTrue);
        expect(capabilities.contains(LLMCapability.imageGeneration), isTrue);
        expect(capabilities.contains(LLMCapability.fileManagement), isTrue);
        expect(capabilities.contains(LLMCapability.moderation), isTrue);
        expect(capabilities.contains(LLMCapability.assistants), isTrue);
      });

      test('Provider should implement capability interfaces', () {
        // Test that provider supports the capabilities through the supports method
        expect(provider.supports(LLMCapability.fileManagement), isTrue);
        expect(provider.supports(LLMCapability.moderation), isTrue);
        expect(provider.supports(LLMCapability.assistants), isTrue);

        // Test interface implementations
        expect(provider, isA<FileManagementCapability>());
        expect(provider, isA<ModerationCapability>());
        expect(provider, isA<AssistantCapability>());
        expect(provider, isA<ProviderCapabilities>());
      });
    });
  });
}
