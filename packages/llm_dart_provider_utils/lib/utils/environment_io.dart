import 'dart:io';

bool get environmentVariablesSupported => true;

String? getEnvironmentVariable(String name) => Platform.environment[name];
