# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(widget_to_image_converter_library VERSION 0.0.1 LANGUAGES C)

add_library(widget_to_image_converter SHARED
  "widget_to_image_converter.c"
  "stb_image_write.h"
)

set_target_properties(widget_to_image_converter PROPERTIES
  PUBLIC_HEADER widget_to_image_converter.h
  OUTPUT_NAME "widget_to_image_converter"
)

target_compile_definitions(widget_to_image_converter PUBLIC DART_SHARED_LIB)

if (ANDROID)
  # Support Android 15 16k page size
  target_link_options(widget_to_image_converter PRIVATE "-Wl,-z,max-page-size=16384")
endif()
