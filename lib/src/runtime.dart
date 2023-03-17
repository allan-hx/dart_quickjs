import 'dart:async';
import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'cache.dart';
import 'js_value.dart';
import 'library.dart';
import 'observer.dart';
import 'plugin.dart';
import 'plugins/timer.dart';
import 'typedef.dart';
import 'extensions.dart';

class Runtime extends Observer {
  Runtime({
    int? stackSize,
    int? memoryLimit,
    List<Plugin>? plugins,
    this.moduleLoader,
  }) : runtime = library.newRuntime() {
    _init(
      stackSize: stackSize,
      plugins: plugins,
    );
  }

  // 运行环境
  final Pointer<JSRuntime> runtime;
  // 模块加载
  final ModuleLoader? moduleLoader;

  // 上下文
  late Pointer<JSContext> _context;
  Pointer<JSContext> get context => _context;

  // js全局对象
  late JSObject _global;
  JSObject get global => _global;

  // 插件
  final List<Plugin> _plugins = [
    // 定时器
    SetTimeout(),
    // 计时器
    SetInterval(),
  ];

  // 通道
  static Pointer _channel(
    Pointer<JSContext> context,
    Pointer<Char> symbol,
    int argc,
    Pointer<JSValue> argv,
  ) {
    // 获取运行时
    final runtime = Cache.instance.getRuntime(context);
    // 方法标识
    final name = symbol.cast<Utf8>().toDartString();
    // 参数
    final List<JSObject> args = List.generate(argc, (index) {
      final ptr = argv.address + (jsValueSizeOf * index);
      final value = Pointer.fromAddress(ptr).cast<JSValue>();
      return value.toJSValue(context);
    });

    // 日志打印
    if (name == runtime._println.hashCode.toString()) {
      runtime._println(args);
      return undefined;
    }

    switch (name) {
      // 模块加载
      case 'module_loader':
        final moduleName = (args.first as JSString).value;

        return runtime._moduleLoader(moduleName);
      default:
        return runtime.emit(name, args).pointer;
    }
  }

  void _init({
    // 栈大小
    int? stackSize,
    // 内存限制
    int? memoryLimit,
    // 插件
    List<Plugin>? plugins,
  }) {
    // 记录当前运行时
    Cache.instance.saveRuntime(runtime, this);
    // 创建默认上下文
    _context = library.newContext(runtime);
    // 获取全局对象
    _global = JSObject(context, library.getGlobalObject(context));
    // 设置通道方法
    final channel = Pointer.fromFunction<ChannelCallback>(_channel);
    library.setChannel(runtime, channel);

    // 开始module
    if (moduleLoader != null) {
      library.enableModuleLoader(runtime);
    }

    // 设置栈大小
    if (stackSize != null) {
      library.setMaxStackSize(runtime, stackSize);
    }

    // 设置运行内存
    if (memoryLimit != null) {
      library.setMemoryLimit(runtime, memoryLimit);
    }

    // 加载插件
    _plugins.addAll(plugins ?? <Plugin>[]);

    // 日志打印方法
    global.setPropertyStr('println', JSFunction.create(context, _println));

    for (Plugin item in _plugins) {
      use(item);
    }
  }

  // 日志打印
  void _println(List<JSObject>? args) {
    if (args != null) {
      final messages = args.map((item) => item.toString()).toList();
      // ignore: avoid_print
      print('JS/println: ${messages.join(", ")}');
    }
  }

  // 设置最大栈
  void setStackSize(int stackSize) {
    library.setMaxStackSize(runtime, stackSize);
  }

  // 更新栈顶
  void updateStackTop() {
    library.updateStackTop(runtime);
  }

  // 执行脚本
  JSObject evaluateJavaScript(
    String script,
    String fileName, [
    JSEvalType mode = JSEvalType.global,
  ]) {
    final scriptPointer = script.toNativeUtf8().cast<Char>();
    final namePointer = fileName.toNativeUtf8().cast<Char>();
    final value = library.evaluateJavaScript(
      _context,
      scriptPointer,
      namePointer,
      mode.value,
    );

    malloc.free(scriptPointer);
    malloc.free(namePointer);

    // 判断是否异常
    if (value.isException) {
      final message = _context.exception;
      throw '$fileName执行异常:$message';
    }

    // 执行挂起的任务
    dispatch();

    return value.toJSValue(_context);
  }

  // 加载模块
  Pointer<Char> _moduleLoader(String name) {
    final script = moduleLoader!(name);
    final pointer = script.toNativeUtf8().cast<Char>();

    Timer.run(() {
      malloc.free(pointer);
    });

    return pointer;
  }

  // 开启任务循环 - 执行挂起的任务
  void dispatch() {
    context.executePendingJob();
  }

  // 加载插件
  void use(Plugin plugin) {
    plugin.onCreate(this);
  }

  // 销毁
  void destroy() {
    // 释放插件插件
    for (Plugin item in _plugins) {
      item.destroy(this);
    }

    // 清除事件订阅
    clear();
    // 清除运行时缓存
    Cache.instance.removeRuntime(runtime);
    // 释放全局对象
    global.free();
    library.freeContext(context);
    library.freeRuntime(runtime);
  }
}
