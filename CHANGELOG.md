# Changelog

## 1.0.0 (2026-10-29)

First public release.

- Ends `Tobii.EyeX.Interaction.exe` so its always-on-top `PeekerWindow` no longer breaks G-SYNC / VRR and Independent Flip.
- Ends it only when the file path is Tobii's own install path.
- Leaves it running while the Tobii Experience window is open on screen.
- Refuses to run as administrator.
- Logs to `%LOCALAPPDATA%\TobiiGuard\log.txt` (rotated at about 100 KB).
- Tray menu: Pause, Start with Windows, Open log folder, About, Exit.
