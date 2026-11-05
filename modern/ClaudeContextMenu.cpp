// Windows 11 top-level context menu entry for Claude Code.
// Implements IExplorerCommand (folder and folder background) for a sparse
// MSIX package. Launches cmd.exe in the folder and runs claude.exe there.

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <shobjidl_core.h>
#include <shlobj.h>
#include <shlguid.h>
#include <shlwapi.h>
#include <servprov.h>
#include <combaseapi.h>
#include <new>
#include <string>
#include <vector>

#pragma comment(lib, "shlwapi.lib")
#pragma comment(lib, "shell32.lib")
#pragma comment(lib, "ole32.lib")
#pragma comment(lib, "uuid.lib")

// Must match the Clsid in AppxManifest.xml.
static const CLSID CLSID_OpenWithClaude =
    {0x29c98cf1, 0xffaf, 0x48d0, {0x81, 0x12, 0xac, 0x3a, 0xee, 0xef, 0x34, 0x89}};

static LONG g_objects = 0;
static LONG g_locks = 0;

static std::wstring ClaudeExePath() {
    wchar_t buf[MAX_PATH * 2];
    DWORD n = ExpandEnvironmentStringsW(L"%USERPROFILE%\\.local\\bin\\claude.exe", buf,
                                        ARRAYSIZE(buf));
    if (n == 0 || n > ARRAYSIZE(buf)) return L"";
    return buf;
}

static HRESULT LaunchClaude(const std::wstring& folder) {
    std::wstring exe = ClaudeExePath();
    if (exe.empty() || GetFileAttributesW(exe.c_str()) == INVALID_FILE_ATTRIBUTES)
        return HRESULT_FROM_WIN32(ERROR_FILE_NOT_FOUND);

    // Same quoting as the classic entry: cmd /k strips the outer quotes.
    std::wstring cmd = L"cmd.exe /d /k \"cd /d \"" + folder + L"\" && \"" + exe + L"\"\"";
    std::vector<wchar_t> line(cmd.begin(), cmd.end());
    line.push_back(L'\0');

    STARTUPINFOW si{};
    si.cb = sizeof(si);
    PROCESS_INFORMATION pi{};
    if (!CreateProcessW(nullptr, line.data(), nullptr, nullptr, FALSE, CREATE_NEW_CONSOLE,
                        nullptr, nullptr, &si, &pi))
        return HRESULT_FROM_WIN32(GetLastError());
    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
    return S_OK;
}

// Folder path of the window that owns the background menu.
static HRESULT FolderFromSite(IUnknown* site, std::wstring& out) {
    if (!site) return E_FAIL;

    IServiceProvider* sp = nullptr;
    HRESULT hr = site->QueryInterface(IID_PPV_ARGS(&sp));
    if (FAILED(hr)) return hr;

    IShellBrowser* browser = nullptr;
    hr = sp->QueryService(SID_STopLevelBrowser, IID_PPV_ARGS(&browser));
    sp->Release();
    if (FAILED(hr)) return hr;

    IShellView* view = nullptr;
    hr = browser->QueryActiveShellView(&view);
    browser->Release();
    if (FAILED(hr)) return hr;

    IFolderView* folderView = nullptr;
    hr = view->QueryInterface(IID_PPV_ARGS(&folderView));
    view->Release();
    if (FAILED(hr)) return hr;

    IPersistFolder2* persist = nullptr;
    hr = folderView->GetFolder(IID_PPV_ARGS(&persist));
    folderView->Release();
    if (FAILED(hr)) return hr;

    LPITEMIDLIST pidl = nullptr;
    hr = persist->GetCurFolder(&pidl);
    persist->Release();
    if (FAILED(hr)) return hr;

    wchar_t path[MAX_PATH];
    if (SHGetPathFromIDListW(pidl, path)) {
        out = path;
        hr = S_OK;
    } else {
        hr = E_FAIL;
    }
    CoTaskMemFree(pidl);
    return hr;
}

class OpenWithClaude final : public IExplorerCommand, public IObjectWithSite {
public:
    OpenWithClaude() { InterlockedIncrement(&g_objects); }
    ~OpenWithClaude() {
        if (site_) site_->Release();
        InterlockedDecrement(&g_objects);
    }

    // IUnknown
    STDMETHODIMP QueryInterface(REFIID riid, void** ppv) override {
        if (!ppv) return E_POINTER;
        if (IsEqualIID(riid, IID_IUnknown) || IsEqualIID(riid, IID_IExplorerCommand)) {
            *ppv = static_cast<IExplorerCommand*>(this);
        } else if (IsEqualIID(riid, IID_IObjectWithSite)) {
            *ppv = static_cast<IObjectWithSite*>(this);
        } else {
            *ppv = nullptr;
            return E_NOINTERFACE;
        }
        AddRef();
        return S_OK;
    }
    STDMETHODIMP_(ULONG) AddRef() override { return InterlockedIncrement(&ref_); }
    STDMETHODIMP_(ULONG) Release() override {
        LONG r = InterlockedDecrement(&ref_);
        if (r == 0) delete this;
        return r;
    }

    // IExplorerCommand
    STDMETHODIMP GetTitle(IShellItemArray*, LPWSTR* name) override {
        return SHStrDupW(L"Open with Claude", name);
    }
    STDMETHODIMP GetIcon(IShellItemArray*, LPWSTR* icon) override {
        HMODULE self = nullptr;
        wchar_t dll[MAX_PATH];
        if (GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS |
                               GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                               reinterpret_cast<LPCWSTR>(&GetModuleHandleExW), &self) &&
            GetModuleFileNameW(self, dll, ARRAYSIZE(dll))) {
            std::wstring p = dll;
            size_t slash = p.find_last_of(L"\\/");
            if (slash != std::wstring::npos) {
                std::wstring ico = p.substr(0, slash + 1) + L"Assets\\claude.ico";
                if (GetFileAttributesW(ico.c_str()) != INVALID_FILE_ATTRIBUTES)
                    return SHStrDupW(ico.c_str(), icon);
            }
        }
        std::wstring exe = ClaudeExePath();
        if (exe.empty()) return E_FAIL;
        return SHStrDupW((exe + L",0").c_str(), icon);
    }
    STDMETHODIMP GetToolTip(IShellItemArray*, LPWSTR*) override { return E_NOTIMPL; }
    STDMETHODIMP GetCanonicalName(GUID* name) override {
        *name = CLSID_OpenWithClaude;
        return S_OK;
    }
    STDMETHODIMP GetState(IShellItemArray*, BOOL, EXPCMDSTATE* state) override {
        *state = ECS_ENABLED;
        return S_OK;
    }
    STDMETHODIMP Invoke(IShellItemArray* items, IBindCtx*) override {
        std::wstring folder;
        if (items) {
            DWORD count = 0;
            items->GetCount(&count);
            if (count >= 1) {
                IShellItem* item = nullptr;
                if (SUCCEEDED(items->GetItemAt(0, &item))) {
                    LPWSTR path = nullptr;
                    if (SUCCEEDED(item->GetDisplayName(SIGDN_FILESYSPATH, &path))) {
                        folder = path;
                        CoTaskMemFree(path);
                    }
                    item->Release();
                }
            }
        }
        if (folder.empty()) {
            HRESULT hr = FolderFromSite(site_, folder);
            if (FAILED(hr)) return hr;
        }
        return LaunchClaude(folder);
    }
    STDMETHODIMP GetFlags(EXPCMDFLAGS* flags) override {
        *flags = ECF_DEFAULT;
        return S_OK;
    }
    STDMETHODIMP EnumSubCommands(IEnumExplorerCommand** commands) override {
        if (commands) *commands = nullptr;
        return E_NOTIMPL;
    }

    // IObjectWithSite
    STDMETHODIMP SetSite(IUnknown* site) override {
        if (site_) site_->Release();
        site_ = site;
        if (site_) site_->AddRef();
        return S_OK;
    }
    STDMETHODIMP GetSite(REFIID riid, void** ppv) override {
        if (!ppv) return E_POINTER;
        if (!site_) {
            *ppv = nullptr;
            return E_FAIL;
        }
        return site_->QueryInterface(riid, ppv);
    }

private:
    LONG ref_ = 1;
    IUnknown* site_ = nullptr;
};

class ClassFactory final : public IClassFactory {
public:
    // IUnknown
    STDMETHODIMP QueryInterface(REFIID riid, void** ppv) override {
        if (!ppv) return E_POINTER;
        if (IsEqualIID(riid, IID_IUnknown) || IsEqualIID(riid, IID_IClassFactory)) {
            *ppv = static_cast<IClassFactory*>(this);
            AddRef();
            return S_OK;
        }
        *ppv = nullptr;
        return E_NOINTERFACE;
    }
    STDMETHODIMP_(ULONG) AddRef() override { return InterlockedIncrement(&ref_); }
    STDMETHODIMP_(ULONG) Release() override {
        LONG r = InterlockedDecrement(&ref_);
        if (r == 0) delete this;
        return r;
    }

    // IClassFactory
    STDMETHODIMP CreateInstance(IUnknown* outer, REFIID riid, void** ppv) override {
        if (outer) return CLASS_E_NOAGGREGATION;
        OpenWithClaude* cmd = new (std::nothrow) OpenWithClaude();
        if (!cmd) return E_OUTOFMEMORY;
        HRESULT hr = cmd->QueryInterface(riid, ppv);
        cmd->Release();
        return hr;
    }
    STDMETHODIMP LockServer(BOOL lock) override {
        if (lock) InterlockedIncrement(&g_locks);
        else InterlockedDecrement(&g_locks);
        return S_OK;
    }

private:
    LONG ref_ = 1;
};

STDAPI DllGetClassObject(REFCLSID clsid, REFIID riid, LPVOID* ppv) {
    if (!IsEqualCLSID(clsid, CLSID_OpenWithClaude)) return CLASS_E_CLASSNOTAVAILABLE;
    ClassFactory* factory = new (std::nothrow) ClassFactory();
    if (!factory) return E_OUTOFMEMORY;
    HRESULT hr = factory->QueryInterface(riid, ppv);
    factory->Release();
    return hr;
}

STDAPI DllCanUnloadNow() {
    return (g_objects == 0 && g_locks == 0) ? S_OK : S_FALSE;
}
