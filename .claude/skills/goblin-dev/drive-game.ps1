param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet("headless", "launch", "shot", "keys", "burst", "status", "stop")]
    [string]$Command,
    [Parameter(Position = 1)]
    [string]$Arg = "",
    [int]$Frames = 20,
    [int]$Count = 6,
    [int]$DelayMs = 40,
    [int]$KeyGapMs = 350
)

$Godot = if ($env:GODOT_EXE) { $env:GODOT_EXE } else { "C:\Users\RayPreston\Dev\Games\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe" }
$Project = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\project")).Path
$StateDir = Join-Path $env:TEMP "goblin-dev"
$PidFile = Join-Path $StateDir "pids.txt"
New-Item -ItemType Directory -Force $StateDir | Out-Null

# Virtual-key codes for the input map in project/project.godot (vi-keys movement).
$Keys = @{
    "n" = 0x4B; "ne" = 0x55; "e" = 0x4C; "se" = 0x4E
    "s" = 0x4A; "sw" = 0x42; "w" = 0x48; "nw" = 0x59
    "wait" = 0xBA; "enter" = 0x0D; "space" = 0x20
    "zoomin" = 0xBB; "zoomout" = 0xBD; "restart" = 0x52; "menu" = 0x43
    "inventory" = 0x49; "1" = 0x31; "2" = 0x32; "3" = 0x33; "4" = 0x34; "5" = 0x35; "6" = 0x36; "7" = 0x37; "8" = 0x38; "9" = 0x39
}

Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class GoblinWin32 {
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr hdc, uint f);
  [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
  [DllImport("user32.dll")] public static extern uint MapVirtualKey(uint c, uint t);
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
}
"@
# Without DPI awareness, capture is clipped to the scaled logical size (e.g. 1024x576 at 125%).
[GoblinWin32]::SetProcessDPIAware() | Out-Null

function Get-TrackedPids {
    if (-not (Test-Path $PidFile)) { return @() }
    return @(Get-Content $PidFile | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ })
}

function Get-GameWindow {
    foreach ($id in Get-TrackedPids) {
        $process = Get-Process -Id $id -ErrorAction SilentlyContinue
        if ($process -and $process.MainWindowTitle -like "*(DEBUG)*") { return $process.MainWindowHandle }
    }
    throw "No tracked game window. Run 'launch' first."
}

function Save-Shot([IntPtr]$Window, [string]$Path) {
    $rect = New-Object GoblinWin32+RECT
    [GoblinWin32]::GetClientRect($Window, [ref]$rect) | Out-Null
    $bitmap = New-Object System.Drawing.Bitmap ($rect.R - $rect.L), ($rect.B - $rect.T)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $hdc = $graphics.GetHdc()
    # 3 = PW_CLIENTONLY | PW_RENDERFULLCONTENT; the latter is required for GPU-rendered windows.
    [GoblinWin32]::PrintWindow($Window, $hdc, 3) | Out-Null
    $graphics.ReleaseHdc($hdc)
    $graphics.Dispose()
    $bitmap.Save($Path)
    $bitmap.Dispose()
    Write-Output "shot: $Path"
}

function Send-Key([IntPtr]$Window, [uint32]$VirtualKey) {
    # Godot binds physical keycodes, which Windows derives from the scan code in lParam.
    $scanCode = [GoblinWin32]::MapVirtualKey($VirtualKey, 0)
    $down = [IntPtr](1 -bor ($scanCode -shl 16))
    $up = [IntPtr]([long](1 -bor ($scanCode -shl 16) -bor (1 -shl 30)) -bor 0x80000000L)
    [GoblinWin32]::PostMessage($Window, 0x100, [IntPtr]$VirtualKey, $down) | Out-Null
    Start-Sleep -Milliseconds 60
    [GoblinWin32]::PostMessage($Window, 0x101, [IntPtr]$VirtualKey, $up) | Out-Null
}

function Resolve-KeySequence([string]$Sequence) {
    $resolved = @()
    foreach ($token in $Sequence.Split(",") | ForEach-Object { $_.Trim() } | Where-Object { $_ }) {
        $name, $times = $token.Split("*")
        if (-not $Keys.ContainsKey($name)) { throw "Unknown key '$name'. Known: $($Keys.Keys -join ', ')" }
        $repeat = if ($times) { [int]$times } else { 1 }
        for ($i = 0; $i -lt $repeat; $i++) { $resolved += $Keys[$name] }
    }
    return $resolved
}

function Default-ShotPath([string]$Name) {
    if ($Name) { return $Name }
    return Join-Path $StateDir ("shot-{0:HHmmss-fff}.png" -f (Get-Date))
}

switch ($Command) {
    "headless" {
        & $Godot --path $Project --headless --quit-after $Frames 2>&1 | ForEach-Object { "$_" }
    }
    "launch" {
        if (Get-TrackedPids | Where-Object { Get-Process -Id $_ -ErrorAction SilentlyContinue }) {
            throw "A tracked game is already running. Run 'stop' first."
        }
        $launcher = Start-Process -FilePath $Godot -ArgumentList @("--path", $Project) -PassThru `
            -RedirectStandardOutput (Join-Path $StateDir "stdout.log") `
            -RedirectStandardError (Join-Path $StateDir "stderr.log")
        $game = $null
        for ($i = 0; $i -lt 30 -and -not $game; $i++) {
            Start-Sleep -Milliseconds 500
            $children = Get-CimInstance Win32_Process -Filter "ParentProcessId=$($launcher.Id)"
            foreach ($child in $children) {
                $process = Get-Process -Id $child.ProcessId -ErrorAction SilentlyContinue
                if ($process -and $process.MainWindowTitle -like "*(DEBUG)*") { $game = $process }
            }
        }
        if (-not $game) { throw "Game window never appeared. Check $StateDir\stderr.log" }
        @($launcher.Id, $game.Id) | Set-Content $PidFile
        Write-Output "launched: launcher $($launcher.Id), game $($game.Id); logs in $StateDir"
    }
    "shot" {
        Save-Shot (Get-GameWindow) (Default-ShotPath $Arg)
    }
    "keys" {
        $window = Get-GameWindow
        foreach ($virtualKey in Resolve-KeySequence $Arg) {
            Send-Key $window $virtualKey
            Start-Sleep -Milliseconds $KeyGapMs
        }
        Write-Output "sent: $Arg"
    }
    "burst" {
        $window = Get-GameWindow
        $prefix = Join-Path $StateDir ("burst-{0:HHmmss}" -f (Get-Date))
        Send-Key $window (Resolve-KeySequence $Arg)[0]
        for ($i = 0; $i -lt $Count; $i++) {
            Save-Shot $window "$prefix-$i.png"
            Start-Sleep -Milliseconds $DelayMs
        }
    }
    "status" {
        foreach ($id in Get-TrackedPids) {
            $process = Get-Process -Id $id -ErrorAction SilentlyContinue
            if ($process) { Write-Output "running: $id $($process.ProcessName) '$($process.MainWindowTitle)'" }
            else { Write-Output "exited: $id" }
        }
        Write-Output "--- stdout (tail)"
        Get-Content (Join-Path $StateDir "stdout.log") -Tail 15 -ErrorAction SilentlyContinue
        Write-Output "--- stderr (tail)"
        Get-Content (Join-Path $StateDir "stderr.log") -Tail 15 -ErrorAction SilentlyContinue
    }
    "stop" {
        foreach ($id in Get-TrackedPids) {
            try { Stop-Process -Id $id -Force -ErrorAction Stop; Write-Output "stopped: $id" } catch { }
        }
        Remove-Item $PidFile -ErrorAction SilentlyContinue
    }
}
