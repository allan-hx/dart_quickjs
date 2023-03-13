import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  final runtime = Runtime(moduleLoader: (String name) {
    return "export const info = {name: 'Allan'};";
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final script = await rootBundle.loadString('assets/main.js');
            runtime.evaluateJavaScript(script, 'main.js', JSEvalType.module);
            // promise.then((value) {
            //   print(value);
            //   return null;
            // }).catchError((value) {
            //   print(value);
            // });
          },
          child: const Text('Run'),
        ),
      ),
    );
  }
}
