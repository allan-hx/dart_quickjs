import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dart_quickjs/dart_quickjs.dart';

void main(List<String> args) {
  runApp(const App());
}

class Test extends Plugin {
  late Runtime _runtime;

  @override
  void onCreate(Runtime runtime) {
    _runtime = runtime;
    runtime.global.setPropertyStr(
      'getMessage',
      JSFunction.create(runtime.context, test),
    );
  }

  JSString test(JSString data) {
    return JSString.create(_runtime.context, '${data.value} World');
  }

  @override
  void destroy(Runtime runtime) {}
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Home(),
    );
  }
}

class Home extends StatelessWidget {
  Home({Key? key}) : super(key: key);

  final runtime = Runtime(
    plugins: [
      Test(),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 执行字符串
            ElevatedButton(
              onPressed: () async {
                final script = await rootBundle.loadString('assets/main.js');
                // 执行字符串
                final int time = DateTime.now().millisecondsSinceEpoch;
                runtime.evaluateJavaScript(script, 'main.js');
                print(DateTime.now().millisecondsSinceEpoch - time);
              },
              child: const Text('Run Script'),
            ),
            const SizedBox(height: 20),
            // 执行字符串
            ElevatedButton(
              onPressed: () async {
                final data = await rootBundle.load('assets/main.bin');
                final bytecode = Uint8List.view(data.buffer);
                final int time = DateTime.now().millisecondsSinceEpoch;
                runtime.evaluateBytecode(bytecode);
                print(DateTime.now().millisecondsSinceEpoch - time);
              },
              child: const Text('Run Bytecode'),
            ),
            const SizedBox(height: 20),
            // 销毁
            ElevatedButton(
              onPressed: () async {
                runtime.destroy();
              },
              child: const Text('Destroy'),
            ),
          ],
        ),
      ),
    );
  }
}
