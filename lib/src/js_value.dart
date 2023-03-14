import 'dart:async';
import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'common.dart';
import 'library.dart';
import 'observer.dart';
import 'typedef.dart';
import 'extensions.dart';

// js value size
final int jsValueSizeOf = library.jsValueSizeOf();
// js undefined指针
final undefined = library.newUndefined();
// js null指针
final jsNull = library.newNull();

// Promise回调
typedef PromiseCallback = JSValue? Function(JSObject? value);

class JSObject {
  JSObject(this.context, this._pointer);

  factory JSObject.create(Pointer<JSContext> context) {
    final pointer = library.newObject(context);
    return JSObject(context, pointer);
  }

  // 上下文
  final Pointer<JSContext> context;

  // 引用
  Pointer<JSValue> _pointer;
  Pointer<JSValue> get pointer => _pointer;

  // 获取类型tag
  int get tag => _pointer.ref.tag;

  // 获取dart数据
  Object? get value => toString();

  // 添加属性 - key为string
  bool setPropertyStr(String key, JSObject value) {
    final keyPointer = key.toNativeUtf8().cast<Char>();
    // 添加
    final state = library.setPropertyStr(
      context,
      pointer,
      keyPointer,
      value.pointer,
    );

    malloc.free(keyPointer);

    if (state == 1) {
      if (value is JSFunction) {
        value._subscription();
      }

      return true;
    }

    return false;
  }

  // 设置属性 - key为js value
  bool setProperty(JSObject key, JSObject value, [JSProp flags = JSProp.cast]) {
    final state = library.setProperty(
      context,
      pointer,
      key.pointer,
      value.pointer,
      flags.value,
    );

    if (state == 1) {
      if (value is JSFunction) {
        value._subscription();
      }

      return true;
    }

    return false;
  }

  // 获取属性 - key为string
  T? getPropertyStr<T extends JSObject?>(String key) {
    final keyPointer = key.toNativeUtf8().cast<Char>();
    final data = library.getPropertyStr(context, pointer, keyPointer);
    final value = data.toJSValue(context);

    malloc.free(keyPointer);

    if (value is T) {
      return value as T;
    }

    return null;
  }

  // 获取属性 - key为js value
  T? getProperty<T extends JSObject?>(JSObject key) {
    final data = library.getProperty(context, pointer, key.pointer);
    final value = data.toJSValue(context);

    if (value is JSUndefined || value is JSNull) {
      return null;
    }

    return value as T;
  }

  // 引用标记
  void dupValue() {
    _pointer = library.dupValue(context, pointer);
  }

  // 释放 - 异步
  void free() {
    library.freeValue(context, pointer);
  }

  // 释放 - 异步
  void freeAsync() {
    Timer.run(free);
  }

  @override
  String toString() {
    return Common.jsToString(context, _pointer) ?? '';
  }
}

class JSString extends JSObject {
  JSString(super.context, super.pointer);

  factory JSString.create(Pointer<JSContext> context, String value) {
    final pointer = value.toNativeUtf8().cast<Char>();
    final data = library.newString(context, pointer);

    malloc.free(pointer);

    return JSString(context, data);
  }

  @override
  String get value => super.toString();
}

class JSNumber extends JSObject {
  JSNumber(super.context, super.pointer);

  factory JSNumber.create(Pointer<JSContext> context, int value) {
    final pointer = library.newInt64(context, value);
    return JSNumber(context, pointer);
  }

  @override
  int get value => library.toInt64(context, pointer);
}

class JSFloat extends JSObject {
  JSFloat(super.context, super.pointer);

  factory JSFloat.create(Pointer<JSContext> context, double value) {
    final pointer = library.newFloat64(context, value);
    return JSFloat(context, pointer);
  }

  @override
  double get value => library.toFloat64(context, pointer);
}

class JSBool extends JSObject {
  JSBool(super.context, super.pointer);

  factory JSBool.create(Pointer<JSContext> context, bool value) {
    final pointer = library.newBool(context, value ? 1 : 0);
    return JSBool(context, pointer);
  }

  @override
  bool get value => library.toBool(context, pointer) == 1;
}

class JSArray extends JSObject {
  JSArray(super.context, super.pointer);

  factory JSArray.create(Pointer<JSContext> context) {
    final pointer = library.newArray(context);
    return JSArray(context, pointer);
  }

  @override
  List<JSObject> get value {
    return List.generate(length, (int value) => index(value));
  }

  // 数组长度
  int get length {
    final data = getPropertyStr<JSNumber>('length');
    return data!.value;
  }

  // 根据下标获取
  T index<T extends JSObject>(int index) {
    final key = JSNumber.create(context, index);
    key.freeAsync();
    return getProperty<T>(key)!;
  }

  // 添加
  bool push(JSObject value) => set(length, value);

  // 设置和修改
  bool set(int index, JSObject value, [JSProp flags = JSProp.cwe]) {
    final state = library.definePropertyValueUint32(
      context,
      pointer,
      index,
      value.pointer,
      flags.value,
    );

    return state == 1;
  }

  void forEach(void Function(JSObject item, int index) callback) {
    final int len = length;

    for (int i = 0; i < len; i++) {
      callback(index(i), i);
    }
  }

  List<T> map<T>(T Function(JSObject item, int index) callback) {
    final List<T> data = <T>[];

    forEach((JSObject item, int index) {
      data.add(callback(item, index));
    });

    return data;
  }
}

class JSFunction extends JSObject {
  JSFunction(
    super.context,
    super.pointer, {
    this.callback,
  });

  // 回调
  final Function? callback;

  factory JSFunction.create(Pointer<JSContext> context, Function callback) {
    final symbol = callback.hashCode.toString().toNativeUtf8().cast<Char>();
    final pointer = library.newCFunctionData(context, symbol);

    malloc.free(symbol);

    return JSFunction(
      context,
      pointer,
      callback: callback,
    );
  }

  // 释放 - 异步
  @override
  void free() {
    final symbol = callback.hashCode.toString();
    Observer.instance.off(symbol);
    super.free();
  }

  // 添加订阅
  void _subscription() {
    if (callback != null) {
      final String symbol = callback.hashCode.toString();
      Observer.instance.on(symbol, callback!);
    }
  }

  JSObject call([List<JSObject>? args, JSObject? self]) {
    final value = library.callFuncton(
      context,
      pointer,
      self?.pointer ?? undefined,
      args?.length ?? 0,
      args == null ? undefined : Common.formatArgs(args),
    );

    if (value.isException) {
      final message = context.exception;
      throw '函数调用执行异常:$message';
    }

    return value.toJSValue(context);
  }
}

class JSPromise extends JSObject {
  JSPromise(
    super.context,
    super.pointer, {
    Pointer<JSValue>? resolvePointer,
    Pointer<JSValue>? rejectPointer,
  })  : _resolvePointer = resolvePointer,
        _rejectPointer = rejectPointer;

  factory JSPromise.create(Pointer<JSContext> context) {
    // resject方法
    final resolve = malloc<Uint8>(jsValueSizeOf * 2).cast<JSValue>();
    // resject方法
    final resject = Pointer<JSValue>.fromAddress(
      resolve.address + jsValueSizeOf,
    );

    return JSPromise(
      context,
      library.newPromise(context, resolve),
      resolvePointer: resolve,
      rejectPointer: resject,
    );
  }

  // js resolve方法
  final Pointer<JSValue>? _resolvePointer;
  // js reject方法
  final Pointer<JSValue>? _rejectPointer;

  void resolve([JSObject? value]) {
    final func = JSFunction(context, _resolvePointer!);
    func.call(value == null ? null : [value]).free();
    context.executePendingJob();
  }

  void reject([JSObject? value]) {
    final func = JSFunction(context, _rejectPointer!);
    func.call(value == null ? null : [value]).free();
    context.executePendingJob();
  }

  JSPromise then(PromiseCallback callback) {
    // 回调标识
    late String symbol;

    final handler = JSFunction.create(context, ([JSObject? value]) {
      Observer.instance.off(symbol);
      callback(value);
    });

    symbol = handler.callback.hashCode.toString();

    Observer.instance.on(symbol, handler.callback!);

    final func = getPropertyStr<JSFunction>('then')!;
    final value = func.call([handler], this);
    context.executePendingJob();
    return value as JSPromise;
  }

  JSPromise catchError(PromiseCallback callback) {
    // 回调标识
    late String symbol;

    final handler = JSFunction.create(context, ([JSObject? value]) {
      Observer.instance.off(symbol);
      callback(value);
    });

    symbol = handler.callback.hashCode.toString();

    Observer.instance.on(symbol, handler.callback!);

    final func = getPropertyStr<JSFunction>('catch')!;
    final value = func.call([handler], this);
    context.executePendingJob();
    return value as JSPromise;
  }
}

class JSNull extends JSObject {
  JSNull() : super(nullptr, jsNull);

  @override
  dynamic get value => null;

  @override
  String toString() => 'null';
}

class JSUndefined extends JSObject {
  JSUndefined() : super(nullptr, undefined);

  @override
  dynamic get value => null;

  @override
  String toString() => 'undefined';
}
