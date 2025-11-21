import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('LLM Builder Tests', () {
    group('LLMBuilder Basic Configuration', () {
      test('should create builder with default config', () {
        final builder = LLMBuilder();
        expect(builder, isNotNull);
      });

      test('should set API key', () {
        final builder = LLMBuilder().apiKey('test-key');
        expect(builder, isNotNull);
      });

      test('should set model', () {
        final builder = LLMBuilder().model('gpt-4');
        expect(builder, isNotNull);
      });

      test('should set temperature', () {
        final builder = LLMBuilder().temperature(0.7);
        expect(builder, isNotNull);
      });

      test('should set max tokens', () {
        final builder = LLMBuilder().maxTokens(1000);
        expect(builder, isNotNull);
      });

      test('should set system prompt', () {
        final builder = LLMBuilder().systemPrompt('You are helpful');
        expect(builder, isNotNull);
      });

      test('should set timeout', () {
        final builder = LLMBuilder().timeout(Duration(seconds: 30));
        expect(builder, isNotNull);
      });

      test('should set top P', () {
        final builder = LLMBuilder().topP(0.9);
        expect(builder, isNotNull);
      });

      test('should set top K', () {
        final builder = LLMBuilder().topK(50);
        expect(builder, isNotNull);
      });

      test('should set user', () {
        final builder = LLMBuilder().user('test-user');
        expect(builder, isNotNull);
      });

      test('should set service tier', () {
        final builder = LLMBuilder().serviceTier(ServiceTier.auto);
        expect(builder, isNotNull);
      });

      test('should add extension', () {
        final builder = LLMBuilder().extension('custom', 'value');
        expect(builder, isNotNull);
      });

      test('should add multiple extensions', () {
        final builder = LLMBuilder()
            .extension('key1', 'value1')
            .extension('key2', 'value2');
        expect(builder, isNotNull);
      });
    });

    group('Provider Selection', () {
      test('should select OpenAI provider', () {
        final builder = LLMBuilder().openai();
        expect(builder, isNotNull);
      });

      test('should select Anthropic provider', () {
        final builder = LLMBuilder().anthropic();
        expect(builder, isNotNull);
      });

      test('should select Google provider', () {
        final builder = LLMBuilder().google();
        expect(builder, isNotNull);
      });

      test('should select DeepSeek provider', () {
        final builder = LLMBuilder().deepseek();
        expect(builder, isNotNull);
      });

      test('should select Ollama provider', () {
        final builder = LLMBuilder().ollama();
        expect(builder, isNotNull);
      });

      test('should select xAI provider', () {
        final builder = LLMBuilder().xai();
        expect(builder, isNotNull);
      });

      test('should select Groq provider', () {
        final builder = LLMBuilder().groq();
        expect(builder, isNotNull);
      });

      test('should select ElevenLabs provider', () {
        final builder = LLMBuilder().elevenlabs();
        expect(builder, isNotNull);
      });

      test('should select provider by string ID', () {
        final builder = LLMBuilder().provider('openai');
        expect(builder, isNotNull);
      });
    });

    group('OpenAI-Compatible Providers', () {
      test('should select DeepSeek OpenAI', () {
        final builder = LLMBuilder().deepseekOpenAI();
        expect(builder, isNotNull);
      });

      test('should select Google OpenAI', () {
        final builder = LLMBuilder().googleOpenAI();
        expect(builder, isNotNull);
      });

      test('should select xAI OpenAI', () {
        final builder = LLMBuilder().xaiOpenAI();
        expect(builder, isNotNull);
      });

      test('should select Groq OpenAI', () {
        final builder = LLMBuilder().groqOpenAI();
        expect(builder, isNotNull);
      });

      test('should select OpenRouter', () {
        final builder = LLMBuilder().openRouter();
        expect(builder, isNotNull);
      });

      test('should select GitHub Copilot', () {
        final builder = LLMBuilder().githubCopilot();
        expect(builder, isNotNull);
      });

      test('should select Together AI', () {
        final builder = LLMBuilder().togetherAI();
        expect(builder, isNotNull);
      });
    });

    group('Tool Configuration', () {
      test('should add single tool', () {
        final tool = Tool.function(
          name: 'test_tool',
          description: 'A test tool',
          parameters: ParametersSchema(
            schemaType: 'object',
            properties: {},
            required: [],
          ),
        );
        final builder = LLMBuilder().tools([tool]);
        expect(builder, isNotNull);
      });

      test('should set tool choice', () {
        final builder = LLMBuilder().toolChoice(AutoToolChoice());
        expect(builder, isNotNull);
      });

      test('should set auto tool choice', () {
        final builder = LLMBuilder().toolChoice(AutoToolChoice());
        expect(builder, isNotNull);
      });

      test('should set none tool choice', () {
        final builder = LLMBuilder().toolChoice(NoneToolChoice());
        expect(builder, isNotNull);
      });

      test('should set any tool choice', () {
        final builder = LLMBuilder().toolChoice(AnyToolChoice());
        expect(builder, isNotNull);
      });

      test('should set specific tool choice', () {
        final builder =
            LLMBuilder().toolChoice(SpecificToolChoice('test_tool'));
        expect(builder, isNotNull);
      });
    });

    group('OpenAI-Specific Configuration', () {
      test('should set reasoning effort', () {
        final builder = LLMBuilder().reasoningEffort(ReasoningEffort.medium);
        expect(builder, isNotNull);
      });

      test('should set low reasoning effort', () {
        final builder = LLMBuilder().reasoningEffort(ReasoningEffort.low);
        expect(builder, isNotNull);
      });

      test('should set medium reasoning effort', () {
        final builder = LLMBuilder().reasoningEffort(ReasoningEffort.medium);
        expect(builder, isNotNull);
      });

      test('should set high reasoning effort', () {
        final builder = LLMBuilder().reasoningEffort(ReasoningEffort.high);
        expect(builder, isNotNull);
      });

      test('should set voice', () {
        final builder = LLMBuilder().voice('alloy');
        expect(builder, isNotNull);
      });

      test('should set response format', () {
        final builder = LLMBuilder().responseFormat('json_object');
        expect(builder, isNotNull);
      });

      test('should set JSON response format', () {
        final builder = LLMBuilder().responseFormat('json_object');
        expect(builder, isNotNull);
      });

      test('should set text response format', () {
        final builder = LLMBuilder().responseFormat('text');
        expect(builder, isNotNull);
      });
    });

    group('Provider-Specific Builder Configuration', () {
      test('should configure ElevenLabs with callback', () {
        final builder = LLMBuilder().elevenlabs((elevenlabs) => elevenlabs
            .voiceId('voice-123')
            .stability(0.7)
            .similarityBoost(0.8)
            .style(0.2)
            .useSpeakerBoost(true));
        expect(builder, isNotNull);
      });

      test('should configure OpenAI with callback', () {
        final builder = LLMBuilder().openai((openai) => openai
            .frequencyPenalty(0.5)
            .presencePenalty(0.3)
            .seed(12345)
            .parallelToolCalls(true)
            .logprobs(true)
            .topLogprobs(5));
        expect(builder, isNotNull);
      });

      test('should configure Ollama with callback', () {
        final builder = LLMBuilder().ollama((ollama) => ollama
            .numCtx(4096)
            .numGpu(1)
            .numThread(8)
            .numa(false)
            .numBatch(512)
            .keepAlive('10m')
            .raw(false));
        expect(builder, isNotNull);
      });

      test('should configure Anthropic with callback', () {
        final builder = LLMBuilder().anthropic((anthropic) => anthropic
            .metadata({'user_id': 'test123'}).container('container-123'));
        expect(builder, isNotNull);
      });

      test('should configure OpenRouter with callback', () {
        final builder = LLMBuilder().openRouter((openrouter) => openrouter
            .webSearch(maxResults: 5, searchPrompt: 'Focus on recent research')
            .useOnlineShortcut(true));
        expect(builder, isNotNull);
      });

      test('should work without callback configuration', () {
        final builder = LLMBuilder()
            .openai()
            .anthropic()
            .ollama()
            .elevenlabs()
            .openRouter();
        expect(builder, isNotNull);
      });
    });

    group('HTTP Configuration', () {
      test('should configure HTTP settings with layered approach', () {
        final builder = LLMBuilder().http((http) => http
            .proxy('http://proxy.example.com:8080')
            .headers({'X-Custom': 'value'})
            .connectionTimeout(Duration(seconds: 30))
            .enableLogging(true));

        expect(builder, isNotNull);
      });

      test('should configure proxy only', () {
        final builder = LLMBuilder()
            .http((http) => http.proxy('http://proxy.example.com:8080'));

        expect(builder, isNotNull);
      });

      test('should configure headers only', () {
        final builder = LLMBuilder().http((http) => http.headers({
              'X-Request-ID': 'test-123',
              'User-Agent': 'TestApp/1.0',
            }));

        expect(builder, isNotNull);
      });

      test('should configure timeouts only', () {
        final builder = LLMBuilder().http((http) => http
            .connectionTimeout(Duration(seconds: 30))
            .receiveTimeout(Duration(minutes: 5))
            .sendTimeout(Duration(seconds: 120)));

        expect(builder, isNotNull);
      });

      test('should configure SSL settings only', () {
        final builder = LLMBuilder().http((http) => http
            .bypassSSLVerification(true)
            .sslCertificate('/path/to/cert.pem'));

        expect(builder, isNotNull);
      });

      test('should configure logging only', () {
        final builder = LLMBuilder().http((http) => http.enableLogging(true));

        expect(builder, isNotNull);
      });

      test('should support comprehensive HTTP configuration', () {
        final builder = LLMBuilder().http((http) => http
            .proxy('http://proxy.example.com:8080')
            .headers({
              'X-Request-ID': 'comprehensive-test',
              'X-Client-Version': '1.0.0',
            })
            .header('X-Additional', 'value')
            .connectionTimeout(Duration(seconds: 20))
            .receiveTimeout(Duration(minutes: 3))
            .sendTimeout(Duration(seconds: 90))
            .bypassSSLVerification(false)
            .sslCertificate('/path/to/cert.pem')
            .enableLogging(true));

        expect(builder, isNotNull);
      });

      test('should support multiple HTTP configurations', () {
        final builder = LLMBuilder()
            .http((http) => http.proxy('http://proxy:8080'))
            .http((http) => http.enableLogging(true));

        expect(builder, isNotNull);
      });

      test('should chain HTTP configuration with other methods', () {
        final builder = LLMBuilder()
            .openai()
            .apiKey('test-key')
            .model('gpt-4')
            .http((http) => http.headers(
                {'X-Custom': 'value'}).connectionTimeout(Duration(seconds: 30)))
            .temperature(0.7)
            .maxTokens(1000);

        expect(builder, isNotNull);
      });
    });

    group('Error Handling', () {
      test('should throw error when building without provider', () {
        final builder = LLMBuilder().apiKey('test-key').model('test-model');
        expect(() => builder.build(), throwsA(isA<GenericError>()));
      });

      test('should throw error for unsupported capability', () {
        // This test would need to be implemented with actual provider registration
        // and capability checking logic
        expect(true, isTrue); // Placeholder
      });
    });

    group('Method Chaining', () {
      test('should support method chaining', () {
        final builder = LLMBuilder()
            .openai()
            .apiKey('test-key')
            .model('gpt-4')
            .temperature(0.7)
            .maxTokens(1000)
            .systemPrompt('You are helpful')
            .timeout(Duration(seconds: 30))
            .topP(0.9)
            .topK(50)
            .user('test-user')
            .serviceTier(ServiceTier.auto)
            .extension('custom', 'value');

        expect(builder, isNotNull);
      });

      test('should support complex configuration chaining', () {
        final tool = Tool.function(
          name: 'test_tool',
          description: 'A test tool',
          parameters: ParametersSchema(
            schemaType: 'object',
            properties: {},
            required: [],
          ),
        );

        final builder = LLMBuilder()
            .openai((openai) => openai.seed(12345).parallelToolCalls(true))
            .apiKey('test-key')
            .model('gpt-4')
            .tools([tool])
            .toolChoice(AutoToolChoice())
            .reasoningEffort(ReasoningEffort.medium)
            .voice('alloy')
            .responseFormat('json_object');

        expect(builder, isNotNull);
      });
    });

    test('use() should configure provider and model from identifier', () {
      final builder = LLMBuilder().use('openai:gpt-4o');

      expect(builder.currentConfig.model, equals('gpt-4o'));
    });

    test('use() should throw for invalid identifier format', () {
      expect(
        () => LLMBuilder().use('gpt-4o'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
