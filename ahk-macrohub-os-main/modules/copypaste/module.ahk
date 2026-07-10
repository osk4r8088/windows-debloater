#Requires AutoHotkey v2.0

global g_CopyPaste := { hks: [] }

CopyPaste_Init(cfgPath) {
    global g_CopyPaste
    copy  := IniRead(cfgPath, "CopyPaste", "CopyHotkey",  "XButton1")
    paste := IniRead(cfgPath, "CopyPaste", "PasteHotkey", "XButton2")
    CopyPaste_Register(copy,  (*) => Send("^c"))
    CopyPaste_Register(paste, (*) => Send("^v"))
}

CopyPaste_Register(hk, fn) {
    global g_CopyPaste
    hk := Trim(hk)
    if (hk = "")
        return
    try {
        Hotkey hk, fn, "Off"
        g_CopyPaste.hks.Push(hk)
        HK_Track("copypaste", hk)
    } catch {
        TrayTip "CopyPaste: failed to bind " hk
    }
}

CopyPaste_SetEnabled(enable) {
    global g_CopyPaste
    state := enable ? "On" : "Off"
    for hk in g_CopyPaste.hks {
        try Hotkey hk, state
    }
}
