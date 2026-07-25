#Requires AutoHotkey v2.0
#SingleInstance Force

Global IsRunning := false
Global IsRecording := false
Global ElapsedSeconds := 0
Global LoopElapsedSeconds := 0
Global TotalEstimatedSeconds := 0
Global CurrentLoop := 0
Global TotalLoopsLimit := 0
Global MacroSteps := []
Global CurrentStepIndex := 1
Global CurrentStartHotkey := "p"

; File penyimpanan preset
Global IniFile := A_ScriptDir "\macro_presets.ini"

Global ihRec := ""
Global LastActionTime := 0
Global ActiveKeys := Map()

MainGui := Gui("+AlwaysOnTop", "Custom Macro Builder")
MainGui.OnEvent("Close", GuiClose)

; Bagian Input Manual & Aksi Tabel
MainGui.Add("Text", "x10 y15 w30", "Key:")
KeyInput := MainGui.Add("Edit", "x40 y10 w60 ReadOnly Center", "")
BtnCapture := MainGui.Add("Button", "x105 y9 w55", "Detect")
BtnCapture.OnEvent("Click", CaptureSingleKey)

MainGui.Add("Text", "x165 y15 w50", "Delay (s):")
DelayInput := MainGui.Add("Edit", "x220 y10 w45", "0.1")

MainGui.Add("Text", "x270 y15 w70", "Duration (s):")
DurationInput := MainGui.Add("Edit", "x345 y10 w45", "1.0")

BtnAdd := MainGui.Add("Button", "x395 y9 w40", "Add")
BtnAdd.OnEvent("Click", AddStep)

BtnEdit := MainGui.Add("Button", "x440 y9 w40", "Edit")
BtnEdit.OnEvent("Click", EditStep)

BtnDel := MainGui.Add("Button", "x485 y9 w40", "Del")
BtnDel.OnEvent("Click", DeleteStep)

BtnClear := MainGui.Add("Button", "x530 y9 w45", "Clear")
BtnClear.OnEvent("Click", ClearSteps)

; Bagian Perekam Langsung
Global BtnLiveRecord := MainGui.Add("Button", "x10 y45 w565 h35", "▶ START LIVE RECORD (Press F12 to Stop)")
BtnLiveRecord.OnEvent("Click", ToggleRecording)

; Bagian Tabel Daftar Eksekusi
Global LV := MainGui.Add("ListView", "x10 y90 w565 h150", ["No", "Key", "Delay (s)", "Hold Duration (s)"])
LV.ModifyCol(1, 40)
LV.ModifyCol(2, 130)
LV.ModifyCol(3, 130)
LV.ModifyCol(4, 150)
LV.OnEvent("Click", LoadToEdit)

; Pengaturan Loop dan Hotkey
MainGui.Add("Text", "x10 y255 w110", "Total Loops (Tick):")
TotalLoopEdit := MainGui.Add("Edit", "x125 y250 w50 Number", "10")

MainGui.Add("Text", "x190 y255 w110", "Start/Stop Hotkey:")
HKInput := MainGui.Add("Hotkey", "x300 y250 w80", "p")
BtnSetHK := MainGui.Add("Button", "x390 y249 w80", "Set Hotkey")
BtnSetHK.OnEvent("Click", UpdateStartHotkey)

; Sistem Preset (Memori)
MainGui.Add("Text", "x10 y290 w50", "Preset:")
Global PresetCB := MainGui.Add("ComboBox", "x60 y285 w160", GetPresetNames())

BtnSavePreset := MainGui.Add("Button", "x230 y284 w50", "Save")
BtnSavePreset.OnEvent("Click", SavePreset)

BtnLoadPreset := MainGui.Add("Button", "x285 y284 w50", "Load")
BtnLoadPreset.OnEvent("Click", LoadPreset)

BtnDelPreset := MainGui.Add("Button", "x340 y284 w50", "Del")
BtnDelPreset.OnEvent("Click", DeletePreset)

; Teks Pemantau (Status & Waktu)
Global StatusText := MainGui.Add("Text", "x10 y325 w565", "Status: Idle (Press '" CurrentStartHotkey "' to Start/Stop)")
Global TimerText := MainGui.Add("Text", "x10 y350 w565", "Time: 00:00 (Left: 00:00) | LoopTime: 00:00 | L: 0/0 | S: 0/0")

MainGui.Show("w585 h380")
Hotkey(CurrentStartHotkey, ToggleMacro)

GuiClose(*) {
    ExitApp()
}

; ==========================================
; SISTEM MEMORI (PRESET)
; ==========================================
GetPresetNames() {
    if !FileExist(IniFile)
        return []
    sections := IniRead(IniFile)
    if (sections == "")
        return []
    return StrSplit(sections, "`n")
}

RefreshPresetList() {
    PresetCB.Delete()
    names := GetPresetNames()
    if (names.Length > 0)
        PresetCB.Add(names)
}

SavePreset(*) {
    Global MacroSteps, IniFile
    presetName := PresetCB.Text
    
    if (presetName == "") {
        MsgBox("Please enter a name for the preset.")
        return
    }
    if (MacroSteps.Length == 0) {
        MsgBox("No steps to save. Please add macro steps first.")
        return
    }
    
    stepsStr := ""
    for index, step in MacroSteps {
        stepsStr .= step["Key"] "|" step["Delay"] "|" step["Duration"]
        if (index < MacroSteps.Length)
            stepsStr .= "||"
    }
    
    IniWrite(stepsStr, IniFile, presetName, "Steps")
    IniWrite(TotalLoopEdit.Value, IniFile, presetName, "Loops")
    IniWrite(CurrentStartHotkey, IniFile, presetName, "Hotkey")
    
    RefreshPresetList()
    PresetCB.Text := presetName
    MsgBox("Preset '" presetName "' successfully saved!")
}

LoadPreset(*) {
    Global MacroSteps, IniFile
    presetName := PresetCB.Text
    
    if (presetName == "") {
        MsgBox("Please select a preset to load.")
        return
    }
    
    try {
        stepsStr := IniRead(IniFile, presetName, "Steps")
        loopsVal := IniRead(IniFile, presetName, "Loops", "10")
        hotkeyVal := IniRead(IniFile, presetName, "Hotkey", "p")
    } catch {
        MsgBox("Preset '" presetName "' not found.")
        return
    }
    
    ClearSteps()
    
    if (stepsStr != "") {
        stepArray := StrSplit(stepsStr, "||")
        for index, item in stepArray {
            parts := StrSplit(item, "|")
            if (parts.Length == 3) {
                key := parts[1]
                delayMs := Integer(parts[2])
                durationMs := Integer(parts[3])
                
                delaySec := Round(delayMs / 1000, 3)
                durSec := Round(durationMs / 1000, 3)
                
                MacroSteps.Push(Map("Key", key, "Delay", delayMs, "Duration", durationMs))
                LV.Add("", index, key, delaySec, durSec)
            }
        }
    }
    
    TotalLoopEdit.Value := loopsVal
    HKInput.Value := hotkeyVal
    UpdateStartHotkey()
    
    MsgBox("Preset '" presetName "' loaded successfully!")
}

DeletePreset(*) {
    Global IniFile
    presetName := PresetCB.Text
    
    if (presetName == "") {
        return
    }
    
    res := MsgBox("Are you sure you want to delete preset '" presetName "'?", "Confirm Deletion", "YesNo")
    if (res == "Yes") {
        try IniDelete(IniFile, presetName)
        RefreshPresetList()
        PresetCB.Text := ""
        ClearSteps()
    }
}

; ==========================================
; FUNGSI UTAMA LAINNYA
; ==========================================
UpdateStartHotkey(*) {
    Global CurrentStartHotkey
    newHK := HKInput.Value
    if (newHK == "") {
        return
    }
    try Hotkey(CurrentStartHotkey, "Off")
    CurrentStartHotkey := newHK
    Hotkey(CurrentStartHotkey, ToggleMacro, "On")
    StatusText.Value := "Status: Hotkey updated to '" CurrentStartHotkey "' (Idle)"
}

ToggleRecording(*) {
    Global IsRecording
    if IsRecording {
        StopLiveRecording()
    } else {
        StartLiveRecording()
    }
}

StartLiveRecording() {
    Global IsRecording, ihRec, LastActionTime, ActiveKeys
    IsRecording := true
    ActiveKeys.Clear()
    LastActionTime := A_TickCount
    
    BtnLiveRecord.Text := "⏹ STOP RECORDING (Or press F12)"
    StatusText.Value := "Status: RECORDING IN PROGRESS... Type anything!"
    
    ihRec := InputHook("V L0")
    ihRec.KeyOpt("{All}", "N")
    ihRec.OnKeyDown := OnLiveKeyDown
    ihRec.OnKeyUp := OnLiveKeyUp
    ihRec.Start()
}

StopLiveRecording() {
    Global IsRecording, ihRec, CurrentStartHotkey
    IsRecording := false
    if (ihRec)
        ihRec.Stop()
    
    BtnLiveRecord.Text := "▶ START LIVE RECORD (Press F12 to Stop)"
    StatusText.Value := "Status: Idle (Press '" CurrentStartHotkey "' to Start/Stop)"
}

OnLiveKeyDown(ih, VK, SC) {
    Global LastActionTime, ActiveKeys
    keyName := GetKeyName(Format("vk{:x}sc{:x}", VK, SC))
    
    if (keyName = "F12") {
        StopLiveRecording()
        return
    }
    
    if ActiveKeys.Has(keyName)
        return
        
    currentTime := A_TickCount
    delayMs := currentTime - LastActionTime
    ActiveKeys[keyName] := {StartTime: currentTime, Delay: delayMs}
}

OnLiveKeyUp(ih, VK, SC) {
    Global LastActionTime, ActiveKeys, MacroSteps
    keyName := GetKeyName(Format("vk{:x}sc{:x}", VK, SC))
    
    if (keyName = "F12")
        return
        
    if ActiveKeys.Has(keyName) {
        currentTime := A_TickCount
        durationMs := currentTime - ActiveKeys[keyName].StartTime
        delayMs := ActiveKeys[keyName].Delay
        
        delaySec := Round(delayMs / 1000, 3)
        durSec := Round(durationMs / 1000, 3)
        
        stepNum := MacroSteps.Length + 1
        MacroSteps.Push(Map("Key", keyName, "Delay", delayMs, "Duration", durationMs))
        LV.Add("", stepNum, keyName, delaySec, durSec)
        LV.Modify(LV.GetCount(), "Vis")
        
        ActiveKeys.Delete(keyName)
        LastActionTime := currentTime
    }
}

CaptureSingleKey(*) {
    KeyInput.Value := "..."
    ih := InputHook("L1")
    ih.KeyOpt("{All}", "E")
    ih.Start()
    ih.Wait()
    key := ih.EndKey
    if (key == "")
        key := ih.Input
    KeyInput.Value := key
}

LoadToEdit(Ctrl, RowNumber) {
    if (RowNumber == 0)
        return
    KeyInput.Value := Ctrl.GetText(RowNumber, 2)
    DelayInput.Value := Ctrl.GetText(RowNumber, 3)
    DurationInput.Value := Ctrl.GetText(RowNumber, 4)
}

AddStep(*) {
    Global IsRunning, MacroSteps
    if IsRunning {
        MsgBox("Please stop the macro before modifying steps.")
        return
    }

    key := KeyInput.Value
    delay := DelayInput.Value
    duration := DurationInput.Value

    if (key == "" || key == "..." || delay == "" || duration == "") {
        MsgBox("Please record a key and fill in all time fields.")
        return
    }
    if (!IsNumber(delay) || !IsNumber(duration)) {
        MsgBox("Delay and Duration must be valid numbers.")
        return
    }

    stepNum := MacroSteps.Length + 1
    delayMs := Float(delay) * 1000
    durationMs := Float(duration) * 1000
    
    MacroSteps.Push(Map("Key", key, "Delay", delayMs, "Duration", durationMs))
    LV.Add("", stepNum, key, delay, duration)
    KeyInput.Value := ""
    LV.Modify(LV.GetCount(), "Vis")
}

EditStep(*) {
    Global IsRunning, MacroSteps
    if IsRunning {
        MsgBox("Please stop the macro before modifying steps.")
        return
    }

    selectedRow := LV.GetNext(0)
    if (selectedRow == 0) {
        MsgBox("Please select a row in the table to edit.")
        return
    }

    key := KeyInput.Value
    delay := DelayInput.Value
    duration := DurationInput.Value

    if (key == "" || key == "..." || delay == "" || duration == "") {
        return
    }
    if (!IsNumber(delay) || !IsNumber(duration)) {
        MsgBox("Delay and Duration must be valid numbers.")
        return
    }

    delayMs := Float(delay) * 1000
    durationMs := Float(duration) * 1000

    MacroSteps[selectedRow] := Map("Key", key, "Delay", delayMs, "Duration", durationMs)
    LV.Modify(selectedRow, "", selectedRow, key, delay, duration)
    KeyInput.Value := ""
}

DeleteStep(*) {
    Global IsRunning, MacroSteps
    if IsRunning {
        MsgBox("Please stop the macro before modifying steps.")
        return
    }

    selectedRow := LV.GetNext(0)
    if (selectedRow == 0) {
        MsgBox("Please select a row in the table to delete.")
        return
    }

    MacroSteps.RemoveAt(selectedRow)
    LV.Delete(selectedRow)

    loop LV.GetCount() {
        LV.Modify(A_Index, "", A_Index)
    }
}

ClearSteps(*) {
    Global IsRunning, MacroSteps
    if IsRunning {
        MsgBox("Please stop the macro before modifying steps.")
        return
    }
    
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
    Global IsRunning, ElapsedSeconds, LoopElapsedSeconds, TotalEstimatedSeconds, CurrentLoop, TotalLoopsLimit, CurrentStepIndex, MacroSteps

    if (MacroSteps.Length == 0) {
        MsgBox("Key list is empty. Please add at least one step first.")
        return
    }
    totalLoops := TotalLoopEdit.Value
    if (totalLoops == "") {
        MsgBox("Please enter a valid number of loops.")
        return
    }

    loopTimeMs := 0
    for index, step in MacroSteps {
        loopTimeMs += step["Delay"] + step["Duration"]
    }
    TotalEstimatedSeconds := Round((loopTimeMs / 1000) * totalLoops)

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
    Global IsRunning, ElapsedSeconds, LoopElapsedSeconds, TotalEstimatedSeconds, CurrentLoop, CurrentStepIndex, MacroSteps, CurrentStartHotkey

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
    TotalEstimatedSeconds := 0
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
    Global ElapsedSeconds, LoopElapsedSeconds, TotalEstimatedSeconds, CurrentLoop, TotalLoopsLimit, CurrentStepIndex, MacroSteps
    
    mTotal := Floor(ElapsedSeconds / 60)
    sTotal := Mod(ElapsedSeconds, 60)
    
    remSecs := TotalEstimatedSeconds - ElapsedSeconds
    if (remSecs < 0)
        remSecs := 0
    mRem := Floor(remSecs / 60)
    sRem := Mod(remSecs, 60)
    
    mLoop := Floor(LoopElapsedSeconds / 60)
    sLoop := Mod(LoopElapsedSeconds, 60)
    
    stepStr := IsRunning ? CurrentStepIndex : 0
    totalStepStr := MacroSteps.Length
    
    TimerText.Value := Format("Time: {:02}:{:02} (Left: {:02}:{:02}) | LoopTime: {:02}:{:02} | L: {}/{} | S: {}/{}", mTotal, sTotal, mRem, sRem, mLoop, sLoop, CurrentLoop, TotalLoopsLimit, stepStr, totalStepStr)
}
