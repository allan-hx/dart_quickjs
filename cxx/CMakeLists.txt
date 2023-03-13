cmake_minimum_required(VERSION 3.7 FATAL_ERROR)
set(LIB_DIR ${CMAKE_CURRENT_LIST_DIR})

# quickjs
set(QUICK_JS_LIB_DIR ${LIB_DIR}/quickjs)
file (STRINGS "${QUICK_JS_LIB_DIR}/VERSION" QUICKJS_VERSION)
add_library(quickjs_lib STATIC
    ${QUICK_JS_LIB_DIR}/cutils.c
    ${QUICK_JS_LIB_DIR}/libregexp.c
    ${QUICK_JS_LIB_DIR}/libunicode.c
    ${QUICK_JS_LIB_DIR}/quickjs.c
)

project(quickjs_lib LANGUAGES C)
target_compile_options(quickjs_lib PRIVATE "-DCONFIG_VERSION=\"${QUICKJS_VERSION}\"")
target_compile_options(quickjs_lib PRIVATE "-DDUMP_LEAKS")
