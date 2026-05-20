import 'package:llm_dart_provider/llm_dart_provider.dart';

sealed class OpenAIShellSkill {
  const OpenAIShellSkill();

  Map<String, Object?> toJson();
}

final class OpenAIShellSkillReference extends OpenAIShellSkill {
  final ProviderReference providerReference;
  final String? version;

  const OpenAIShellSkillReference({
    required this.providerReference,
    this.version,
  });

  @override
  Map<String, Object?> toJson() {
    return {
      'type': 'skill_reference',
      'skill_id': providerReference.requireProvider(
        'openai',
        context: 'OpenAI shell skill',
      ),
      'version': version ?? 'latest',
    };
  }
}

final class OpenAIShellInlineSkill extends OpenAIShellSkill {
  final String name;
  final String description;
  final OpenAIShellInlineSkillSource source;

  const OpenAIShellInlineSkill({
    required this.name,
    required this.description,
    required this.source,
  });

  @override
  Map<String, Object?> toJson() {
    return {
      'type': 'inline',
      'name': name,
      'description': description,
      'source': source.toJson(),
    };
  }
}

final class OpenAIShellInlineSkillSource {
  final String data;

  const OpenAIShellInlineSkillSource.base64Zip({
    required this.data,
  });

  Map<String, Object?> toJson() {
    return {
      'type': 'base64',
      'media_type': 'application/zip',
      'data': data,
    };
  }
}

final class OpenAIShellLocalSkill {
  final String name;
  final String description;
  final String path;

  const OpenAIShellLocalSkill({
    required this.name,
    required this.description,
    required this.path,
  });

  Map<String, Object?> toJson() {
    return {
      'name': name,
      'description': description,
      'path': path,
    };
  }
}
