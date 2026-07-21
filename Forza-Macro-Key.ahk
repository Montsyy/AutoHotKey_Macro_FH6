#Requires AutoHotkey v2.0
#SingleInstance Force

Global IsRunning := false
Global ElapsedSeconds := 0
Global LoopElapsedSeconds := 0
Global CurrentLoop := 0
Global TotalLoopsLimit := 0
Global MacroSteps := []
Global CurrentStepIndex := 1
Global CurrentStartHotkey := "p"

MainGui := Gui("+AlwaysOnTop", "Custom Macro Builder")
MainGui.OnEvent("Close", GuiClose) ; Menghentikan program sepenuhnya saat jendela ditutup

; Bagian Perekam Tombol
MainGui.Add("Text", "x10 y15 w40", "Key:")
KeyInput := MainGui.Add("Edit", "x50 y10 w70 ReadOnly Center", "")
BtnCapture := MainGui.Add("Button", "x125 y9 w60", "Record")
BtnCapture.OnEvent("Click", CaptureKey)

; Bagian Waktu (Detik)
MainGui.Add("Text", "x195 y15 w60", "Delay (s):")
DelayInput := MainGui.Add("Edit", "x255 y10 w50", "0.1")

MainGui.Add("Text", "x315 y15 w75", "Duration (s):")
DurationInput := MainGui.Add("Edit", "x390 y10 w50", "1.0")

BtnAdd := MainGui.Add("Button", "x450 y9 w50", "Add")
BtnAdd.OnEvent("Click", AddStep)

BtnClear := MainGui.Add("Button", "x510 y9 w50", "Clear")
BtnClear.OnEvent("Click", ClearSteps)

; Daftar Eksekusi
LV := MainGui.Add("ListView", "x10 y45 w550 h150", ["No", "Key", "Delay (s)", "Hold Duration (s)"])
LV.ModifyCol(1, 40)
LV.ModifyCol(2, 120)
LV.ModifyCol(3, 120)
LV.ModifyCol(4, 150)

; Konfigurasi Pengulangan dan Hotkey Kustom
MainGui.Add("Text", "x10 y210 w110", "Total Loops (Tick):")
TotalLoopEdit := MainGui.Add("Edit", "x125 y205 w50 Number", "10")

MainGui.Add("Text", "x190 y210 w110", "Start/Stop Hotkey:")
HKInput := MainGui.Add("Hotkey", "x300 y205 w80", "p")
BtnSetHK := MainGui.Add("Button", "x390 y204 w80", "Set Hotkey")
BtnSetHK.OnEvent("Click", UpdateStartHotkey)

; Teks Pemantau
StatusText := MainGui.Add("Text", "x10 y240 w550", "Status: Idle (Press '" CurrentStartHotkey "' to Start/Stop)")
TimerText := MainGui.Add("Text", "x10 y265 w550", "Total Time: 00:00 | 1 Loop Time: 00:00 | Loop: 0/0 | Step: 0/0")

MainGui.Show("w570 h300")

; Mendaftarkan Hotkey Awal
Hotkey(CurrentStartHotkey, ToggleMacro)

GuiClose(*) {
    ExitApp()
}

UpdateStartHotkey(*) {
    Global CurrentStartHotkey
    newHK := HKInput.Value
    
    if (newHK == "") {
        MsgBox("Please enter a valid hotkey.")
        return
    }
    
    ; Menonaktifkan Hotkey lama lalu menerapkan yang baru
    try Hotkey(CurrentStartHotkey, "Off")
    
    CurrentStartHotkey := newHK
    Hotkey(CurrentStartHotkey, ToggleMacro, "On")
    
    StatusText.Value := "Status: Hotkey updated to '" CurrentStartHotkey "' (Idle)"
}

CaptureKey(*) {
    KeyInput.Value := "..."
    ih := InputHook("L1")
    ih.KeyOpt("{All}", "E")
    ih.Start()
    ih.Wait()
    
    key := ih.EndKey
    if (key == "") {
        key := ih.Input
    }
    KeyInput.Value := key
}

AddStep(*) {
    key := KeyInput.Value
    delay := DelayInput.Value
    duration := DurationInput.Value

    if (key == "" || key == "..." || delay == "" || duration == "") {
        MsgBox("Please record a key and fill in all time fields.")
        return
    }

    if (!IsNumber(delay) || !IsNumber(duration)) {
        MsgBox("Delay and Duration must be valid numbers (e.g., 1 or 0.5).")
        return
    }

    stepNum := MacroSteps.Length + 1
    
    ; Mengubah detik menjadi milidetik khusus untuk hitungan sistem background
    delayMs := Float(delay) * 1000
    durationMs := Float(duration) * 1000
    
    MacroSteps.Push(Map("Key", key, "Delay", delayMs, "Duration", durationMs))
    LV.Add("", stepNum, key, delay, duration)
    
    KeyInput.Value := ""
}

ClearSteps(*) {
    Global MacroSteps
    MacroSteps := []
    LV.Delete()
}

ToggleMacro(*) {
    Global IsRunning
    if IsRunning {
        StopAndResetMacro("Status: Force stopped by user")
    } else {
        StartMacro()
    }
}

StartMacro() {
    Global IsRunning, ElapsedSeconds, LoopElapsedSeconds, CurrentLoop, TotalLoopsLimit, CurrentStepIndex, MacroSteps

    if (MacroSteps.Length == 0) {
        MsgBox("Key list is empty. Please add at least one step first.")
        return
    }

    totalLoops := TotalLoopEdit.Value
    if (totalLoops == "") {
        MsgBox("Please enter a valid number of loops.")
        return
    }

    IsRunning := true
    ElapsedSeconds := 0
    LoopElapsedSeconds := 0
    CurrentLoop := 0
    CurrentStepIndex := 1
    TotalLoopsLimit := totalLoops

    UpdateTimerText()
    SetTimer(UpdateTimer, 1000)
    ExecuteNextStep()
}

ExecuteNextStep() {
    Global IsRunning, CurrentLoop, TotalLoopsLimit, CurrentStepIndex, MacroSteps, LoopElapsedSeconds

    if (!IsRunning)
        return

    if (CurrentStepIndex > MacroSteps.Length) {
        CurrentLoop++
        CurrentStepIndex := 1
        LoopElapsedSeconds := 0
        UpdateTimerText()

        if (CurrentLoop >= TotalLoopsLimit) {
            StopAndResetMacro("Status: Finished (Loop limit reached)")
            return
        }
    }

    stepData := MacroSteps[CurrentStepIndex]
    StatusText.Value := "Status: Waiting Delay (" (stepData["Delay"] / 1000) " s) for key '" stepData["Key"] "'"
    UpdateTimerText()

    if (stepData["Delay"] > 0) {
        SetTimer(() => PressKey(stepData), -1 * stepData["Delay"])
    } else {
        PressKey(stepData)
    }
}

PressKey(stepData) {
    Global IsRunning
    if (!IsRunning)
        return

    StatusText.Value := "Status: Holding key '" stepData["Key"] "' (" (stepData["Duration"] / 1000) " s)"
    
    try Send("{" stepData["Key"] " down}")

    if (stepData["Duration"] > 0) {
        SetTimer(() => ReleaseKey(stepData), -1 * stepData["Duration"])
    } else {
        ReleaseKey(stepData)
    }
}

ReleaseKey(stepData) {
    Global IsRunning, CurrentStepIndex
    if (!IsRunning)
        return

    try Send("{" stepData["Key"] " up}")
    CurrentStepIndex++
    
    SetTimer(ExecuteNextStep, -1)
}

StopAndResetMacro(msg := "Status: Finished") {
    Global IsRunning, ElapsedSeconds, LoopElapsedSeconds, CurrentLoop, CurrentStepIndex, MacroSteps, CurrentStartHotkey

    IsRunning := false
    SetTimer(UpdateTimer, 0)
    
    for index, step in MacroSteps {
        try Send("{" step["Key"] " up}")
    }

    if (msg == "Status: Finished") {
        msg := msg " (Press '" CurrentStartHotkey "' to Start)"
    }
    
    StatusText.Value := msg
    ElapsedSeconds := 0
    LoopElapsedSeconds := 0
    CurrentLoop := 0
    CurrentStepIndex := 1
    UpdateTimerText()
}

UpdateTimer() {
    Global ElapsedSeconds, LoopElapsedSeconds
    if (!IsRunning)
        return
        
    ElapsedSeconds++
    LoopElapsedSeconds++
    UpdateTimerText()
}

UpdateTimerText() {
    Global ElapsedSeconds, LoopElapsedSeconds, CurrentLoop, TotalLoopsLimit, CurrentStepIndex, MacroSteps
    
    mTotal := Floor(ElapsedSeconds / 60)
    sTotal := Mod(ElapsedSeconds, 60)
    
    mLoop := Floor(LoopElapsedSeconds / 60)
    sLoop := Mod(LoopElapsedSeconds, 60)
    
    stepStr := IsRunning ? CurrentStepIndex : 0
    totalStepStr := MacroSteps.Length
    
    TimerText.Value := Format("Total Time: {:02}:{:02} | 1 Loop Time: {:02}:{:02} | Loop: {}/{} | Step: {}/{}", mTotal, sTotal, mLoop, sLoop, CurrentLoop, TotalLoopsLimit, stepStr, totalStepStr)
}