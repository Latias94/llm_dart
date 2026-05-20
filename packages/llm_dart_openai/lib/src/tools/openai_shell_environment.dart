import 'openai_shell_skill.dart';

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
