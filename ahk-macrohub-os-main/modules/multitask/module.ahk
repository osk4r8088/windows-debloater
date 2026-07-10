#Requires AutoHotkey v2.0

global g_MultiTaskHK := []
global g_MultiTaskInited := false

MultiTask_Init(cfgPath) {
    global g_MultiTaskHK, g_MultiTaskInited
    if g_MultiTaskInited
        return
    g_MultiTaskInited := true

    ; hotkeys
    hkPlain := IniRead(cfgPath, "MultiTask", "PlainPaste", "^+v")
    hkDT    := IniRead(cfgPath, "MultiTask", "DateTime",   "NumpadMult")
    hkFS    := IniRead(cfgPath, "MultiTask", "FileStamp",  "NumpadSub")
    hkEdge  := IniRead(cfgPath, "MultiTask", "Edge",       "Numpad7")
    hkNpp   := IniRead(cfgPath, "MultiTask", "NotepadPP",  "Numpad8")
    hkTeams := IniRead(cfgPath, "MultiTask", "Teams",      "Numpad9")
    hkOutl  := IniRead(cfgPath, "MultiTask", "Outlook",    "NumpadAdd")

    ; paths
    pEdge   := IniRead(cfgPath, "MultiTask.Paths", "edge",      "")
    pNpp    := IniRead(cfgPath, "MultiTask.Paths", "notepadpp", "C:\Program Files\Notepad++\notepad++.exe")
    pTeams  := IniRead(cfgPath, "MultiTask.Paths", "teams",     "")
    pOutl   := IniRead(cfgPath, "MultiTask.Paths", "outlook",   "")

    ; register hotkeys OFF initially
    MultiTask_RegisterHotkey(hkPlain, (*) => MultiTask_PlainPaste())
    MultiTask_RegisterHotkey(hkDT,    (*) => SendText(FormatTime(, "dd.MM.yyyy HH:mm")))
    MultiTask_RegisterHotkey(hkFS,    (*) => SendText(FormatTime(, "yyyy-MM-dd_HHmm")))
    MultiTask_RegisterHotkey(hkEdge,  (*) => MultiTask_Launch(pEdge,  "msedge.exe"))
    MultiTask_RegisterHotkey(hkNpp,   (*) => MultiTask_Launch(pNpp,   "notepad.exe"))
    MultiTask_RegisterHotkey(hkTeams, (*) => MultiTask_LaunchTeams(pTeams))
    MultiTask_RegisterHotkey(hkOutl,  (*) => MultiTask_Launch(pOutl,  "outlook.exe"))
}

MultiTask_RegisterHotkey(hk, fn) {
    global g_MultiTaskHK
    hk := Trim(hk)
    if (hk = "")
        return
    try {
        Hotkey hk, fn, "Off"
        g_MultiTaskHK.Push(hk)
        HK_Track("multitask", hk)
    } catch as e {
        TrayTip "MultiTask: failed to bind " hk
    }
}

MultiTask_SetEnabled(enable) {
    global g_MultiTaskHK
    state := enable ? "On" : "Off"
    for hk in g_MultiTaskHK {
        try Hotkey hk, state
    }
}

MultiTask_PlainPaste() {
    txt := A_Clipboard
    if (txt = "") {
        TrayTip "Plain paste: no text on clipboard"
        return
    }
    save := ClipboardAll()
    A_Clipboard := txt
    if !ClipWait(0.5) {
        A_Clipboard := save
        TrayTip "Plain paste failed"
        return
    }
    Send "^v"
    Sleep 150  ; let the target app read the clipboard before restoring it
    A_Clipboard := save
}

MultiTask_Launch(path, fallbackExe) {
    try {
        if (path != "" && FileExist(path))
            Run('"' path '"')
        else
            Run(fallbackExe)
    } catch {
        TrayTip "Launch failed: " (path != "" ? path : fallbackExe)
    }
}

MultiTask_LaunchTeams(path := "") {
    if (path != "" && FileExist(path)) {
        try {
            Run('"' path '"')
            return
        }
    }

    for uri in ["msteams:", "ms-teams:", "teams:"] {
        try {
            Run(uri)
            return
        }
    }

    try {
        Run("teams.exe")
        return
    } catch {
        TrayTip "Teams launch failed (Store app not found)"
    }
}
