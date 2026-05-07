part of 'provider_compat.dart';

mixin _ElevenLabsProviderModels {
  ElevenLabsCompatShellSupport get _compatShell;

  Future<List<Map<String, dynamic>>> getModels() async {
    return _compatShell.getModels();
  }

  Future<Map<String, dynamic>> getUserInfo() async {
    return _compatShell.getUserInfo();
  }
}
