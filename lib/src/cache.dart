import 'dart:ffi';

import 'library.dart';
import 'runtime.dart';
import 'typedef.dart';

class Cache {
  Cache._();

  static final instance = Cache._();

  final Map<int, Runtime> _runtimes = {};

  // 获取运行时
  Runtime getRuntime(Pointer<JSContext> context) {
    final pointer = library.getRuntime(context);
    return _runtimes[pointer.hashCode]!;
  }

  // 保存运行时
  void saveRuntime(Pointer<JSRuntime> key, Runtime runtime) {
    _runtimes[key.hashCode] = runtime;
  }

  // 移除运行时
  void removeRuntime(Pointer<JSRuntime> key) {
    _runtimes.remove(key.hashCode);
  }
}
