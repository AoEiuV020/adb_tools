import 'dart:async';
import 'dart:typed_data';

/// Shell 进程的抽象接口
abstract class Shell {
  /// Shell 的标准输入流
  StreamSink<String> get stdin;

  /// Shell 的标准输出流
  Stream<Uint8List> get stdout;

  /// Shell 的标准错误流
  Stream<Uint8List> get stderr;

  /// 关闭 Shell
  Future<void> terminate();
}
