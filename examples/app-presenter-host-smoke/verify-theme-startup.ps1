$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path

function Find-SampleExe {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ExampleRoot
    )

    $match = Get-ChildItem (Join-Path $ExampleRoot "target") -Recurse -Filter "app-presenter-host-smoke.exe" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($null -eq $match) {
        return $null
    }

    return $match.FullName
}

$exe = Find-SampleExe -ExampleRoot $root

if ($null -eq $exe) {
    Push-Location $root
    try {
        & runa build | Out-Null
    }
    finally {
        Pop-Location
    }

    $exe = Find-SampleExe -ExampleRoot $root
}

if ($null -eq $exe) {
    throw "sample executable was not built under $root\\target"
}

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Text;

public static class PresenterHostVerify {
  public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

  [DllImport("user32.dll")]
  public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

  [DllImport("user32.dll", CharSet = CharSet.Unicode)]
  public static extern int GetWindowTextW(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

  [DllImport("user32.dll")]
  public static extern bool IsWindowVisible(IntPtr hWnd);

  [DllImport("user32.dll")]
  public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);

  [DllImport("dwmapi.dll")]
  public static extern int DwmGetWindowAttribute(IntPtr hwnd, uint dwAttribute, out int pvAttribute, uint cbAttribute);
}
'@

function Get-SystemThemeName {
    $value = Get-ItemPropertyValue -Path "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize" -Name "AppsUseLightTheme"
    if ($value -eq 0) {
        return "Dark"
    }
    return "Light"
}

function Find-PresenterHostWindow {
    param(
        [Parameter(Mandatory = $true)]
        [System.Diagnostics.Process]$Process
    )

    $script:match = $null
    [PresenterHostVerify]::EnumWindows({
        param($hWnd, $lParam)

        [uint32]$windowProcessId = 0
        [PresenterHostVerify]::GetWindowThreadProcessId($hWnd, [ref]$windowProcessId) | Out-Null

        if ($windowProcessId -ne [uint32]$Process.Id) {
            return $true
        }

        if (-not [PresenterHostVerify]::IsWindowVisible($hWnd)) {
            return $true
        }

        $title = New-Object System.Text.StringBuilder 512
        [PresenterHostVerify]::GetWindowTextW($hWnd, $title, $title.Capacity) | Out-Null
        $text = $title.ToString()

        if ($text.StartsWith("Presenter Host |")) {
            $script:match = [pscustomobject]@{
                HWnd = $hWnd
                Title = $text
            }
            return $false
        }

        return $true
    }, [IntPtr]::Zero) | Out-Null

    return $script:match
}

$process = Start-Process -FilePath $exe -PassThru

try {
    $visibleWindow = $null
    $attempt = 0

    while ($attempt -lt 40) {
        Start-Sleep -Milliseconds 100

        if ($process.HasExited) {
            throw "sample exited early with code $($process.ExitCode)"
        }

        $visibleWindow = Find-PresenterHostWindow -Process $process
        if ($null -ne $visibleWindow) {
            break
        }

        $attempt = $attempt + 1
    }

    if ($null -eq $visibleWindow) {
        throw "presenter-host window did not become visible"
    }

    $expectedTheme = Get-SystemThemeName
    $expectedDarkFlag = 0
    if ($expectedTheme -eq "Dark") {
        $expectedDarkFlag = 1
    }

    [int]$darkFlag = 0
    $status = [PresenterHostVerify]::DwmGetWindowAttribute($visibleWindow.HWnd, 20, [ref]$darkFlag, 4)
    if ($status -ne 0) {
        throw "DwmGetWindowAttribute(20) failed with status $status"
    }

    if ($visibleWindow.Title.Contains("Theme:Unknown")) {
        throw "sample reported unknown applied theme at startup: $($visibleWindow.Title)"
    }

    if ($visibleWindow.Title.Contains("Target:Missing")) {
        throw "sample presenter target was missing at startup: $($visibleWindow.Title)"
    }

    if ($darkFlag -ne $expectedDarkFlag) {
        throw "startup dark-mode attribute mismatch: expected $expectedDarkFlag for $expectedTheme, got $darkFlag"
    }

    Write-Output "startup theme verified"
    Write-Output "title: $($visibleWindow.Title)"
    Write-Output "dark_mode_attribute: $darkFlag"
}
finally {
    if (!$process.HasExited) {
        Stop-Process -Id $process.Id -Force
    }
}
