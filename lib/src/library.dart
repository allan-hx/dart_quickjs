import 'dart:ffi';
import 'dart:io';
import 'bindings.dart';

final library = QuickjsLibrary(
  Platform.isAndroid
      ? DynamicLibrary.open('libquickjs.so')
      : DynamicLibrary.process(),
);
