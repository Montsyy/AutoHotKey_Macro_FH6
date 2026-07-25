# Custom Macro Builder (AutoHotkey v2)

A powerful, GUI based macro builder written in AutoHotkey v2. This tool allows users to easily record keystrokes in real time, set custom delays, manage macro presets, and execute sequences in a controlled loop.

<img width="733" height="514" alt="Image" src="https://github.com/user-attachments/assets/71bea29d-4243-44f6-a7b6-b85a2577c5d5" />

## Features

* **Live Record Mode:** Record your physical keystrokes, delays, and hold durations in real time. Just press record, do your actions, and let the program calculate the precise timings for you.
* **Preset System (Memory):** Save your macro configurations (steps, total loops, and start hotkey) into a profile and load them instantly anytime.
* **Step Management:** Click on any step in the list to easily edit its key, delay, or duration, or delete specific steps without clearing the whole list.
* **Custom Timings:** Manually define precise delay (wait time before press) and hold duration for every single key in seconds (e.g., 0.5 for half a second).
* **Advanced Tracking & Countdown:** Real time tracking of total elapsed time, estimated time left (countdown), current loop time, loop count, and active step.
* **Dynamic Hotkeys:** Change the Start/Stop hotkey directly from the UI without editing the code.
* **Safety Locks:** The UI prevents accidental edits or deletions while the macro is actively running to ensure stability.
* **Safe Exit:** Closing the GUI completely terminates the script from the background to prevent unwanted macro execution.

## Prerequisites

* [AutoHotkey v2](https://www.autohotkey.com/) must be installed on your Windows machine.

## Installation and Usage

1. Download or clone this repository.
2. Make sure you have AutoHotkey v2 installed.
3. Double click the `.ahk` script file to run the program.
4. A file named `macro_presets.ini` will be generated automatically in the same folder when you save your first preset.

## How to Use

### Method 1: Live Recording (Recommended)
1. Click the **▶ START LIVE RECORD** button.
2. Perform your desired keystrokes and combos normally.
3. Press **F12** on your keyboard (or click the button again) to stop recording. The sequence will be added to the list automatically.

### Method 2: Manual Entry
1. Click the **Detect** button and press any key on your keyboard.
2. Set the **Delay (s)** and **Duration (s)**.
3. Click **Add** to insert the step into your macro sequence.

### Managing Steps
* **Edit:** Click any row in the table, modify the values in the input boxes above, and click **Edit**.
* **Delete:** Click any row in the table and click **Del** to remove it.

### Saving and Loading Presets
* **Save:** Type a name in the Preset box (e.g., "Farming Combo") and click **Save**.
* **Load:** Click the dropdown arrow, select your saved preset, and click **Load**.

### Executing the Macro
1. Set the **Total Loops (Tick)** for how many times the entire sequence should run.
2. Set your preferred **Start/Stop Hotkey** and click **Set Hotkey**.
3. Press your configured hotkey to start the macro. Press it again to stop it at any time.

## Important Notes
* The macro is designed for flexibility and safety. If you forcefully stop the macro while it is running, it will automatically release all held keys to prevent them from getting stuck.
