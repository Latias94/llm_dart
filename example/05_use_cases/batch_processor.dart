// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;

/// Batch processing example using the stable model API.
Future<void> main(List<String> arguments) async {
  print('📊 Batch Processing Tool - Large-scale Data Processing\n');

  final processor = BatchProcessor();
  await processor.run(arguments);
}

class BatchProcessor {
  String _inputFile = '';
  String _outputFile = '';
  String _operation = 'analyze';
  int _concurrency = 3;
  int _batchSize = 10;
  bool _verbose = false;
  final Duration _rateLimitDelay = const Duration(milliseconds: 500);

  late core.LanguageModel _model;

  Future<void> run(List<String> arguments) async {
    try {
      if (!parseArguments(arguments)) {
        return;
      }

      initializeAI();
      await processData();

      print('\n✅ Batch processing completed successfully!');
    } catch (error) {
      print('❌ Batch processing failed: $error');
      exit(1);
    }
  }

  bool parseArguments(List<String> arguments) {
    if (arguments.isEmpty || arguments.contains('--help')) {
      showHelp();
      return false;
    }

    for (var i = 0; i < arguments.length; i++) {
      switch (arguments[i]) {
        case '--input':
        case '-i':
          if (i + 1 < arguments.length) {
            _inputFile = arguments[++i];
          }
        case '--output':
        case '-o':
          if (i + 1 < arguments.length) {
            _outputFile = arguments[++i];
          }
        case '--operation':
          if (i + 1 < arguments.length) {
            _operation = arguments[++i];
          }
        case '--concurrency':
        case '-c':
          if (i + 1 < arguments.length) {
            _concurrency = int.tryParse(arguments[++i]) ?? 3;
          }
        case '--batch-size':
        case '-b':
          if (i + 1 < arguments.length) {
            _batchSize = int.tryParse(arguments[++i]) ?? 10;
          }
        case '--verbose':
        case '-v':
          _verbose = true;
      }
    }

    if (_inputFile.isEmpty || _outputFile.isEmpty) {
      print('❌ Error: Input and output files are required');
      showHelp();
      return false;
    }

    return true;
  }

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

  void initializeAI() {
    final groqKey = Platform.environment['GROQ_API_KEY'];
    if (groqKey == null || groqKey.isEmpty) {
      throw StateError('GROQ_API_KEY environment variable not set');
    }

    _model = llm.AI.groq(
      apiKey: groqKey,
    ).chatModel('llama-3.3-70b-versatile');

    if (_verbose) {
      print('✅ AI model initialized (${_model.providerId}/${_model.modelId})');
    }
  }

  Future<void> processData() async {
    print('🔄 Starting batch processing...');
    print('   Input: $_inputFile');
    print('   Output: $_outputFile');
    print('   Operation: $_operation');
    print('   Concurrency: $_concurrency');
    print('   Batch size: $_batchSize\n');

    final inputFile = File(_inputFile);
    if (!await inputFile.exists()) {
      throw Exception('Input file not found: $_inputFile');
    }

    final outputFile = File(_outputFile);
    final outputSink = outputFile.openWrite();

    try {
      final processor = DataProcessor(
        model: _model,
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

class DataProcessor {
  final core.LanguageModel model;
  final String operation;
  final int concurrency;
  final bool verbose;
  final Duration rateLimitDelay;

  int _processedCount = 0;
  int _errorCount = 0;
  final Stopwatch _stopwatch = Stopwatch();

  DataProcessor({
    required this.model,
    required this.operation,
    required this.concurrency,
    required this.verbose,
    required this.rateLimitDelay,
  });

  Future<void> processFile(
    File inputFile,
    IOSink outputSink,
    int batchSize,
  ) async {
    _stopwatch.start();

    final lines = await inputFile.readAsLines();
    final totalItems = lines.length;

    print('📋 Processing $totalItems items in batches of $batchSize');
    print('⚡ Using $concurrency concurrent workers\n');

    for (var i = 0; i < lines.length; i += batchSize) {
      final batchEnd = (i + batchSize < lines.length)
          ? i + batchSize
          : lines.length;
      final batch = lines.sublist(i, batchEnd);

      await processBatch(batch, outputSink);

      final progress = ((i + batch.length) / totalItems * 100).toInt();
      print(
        '📈 Progress: $progress% (${i + batch.length}/$totalItems) - '
        'Processed: $_processedCount, Errors: $_errorCount',
      );
    }

    _stopwatch.stop();
    printSummary(totalItems);
  }

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

  Future<void> processItem(String line, IOSink outputSink) async {
    try {
      final data = jsonDecode(line) as Map<String, dynamic>;
      final id = data['id'] as String;
      final text = data['text'] as String;

      if (verbose) {
        print('   🔄 Processing item $id...');
      }

      await Future.delayed(rateLimitDelay);

      final result = await processWithAI(text);

      final output = {
        'id': id,
        'input': text,
        'result': result,
        'operation': operation,
        'timestamp': DateTime.now().toIso8601String(),
        'metadata': {
          'processed_at': DateTime.now().millisecondsSinceEpoch,
          'operation_type': operation,
          'provider': model.providerId,
          'model': model.modelId,
        },
      };

      outputSink.writeln(jsonEncode(output));
      _processedCount++;

      if (verbose) {
        print('   ✅ Completed item $id');
      }
    } catch (error) {
      _errorCount++;
      if (verbose) {
        print('   ❌ Error processing item: $error');
      }

      try {
        final data = jsonDecode(line) as Map<String, dynamic>;
        final errorOutput = {
          'id': data['id'],
          'input': data['text'],
          'error': error.toString(),
          'operation': operation,
          'timestamp': DateTime.now().toIso8601String(),
        };
        outputSink.writeln(jsonEncode(errorOutput));
      } catch (_) {
        // Ignore malformed lines that cannot be parsed a second time.
      }
    }
  }

  Future<String> processWithAI(String text) async {
    final result = await core.generateTextCall(
      model: model,
      prompt: [
        core.SystemPromptMessage.text(getSystemPromptForOperation(operation)),
        core.UserPromptMessage.text(text),
      ],
      options: const core.GenerateTextOptions(
        temperature: 0.3,
        maxOutputTokens: 1000,
      ),
    );

    return result.text.isEmpty ? 'No response generated' : result.text;
  }

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

  void printSummary(int totalItems) {
    final duration = _stopwatch.elapsed;
    final seconds =
        duration.inMilliseconds <= 0 ? 1 : duration.inMilliseconds / 1000;
    final itemsPerSecond = _processedCount / seconds;

    print('\n📊 Batch Processing Summary:');
    print('   Total items: $totalItems');
    print('   Successfully processed: $_processedCount');
    print('   Errors: $_errorCount');
    print(
      '   Success rate: ${((_processedCount / totalItems) * 100).toStringAsFixed(1)}%',
    );
    print('   Total time: ${duration.inMinutes}m ${duration.inSeconds % 60}s');
    print(
      '   Processing rate: ${itemsPerSecond.toStringAsFixed(2)} items/second',
    );
  }
}

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
