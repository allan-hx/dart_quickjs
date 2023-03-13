import 'dart:async';
import 'dart:ffi';

import 'library.dart';
import 'js_value.dart';
import 'common.dart';
import 'typedef.dart';

extension PointerJSValue on Pointer<JSValue> {
  // 是否异常
  bool get isException {
    return ref.tag == 6;
  }

  // 转换成js object
  JSObject toJSValue(Pointer<JSContext> context) {
    switch (ref.tag) {
      case JSValueTag.string:
        return JSString(context, this);
      case JSValueTag.number:
        return JSNumber(context, this);
      case JSValueTag.float64:
        return JSFloat(context, this);
      case JSValueTag.bool:
        return JSBool(context, this);
      case JSValueTag.nullptr:
        return JSNull();
      case JSValueTag.undefined:
        return JSUndefined();
    }

    if (library.isArray(context, this) == 1) {
      return JSArray(context, this);
    } else if (library.isFunction(context, this) == 1) {
      return JSFunction(context, this);
    } else if (library.isPromise(context, this) == 1) {
      return JSPromise(context, this);
    }

    return JSObject(context, this);
  }
}

extension PointerJSContext on Pointer<JSContext> {
  // 获取异常
  String? get exception {
    final value = library.getException(this);

    if (value.ref.tag != JSValueTag.nullptr) {
      return Common.jsToString(this, value);
    }

    return null;
  }

  // 执行挂起的任务
  void executePendingJob() {
    final runtime = library.getRuntime(this);

    Timer.run(() {
      while (true) {
        int err = library.executePendingJob(runtime);

        if (err <= 0) {
          if (err < 0) {
            throw exception ?? 'Dispatch Error';
          }

          break;
        }
      }
    });
  }
}
