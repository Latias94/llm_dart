import 'package:llm_dart/legacy.dart';

/// Comprehensive assistants examples using the unified AssistantCapability interface
///
/// This example demonstrates:
/// - Assistant creation and configuration
/// - Assistant management operations
/// - Different assistant types and purposes
/// - Assistant modification and updates
/// - Provider capability detection
/// - Error handling for assistant operations
Future<void> main() async {
  print('🤖 AI Assistants Examples\n');

  // Example with providers that support assistants
  final providers = [
    ('OpenAI', () => ai().openai().apiKey('your-openai-key')),
    // Add other providers that support assistants
  ];

  for (final (name, builderFactory) in providers) {
    print('🔧 Testing $name Assistants:');

    try {
      final provider = await builderFactory().buildAssistant();
      await demonstrateAssistantFeatures(provider, name);
    } catch (e) {
      print('   ❌ Failed to initialize $name: $e\n');
    }
  }

  print('✅ Assistants examples completed!');
  print('💡 For provider-specific features, see:');
  print('   • example/04_providers/openai/assistants.dart');
}

/// Helper function to create assistant tools from string
AssistantTool _createAssistantTool(String toolType) {
  switch (toolType) {
    case 'code_interpreter':
      return const CodeInterpreterTool();
    case 'file_search':
    case 'retrieval': // Support legacy name
      return const FileSearchTool();
    default:
      throw ArgumentError('Unsupported tool type: $toolType');
  }
}

/// Demonstrate various assistant features with a provider
Future<void> demonstrateAssistantFeatures(
    AssistantCapability provider, String providerName) async {
  final createdAssistants = <Assistant>[];

  try {
    // Assistant creation examples
    final assistants =
        await demonstrateAssistantCreation(provider, providerName);
    createdAssistants.addAll(assistants);

    // Assistant listing and retrieval
    await demonstrateAssistantListing(provider, providerName);

    // Assistant modification
    if (createdAssistants.isNotEmpty) {
      await demonstrateAssistantModification(
          provider, providerName, createdAssistants.first);
    }

    // Assistant management
    await demonstrateAssistantManagement(provider, providerName);
  } finally {
    // Cleanup created assistants
    await demonstrateAssistantCleanup(
        provider, providerName, createdAssistants);
  }

  print('');
}

/// Demonstrate assistant creation
Future<List<Assistant>> demonstrateAssistantCreation(
    AssistantCapability provider, String providerName) async {
  print('   🛠️  Assistant Creation:');

  final createdAssistants = <Assistant>[];

  try {
    // Create different types of assistants
    final assistantConfigs = [
      {
        'name': 'Code Helper',
        'description':
            'An assistant specialized in programming and code review',
        'instructions':
            'You are a helpful programming assistant. Help users with coding questions, code review, and best practices.',
        'model': 'gpt-4',
        'tools': ['code_interpreter'],
      },
      {
        'name': 'Research Assistant',
        'description': 'An assistant for research and information gathering',
        'instructions':
            'You are a research assistant. Help users find information, analyze data, and provide insights.',
        'model': 'gpt-4',
        'tools': ['retrieval'],
      },
      {
        'name': 'Creative Writer',
        'description':
            'An assistant for creative writing and content generation',
        'instructions':
            'You are a creative writing assistant. Help users with storytelling, content creation, and writing improvement.',
        'model': 'gpt-4',
        'tools': [],
      },
    ];

    for (final config in assistantConfigs) {
      try {
        print('      🔄 Creating ${config['name']}...');

        final request = CreateAssistantRequest(
          model: config['model'] as String,
          name: config['name'] as String,
          description: config['description'] as String,
          instructions: config['instructions'] as String,
          tools: (config['tools'] as List<String>)
              .map((tool) => _createAssistantTool(tool))
              .toList(),
          metadata: {
            'created_by': 'llm_dart_example',
            'purpose': 'demonstration',
          },
        );

        final assistant = await provider.createAssistant(request);
        createdAssistants.add(assistant);

        print('         ✅ Created: ${assistant.id}');
        print('         📝 Name: ${assistant.name}');
        print('         🤖 Model: ${assistant.model}');
        print(
            '         🛠️  Tools: ${assistant.tools.map((t) => t.type.value).join(', ')}');
      } catch (e) {
        print('         ❌ Creation failed: $e');
      }
    }

    print('      📊 Total created: ${createdAssistants.length} assistants');
  } catch (e) {
    print('      ❌ Assistant creation demonstration failed: $e');
  }

  return createdAssistants;
}

/// Demonstrate assistant listing and retrieval
Future<void> demonstrateAssistantListing(
    AssistantCapability provider, String providerName) async {
  print('   📋 Assistant Listing:');

  try {
    // List all assistants
    print('      🔄 Listing all assistants...');
    final allAssistants = await provider.listAssistants();

    print('      📊 Total assistants: ${allAssistants.data.length}');

    if (allAssistants.data.isNotEmpty) {
      print('      🤖 Available assistants:');
      for (final assistant in allAssistants.data.take(5)) {
        final toolsStr = assistant.tools.map((t) => t.type.value).join(', ');
        print('         • ${assistant.name} (${assistant.id})');
        print('           Model: ${assistant.model}, Tools: $toolsStr');
      }
    }

    // List with filtering
    print('      🔍 Filtering assistants...');
    final filteredAssistants = await provider.listAssistants(
      ListAssistantsQuery(limit: 10, order: 'desc'),
    );

    print('      📋 Recent assistants: ${filteredAssistants.data.length}');

    // Retrieve specific assistant details
    if (allAssistants.data.isNotEmpty) {
      final firstAssistant = allAssistants.data.first;
      print('      🔍 Retrieving details for ${firstAssistant.name}...');

      final detailedAssistant =
          await provider.retrieveAssistant(firstAssistant.id);

      print('         ✅ Retrieved: ${detailedAssistant.name}');
      print('         📝 Description: ${detailedAssistant.description}');
      print('         📅 Created: ${detailedAssistant.createdAt}');
      print('         🏷️  Metadata: ${detailedAssistant.metadata}');
    }
  } catch (e) {
    print('      ❌ Assistant listing failed: $e');
  }
}

/// Demonstrate assistant modification
Future<void> demonstrateAssistantModification(AssistantCapability provider,
    String providerName, Assistant assistant) async {
  print('   ✏️  Assistant Modification:');

  try {
    print('      🔄 Modifying ${assistant.name}...');

    final modifyRequest = ModifyAssistantRequest(
      name: '${assistant.name} (Updated)',
      description: '${assistant.description} - Updated with new capabilities',
      instructions:
          '${assistant.instructions}\n\nAdditional instruction: Always be helpful and provide detailed explanations.',
      metadata: {
        ...?assistant.metadata,
        'last_updated': DateTime.now().toIso8601String(),
        'version': '2.0',
      },
    );

    final updatedAssistant =
        await provider.modifyAssistant(assistant.id, modifyRequest);

    print('      ✅ Modified successfully');
    print('         📝 New name: ${updatedAssistant.name}');
    print('         📄 New description: ${updatedAssistant.description}');
    print('         🏷️  Updated metadata: ${updatedAssistant.metadata}');

    // Show the differences
    print('      🔄 Changes made:');
    if (assistant.name != updatedAssistant.name) {
      print(
          '         • Name: "${assistant.name}" → "${updatedAssistant.name}"');
    }
    if (assistant.description != updatedAssistant.description) {
      print('         • Description updated');
    }
    if (assistant.instructions != updatedAssistant.instructions) {
      print('         • Instructions updated');
    }
  } catch (e) {
    print('      ❌ Assistant modification failed: $e');
  }
}

/// Demonstrate assistant management operations
Future<void> demonstrateAssistantManagement(
    AssistantCapability provider, String providerName) async {
  print('   📊 Assistant Management:');

  try {
    // Get all assistants for analysis
    final assistants = await provider.listAssistants();

    if (assistants.data.isEmpty) {
      print('      ℹ️  No assistants available for management demo');
      return;
    }

    // Analyze assistant distribution
    print('      📈 Assistant Analytics:');

    // Group by model
    final modelGroups = <String, int>{};
    for (final assistant in assistants.data) {
      modelGroups[assistant.model] = (modelGroups[assistant.model] ?? 0) + 1;
    }

    print('         🤖 Models in use:');
    for (final entry in modelGroups.entries) {
      print('           • ${entry.key}: ${entry.value} assistant(s)');
    }

    // Group by tools
    final toolUsage = <String, int>{};
    for (final assistant in assistants.data) {
      for (final tool in assistant.tools) {
        toolUsage[tool.type.value] = (toolUsage[tool.type.value] ?? 0) + 1;
      }
    }

    print('         🛠️  Tool usage:');
    for (final entry in toolUsage.entries) {
      print('           • ${entry.key}: ${entry.value} assistant(s)');
    }

    // Find assistants created by this example
    final exampleAssistants = assistants.data
        .where((a) => a.metadata?['created_by'] == 'llm_dart_example')
        .toList();

    print('         📋 Example assistants: ${exampleAssistants.length}');

    // Show creation timeline
    if (assistants.data.length > 1) {
      final sortedByDate = assistants.data.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      final oldest = sortedByDate.first;
      final newest = sortedByDate.last;

      print('         📅 Timeline:');
      print('           • Oldest: ${oldest.name} (${oldest.createdAt})');
      print('           • Newest: ${newest.name} (${newest.createdAt})');
    }
  } catch (e) {
    print('      ❌ Assistant management failed: $e');
  }
}

/// Demonstrate assistant cleanup
Future<void> demonstrateAssistantCleanup(AssistantCapability provider,
    String providerName, List<Assistant> assistants) async {
  print('   🗑️  Assistant Cleanup:');

  if (assistants.isEmpty) {
    print('      ℹ️  No assistants to clean up');
    return;
  }

  try {
    print('      🔄 Cleaning up ${assistants.length} created assistants...');

    int deletedCount = 0;
    for (final assistant in assistants) {
      try {
        final result = await provider.deleteAssistant(assistant.id);
        if (result.deleted) {
          deletedCount++;
          print('         ✅ Deleted: ${assistant.name}');
        } else {
          print('         ❌ Failed to delete: ${assistant.name}');
        }
      } catch (e) {
        print('         ❌ Delete error for ${assistant.name}: $e');
      }
    }

    print(
        '      📊 Cleanup summary: $deletedCount/${assistants.length} assistants deleted');
  } catch (e) {
    print('      ❌ Assistant cleanup failed: $e');
  }
}

/// Utility class for assistant management
class AssistantUtils {
  /// Get recommended model based on assistant purpose
  static String getRecommendedModel(String purpose) {
    switch (purpose.toLowerCase()) {
      case 'code':
      case 'programming':
        return 'gpt-4';
      case 'creative':
      case 'writing':
        return 'gpt-4';
      case 'research':
      case 'analysis':
        return 'gpt-4';
      case 'simple':
      case 'basic':
        return 'gpt-3.5-turbo';
      default:
        return 'gpt-4';
    }
  }

  /// Get recommended tools based on assistant type
  static List<String> getRecommendedTools(String assistantType) {
    switch (assistantType.toLowerCase()) {
      case 'code':
      case 'programming':
        return ['code_interpreter'];
      case 'research':
      case 'analysis':
        return ['retrieval'];
      case 'creative':
      case 'writing':
        return [];
      case 'data':
      case 'analytics':
        return ['code_interpreter', 'retrieval'];
      default:
        return [];
    }
  }

  /// Validate assistant configuration
  static bool isValidConfiguration(CreateAssistantRequest request) {
    if (request.name?.isEmpty ?? true) return false;
    if (request.instructions?.isEmpty ?? true) return false;
    if (request.model.isEmpty) return false;

    // Check name length
    if ((request.name?.length ?? 0) > 256) return false;

    // Check instructions length
    if ((request.instructions?.length ?? 0) > 32768) return false;

    return true;
  }

  /// Generate assistant instructions based on role
  static String generateInstructions(String role, String domain) {
    final baseInstructions = {
      'helper':
          'You are a helpful assistant specialized in $domain. Provide clear, accurate, and useful information.',
      'teacher':
          'You are an educational assistant for $domain. Explain concepts clearly and provide examples.',
      'analyst':
          'You are an analytical assistant for $domain. Analyze data and provide insights.',
      'creator':
          'You are a creative assistant for $domain. Help generate ideas and content.',
    };

    return baseInstructions[role.toLowerCase()] ??
        'You are a helpful assistant. Assist users with their questions and tasks.';
  }

  /// Format assistant summary
  static String formatAssistantSummary(Assistant assistant) {
    final tools = assistant.tools.map((t) => t.type.value).join(', ');
    final toolsStr = tools.isNotEmpty ? ' | Tools: $tools' : '';

    return '${assistant.name} (${assistant.model}$toolsStr)';
  }
}
