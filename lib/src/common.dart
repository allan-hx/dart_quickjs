import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'js_value.dart';
import 'library.dart';
import 'typedef.dart';

class Common {
  Common._();

  // js to string
  static String? jsToString(Pointer<JSContext> context, Pointer<JSValue> value) {
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
}
