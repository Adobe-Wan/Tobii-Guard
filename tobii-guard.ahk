; Tobii Guard
; https://github.com/Adobe-Wan/tobii-guard
; SPDX-License-Identifier: MIT
;
; Ends Tobii.EyeX.Interaction.exe so its always-on-top 1x1 "PeekerWindow" stops
; forcing Windows to composite games, which breaks G-SYNC / VRR and Independent Flip.
; Head tracking keeps working: it runs through Tobii's service and engine, which this
; script never touches.
;
; What this script does, and nothing else:
;   - every few seconds, looks for a process named exactly Tobii.EyeX.Interaction.exe
;   - ends it only if its file path is Tobii's own install path (see ALLOWED_PATHS)
;   - leaves it running while the Tobii Experience window is open on screen
;   - writes a small log to %LOCALAPPDATA%\TobiiGuard\log.txt (rotated at 100 KB)
;   - optionally creates/deletes ONE shortcut in your own Startup folder (tray menu)
; It refuses to run as administrator, makes no network connections, writes nothing
; to the registry and starts no other programs (except Explorer, if you click
; "Open log folder" in the tray menu).

#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn All, OutputDebug
Persistent

VERSION := "1.0.0"
TARGET_EXE := "Tobii.EyeX.Interaction.exe"
CHECK_INTERVAL_MS := 5000

; Tobii Experience's main window. While it is open on screen, Interaction is left
; alone so the app does not show its "Something's not quite right" troubleshooter.
TOBII_APP_WINDOW := "Tobii Experience ahk_exe Tobii.EyeTracking.Portal.WPF.exe"

; Only a process at one of these exact paths is ever ended.
ALLOWED_PATHS := []
for envName in ["ProgramFiles", "ProgramFiles(x86)", "ProgramW6432"] {
    if (dir := EnvGet(envName))
        ALLOWED_PATHS.Push(dir "\Tobii\Tobii EyeX\" TARGET_EXE)
}

LOG_DIR := EnvGet("LOCALAPPDATA") "\TobiiGuard"
LOG_FILE := LOG_DIR "\log.txt"
LOG_MAX_BYTES := 100000
STARTUP_LINK := A_Startup "\Tobii Guard.lnk"

; Least privilege: Interaction runs as the signed-in user, so admin rights are never
; needed. Refuse them so the script can never act on other users' processes.
if A_IsAdmin {
    MsgBox("Tobii Guard does not need administrator rights and will not run with them.`n`n"
        . "Please start it normally (double-click, not 'Run as administrator').",
        "Tobii Guard", "Icon!")
    ExitApp()
}

paused := false
skipping := false

BuildTrayMenu()
Log("started v" VERSION)
SetTimer(Check, CHECK_INTERVAL_MS)
Check()

Check() {
    global skipping
    if paused
        return

    ; Loop in case more than one instance exists (for example, two signed-in users;
    ; another user's instance cannot be ended without admin rights and is only logged).
    attempts := 0
    while (pid := ProcessExist(TARGET_EXE)) && attempts < 5 {
        attempts++

        if TobiiAppOpen() {
            if !skipping
                Log("leaving " TARGET_EXE " running: Tobii Experience window is open")
            skipping := true
            return
        }
        skipping := false

        path := ""
        try path := ProcessGetPath(pid)
        if !IsAllowedPath(path) {
            Log("not ending pid " pid ": unexpected path '" path "'")
            return
        }

        try ProcessClose(pid)
        if ProcessWaitClose(pid, 2) {
            Log("could not end " TARGET_EXE " (pid " pid ")")
            return
        }
        Log("ended " TARGET_EXE " (pid " pid ")")
    }
}

IsAllowedPath(path) {
    if (path = "")
        return false
    for allowed in ALLOWED_PATHS {
        if (StrLower(path) = StrLower(allowed))
            return true
    }
    return false
}

; True only while the Tobii Experience window is really on screen.
; "Close to tray" keeps the window alive but parks it far off-screen.
TobiiAppOpen() {
    DetectHiddenWindows(false)
    hwnd := WinExist(TOBII_APP_WINDOW)
    if !hwnd
        return false
    try {
        if (WinGetMinMax(hwnd) = -1)
            return false
        WinGetPos(&x, &y, , , hwnd)
        return x > -10000 && y > -10000
    }
    return false
}

Log(msg) {
    try {
        if !DirExist(LOG_DIR)
            DirCreate(LOG_DIR)
        if FileExist(LOG_FILE) && FileGetSize(LOG_FILE) > LOG_MAX_BYTES
            FileMove(LOG_FILE, LOG_FILE ".old", true)
        FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") " " msg "`n", LOG_FILE, "UTF-8")
    }
}

; ---------- Tray menu ----------

BuildTrayMenu() {
    A_IconTip := "Tobii Guard " VERSION
    tray := A_TrayMenu
    tray.Delete()
    tray.Add("Pause", TogglePause)
    tray.Add("Start with Windows", ToggleStartup)
    tray.Add("Open log folder", OpenLogFolder)
    tray.Add()
    tray.Add("About", ShowAbout)
    tray.Add("Exit", (*) => ExitApp())
    if FileExist(STARTUP_LINK)
        tray.Check("Start with Windows")
}

TogglePause(*) {
    global paused
    paused := !paused
    if paused {
        A_TrayMenu.Check("Pause")
        A_IconTip := "Tobii Guard " VERSION " (paused)"
        Log("paused")
    } else {
        A_TrayMenu.Uncheck("Pause")
        A_IconTip := "Tobii Guard " VERSION
        Log("resumed")
        Check()
    }
}

; Creates or removes a single shortcut in the current user's Startup folder.
; It starts this same script with the AutoHotkey that is running it now.
ToggleStartup(*) {
    if FileExist(STARTUP_LINK) {
        FileDelete(STARTUP_LINK)
        A_TrayMenu.Uncheck("Start with Windows")
        Log("start with Windows: off")
    } else {
        FileCreateShortcut(A_AhkPath, STARTUP_LINK, A_ScriptDir, '"' A_ScriptFullPath '"',
            "Tobii Guard: keeps Tobii's PeekerWindow from breaking G-SYNC")
        A_TrayMenu.Check("Start with Windows")
        Log("start with Windows: on")
    }
}

OpenLogFolder(*) {
    if !DirExist(LOG_DIR)
        DirCreate(LOG_DIR)
    Run('explorer.exe "' LOG_DIR '"')
}

ShowAbout(*) {
    MsgBox("Tobii Guard " VERSION "`n`n"
        . "Ends " TARGET_EXE " so its always-on-top window stops breaking G-SYNC.`n"
        . "Head tracking keeps working.`n`n"
        . "Source and documentation:`nhttps://github.com/Adobe-Wan/tobii-guard`n`n"
        . "Not affiliated with or endorsed by Tobii AB.",
        "About Tobii Guard", "Iconi")
}
