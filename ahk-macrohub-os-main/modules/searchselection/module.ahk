#Requires AutoHotkey v2.0

global g_SearchSelection := { hk: "", url: "", ok: false }

SearchSelection_Init(cfgPath) {
    global g_SearchSelection
    g_SearchSelection.hk  := IniRead(cfgPath, "SearchSelection", "Hotkey", "^!s")
    g_SearchSelection.url := IniRead(cfgPath, "SearchSelection", "URL", "https://www.google.com/search?q=%s")
    try {
        Hotkey g_SearchSelection.hk, SearchSelection_Search, "Off"
        g_SearchSelection.ok := true
        HK_Track("searchselection", g_SearchSelection.hk)
    } catch {
        TrayTip "SearchSelection: failed to bind " g_SearchSelection.hk
    }
}

SearchSelection_SetEnabled(enable) {
    global g_SearchSelection
    if g_SearchSelection.ok
        try Hotkey g_SearchSelection.hk, enable ? "On" : "Off"
}

SearchSelection_Search(*) {
    global g_SearchSelection
    saved := ClipboardAll()
    A_Clipboard := ""
    Send "^c"
    hasSel := ClipWait(0.4)
    txt := Trim(hasSel ? A_Clipboard : "")
    A_Clipboard := saved
    if (txt = "") {
        TrayTip "No text selected", "SearchSelection", 1
        return
    }
    if (StrLen(txt) > 500)  ; keep the URL sane for huge selections
        txt := SubStr(txt, 1, 500)
    url := StrReplace(g_SearchSelection.url, "%s", SearchSelection_UrlEncode(txt))
    try Run url
}

; percent-encodes UTF-8 bytes; unreserved chars (RFC 3986) pass through
SearchSelection_UrlEncode(str) {
    buf := Buffer(StrPut(str, "UTF-8"))
    StrPut(str, buf, "UTF-8")
    out := ""
    Loop buf.Size - 1 {
        b := NumGet(buf, A_Index - 1, "UChar")
        if (b >= 0x30 && b <= 0x39) || (b >= 0x41 && b <= 0x5A) || (b >= 0x61 && b <= 0x7A) || b = 0x2D || b = 0x2E || b = 0x5F || b = 0x7E
            out .= Chr(b)
        else
            out .= Format("%{:02X}", b)
    }
    return out
}
