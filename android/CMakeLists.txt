cmake_minimum_required(VERSION 3.6)

include("${CMAKE_CURRENT_SOURCE_DIR}/../cxx/CMakeLists.txt")

add_library(
  "quickjs"
  SHARED
  ${LIB_DIR}/ffi.cpp
)

find_library( # Sets the name of the path variable.
              log-lib

              # Specifies the name of the NDK library that
              # you want CMake to locate.
              log )

target_link_libraries(
  quickjs
  quickjs_lib
  ${log-lib}
)
