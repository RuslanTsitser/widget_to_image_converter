#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#if _WIN32
#include <windows.h>
#else
#include <pthread.h>
#include <unistd.h>
#endif

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

// Convert RGBA image data to JPEG and save to file
FFI_PLUGIN_EXPORT char *convert_rgba_to_jpeg(const uint8_t *rgba_data,
                                             int width,
                                             int height,
                                             int quality,
                                             const char *output_path);

// Convert RGBA file to JPEG and save to file
FFI_PLUGIN_EXPORT char *convert_rgba_file_to_jpeg(const char *input_path,
                                                  int width,
                                                  int height,
                                                  int quality,
                                                  const char *output_path);
