import 'dart:async';
import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'cache.dart';
import 'common.dart';
import 'library.dart';
import 'runtime.dart';
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

    return state == 1;
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

    return state == 1;
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

  // 释放 - 同步
  void free() {
    library.freeValue(context, pointer);
  }

  // 释放 - 异步
  void freeAsync() {
    Future(free);
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

  int get length {
    return getPropertyStr<JSNumber>('length')!.value;
  }

  JSNumber indexOf(String value) {
    final indexOf = getPropertyStr<JSFunction>('indexOf')!;
    final args = JSString.create(context, value);
    final result = indexOf.call([args], this) as JSNumber;

    args.free();
    indexOf.free();

    return result;
  }

  JSNumber lastIndexOf(String value) {
    final lastIndexOf = getPropertyStr<JSFunction>('lastIndexOf')!;
    final args = JSString.create(context, value);
    final result = lastIndexOf.call([args], this) as JSNumber;

    args.free();
    lastIndexOf.free();

    return result;
  }

  JSBool includes(String value) {
    final includes = getPropertyStr<JSFunction>('includes')!;
    final args = JSString.create(context, value);
    final result = includes.call([args], this) as JSBool;

    args.free();
    includes.free();

    return result;
  }

  JSArray split(String separator) {
    final split = getPropertyStr<JSFunction>('split')!;
    final args = JSString.create(context, separator);
    final result = split.call([args], this) as JSArray;

    args.free();
    split.free();

    return result;
  }

  JSString slice([int? start, int? end]) {
    final slice = getPropertyStr<JSFunction>('slice')!;
    final List<JSNumber> args = [];

    if (start != null) {
      args.add(JSNumber.create(context, start));
    }

    if (end != null) {
      args.add(JSNumber.create(context, end));
    }

    final result = slice.call(args, this) as JSString;

    for (final item in args) {
      item.free();
    }

    slice.free();

    return result;
  }

  JSString concat(List<String> list) {
    final concat = getPropertyStr<JSFunction>('concat')!;
    final List<JSString> args =
        list.map((item) => JSString.create(context, item)).toList();
    final result = concat.call(args, this) as JSString;

    for (final item in args) {
      item.free();
    }

    concat.free();

    return result;
  }
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

  static bool isArray(Runtime runtime, JSObject data) {
    final value = library.isArray(runtime.context, data.pointer);
    return value == 1;
  }

  int get length {
    final data = getPropertyStr<JSNumber>('length');
    return data!.value;
  }

  T index<T extends JSObject>(int index) {
    final key = JSNumber.create(context, index);
    key.freeAsync();
    return getProperty<T>(key)!;
  }

  bool push(JSObject value) => set(length, value);

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

  JSObject shift() {
    final shift = getPropertyStr<JSFunction>('shift')!;

    shift.freeAsync();

    return shift.call(null, this);
  }

  JSNumber unshift(List<JSObject> args) {
    final unshift = getPropertyStr<JSFunction>('unshift')!;

    unshift.freeAsync();

    return unshift.call(args, this) as JSNumber;
  }

  JSObject pop() {
    final pop = getPropertyStr<JSFunction>('pop')!;

    pop.freeAsync();

    return pop.call(null, this);
  }

  JSArray splice(int index, [int? howmany, List<JSObject>? value]) {
    final splice = getPropertyStr<JSFunction>('splice')!;
    final List<JSObject> args = [];

    args.add(JSNumber.create(context, index));

    if (howmany != null) {
      args.add(JSNumber.create(context, howmany));
    }

    args.addAll(value ?? <JSObject>[]);

    final result = splice.call(args, this) as JSArray;

    for (final item in args) {
      item.free();
    }

    splice.free();

    return result;
  }

  JSString join(String separator) {
    final join = getPropertyStr<JSFunction>('join')!;
    final args = JSString.create(context, separator);
    final result = join.call([], this) as JSString;

    args.free();
    join.free();

    return result;
  }

  JSArray slice([int? start, int? end]) {
    final slice = getPropertyStr<JSFunction>('slice')!;
    final List<JSNumber> args = [];

    if (start != null) {
      args.add(JSNumber.create(context, start));
    }

    if (end != null) {
      args.add(JSNumber.create(context, end));
    }

    final result = slice.call(args, this) as JSArray;

    for (final item in args) {
      item.free();
    }

    slice.free();

    return result;
  }

  JSArray concat(JSArray value) {
    final concat = getPropertyStr<JSFunction>('concat')!;
    concat.freeAsync();
    return concat.call([value], this) as JSArray;
  }

  JSNumber indexOf(JSObject value) {
    final indexOf = getPropertyStr<JSFunction>('indexOf')!;
    indexOf.freeAsync();
    return indexOf.call([value], this) as JSNumber;
  }

  JSNumber lastIndexOf(JSObject value) {
    final lastIndexOf = getPropertyStr<JSFunction>('lastIndexOf')!;
    lastIndexOf.freeAsync();
    return lastIndexOf.call([value], this) as JSNumber;
  }

  JSBool includes(JSObject value) {
    final includes = getPropertyStr<JSFunction>('includes')!;
    includes.freeAsync();
    return includes.call([value], this) as JSBool;
  }

  JSArray reverse() {
    final reverse = getPropertyStr<JSFunction>('reverse')!;
    reverse.freeAsync();
    return reverse.call(null, this) as JSArray;
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
    final runtime = Cache.instance.getRuntime(context);
    final symbol = callback.hashCode.toString().toNativeUtf8().cast<Char>();
    final pointer = library.newCFunctionData(context, symbol);

    malloc.free(symbol);
    // 订阅
    runtime.on(callback.hashCode.toString(), callback);

    return JSFunction(
      context,
      pointer,
      callback: callback,
    );
  }

  @override
  void free() {
    off();
    super.free();
  }

  @override
  void freeAsync() {
    Future(free);
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

  // 对象需要在适当的时候调用此方法解除订阅，以免造成内存泄漏
  void off() {
    final runtime = Cache.instance.getRuntime(context);
    final symbol = callback.hashCode.toString();
    runtime.off(symbol);
  }
}

class JSPromise extends JSObject {
  JSPromise(
    super.context,
    super.pointer, {
    Pointer<JSValue>? resolvePointer,
    Pointer<JSValue>? rejectPointer,
  })  : _resolvePointer = resolvePointer,
        _rejectPointer = rejectPointer,
        _runtime = Cache.instance.getRuntime(context);

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
  // 当前运行时
  final Runtime _runtime;

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
      _runtime.off(symbol);
      callback(value);
    });

    symbol = handler.callback.hashCode.toString();

    _runtime.on(symbol, handler.callback!);

    final func = getPropertyStr<JSFunction>('then')!;
    final value = func.call([handler], this);
    context.executePendingJob();
    return value as JSPromise;
  }

  JSPromise catchError(PromiseCallback callback) {
    // 回调标识
    late String symbol;

    final handler = JSFunction.create(context, ([JSObject? value]) {
      _runtime.off(symbol);
      callback(value);
    });

    symbol = handler.callback.hashCode.toString();

    _runtime.on(symbol, handler.callback!);

    final func = getPropertyStr<JSFunction>('catch')!;
    final value = func.call([handler], this);
    context.executePendingJob();
    return value as JSPromise;
  }
}

class JSRegExp extends JSObject {
  JSRegExp(super.context, super.pointer);

  factory JSRegExp.create(
    Pointer<JSContext> context,
    String pattern, [
    String? flags,
  ]) {
    final args = [JSString.create(context, pattern)];

    if (flags != null) {
      args.add(JSString.create(context, flags));
    }

    final global = library.getGlobalObject(context);
    final keyPointer = 'RegExp'.toNativeUtf8().cast<Char>();
    // 获取构造函数
    final constructor = library.getPropertyStr(context, global, keyPointer);
    // 执行构造函数
    final pointer = Common.callConstructor(context, constructor, args);

    malloc.free(keyPointer);
    library.freeValue(context, global);
    library.freeValue(context, constructor);

    return JSRegExp(context, pointer);
  }

  bool test(String value) {
    final test = getPropertyStr<JSFunction>('test')!;
    final args = JSString.create(context, value);
    final result = test.call([args], this) as JSBool;

    args.free();
    test.free();

    return result.value;
  }

  JSArray? exec(String value) {
    final exec = getPropertyStr<JSFunction>('exec')!;
    final args = JSString.create(context, value);
    final data = exec.call([args], this);

    args.free();
    exec.free();

    return data is JSArray ? data : null;
  }

  @override
  String get value => toString();
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
