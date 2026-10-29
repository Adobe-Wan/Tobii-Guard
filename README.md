# Tobii Guard

**Keeps Tobii Experience from silently breaking G-SYNC / VRR in games, without breaking head tracking.**

Tobii Guard is a single, readable [AutoHotkey v2](https://www.autohotkey.com/) script (about 200 lines). It ends one Tobii background process, `Tobii.EyeX.Interaction.exe`, whenever that process is running and the Tobii Experience window is closed. There is no installer, no `.exe` and no admin prompt, so you can read every line before you run it.

> **Made with Claude Code.** This project was written with [Claude Code](https://claude.com/claude-code), Anthropic's AI coding tool, working with the repository owner, who found the problem, confirmed the cause on their own PC and tested the fix. Please review the script yourself; it is short on purpose.

> **Not affiliated with Tobii.** "Tobii" and "Tobii Experience" are trademarks of Tobii AB. This project is independent and is not endorsed by or connected to Tobii AB.

---

## The problem

With Tobii Experience installed, a G-SYNC / FreeSync (VRR) monitor can stay locked at its maximum refresh rate in games, even in exclusive fullscreen, instead of following the game's frame rate. The NVIDIA settings still say G-SYNC is on, so the failure is silent.

**Cause:** `Tobii.EyeX.Interaction.exe` creates a window titled `PeekerWindow`:

| Property | Value |
|---|---|
| Owner | `Tobii.EyeX.Interaction.exe` (`%ProgramFiles%\Tobii\Tobii EyeX\`) |
| Class | `HwndWrapper[Tobii.EyeX.Interaction.exe;;<guid>]` |
| Size and position | 1 x 1 pixel at the top-left of the primary display |
| State | visible |
| Extended styles | `WS_EX_TOPMOST`, `WS_EX_LAYERED`, `WS_EX_TRANSPARENT` |

A visible, always-on-top layered window above a game makes Windows **compose** the game through the desktop compositor (DWM) instead of handing it the display directly (**Independent Flip**). Composed presentation is incompatible with G-SYNC / VRR, and typically costs frame rate and frame-time consistency too. Any always-on-top overlay can do this; this one is invisible, so it is hard to find.

**Why ending it is safe for head tracking:** head and eye tracking in games use Tobii's service and engine (`Tobii.Service`, `Tobii.EyeX.Engine`, `TobiiVirtualDevice`). Tobii Guard never touches those. Only the Interaction component (Windows-level features of Tobii Experience) is stopped.

### Check it on your own PC

You do not need to trust this README:

1. Turn on your monitor's own refresh-rate / FPS counter (many monitors have one in the on-screen menu).
2. Start a game with Tobii Experience running. If the counter stays pinned at the maximum refresh rate while your frame rate is lower, VRR is not engaging.
3. In Task Manager > Details, end `Tobii.EyeX.Interaction.exe`. The counter should now follow your frame rate, and head tracking should keep working.

To see the window itself, use **Window Spy** (installed with AutoHotkey) or Microsoft Spy++ and look for `PeekerWindow` at the top-left corner of your main screen. To see the presentation mode, [PresentMon](https://github.com/GameTechDev/PresentMon) reports `Composed: Flip` while the window exists and `Hardware: Independent Flip` after it is gone.

## What Tobii Guard does

Every 5 seconds it:

1. Looks for a process named exactly `Tobii.EyeX.Interaction.exe`.
2. Leaves it alone if the **Tobii Experience window is open on screen**, so you can still use the app normally. When you close the app to the tray, protection resumes.
3. Checks that the process file is Tobii's own, at exactly `%ProgramFiles%\Tobii\Tobii EyeX\Tobii.EyeX.Interaction.exe` (or the `Program Files (x86)` equivalent). Anything else is logged and left alone.
4. Ends that one process and writes a line to its log.

In testing, Tobii's engine does not restart the process on its own, so in practice it is ended once after you sign in.

### What it does not do

- It does **not** run as administrator. It refuses to start if launched elevated.
- It makes **no network connections** and collects no data.
- It writes **nothing to the registry** and installs no services or scheduled tasks.
- It **only ever ends** `Tobii.EyeX.Interaction.exe`, verified by exact name and exact file path. It never touches the Tobii service, engine, drivers or any other process.
- It does not modify, patch or inject into any Tobii file or process.

The only files it writes:

| Path | When |
|---|---|
| `%LOCALAPPDATA%\TobiiGuard\log.txt` (and `log.txt.old`, max ~100 KB each) | always |
| `%LOCALAPPDATA%\TobiiGuard\setup-done` (empty file) | after the first-run question, so it is asked only once |
| `%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\Tobii Guard.lnk` | only if you answer **Yes** on first run or tick **Start with Windows** in the tray menu |

## Why not just delete or rename the Tobii file?

- It lives in `Program Files`, so changing it needs administrator rights and modifies Tobii's own installation.
- Tobii updates and repairs put the file back, so the problem silently returns.
- Tobii Experience would show its troubleshooter all the time. Tobii Guard lets Interaction run while you have the app open and removes it only when you close the app.
- Undoing Tobii Guard is one click, and no Tobii file is ever touched.

## Trade-offs

- While Tobii Guard is active, Tobii Experience's Windows features that depend on the Interaction component are off. If you open the Tobii Experience app, Interaction is left alone; restart Tobii Experience to bring it back.
- Tobii Experience may show a **"Something's not quite right"** banner or offer a troubleshooter because Interaction is missing. That is expected; head tracking still works.
- If a future Tobii update moves or renames the file, Tobii Guard will log the unexpected path and do nothing, which is the safe failure mode.

## Install

**Requirements:** Windows 10 or 11, a Tobii eye tracker with Tobii Experience, and [AutoHotkey v2](https://www.autohotkey.com/) (free, open source, installed from its official website).

1. Install **AutoHotkey v2** from [autohotkey.com](https://www.autohotkey.com/).
2. Download `tobii-guard-vX.Y.Z.zip` and `SHA256SUMS.txt` from the [latest release](https://github.com/Adobe-Wan/tobii-guard/releases/latest).
3. *(Recommended)* Verify the download in PowerShell:
   ```powershell
   Get-FileHash .\tobii-guard-v1.0.0.zip -Algorithm SHA256
   ```
   The hash must match the line in `SHA256SUMS.txt`. Releases are built by the public [GitHub Actions workflow](.github/workflows/release.yml) in this repository, straight from the tagged source.
4. Extract the zip to a folder you keep, for example `Documents\Tobii Guard`.
5. *(Recommended)* Open `tobii-guard.ahk` in Notepad and read it.
6. Double-click `tobii-guard.ahk`. A green **H** icon appears in the system tray.
7. On first run it asks **"Start Tobii Guard automatically every time you sign in to Windows?"** Click **Yes**.

That's the whole setup. From then on it starts by itself at every sign-in and runs quietly in the tray; there is nothing to toggle. You can change the startup choice any time from the tray menu.

You can also skip the zip entirely and download `tobii-guard.ahk` straight from this repository. It is the same file.

### Tray menu

| Item | Does |
|---|---|
| Pause | Temporarily stops checking (for example, to demo the problem). |
| Start with Windows | Adds or removes the shortcut in your Startup folder. |
| Open log folder | Opens `%LOCALAPPDATA%\TobiiGuard` in Explorer. |
| About | Version and link to this page. |
| Exit | Stops Tobii Guard. |

## Uninstall

1. Right-click the tray icon and untick **Start with Windows** (or delete `Tobii Guard.lnk` from `shell:startup`).
2. Right-click the tray icon > **Exit**.
3. Delete the folder you extracted, and `%LOCALAPPDATA%\TobiiGuard`.
4. Restart Tobii Experience (or sign out and back in) to get `Tobii.EyeX.Interaction.exe` back.

Nothing else on your system was changed.

## Tested with

| Component | Version |
|---|---|
| Windows | 11 Pro, build 26200 |
| Tobii Experience | 1.69.9.32600 (Microsoft Store) |
| Tobii EyeX (`Tobii.EyeX.Interaction.exe`) | 4.72.0.29983 |
| AutoHotkey | 2.0.28 |
| GPU / monitor | NVIDIA RTX 4080 SUPER (driver 621.01), 4K 240 Hz OLED, G-SYNC Compatible over DisplayPort |
| Game | Star Citizen (Vulkan), with Tobii head tracking |

Reports from other setups are welcome. Please open an issue with your versions and whether VRR started working.

## Why AutoHotkey and not an .exe?

A compiled, unsigned `.exe` from a small project is something Windows SmartScreen and antivirus tools rightly treat with suspicion, and you cannot read it. A plain-text `.ahk` script runs on the widely used, open-source AutoHotkey interpreter that you install from its official site, and the whole program is visible in one file.

## Security

See [SECURITY.md](SECURITY.md) for the threat model and how to report a vulnerability privately.

## License

[MIT](LICENSE)
