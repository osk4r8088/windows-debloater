#Requires AutoHotkey v2.0

global g_AutoReplace := { hs: [] }

AutoReplace_Init(cfgPath) {
    global g_AutoReplace

    try
        pairs := IniRead(cfgPath, "AutoReplace")
    catch
        return

    for line in StrSplit(pairs, "`n", "`r") {
        line := Trim(line)
        if (line = "")
            continue
        eq := InStr(line, "=")
        if (!eq)
            continue
        typo := Trim(SubStr(line, 1, eq - 1))
        correction := Trim(SubStr(line, eq + 1))
        if (typo = "" || correction = "")
            continue
        ; C = case-sensitive (so "IM" won't become "I'M"), T = send correction as raw text
        name := ":CT:" typo
        try {
            Hotstring name, correction, "Off"
            g_AutoReplace.hs.Push(name)
            HK_Track("autoreplace", 'abbreviation "' typo '"')
        } catch {
            TrayTip "AutoReplace: invalid entry '" typo "'"
        }
    }
}

AutoReplace_SetEnabled(enable) {
    global g_AutoReplace
    state := enable ? "On" : "Off"
    for name in g_AutoReplace.hs {
        try Hotstring name, , state
    }
}
