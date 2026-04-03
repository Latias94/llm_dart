import 'dart:io';
import 'package:llm_dart/legacy.dart';

/// Content moderation examples using ModerationCapability interface
///
/// This example demonstrates:
/// - Basic content moderation
/// - Batch processing
/// - Category analysis
Future<void> main() async {
  print('🛡️ Content Moderation Examples\n');

  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null) {
    print('❌ Please set OPENAI_API_KEY environment variable');
    return;
  }

  try {
    final provider = await ai().openai().apiKey(apiKey).buildModeration();

    await demonstrateBasicModeration(provider, 'OpenAI');
    await demonstrateBatchModeration(provider, 'OpenAI');
  } catch (e) {
    print('❌ Failed to initialize moderation: $e');
  }

  print('✅ Content moderation examples completed!');
}

/// Demonstrate basic content moderation
Future<void> demonstrateBasicModeration(
    ModerationCapability provider, String providerName) async {
  print('🔍 Basic Content Moderation ($providerName):\n');

  final testContents = [
    'Hello, how are you today?', // Safe content
    'This is a normal conversation.', // Safe content
    'Thank you for your help!', // Safe content
  ];

  for (int i = 0; i < testContents.length; i++) {
    final content = testContents[i];
    print('   📝 Testing: "$content"');

    try {
      final request = ModerationRequest(input: content);
      final result = await provider.moderate(request);

      final firstResult = result.results.first;
      final status = firstResult.flagged ? '🚨 FLAGGED' : '✅ SAFE';
      print('         $status (ID: ${result.id})');

      if (firstResult.flagged) {
        print('         ⚠️  Content flagged for review');
      }
    } catch (e) {
      print('         ❌ Moderation failed: $e');
    }
    print('');
  }
}

/// Demonstrate batch moderation processing
Future<void> demonstrateBatchModeration(
    ModerationCapability provider, String providerName) async {
  print('📦 Batch Moderation ($providerName):\n');

  final batchContent = [
    'Welcome to our platform!',
    'Please follow our community guidelines.',
    'Thank you for your contribution.',
    'This is educational content about safety.',
    'Let\'s have a respectful discussion.',
  ];

  print('   🔄 Processing ${batchContent.length} items in batch...');
  final startTime = DateTime.now();

  final results = <ModerationResponse>[];
  for (final content in batchContent) {
    try {
      final request = ModerationRequest(input: content);
      final result = await provider.moderate(request);
      results.add(result);
    } catch (e) {
      print('   ❌ Failed to moderate: "$content" - $e');
    }
  }

  final duration = DateTime.now().difference(startTime);
  print('   ✅ Batch completed in ${duration.inMilliseconds}ms');

  // Analyze batch results
  final flaggedCount = results.where((r) => r.results.first.flagged).length;
  final safeCount = results.length - flaggedCount;

  print('   📊 Batch Results:');
  print('      ✅ Safe: $safeCount');
  print('      🚨 Flagged: $flaggedCount');
  print(
      '      📈 Safety rate: ${(safeCount / results.length * 100).toStringAsFixed(1)}%');
}
