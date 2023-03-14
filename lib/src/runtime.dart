import 'dart:async';
import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'js_value.dart';
import 'library.dart';
import 'observer.dart';
import 'plugin.dart';
import 'plugins/println.dart';
import 'plugins/timer.dart';
import 'typedef.dart';
import 'extensions.dart';

final Map<int, Runtime> _runtimes = {};

class Runtime {
  Runtime({
    int? stackSize,
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
    // 日志打印
    Println(),
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
    // 方法标识
    final name = symbol.cast<Utf8>().toDartString();
    // 参数
    final List<JSObject> args = List.generate(argc, (index) {
      final ptr = argv.address + (jsValueSizeOf * index);
      final value = Pointer.fromAddress(ptr).cast<JSValue>();
      return value.toJSValue(context);
    });

    switch (name) {
      // 模块加载
      case 'module_loader':
        final pointer = library.getRuntime(context);
        final runtime = _runtimes[pointer.hashCode];
        final moduleName = (args.first as JSString).value;

        return runtime!._moduleLoader(moduleName);
      default:
        return Observer.instance.emit(name, args).pointer;
    }
  }

  void _init({
    // 栈大小
    int? stackSize,
    // 插件
    List<Plugin>? plugins,
  }) {
    // 记录当前运行时
    _runtimes[runtime.hashCode] = this;
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

    // 加载插件
    _plugins.addAll(plugins ?? <Plugin>[]);

    for (Plugin item in _plugins) {
      use(item);
    }
  }

  // 设置最大栈
  void setStackSize(int stackSize) {
    library.setMaxStackSize(runtime, stackSize);
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
    // 销毁插件
    for (Plugin item in _plugins) {
      item.destroy(this);
    }

    global.free();
    _runtimes.remove(runtime.hashCode);
    library.freeContext(context);
    library.freeRuntime(runtime);
  }
}
