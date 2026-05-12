#include <windows.h>
#include <shellapi.h>
#include <string>
#include <cwctype>

std::wstring ToWslPath(std::wstring winPath) {
    for (auto& c : winPath) { if (c == L'\\') c = L'/'; }
    if (winPath.length() >= 2 && winPath[1] == L':') {
        wchar_t drive = towlower(winPath[0]);
        winPath = L"/mnt/" + std::wstring(1, drive) + winPath.substr(2);
    } else if (winPath.find(L"//wsl.localhost/") == 0 || winPath.find(L"//wsl$/") == 0) {
        size_t firstSlash = winPath.find(L'/', 2);
        if (firstSlash != std::wstring::npos) {
            size_t secondSlash = winPath.find(L'/', firstSlash + 1);
            if (secondSlash != std::wstring::npos) winPath = winPath.substr(secondSlash);
        }
    }
    return winPath;
}

int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PWSTR pCmdLine, int nCmdShow) {
    int argc;
    LPWSTR* argv = CommandLineToArgvW(GetCommandLineW(), &argc);
    
    // INJECTED FLAG HERE: --maximized (or change to --fullscreen)
    // Neovide's winit backend will respect this and skip the minimized state.
    std::wstring params = L"--maximized --wsl --";
    
    if (argv != NULL) {
        for (int i = 1; i < argc; ++i) {
            params += L" \"";
            params += ToWslPath(argv[i]);
            params += L"\"";
        }
        LocalFree(argv);
    }

    // We pass SW_SHOW to cleanly ask the OS to display the window,
    // but Neovide's internal flags will dictate the final dimensions.
    ShellExecuteW(NULL, L"open", L"neovide.exe", params.c_str(), NULL, SW_SHOW);
    
    return 0;
}
