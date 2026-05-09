import '../common/provider_metadata.dart';
import '../common/provider_reference.dart';
import '../content/file_data.dart';

sealed class ToolOutput {
  const ToolOutput();

  factory ToolOutput.fromValue(
    Object? value, {
    bool isError = false,
    ProviderMetadata? providerMetadata,
  }) {
    if (isError) {
      return value is String
          ? ErrorTextToolOutput(
              value,
              providerMetadata: providerMetadata,
            )
          : ErrorJsonToolOutput(
              value,
              providerMetadata: providerMetadata,
            );
    }

    return value is String
        ? TextToolOutput(
            value,
            providerMetadata: providerMetadata,
          )
        : JsonToolOutput(
            value,
            providerMetadata: providerMetadata,
          );
  }

  Object? get value;

  ProviderMetadata? get providerMetadata;

  bool get isError => false;

  bool get denied => false;
}

final class TextToolOutput extends ToolOutput {
  @override
  final String value;
  @override
  final ProviderMetadata? providerMetadata;

  const TextToolOutput(
    this.value, {
    this.providerMetadata,
  });
}

final class JsonToolOutput extends ToolOutput {
  @override
  final Object? value;
  @override
  final ProviderMetadata? providerMetadata;

  const JsonToolOutput(
    this.value, {
    this.providerMetadata,
  });
}

final class ErrorTextToolOutput extends ToolOutput {
  @override
  final String value;
  @override
  final ProviderMetadata? providerMetadata;

  const ErrorTextToolOutput(
    this.value, {
    this.providerMetadata,
  });

  @override
  bool get isError => true;
}

final class ErrorJsonToolOutput extends ToolOutput {
  @override
  final Object? value;
  @override
  final ProviderMetadata? providerMetadata;

  const ErrorJsonToolOutput(
    this.value, {
    this.providerMetadata,
  });

  @override
  bool get isError => true;
}

final class ExecutionDeniedToolOutput extends ToolOutput {
  final String? reason;
  @override
  final ProviderMetadata? providerMetadata;

  const ExecutionDeniedToolOutput([this.reason]) : providerMetadata = null;

  const ExecutionDeniedToolOutput.withMetadata({
    this.reason,
    this.providerMetadata,
  });

  @override
  String? get value => reason;

  @override
  bool get denied => true;
}

final class ContentToolOutput extends ToolOutput {
  final List<ToolOutputContentPart> parts;
  @override
  final ProviderMetadata? providerMetadata;

  ContentToolOutput({
    required List<ToolOutputContentPart> parts,
    this.providerMetadata,
  }) : parts = List.unmodifiable(parts);

  @override
  List<ToolOutputContentPart> get value => parts;
}

sealed class ToolOutputContentPart {
  const ToolOutputContentPart();

  ProviderMetadata? get providerMetadata;
}

final class TextToolOutputContentPart extends ToolOutputContentPart {
  final String text;
  @override
  final ProviderMetadata? providerMetadata;

  const TextToolOutputContentPart(
    this.text, {
    this.providerMetadata,
  });
}

final class JsonToolOutputContentPart extends ToolOutputContentPart {
  final Object? value;
  @override
  final ProviderMetadata? providerMetadata;

  const JsonToolOutputContentPart(
    this.value, {
    this.providerMetadata,
  });
}

final class FileToolOutputContentPart extends ToolOutputContentPart {
  final String mediaType;
  final String? filename;
  final FileData data;
  @override
  final ProviderMetadata? providerMetadata;

  const FileToolOutputContentPart({
    required this.mediaType,
    this.filename,
    required this.data,
    this.providerMetadata,
  });

  Uri? get uri => data.uri;

  List<int>? get bytes => data.bytes;

  String? get text => data.text;

  ProviderReference? get providerReference => data.providerReference;
}

final class CustomToolOutputContentPart extends ToolOutputContentPart {
  final String kind;
  final Object? data;
  @override
  final ProviderMetadata? providerMetadata;

  const CustomToolOutputContentPart({
    required this.kind,
    this.data,
    this.providerMetadata,
  });
}
