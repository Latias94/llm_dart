import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_builtin_tool.dart';

enum OpenAIShellMemoryLimit {
  oneGb('1g'),
  fourGb('4g'),
  sixteenGb('16g'),
  sixtyFourGb('64g');

  const OpenAIShellMemoryLimit(this.value);

  final String value;
}

sealed class OpenAIShellNetworkPolicy {
  const OpenAIShellNetworkPolicy();

  Map<String, Object?> toJson();
}

final class OpenAIShellDisabledNetworkPolicy extends OpenAIShellNetworkPolicy {
  const OpenAIShellDisabledNetworkPolicy();

  @override
  Map<String, Object?> toJson() {
    return const {
      'type': 'disabled',
    };
  }
}

final class OpenAIShellAllowlistNetworkPolicy extends OpenAIShellNetworkPolicy {
  final List<String> allowedDomains;
  final List<OpenAIShellDomainSecret>? domainSecrets;

  OpenAIShellAllowlistNetworkPolicy({
    required List<String> allowedDomains,
    this.domainSecrets,
  }) : allowedDomains = List.unmodifiable(allowedDomains) {
    if (allowedDomains.isEmpty) {
      throw ArgumentError.value(
        allowedDomains,
        'allowedDomains',
        'OpenAIShellAllowlistNetworkPolicy requires allowed domains.',
      );
    }
  }

  @override
  Map<String, Object?> toJson() {
    return {
      'type': 'allowlist',
      'allowed_domains': allowedDomains,
      if (domainSecrets != null && domainSecrets!.isNotEmpty)
        'domain_secrets': [
          for (final secret in domainSecrets!) secret.toJson(),
        ],
    };
  }
}

final class OpenAIShellDomainSecret {
  final String domain;
  final String name;
  final String value;

  const OpenAIShellDomainSecret({
    required this.domain,
    required this.name,
    required this.value,
  });

  Map<String, Object?> toJson() {
    return {
      'domain': domain,
      'name': name,
      'value': value,
    };
  }
}

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

sealed class OpenAIShellEnvironment {
  const OpenAIShellEnvironment();

  Map<String, Object?> toJson();
}

final class OpenAIShellContainerAutoEnvironment extends OpenAIShellEnvironment {
  final List<String>? fileIds;
  final OpenAIShellMemoryLimit? memoryLimit;
  final OpenAIShellNetworkPolicy? networkPolicy;
  final List<OpenAIShellSkill>? skills;

  OpenAIShellContainerAutoEnvironment({
    this.fileIds,
    this.memoryLimit,
    this.networkPolicy,
    this.skills,
  });

  @override
  Map<String, Object?> toJson() {
    return {
      'type': 'container_auto',
      if (fileIds != null && fileIds!.isNotEmpty)
        'file_ids': List<String>.unmodifiable(fileIds!),
      if (memoryLimit != null) 'memory_limit': memoryLimit!.value,
      if (networkPolicy != null) 'network_policy': networkPolicy!.toJson(),
      if (skills != null && skills!.isNotEmpty)
        'skills': [
          for (final skill in skills!) skill.toJson(),
        ],
    };
  }
}

final class OpenAIShellContainerReferenceEnvironment
    extends OpenAIShellEnvironment {
  final String containerId;

  const OpenAIShellContainerReferenceEnvironment(this.containerId);

  @override
  Map<String, Object?> toJson() {
    return {
      'type': 'container_reference',
      'container_id': containerId,
    };
  }
}

final class OpenAIShellLocalEnvironment extends OpenAIShellEnvironment {
  final List<OpenAIShellLocalSkill>? skills;

  const OpenAIShellLocalEnvironment({
    this.skills,
  });

  @override
  Map<String, Object?> toJson() {
    return {
      'type': 'local',
      if (skills != null && skills!.isNotEmpty)
        'skills': [
          for (final skill in skills!) skill.toJson(),
        ],
    };
  }
}

final class OpenAILocalShellTool implements OpenAIBuiltInTool {
  const OpenAILocalShellTool();

  @override
  OpenAIBuiltInToolType get type => OpenAIBuiltInToolType.localShell;

  @override
  Map<String, Object?> toJson() {
    return const {
      'type': 'local_shell',
    };
  }
}

final class OpenAIShellTool implements OpenAIBuiltInTool {
  final OpenAIShellEnvironment? environment;

  const OpenAIShellTool({
    this.environment,
  });

  @override
  OpenAIBuiltInToolType get type => OpenAIBuiltInToolType.shell;

  @override
  Map<String, Object?> toJson() {
    return {
      'type': 'shell',
      if (environment != null) 'environment': environment!.toJson(),
    };
  }
}

final class OpenAIApplyPatchTool implements OpenAIBuiltInTool {
  const OpenAIApplyPatchTool();

  @override
  OpenAIBuiltInToolType get type => OpenAIBuiltInToolType.applyPatch;

  @override
  Map<String, Object?> toJson() {
    return const {
      'type': 'apply_patch',
    };
  }
}
