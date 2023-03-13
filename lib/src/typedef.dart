import 'dart:ffi';

// 运行时
class JSRuntime extends Opaque {}

// 上下文
class JSContext extends Opaque {}

// 通道回调
typedef ChannelCallback = Pointer<JSValue> Function(
  Pointer<JSContext>,
  Pointer<Char>,
  Int32,
  Pointer<JSValue>,
);

// 通道方法
typedef Channel = NativeFunction<ChannelCallback>;

// 模块加载
typedef ModuleLoader = String Function(String name);

// js对象
class JSValue extends Struct {
  external JSValueUnion u;

  @Int64()
  external int tag;
}

class JSValueUnion extends Union {
  @Int32()
  external int int32;

  @Double()
  external double float64;

  external Pointer<Void> ptr;
}

// js类型标签
class JSValueTag {
  static const first = -11;

  static const decimal = -11;

  static const bigInt = -10;

  static const bigFloat = -9;

  static const symbol = -8;

  static const string = -7;

  static const module = -3;

  static const bytecode = -2;

  static const object = -1;

  static const number = 0;

  static const bool = 1;

  static const nullptr = 2;

  static const undefined = 3;

  static const uninitialized = 4;

  static const catchOffset = 5;

  static const exception = 6;

  static const float64 = 7;
}

enum JSEvalType {
  global(0),

  module(1),

  direct(2),

  indirect(3),

  mask(3);
 
  const JSEvalType(this.value);

  final int value;
}

// 属性flags
enum JSProp {
  configurable(1),

  writable(2),

  enumerable(4),

  cwe(7),

  length(8),

  tmask(48),

  normal(0),

  getset(16),

  varref(32),

  autoinit(48),

  hasShift(8),

  hasConfigurable(256),

  hasWritable(512),

  hasEnumerable(1024),

  hasGet(2048),

  hasSet(4096),

  hasValue(8192),

  cast(16384),

  throwStrict(32768),

  noAdd(65536),

  noExotic(131072);

  const JSProp(this.value);

  final int value;
}