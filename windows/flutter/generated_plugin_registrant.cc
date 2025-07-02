//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <screen_capturer_windows/screen_capturer_windows_plugin_c_api.h>
#include <window_size/window_size_plugin.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  ScreenCapturerWindowsPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("ScreenCapturerWindowsPluginCApi"));
  WindowSizePluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("WindowSizePlugin"));
}
