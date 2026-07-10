#Requires AutoHotkey v2.0

global g_StringPaste := { hk: "", text: "", ok: false }

StringPaste_Init(cfgPath) {
    global g_StringPaste
    g_StringPaste.text := IniRead(cfgPath, "StringPaste", "Text", "paste")
    g_StringPaste.hk   := IniRead(cfgPath, "StringPaste", "Hotkey", "^!p")
    try {
        Hotkey g_StringPaste.hk, StringPaste_Handler, "Off"
        g_StringPaste.ok := true
        HK_Track("stringpaste", g_StringPaste.hk)
    } catch {
        TrayTip "StringPaste: failed to bind " g_StringPaste.hk
    }
}

StringPaste_SetEnabled(enable) {
    global g_StringPaste
    if g_StringPaste.ok
        try Hotkey g_StringPaste.hk, enable ? "On" : "Off"
}

StringPaste_Handler(*) {
    global g_StringPaste
    saved := ClipboardAll()
    A_Clipboard := g_StringPaste.text
    if !ClipWait(0.5) {
        A_Clipboard := saved
        TrayTip "StringPaste: clipboard not ready"
        return
    }
    Send "^v"
    Sleep 150  ; let the target app read the clipboard before restoring it
    A_Clipboard := saved
}
