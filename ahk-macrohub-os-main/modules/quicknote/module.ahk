#Requires AutoHotkey v2.0

global g_QuickNote := { file: "", hks: [] }

QuickNote_Init(cfgPath) {
    global g_QuickNote
    hkCapture := IniRead(cfgPath, "QuickNote", "Hotkey", "^!n")
    hkOpen    := IniRead(cfgPath, "QuickNote", "OpenHotkey", "")
    f := IniRead(cfgPath, "QuickNote", "File", "notes.txt")
    if !RegExMatch(f, "i)^([a-z]:\\|\\\\)")  ; relative path → next to the script
        f := A_ScriptDir "\" f
    g_QuickNote.file := f
    QuickNote_Register(hkCapture, QuickNote_Capture)
    QuickNote_Register(hkOpen, QuickNote_Open)
}

QuickNote_Register(hk, fn) {
    global g_QuickNote
    hk := Trim(hk)
    if (hk = "")
        return
    try {
        Hotkey hk, fn, "Off"
        g_QuickNote.hks.Push(hk)
        HK_Track("quicknote", hk)
    } catch {
        TrayTip "QuickNote: failed to bind " hk
    }
}

QuickNote_SetEnabled(enable) {
    global g_QuickNote
    state := enable ? "On" : "Off"
    for hk in g_QuickNote.hks {
        try Hotkey hk, state
    }
}

; appends the selected text to the notes file; with nothing selected, asks for a note
QuickNote_Capture(*) {
    global g_QuickNote
    saved := ClipboardAll()
    A_Clipboard := ""
    Send "^c"
    hasSel := ClipWait(0.4)
    txt := hasSel ? A_Clipboard : ""
    A_Clipboard := saved
    if (Trim(txt) = "") {
        ib := InputBox("Note text:", "QuickNote")
        if (ib.Result != "OK" || Trim(ib.Value) = "")
            return
        txt := ib.Value
    }
    line := "[" FormatTime(, "yyyy-MM-dd HH:mm") "] " txt "`r`n"
    try {
        FileAppend line, g_QuickNote.file, "UTF-8"
        TrayTip "Saved", "QuickNote", 1
    } catch {
        TrayTip "Failed to write " g_QuickNote.file, "QuickNote", 1
    }
}

QuickNote_Open(*) {
    global g_QuickNote
    if !FileExist(g_QuickNote.file)
        try FileAppend "", g_QuickNote.file, "UTF-8"
    try Run 'notepad.exe "' g_QuickNote.file '"'
}
