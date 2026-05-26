import 'package:llm_dart_provider/llm_dart_provider.dart';

void requireDescribedModelCapability({
  required Object model,
  required ModelCapabilityKind kind,
  String? featureId,
  required String usageContext,
}) {
  if (model is! CapabilityDescribedModel) {
    return;
  }

  final gate = ModelCapabilityGate(model.capabilityProfile);
  final kindDecision = gate.modelKind(kind);
  if (kindDecision.unsupported) {
    throw UnsupportedError(
      '$usageContext is not supported: ${kindDecision.reason}',
    );
  }

  if (featureId == null) {
    return;
  }

  final featureDecision = gate.sharedCapability(featureId);
  if (featureDecision.unsupported) {
    throw UnsupportedError(
      '$usageContext requires "$featureId": ${featureDecision.reason}',
    );
  }
}
