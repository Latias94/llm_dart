/// Legacy configuration utilities.
///
/// 新代码应优先直接使用 `HttpHeaderUtils`、`HttpConfigUtils`，并在各
/// provider 子包内部实现消息/参数转换逻辑。
///
/// 本文件只为需要兼容旧版 `ConfigUtils` 的场景提供显式导入路径：
/// `import 'package:llm_dart/legacy/config_utils.dart';`.
library;

export '../utils/config_utils.dart' show ConfigUtils;
