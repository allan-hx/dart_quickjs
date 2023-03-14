import 'runtime.dart';

abstract class Plugin {
  void onCreate(Runtime runtime);

  void destroy(Runtime runtime) {}
}
