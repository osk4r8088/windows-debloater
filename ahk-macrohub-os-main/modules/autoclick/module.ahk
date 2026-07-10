#Requires AutoHotkey v2.0

global g_AutoClick := { delay: 30, button: "Left", ok: false }

AutoClick_Init(cfgPath) {
    global g_AutoClick
    try
        g_AutoClick.delay := Integer(IniRead(cfgPath, "AutoClick", "DelayMs", "30"))
    catch
        g_AutoClick.delay := 30
    g_AutoClick.button := IniRead(cfgPath, "AutoClick", "Button", "Left")
    try {
        Hotkey "^LButton", AutoClick_Handler, "Off"
        g_AutoClick.ok := true
        HK_Track("autoclick", "^LButton")
    } catch {
        TrayTip "AutoClick: failed to bind ^LButton"
    }
}

AutoClick_SetEnabled(enable) {
    global g_AutoClick
    if g_AutoClick.ok
        try Hotkey "^LButton", enable ? "On" : "Off"
}

AutoClick_Handler(*) {
    global g_AutoClick
    while GetKeyState("Ctrl", "P") && GetKeyState("LButton", "P") {
        Click g_AutoClick.button
        Sleep g_AutoClick.delay
    }
}
