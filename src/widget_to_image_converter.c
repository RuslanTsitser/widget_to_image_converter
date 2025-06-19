#include "widget_to_image_converter.h"
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"
#include <stdlib.h>
#include <string.h>
#include <time.h>

// A very short-lived native function.
//
// For very short-lived functions, it is fine to call them on the main isolate.
// They will block the Dart execution while running the native function, so
// only do this for native functions which are guaranteed to be short-lived.
FFI_PLUGIN_EXPORT int sum(int a, int b) { return a + b; }

// A longer-lived native function, which occupies the thread calling it.
//
// Do not call these kind of native functions in the main isolate. They will
// block Dart execution. This will cause dropped frames in Flutter applications.
// Instead, call these native functions on a separate isolate.
FFI_PLUGIN_EXPORT int sum_long_running(int a, int b)
{
  // Simulate work.
#if _WIN32
  Sleep(5000);
#else
  usleep(5000 * 1000);
#endif
  return a + b;
}

// Convert RGBA image data to JPEG and save to file
FFI_PLUGIN_EXPORT char *convert_rgba_to_jpeg(const uint8_t *rgba_data,
                                             int width,
                                             int height,
                                             int quality,
                                             const char *output_path)
{
  if (!rgba_data || width <= 0 || height <= 0 || quality < 1 || quality > 100 || !output_path)
  {
    return NULL;
  }

  // Generate unique filename if output_path is a directory
  char final_path[1024];
  if (strlen(output_path) == 0 || output_path[strlen(output_path) - 1] == '/' ||
      output_path[strlen(output_path) - 1] == '\\')
  {
    // Generate timestamp-based filename
    time_t now = time(NULL);
    struct tm *t = localtime(&now);
    snprintf(final_path, sizeof(final_path), "%simage_%04d%02d%02d_%02d%02d%02d.jpg",
             output_path, t->tm_year + 1900, t->tm_mon + 1, t->tm_mday,
             t->tm_hour, t->tm_min, t->tm_sec);
  }
  else
  {
    strncpy(final_path, output_path, sizeof(final_path) - 1);
    final_path[sizeof(final_path) - 1] = '\0';
  }

  // Convert RGBA to RGB (stb_image_write expects RGB)
  int rgb_size = width * height * 3;
  uint8_t *rgb_data = malloc(rgb_size);
  if (!rgb_data)
    return NULL;

  for (int i = 0; i < width * height; i++)
  {
    rgb_data[i * 3] = rgba_data[i * 4];         // R
    rgb_data[i * 3 + 1] = rgba_data[i * 4 + 1]; // G
    rgb_data[i * 3 + 2] = rgba_data[i * 4 + 2]; // B
  }

  // Write JPEG file
  int success = stbi_write_jpg(final_path, width, height, 3, rgb_data, quality);
  free(rgb_data);

  if (!success)
    return NULL;

  // Return allocated copy of the path
  char *result = malloc(strlen(final_path) + 1);
  if (result)
  {
    strcpy(result, final_path);
  }

  return result;
}
