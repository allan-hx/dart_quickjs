import 'package:dart_quickjs/dart_quickjs.dart';

class Println extends Plugin {
  @override
  void onCreate(Runtime runtime) {
    final value = JSFunction.create(runtime.context, println);
    runtime.global.setPropertyStr('_println_', value);
  }

  void println(JSString type, JSArray args) {
    if (args.length > 0) {
      final tag = type.toString();
      final message = args.toString();

      // ignore: avoid_print
      print("console/$tag: $message");
    }
  }
}
