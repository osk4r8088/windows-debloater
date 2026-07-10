#Requires AutoHotkey v2.0

global g_ClipHistory := { hk: "", max: 15, items: [], ok: false }

ClipHistory_Init(cfgPath) {
    global g_ClipHistory
    g_ClipHistory.hk := IniRead(cfgPath, "ClipHistory", "Hotkey", "^!h")
    try
        g_ClipHistory.max := Integer(IniRead(cfgPath, "ClipHistory", "MaxItems", "15"))
    catch
        g_ClipHistory.max := 15
    if (g_ClipHistory.max < 1)
        g_ClipHistory.max := 15
    try {
        Hotkey g_ClipHistory.hk, ClipHistory_ShowMenu, "Off"
        g_ClipHistory.ok := true
        HK_Track("cliphistory", g_ClipHistory.hk)
    } catch {
        TrayTip "ClipHistory: failed to bind " g_ClipHistory.hk
    }
}

ClipHistory_SetEnabled(enable) {
    global g_ClipHistory
    if g_ClipHistory.ok
        try Hotkey g_ClipHistory.hk, enable ? "On" : "Off"
    ; only record clipboard changes while enabled
    OnClipboardChange ClipHistory_OnChange, enable ? 1 : 0
}

ClipHistory_OnChange(dataType) {
    global g_ClipHistory
    if (dataType != 1)  ; text only
        return
    txt := A_Clipboard
    if (txt = "")
        return
    ; move-to-front dedupe
    for i, item in g_ClipHistory.items {
        if (item == txt) {
            g_ClipHistory.items.RemoveAt(i)
            break
        }
    }
    g_ClipHistory.items.InsertAt(1, txt)
    while (g_ClipHistory.items.Length > g_ClipHistory.max)
        g_ClipHistory.items.Pop()
}

ClipHistory_ShowMenu(*) {
    global g_ClipHistory
    if (g_ClipHistory.items.Length = 0) {
        TrayTip "History is empty", "ClipHistory", 1
        return
    }
    m := Menu()
    for i, txt in g_ClipHistory.items {
        label := Trim(RegExReplace(txt, "\s+", " "))
        if (StrLen(label) > 60)
            label := SubStr(label, 1, 57) "..."
        label := StrReplace(label, "&", "&&")
        ; number prefix keeps every label unique and gives Alt-style accelerators 1-9
        prefix := (i <= 9) ? "&" i "  " : i "  "
        m.Add(prefix label, ClipHistory_Paste.Bind(txt))
    }
    m.Add()
    m.Add("Clear history", ClipHistory_Clear)
    m.Show()
}

ClipHistory_Paste(txt, *) {
    A_Clipboard := txt
    if !ClipWait(0.5)
        return
    Send "^v"
    ; the chosen clip intentionally stays on the clipboard (like Win+V)
}

ClipHistory_Clear(*) {
    global g_ClipHistory
    g_ClipHistory.items := []
}
