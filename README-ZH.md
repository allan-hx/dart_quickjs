# dart_quickjs

[![Pub](https://img.shields.io/pub/v/dart_quickjs.svg)](https://pub.flutter-io.cn/packages/dart_quickjs)

Language: 简体中文 | [English](README.md)

```dart_quickjs```是一个使用```Dart```对```QuickJS```引擎的一个绑定，支持在```Android``` ```IOS```中执行```JavaScript```代码, ```QuickJS``` 是一款轻量级, 并支持ECMAScript 2019规范的```JavaScript```引擎

## 开始使用

### 添加依赖
```console
$ dart pub add dart_quickjs
```
如果需要指定版本可以在```pubspec.yaml```文件中添加

```console
dependencies:
  dart_quickjs: ^版本号
```
最新稳定版本：![Pub](https://img.shields.io/pub/v/dart_quickjs.svg)

## 示例
```println```为```dart_quickjs```注入的打印函数
```dart
import 'package:dart_quickjs/dart_quickjs.dart';

final runtime = Runtime();
const script = 'println("Hello World");';

runtime.evaluateJavaScript(script, 'main.js');
```

## 类型支持和映射
| Dart | JavasCript |
| - | - |
| JSObject | Object |
| JSString | String |
| JSNumber | Number |
| JSFloat | Number |
| Boolean | JSBool |
| JSArray | Array |
| JSFunction | Function |
| JSPromise | Promise |
| JSNull | null |
| JSUndefined | undefined |

## 注入对象
```dart
import 'package:dart_quickjs/dart_quickjs.dart';

final runtime = Runtime();
// 创建和注入对象
final value = JSString.create(runtime.context, 'dart_quickjs');
// 添加到全局对象
runtime.global.setPropertyStr('name', value);
// 打印name
runtime.evaluateJavaScript('println(name);', 'main.js');
```

## 注入方法
```dart
import 'package:dart_quickjs/dart_quickjs.dart';

final runtime = Runtime();
// 创建方法
final value = JSFunction.create(runtime.context, (JSNumber data) {
  return JSNumber.create(runtime.context, data.value + 1);
});
// 添加到全局对象
runtime.global.setPropertyStr('add', value);
// 执行代码
runtime.evaluateJavaScript('println(add(1));', 'main.js');
```

## 通信
```JavaScript```调用```dart```
```dart
import 'package:dart_quickjs/dart_quickjs.dart';

final runtime = Runtime();
// 创建方法
final value = JSFunction.create(runtime.context, (JSString message) {
  print('JavaScriptMessage: ${message.value}');
});
// 添加到全局对象
runtime.global.setPropertyStr('test', value);
// 执行代码
runtime.evaluateJavaScript('test("dart_quickjs");', 'main.js');
```
```dart```调用```JavaScript```
```dart
import 'package:dart_quickjs/dart_quickjs.dart';

final runtime = Runtime();
// javascript代码
const code  = '''function message(value) {
  return value + 1;
}
message;''';
// 执行代码
final callback = runtime.evaluateJavaScript(code, 'main.js') as JSFunction;
// 调用javascript方法
final value = callback.call([JSNumber.create(runtime.context, 1)]);
// 打印返回值
print(value);
```
在通信中可以传递基础类型和函数类型
## module导入
- 使用模块系统时需要传递```moduleLoader```方法来加载模块
- 在运行入口时候运行模式需要设置成```JSEvalType.module```

```dart
import 'package:dart_quickjs/dart_quickjs.dart';

// 创建运行时
final runtime = Runtime(
  moduleLoader: (String name) {
    if (name == 'message') {
      return "export const message = 'dart_quickjs'";;
    }

    return '';
  },
);
// main.js
const main  = '''
  import { message } from 'message'
  println(message)
''';
// 执行代码
runtime.evaluateJavaScript(main, 'main.js', JSEvalType.module);
```
## 销毁和释放
```dart
import 'package:dart_quickjs/dart_quickjs.dart';

final runtime = Runtime();

// 释放运行时
runtime.destroy();
```
## 内置api方法
```println``` ```setInterval``` ```clearInterval``` ```setTimeout``` ```clearTimeout```
