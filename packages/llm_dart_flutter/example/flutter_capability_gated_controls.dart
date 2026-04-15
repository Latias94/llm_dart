import 'package:flutter/material.dart';

import 'capability_gated_demo_support.dart';

void main() {
  runApp(const CapabilityGatedControlsApp());
}

class CapabilityGatedControlsApp extends StatelessWidget {
  const CapabilityGatedControlsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const CapabilityGatedControlsPage(),
    );
  }
}

class CapabilityGatedControlsPage extends StatefulWidget {
  const CapabilityGatedControlsPage({super.key});

  @override
  State<CapabilityGatedControlsPage> createState() =>
      _CapabilityGatedControlsPageState();
}

class _CapabilityGatedControlsPageState
    extends State<CapabilityGatedControlsPage> {
  late CapabilityDemoPreset _selectedPreset;

  @override
  void initState() {
    super.initState();
    _selectedPreset = capabilityGatedDemoPresets.first;
  }

  @override
  Widget build(BuildContext context) {
    final policy = buildChatComposerPolicy(_selectedPreset.profile);
    final reasoningFallback = suggestFallbackPreset(
      selected: _selectedPreset,
      candidates: capabilityGatedDemoPresets,
      requiredFeatures: reasoningInspectorFeatureIds,
    );
    final sourceFallback = suggestFallbackPreset(
      selected: _selectedPreset,
      candidates: capabilityGatedDemoPresets,
      requiredFeatures: sourceBackedAnswerFeatureIds,
    );
    final missingReasoning = missingSharedFeatureLabels(
      _selectedPreset.profile,
      reasoningInspectorFeatureIds,
    );
    final missingSources = missingSharedFeatureLabels(
      _selectedPreset.profile,
      sourceBackedAnswerFeatureIds,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Capability-Gated Controls Demo'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected chat model',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedPreset.id,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Model preset',
                      ),
                      items: [
                        for (final preset in capabilityGatedDemoPresets)
                          DropdownMenuItem<String>(
                            value: preset.id,
                            child: Text(preset.label),
                          ),
                      ],
                      onChanged: (selectedId) {
                        if (selectedId == null) {
                          return;
                        }

                        setState(() {
                          _selectedPreset =
                              capabilityGatedDemoPresets.firstWhere(
                            (preset) => preset.id == selectedId,
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(_selectedPreset.description),
                    const SizedBox(height: 8),
                    Text('Provider route: ${policy.routeLabel}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shared affordances',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildActionButton(
                          context,
                          label: 'Attach image',
                          icon: Icons.image_outlined,
                          enabled: policy.canAttachImages,
                        ),
                        _buildActionButton(
                          context,
                          label: 'Attach file',
                          icon: Icons.attach_file,
                          enabled: policy.canAttachFiles,
                        ),
                        _buildActionButton(
                          context,
                          label: 'Structured reply',
                          icon: Icons.data_object,
                          enabled: policy.canUseStructuredOutput,
                        ),
                        _buildActionButton(
                          context,
                          label: 'Reasoning panel',
                          icon: Icons.psychology_outlined,
                          enabled: policy.canShowReasoningPanel,
                        ),
                        _buildActionButton(
                          context,
                          label: 'Source citations',
                          icon: Icons.link_outlined,
                          enabled: policy.canShowSourcesPanel,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Use shared capability IDs to gate these controls. Keep '
                      'provider validation and warnings in the request path.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Provider-aware panels',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text('Route: ${policy.routeLabel}'),
                        ),
                        for (final badge in policy.providerBadges)
                          Chip(label: Text(badge)),
                        if (policy.providerBadges.isEmpty)
                          const Chip(label: Text('No provider-native badges')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Provider-native configuration should still stay '
                      'provider-aware even when the shared composer controls are '
                      'uniform.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fallback suggestions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _FallbackTile(
                      title: 'Reasoning inspector',
                      missingLabels: missingReasoning,
                      fallbackLabel: reasoningFallback?.label,
                    ),
                    const SizedBox(height: 12),
                    _FallbackTile(
                      title: 'Source-backed answer flow',
                      missingLabels: missingSources,
                      fallbackLabel: sourceFallback?.label,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool enabled,
  }) {
    return FilledButton.tonalIcon(
      onPressed: enabled ? () {} : null,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        disabledBackgroundColor:
            Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    );
  }
}

class _FallbackTile extends StatelessWidget {
  final String title;
  final List<String> missingLabels;
  final String? fallbackLabel;

  const _FallbackTile({
    required this.title,
    required this.missingLabels,
    required this.fallbackLabel,
  });

  @override
  Widget build(BuildContext context) {
    final hasMissing = missingLabels.isNotEmpty;
    final body = hasMissing
        ? 'Missing: ${missingLabels.join(', ')}. '
            'Suggested fallback: ${fallbackLabel ?? 'none available'}.'
        : 'No fallback needed for this flow.';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(body),
      leading: Icon(
        hasMissing ? Icons.swap_horiz : Icons.check_circle_outline,
      ),
    );
  }
}
