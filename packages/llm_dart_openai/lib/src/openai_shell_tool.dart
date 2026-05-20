import 'openai_builtin_tool.dart';
import 'openai_shell_environment.dart';

export 'openai_shell_environment.dart'
    show
        OpenAIShellAllowlistNetworkPolicy,
        OpenAIShellContainerAutoEnvironment,
        OpenAIShellContainerReferenceEnvironment,
        OpenAIShellDisabledNetworkPolicy,
        OpenAIShellDomainSecret,
        OpenAIShellEnvironment,
        OpenAIShellLocalEnvironment,
        OpenAIShellMemoryLimit,
        OpenAIShellNetworkPolicy;
export 'openai_shell_skill.dart'
    show
        OpenAIShellInlineSkill,
        OpenAIShellInlineSkillSource,
        OpenAIShellLocalSkill,
        OpenAIShellSkill,
        OpenAIShellSkillReference;

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
