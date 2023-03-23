import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'js_value.dart';
import 'library.dart';
import 'typedef.dart';
import 'extensions.dart';

class Common {
  Common._();

  // js to string
  static String? jsToString(
      Pointer<JSContext> context, Pointer<JSValue> value) {
    final pointer = library.jsToCString(context, value);

    if (pointer.address != 0) {
      final message = pointer.cast<Utf8>().toDartString();
      library.freeCString(context, pointer);
      return message;
    }

    return null;
  }

  // 转换参数
  static Pointer<JSValue> formatArgs(List<JSObject> args) {
    final size = args.length * jsValueSizeOf;
    final data = calloc<Pointer>(size).cast<JSValue>();

    for (int index = 0; index < args.length; index++) {
      library.setValueAt(data, index, args[index].pointer);
    }

    return data;
  }

  // 执行构造函数
  static Pointer<JSValue> callConstructor(
    Pointer<JSContext> context,
    Pointer<JSValue> constructor, [
    List<JSObject>? args,
  ]) {
    if (library.isConstructor(context, constructor) == 0) {
      throw 'constructor不是构造函数';
    }

    final pointer = library.callConstructor(
      context,
      constructor,
      args?.length ?? 0,
      args == null ? undefined : Common.formatArgs(args),
    );

    if (pointer.isException) {
      final message = context.exception;
      throw '函数调用执行异常:$message';
    }

    return pointer;
  }
}
