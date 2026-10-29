# Security

## Reporting a vulnerability

Please **do not** open a public issue for security problems. Use GitHub's private reporting instead: go to the **Security** tab of this repository and click **Report a vulnerability**. You should get a reply within 7 days.

## Design and threat model

Tobii Guard is a single plain-text AutoHotkey v2 script. Its security properties are meant to be checkable by reading `tobii-guard.ahk`.

| Property | How it is enforced |
|---|---|
| Least privilege | The script exits immediately if it is running as administrator (`A_IsAdmin`). It only acts on the signed-in user's own processes. |
| Narrow target | A process is ended only if its name is exactly `Tobii.EyeX.Interaction.exe` **and** its full path is exactly `%ProgramFiles%\Tobii\Tobii EyeX\Tobii.EyeX.Interaction.exe` (or the `Program Files (x86)` equivalent). Both are case-insensitive exact matches, not substring or wildcard matches. If the path cannot be read, nothing is ended. |
| No network | The script contains no networking calls. |
| No registry | The script contains no registry calls. |
| No code execution | The script runs no other programs, with one exception: `explorer.exe` to open the log folder when you click **Open log folder**. It does not read or evaluate any external input, configuration file or command-line argument. |
| Bounded file writes | Only `%LOCALAPPDATA%\TobiiGuard\log.txt` (rotated at about 100 KB to `log.txt.old`) and, if you opt in from the tray menu, one shortcut in your own Startup folder. The log contains timestamps, process IDs and file paths of the target process only. |
| No persistence by default | Nothing starts automatically unless you tick **Start with Windows**, which you can untick at any time. |

### Things to be aware of

- **Run only a copy you trust.** Like any script, a modified copy could do anything AutoHotkey can do. Download from this repository's Releases page, check the SHA-256 hash, and read the script before running it.
- **Keep the script in a folder only you can write to** (for example under `Documents`). The Startup shortcut runs whatever file is at that path.
- **AutoHotkey itself** should come only from the official site, [autohotkey.com](https://www.autohotkey.com/).

## Release integrity

Release zips are built by the [release workflow](.github/workflows/release.yml) on GitHub's servers from the tagged commit, using no third-party actions. Each release includes `SHA256SUMS.txt`. The `.ahk` file inside the zip is byte-for-byte the file at that tag (with Windows line endings, per `.gitattributes`).
