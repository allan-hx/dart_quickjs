#include "quickjs/quickjs.h"
#include <string.h>

#ifdef _MSC_VER
#define DART_EXPORT __declspec(dllexport)
#else
#define DART_EXPORT __attribute__((visibility("default"))) __attribute__((used))
#endif

// 通道
typedef JSValue *CHANNEL(JSContext *ctx, const char *symbol, int32_t argc, JSValueConst *argv);

extern "C" {
  // 设置通道
  DART_EXPORT void SetChannel(JSRuntime *runtime, CHANNEL channel);

  // 启用模块加载
  DART_EXPORT void EnableModuleLoader(JSRuntime *runtime);

  // 获取全局对象
  DART_EXPORT JSValue *GetGlobalObject(JSContext *ctx);

  // 执行js代码
  DART_EXPORT JSValue *EvaluateJavaScript(JSContext *ctx, const char *script, const char *fileName, int32_t flags);

  // 获取js value的大小
  DART_EXPORT uint32_t JSValueSizeOf();

  // 根据下标设置value
  DART_EXPORT void SetValueAt(JSValue *data, uint32_t index, JSValue *value);

  // 获取异常
  DART_EXPORT JSValue *GetException(JSContext *ctx);

  // 执行挂起任务
  DART_EXPORT int32_t ExecutePendingJob(JSRuntime *runtime);

  // 创建对象
  DART_EXPORT JSValue *NewObject(JSContext  *ctx);

  // 创建字符串
  DART_EXPORT JSValue *NewString(JSContext *ctx, const char *data);

  // 创建int64
  DART_EXPORT JSValue *NewInt64(JSContext *ctx, int64_t value);

  // 创建float64
  DART_EXPORT JSValue *NewFloat64(JSContext *ctx, double value);

  // 创建bool
  DART_EXPORT JSValue *NewBool(JSContext *ctx, int32_t value);

  // 创建数组
  DART_EXPORT JSValue *NewArray(JSContext *ctx);

  // 创建promise
  DART_EXPORT JSValue *NewPromiseCapability(JSContext *ctx, JSValue *resolving_funcs);

  // 创建js方法
  DART_EXPORT JSValue *NewCFunctionData(JSContext *ctx, const char *symbol);

  // 创建null
  DART_EXPORT JSValue *NewNull();

  // 创建undefined
  DART_EXPORT JSValue *NewUndefined();

  // 添加属性 - key为string类型
  DART_EXPORT int32_t SetPropertyStr(JSContext *ctx, JSValueConst *obj, const char *key, JSValue *value);

  // 添加属性 - key为js value
  DART_EXPORT int32_t SetProperty(JSContext *ctx, JSValueConst *obj, JSValueConst *key, JSValueConst *value, int flags);

  // 添加属性 - key为uint32
  DART_EXPORT int DefinePropertyValueUint32(JSContext *ctx, JSValueConst *obj, uint32_t index, JSValue *value, int32_t flags);

  // 读取属性 - key为string类型
  JSValue *GetPropertyStr(JSContext *ctx, JSValueConst *obj, const char *prop);

  // 读取属性 - key为js value
  DART_EXPORT JSValue *GetProperty(JSContext *ctx, JSValueConst *obj, JSValueConst *key);

  // 增加引用标记
  DART_EXPORT JSValue *JSDupValue(JSContext *ctx, JSValueConst *value);

  // 释放js value
  DART_EXPORT void JSFreeValue(JSContext *ctx, JSValue *value);

  // 释放运行时
  DART_EXPORT void FreeRuntime(JSRuntime *runtime);

  // js value转string
  DART_EXPORT const char *JSToCString(JSContext *ctx, JSValueConst *value);

  // 转int 64
  DART_EXPORT int64_t JSToInt64(JSContext *ctx, JSValueConst *value);

  // 转Float 64
  DART_EXPORT double JSToFloat64(JSContext *ctx, JSValueConst *value);

  // 转布尔值
  DART_EXPORT int32_t JSToBool(JSContext *ctx, JSValueConst *value);

  // 调用js方法
  DART_EXPORT JSValue *CallFuncton(JSContext *ctx, JSValueConst *func_obj, JSValueConst *this_obj, int32_t argc, JSValueConst *argv);

  // 是否是数组
  DART_EXPORT int32_t IsArray(JSContext *ctx, JSValueConst *value);

  // 是否是函数
  DART_EXPORT int32_t IsFunction(JSContext *ctx, JSValueConst *value);

  // 是否是promise
  DART_EXPORT int32_t IsPromise(JSContext *ctx, JSValueConst *value);
}
