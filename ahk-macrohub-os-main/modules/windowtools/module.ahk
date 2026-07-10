#Requires AutoHotkey v2.0

global g_WindowTools := { hks: [] }

WindowTools_Init(cfgPath) {
    hkTop    := IniRead(cfgPath, "WindowTools", "AlwaysOnTop", "^!t")
    hkMon    := IniRead(cfgPath, "WindowTools", "NextMonitor", "^!m")
    hkCenter := IniRead(cfgPath, "WindowTools", "Center",      "^!c")
    WindowTools_Register(hkTop,    WindowTools_ToggleTop)
    WindowTools_Register(hkMon,    WindowTools_NextMonitor)
    WindowTools_Register(hkCenter, WindowTools_Center)
}

WindowTools_Register(hk, fn) {
    global g_WindowTools
    hk := Trim(hk)
    if (hk = "")
        return
    try {
        Hotkey hk, fn, "Off"
        g_WindowTools.hks.Push(hk)
        HK_Track("windowtools", hk)
    } catch {
        TrayTip "WindowTools: failed to bind " hk
    }
}

WindowTools_SetEnabled(enable) {
    global g_WindowTools
    state := enable ? "On" : "Off"
    for hk in g_WindowTools.hks {
        try Hotkey hk, state
    }
}

WindowTools_ToggleTop(*) {
    hwnd := WinExist("A")
    if !hwnd
        return
    try {
        WinSetAlwaysOnTop -1, hwnd
        onTop := WinGetExStyle(hwnd) & 0x8  ; WS_EX_TOPMOST
        TrayTip (onTop ? "Always on top: ON" : "Always on top: OFF"), WinGetTitle(hwnd), 1
    }
}

WindowTools_NextMonitor(*) {
    hwnd := WinExist("A")
    if !hwnd
        return
    count := MonitorGetCount()
    if (count < 2) {
        TrayTip "Only one monitor detected", "WindowTools", 1
        return
    }
    try {
        WinGetPos &x, &y, &w, &h, hwnd
        cur := WindowTools_MonitorOf(x + w // 2, y + h // 2)
        next := Mod(cur, count) + 1
        MonitorGetWorkArea cur,  &cl, &ct, &cr, &cb
        MonitorGetWorkArea next, &nl, &nt, &nr, &nb

        wasMax := WinGetMinMax(hwnd) = 1
        if wasMax {
            WinRestore hwnd
            WinGetPos &x, &y, &w, &h, hwnd
        }
        ; keep the window's relative position on the new monitor
        relX := (cr - cl) ? (x - cl) / (cr - cl) : 0
        relY := (cb - ct) ? (y - ct) / (cb - ct) : 0
        WinMove Round(nl + relX * (nr - nl)), Round(nt + relY * (nb - nt)), , , hwnd
        if wasMax
            WinMaximize hwnd
    }
}

WindowTools_Center(*) {
    hwnd := WinExist("A")
    if !hwnd
        return
    try {
        if (WinGetMinMax(hwnd) != 0)  ; skip maximized/minimized windows
            return
        WinGetPos &x, &y, &w, &h, hwnd
        mon := WindowTools_MonitorOf(x + w // 2, y + h // 2)
        MonitorGetWorkArea mon, &l, &t, &r, &b
        WinMove l + ((r - l) - w) // 2, t + ((b - t) - h) // 2, , , hwnd
    }
}

; monitor index containing the point, falling back to the primary monitor
WindowTools_MonitorOf(px, py) {
    Loop MonitorGetCount() {
        MonitorGet A_Index, &l, &t, &r, &b
        if (px >= l && px < r && py >= t && py < b)
            return A_Index
    }
    return MonitorGetPrimary()
}
