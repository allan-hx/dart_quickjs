#import "DartQuickjsPlugin.h"
#if __has_include(<dart_quickjs/dart_quickjs-Swift.h>)
#import <dart_quickjs/dart_quickjs-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "dart_quickjs-Swift.h"
#endif

@implementation DartQuickjsPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftDartQuickjsPlugin registerWithRegistrar:registrar];
}
@end
