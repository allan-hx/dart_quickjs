import 'package:flutter/material.dart';
import 'package:dart_quickjs/dart_quickjs.dart';

void main(List<String> args) {
  runApp(const App());
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

  final runtime = Runtime();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 执行
            ElevatedButton(
              onPressed: () {
                // 执行代码，打印name
                runtime.evaluateJavaScript('println("Hello World");', 'main.js');
              },
              child: const Text('Run'),
            ),
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
