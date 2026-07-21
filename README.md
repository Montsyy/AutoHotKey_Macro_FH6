# Custom Macro Builder (AutoHotkey v2) 'Forza Horizon 6'

A flexible, GUI based macro builder written in AutoHotkey v2. This tool allows users to easily record keystrokes, set custom delays, define hold durations, and execute the sequence in a controlled loop.

## Features

* **GUI Based Configuration:** Easy to use interface to build your macro step by step.
* **Auto Key Recording:** Built in key catcher to record any keystroke (including modifier keys like Ctrl, Shift, Esc, Win, etc.).
* **Custom Timings:** Define precise delay (wait time before press) and hold duration for every single key in seconds (e.g., 0.5 for half a second).
* **Dynamic Hotkeys:** Change the Start/Stop hotkey directly from the UI without editing the code.
* **Advanced Tracking:** Real time tracking of total elapsed time, current loop time, loop count, and active step.
* **Safe Exit:** Closing the GUI completely terminates the script from the background to prevent unwanted macro execution.

## Prerequisites

* [AutoHotkey v2](https://www.autohotkey.com/) must be installed on your Windows machine.

## Installation and Usage

1. Download or clone this repository.
2. Make sure you have AutoHotkey v2 installed.
3. Double click the `.ahk` script file to run the program.

## How to Build a Macro

1. **Record a Key:** Click the **Record** button and press any key on your keyboard.
2. **Set Timings:**
   * **Delay (s):** Time to wait before pressing the key.
   * **Duration (s):** How long to hold the key down.
3. **Add Step:** Click **Add** to insert the step into your macro sequence. Repeat this to chain multiple keys.
4. **Configure Execution:**
   * Set the **Total Loops (Tick)** for how many times the entire sequence should run.
   * Set your preferred **Start/Stop Hotkey** and click **Set Hotkey**.
5. **Run:** Press your configured hotkey to start the macro. Press it again to stop it at any time.

## Important Notes

* If you close the program window (via the X button), the script will fully terminate and exit the system memory.
* The macro is designed for flexibility and safety. If you forcefully stop the macro while it is running, it will automatically release all held keys to prevent them from getting stuck.
