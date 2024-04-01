#include "flutter_window.h"
#include <flutter/event_channel.h>
#include <flutter/event_sink.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>
#include <ShObjIdl_core.h>

#include <memory>

#include <optional>

#include "flutter/generated_plugin_registrant.h"
#include <variant>

static bool SetDesktopWallpaper(std::string wallpaper_file_path, std::int64_t fit_mode) {
    
    DESKTOP_WALLPAPER_POSITION fit_type = DESKTOP_WALLPAPER_POSITION::DWPOS_CENTER;

    switch (fit_mode)
    {
        case 0:
            fit_type = DESKTOP_WALLPAPER_POSITION::DWPOS_CENTER;
            break;
        case 1:
            fit_type = DESKTOP_WALLPAPER_POSITION::DWPOS_TILE;
            break;
        case 2:
            fit_type = DESKTOP_WALLPAPER_POSITION::DWPOS_STRETCH;
            break;
        case 3:
            fit_type = DESKTOP_WALLPAPER_POSITION::DWPOS_FIT;
            break;
        case 4:
            fit_type = DESKTOP_WALLPAPER_POSITION::DWPOS_FILL;
            break;
        case 5:
            fit_type = DESKTOP_WALLPAPER_POSITION::DWPOS_SPAN;
            break;
        default:
            fit_type = DESKTOP_WALLPAPER_POSITION::DWPOS_CENTER;
            break;
    }

    // Convert char* to wchar_t*
    int len = MultiByteToWideChar(CP_UTF8, 0, wallpaper_file_path.c_str(), -1, nullptr, 0);
    wchar_t* wallpaperPath = new wchar_t[len];
    MultiByteToWideChar(CP_UTF8, 0, wallpaper_file_path.c_str(), -1, wallpaperPath, len);

    // Setting desktop wallpaper
    HRESULT hr = CoInitialize(NULL);

    IDesktopWallpaper* pDesktopWallpaper = NULL;
    hr = CoCreateInstance(__uuidof(DesktopWallpaper), NULL, CLSCTX_ALL, IID_PPV_ARGS(&pDesktopWallpaper));

    bool success = false;

    if (SUCCEEDED(hr))
    {
        // pDesktopWallpaper->GetPosition(&fit_type);
        pDesktopWallpaper->SetPosition(fit_type);
        hr = pDesktopWallpaper->SetWallpaper(NULL, wallpaperPath);
        pDesktopWallpaper->Release();

        success = true;
    }

    CoUninitialize();

    delete[] wallpaperPath; // Clean up allocated memory

    return success;
}

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());

  flutter::MethodChannel<> channel(
      flutter_controller_->engine()->messenger(), "blissful_backdrop.native/wallpaper",
      &flutter::StandardMethodCodec::GetInstance());
  channel.SetMethodCallHandler(
      [](const flutter::MethodCall<>& call,
         std::unique_ptr<flutter::MethodResult<>> result) {
        if (call.method_name() == "setDesktopWallpaper") {
            const auto* arguments = std::get_if<flutter::EncodableMap>(call.arguments());
            auto file_path_it = arguments->find(flutter::EncodableValue("filePath"));
            auto fit_mode_it = arguments->find(flutter::EncodableValue("fitMode"));
            std::string file_path = std::get<std::string>(file_path_it->second);
            std::int64_t fit_mode = fit_mode_it->second.LongValue();
            bool success = SetDesktopWallpaper(file_path, fit_mode);
        if (success) {
          result->Success("Wallpaper set successfully.");
        } else {
          result->Error("UNAVAILABLE", "Something went wrong.");
        }
      } else {
        result->NotImplemented();
      }
      });

  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
