#Requires AutoHotkey v2.0

global g_TextExpander := { hs: [] }

TextExpander_Init(cfgPath) {
    global g_TextExpander

    try
        pairs := IniRead(cfgPath, "TextExpander")
    catch
        return

    for line in StrSplit(pairs, "`n", "`r") {
        line := Trim(line)
        if (line = "")
            continue
        eq := InStr(line, "=")
        if (!eq)
            continue
        abbr := Trim(SubStr(line, 1, eq - 1))
        expansion := Trim(SubStr(line, eq + 1))
        if (abbr = "" || expansion = "")
            continue
        ; T = send expansion as raw text; expansion fires after an ending character
        ; (space/enter/punctuation) so abbreviations don't trigger mid-word
        ; ("addr" no longer breaks typing "address")
        name := ":T:" abbr
        try {
            Hotstring name, expansion, "Off"
            g_TextExpander.hs.Push(name)
            HK_Track("textexpander", 'abbreviation "' abbr '"')
        } catch {
            TrayTip "TextExpander: invalid abbreviation '" abbr "'"
        }
    }
}

TextExpander_SetEnabled(enable) {
    global g_TextExpander
    state := enable ? "On" : "Off"
    for name in g_TextExpander.hs {
        try Hotstring name, , state
    }
}
