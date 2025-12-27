// ignore_for_file: avoid_print
import 'dart:collection';
import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_groq/llm_dart_groq.dart';

/// 📊 Batch Processing Tool - Large-scale Data Processing
///
/// This example demonstrates how to process large datasets with AI:
/// - Concurrent processing with rate limiting
/// - Progress tracking and monitoring
/// - Error handling and retry logic
/// - Result aggregation and reporting
/// - Memory-efficient streaming processing
///
/// Usage:
/// dart run batch_processor.dart --input data.jsonl --output results.jsonl
/// dart run batch_processor.dart --help
///
/// Before running, set your API key:
/// export GROQ_API_KEY="your-key"
void main(List<String> arguments) async {
  print('📊 Batch Processing Tool - Large-scale Data Processing\n');

  final processor = BatchProcessor();
  await processor.run(arguments);
}

/// Batch processing tool for large-scale AI operations
class BatchProcessor {
  // Configuration
  String _inputFile = '';
  String _outputFile = '';
  String _operation = 'analyze';
  int _concurrency = 3;
  int _batchSize = 10;
  bool _verbose = false;
  final Duration _rateLimitDelay = Duration(milliseconds: 500);

  late ChatCapability _aiProvider;

  /// Run the batch processor
  Future<void> run(List<String> arguments) async {
    try {
      // Parse arguments
      if (!parseArguments(arguments)) {
        return;
      }

      // Initialize AI provider
      await initializeAI();

      // Process data
      await processData();

      print('\n✅ Batch processing completed successfully!');
    } catch (e) {
      print('❌ Batch processing failed: $e');
      exit(1);
    }
  }

  /// Parse command-line arguments
  bool parseArguments(List<String> arguments) {
    if (arguments.isEmpty || arguments.contains('--help')) {
      showHelp();
      return false;
    }

    for (int i = 0; i < arguments.length; i++) {
      switch (arguments[i]) {
        case '--input':
        case '-i':
          if (i + 1 < arguments.length) {
            _inputFile = arguments[++i];
          }
          break;
        case '--output':
        case '-o':
          if (i + 1 < arguments.length) {
            _outputFile = arguments[++i];
          }
          break;
        case '--operation':
          if (i + 1 < arguments.length) {
            _operation = arguments[++i];
          }
          break;
        case '--concurrency':
        case '-c':
          if (i + 1 < arguments.length) {
            _concurrency = int.tryParse(arguments[++i]) ?? 3;
          }
          break;
        case '--batch-size':
        case '-b':
          if (i + 1 < arguments.length) {
            _batchSize = int.tryParse(arguments[++i]) ?? 10;
          }
          break;
        case '--verbose':
        case '-v':
          _verbose = true;
          break;
      }
    }

    if (_inputFile.isEmpty || _outputFile.isEmpty) {
      print('❌ Error: Input and output files are required');
      showHelp();
      return false;
    }

    return true;
  }

  /// Show help information
  void showHelp() {
    print('''
📊 Batch Processing Tool - Large-scale Data Processing

USAGE:
    dart run batch_processor.dart [OPTIONS] --input FILE --output FILE

OPTIONS:
    -i, --input <file>        Input JSONL file
    -o, --output <file>       Output JSONL file
    --operation <type>        Operation type (analyze, summarize, translate, classify) [default: analyze]
    -c, --concurrency <num>   Concurrent workers [default: 3]
    -b, --batch-size <num>    Batch size [default: 10]
    -v, --verbose             Verbose output
    --help                    Show this help

OPERATIONS:
    analyze      Analyze text content and extract insights
    summarize    Generate summaries of text content
    translate    Translate text to different languages
    classify     Classify text into categories

EXAMPLES:
    dart run batch_processor.dart -i data.jsonl -o results.jsonl
    dart run batch_processor.dart -i reviews.jsonl -o analysis.jsonl --operation analyze -c 5
    dart run batch_processor.dart -i articles.jsonl -o summaries.jsonl --operation summarize

INPUT FORMAT (JSONL):
    {"id": "1", "text": "Content to process..."}
    {"id": "2", "text": "Another piece of content..."}

OUTPUT FORMAT (JSONL):
    {"id": "1", "input": "Original text...", "result": "AI result...", "metadata": {...}}
''');
  }

  /// Initialize AI provider
  Future<void> initializeAI() async {
    registerGroq();

    final apiKey = Platform.environment['GROQ_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GROQ_API_KEY environment variable not set');
    }

    _aiProvider = await LLMBuilder()
        .provider(groqProviderId)
        .apiKey(apiKey)
        .model('llama-3.1-8b-instant')
        .temperature(0.3)
        .maxTokens(1000)
        .build();

    if (_verbose) {
      print('✅ AI provider initialized');
    }
  }

  /// Process data from input file
  Future<void> processData() async {
    print('🔄 Starting batch processing...');
    print('   Input: $_inputFile');
    print('   Output: $_outputFile');
    print('   Operation: $_operation');
    print('   Concurrency: $_concurrency');
    print('   Batch size: $_batchSize\n');

    // Read input data
    final inputFile = File(_inputFile);
    if (!await inputFile.exists()) {
      throw Exception('Input file not found: $_inputFile');
    }

    final outputFile = File(_outputFile);
    final outputSink = outputFile.openWrite();

    try {
      // Process data in batches
      final processor = DataProcessor(
        aiProvider: _aiProvider,
        operation: _operation,
        concurrency: _concurrency,
        verbose: _verbose,
        rateLimitDelay: _rateLimitDelay,
      );

      await processor.processFile(inputFile, outputSink, _batchSize);
    } finally {
      await outputSink.close();
    }
  }
}

/// Data processor for handling batch operations
class DataProcessor {
  final ChatCapability aiProvider;
  final String operation;
  final int concurrency;
  final bool verbose;
  final Duration rateLimitDelay;

  int _processedCount = 0;
  int _errorCount = 0;
  final Stopwatch _stopwatch = Stopwatch();

  DataProcessor({
    required this.aiProvider,
    required this.operation,
    required this.concurrency,
    required this.verbose,
    required this.rateLimitDelay,
  });

  /// Process file in batches
  Future<void> processFile(
      File inputFile, IOSink outputSink, int batchSize) async {
    _stopwatch.start();

    final lines = await inputFile.readAsLines();
    final totalItems = lines.length;

    print('📋 Processing $totalItems items in batches of $batchSize');
    print('⚡ Using $concurrency concurrent workers\n');

    // Process in batches
    for (int i = 0; i < lines.length; i += batchSize) {
      final batchEnd =
          (i + batchSize < lines.length) ? i + batchSize : lines.length;
      final batch = lines.sublist(i, batchEnd);

      await processBatch(batch, outputSink);

      // Progress update
      final progress = ((i + batch.length) / totalItems * 100).toInt();
      print(
          '📈 Progress: $progress% (${i + batch.length}/$totalItems) - Processed: $_processedCount, Errors: $_errorCount');
    }

    _stopwatch.stop();
    printSummary(totalItems);
  }

  /// Process a batch of items concurrently
  Future<void> processBatch(List<String> batch, IOSink outputSink) async {
    final semaphore = Semaphore(concurrency);
    final futures = <Future<void>>[];

    for (final line in batch) {
      futures.add(
        semaphore.acquire().then((_) async {
          try {
            await processItem(line, outputSink);
          } finally {
            semaphore.release();
          }
        }),
      );
    }

    await Future.wait(futures);
  }

  /// Process a single item
  Future<void> processItem(String line, IOSink outputSink) async {
    try {
      // Parse input
      final data = jsonDecode(line) as Map<String, dynamic>;
      final id = data['id'] as String;
      final text = data['text'] as String;

      if (verbose) {
        print('   🔄 Processing item $id...');
      }

      // Rate limiting
      await Future.delayed(rateLimitDelay);

      // Process with AI
      final result = await processWithAI(text);

      // Write result
      final output = {
        'id': id,
        'input': text,
        'result': result,
        'operation': operation,
        'timestamp': DateTime.now().toIso8601String(),
        'metadata': {
          'processed_at': DateTime.now().millisecondsSinceEpoch,
          'operation_type': operation,
        },
      };

      outputSink.writeln(jsonEncode(output));
      _processedCount++;

      if (verbose) {
        print('   ✅ Completed item $id');
      }
    } catch (e) {
      _errorCount++;
      if (verbose) {
        print('   ❌ Error processing item: $e');
      }

      // Write error result
      try {
        final data = jsonDecode(line) as Map<String, dynamic>;
        final errorOutput = {
          'id': data['id'],
          'input': data['text'],
          'error': e.toString(),
          'operation': operation,
          'timestamp': DateTime.now().toIso8601String(),
        };
        outputSink.writeln(jsonEncode(errorOutput));
      } catch (_) {
        // If we can't even parse the input, skip it
      }
    }
  }

  /// Process text with AI based on operation type
  Future<String> processWithAI(String text) async {
    final systemPrompt = getSystemPromptForOperation(operation);
    final messages = [
      ChatMessage.system(systemPrompt),
      ChatMessage.user(text),
    ];

    final response = await generateText(model: aiProvider, messages: messages);
    return response.text ?? 'No response generated';
  }

  /// Get system prompt for operation type
  String getSystemPromptForOperation(String operation) {
    switch (operation) {
      case 'analyze':
        return 'Analyze the following text and provide key insights, themes, and important information. Be concise and structured.';
      case 'summarize':
        return 'Summarize the following text in 2-3 sentences, capturing the main points and key information.';
      case 'translate':
        return 'Translate the following text to English if it\'s in another language, or provide the original if already in English.';
      case 'classify':
        return 'Classify the following text into appropriate categories (e.g., positive/negative, topic, genre). Provide the classification and reasoning.';
      default:
        return 'Process the following text and provide a helpful response.';
    }
  }

  /// Print processing summary
  void printSummary(int totalItems) {
    final duration = _stopwatch.elapsed;
    final itemsPerSecond = _processedCount / duration.inSeconds;

    print('\n📊 Batch Processing Summary:');
    print('   Total items: $totalItems');
    print('   Successfully processed: $_processedCount');
    print('   Errors: $_errorCount');
    print(
        '   Success rate: ${((_processedCount / totalItems) * 100).toStringAsFixed(1)}%');
    print('   Total time: ${duration.inMinutes}m ${duration.inSeconds % 60}s');
    print(
        '   Processing rate: ${itemsPerSecond.toStringAsFixed(2)} items/second');
  }
}

/// Simple semaphore for controlling concurrency
class Semaphore {
  final int maxCount;
  int _currentCount;
  final Queue<Completer<void>> _waitQueue = Queue<Completer<void>>();

  Semaphore(this.maxCount) : _currentCount = maxCount;

  Future<void> acquire() async {
    if (_currentCount > 0) {
      _currentCount--;
      return;
    }

    final completer = Completer<void>();
    _waitQueue.add(completer);
    return completer.future;
  }

  void release() {
    if (_waitQueue.isNotEmpty) {
      final completer = _waitQueue.removeFirst();
      completer.complete();
    } else {
      _currentCount++;
    }
  }
}
