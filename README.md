# dart_quickjs

[![Pub](https://img.shields.io/pub/v/dart_quickjs.svg)](https://pub.flutter-io.cn/packages/dart_quickjs)

Language: English | [简体中文](README-ZH.md)

```dart_quickjs``` is a binding for the ```QuickJS``` engine using Dart, which supports executing JavaScript code on ```Android``` and ```iOS```. QuickJS is a lightweight JavaScript engine that supports the ECMAScript 2019 specification.

## Get started

### Add dependency
```console
$ dart pub add dart_quickjs
```
If you need to specify a version, you can add it to the ```pubspec.yaml``` file.

```console
dependencies:
  dart_quickjs: ^Version number
```
Latest stable version：![Pub](https://img.shields.io/pub/v/dart_quickjs.svg)

## Example
```println``` is the print function injected by ```dart_quickjs```.
```dart
import 'package:dart_quickjs/dart_quickjs.dart';

final runtime = Runtime();
const script = 'println("Hello World");';

runtime.evaluateJavaScript(script, 'main.js');
```

## Type support and mapping
| Dart | JavasCript |
| - | - |
| JSObject | Object |
| JSString | String |
| JSNumber | Number |
| JSFloat | Number |
| JSBool | Boolean |
| JSArray | Array |
| JSFunction | Function |
| JSPromise | Promise |
| JSNull | null |
| JSUndefined | undefined |

## Injecting objects
```dart
import 'package:dart_quickjs/dart_quickjs.dart';

final runtime = Runtime();
// Creating and injecting objects
final value = JSString.create(runtime.context, 'dart_quickjs');
// Add to global objects
runtime.global.setPropertyStr('name', value);
// Print name
runtime.evaluateJavaScript('println(name);', 'main.js');
```

## Injecting methods
```dart
import 'package:dart_quickjs/dart_quickjs.dart';

final runtime = Runtime();
// Creating methods
final value = JSFunction.create(runtime.context, (JSNumber data) {
  return JSNumber.create(runtime.context, data.value + 1);
});
// Add to global objects
runtime.global.setPropertyStr('add', value);
// Execute code
runtime.evaluateJavaScript('println(add(1));', 'main.js');
```

## 通信
Calling ```Dart``` from ```JavaScript```
```dart
import 'package:dart_quickjs/dart_quickjs.dart';

final runtime = Runtime();
// Creating methods
final value = JSFunction.create(runtime.context, (JSString message) {
  print('JavaScriptMessage: ${message.value}');
});
// Add to global objects
runtime.global.setPropertyStr('test', value);
// Execute code
runtime.evaluateJavaScript('test("dart_quickjs");', 'main.js');
```
Calling ```JavaScript``` from ```Dart```
```dart
import 'package:dart_quickjs/dart_quickjs.dart';

final runtime = Runtime();
// JavaScript code
const code  = '''function message(value) {
  return value + 1;
}
message;''';
// Execute code
final callback = runtime.evaluateJavaScript(code, 'main.js') as JSFunction;
// Calling JavaScript methods
final value = callback.call([JSNumber.create(runtime.context, 1)]);
// Print return value
print(value);
```
In communication, you can pass basic types and function types.
## Module import
- When using the module system, you need to pass the ```moduleLoader``` method to load modules.
- When running the entry point, the run mode needs to be set to ```JSEvalType.module```.

```dart
import 'package:dart_quickjs/dart_quickjs.dart';

final runtime = Runtime(
  moduleLoader: (String name) {
    if (name == 'message') {
      return "export const message = 'dart_quickjs'";
    }

    return '';
  },
);
// main.js
const main  = '''
  import { message } from 'message'
  println(message)
''';
// Execute code
runtime.evaluateJavaScript(main, 'main.js', JSEvalType.module);
```
## Destroy and release
```dart
import 'package:dart_quickjs/dart_quickjs.dart';

final runtime = Runtime();

runtime.destroy();
```

## Built-in API methods
```println``` ```setInterval``` ```clearInterval``` ```setTimeout``` ```clearTimeout```

This document was translated using ChatGPT. 🎉
