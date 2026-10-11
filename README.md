# AI-enabled Software Delivery – Session 1 workshop

Facilitator repository for the **Work differently with AI** hands-on session.

---

## Repository structure

| Path | Contents |
|---|---|
| `workshop/exercise1/` | Exercise 1 starting state – baseline Northwind Energy app, no offer comparison |
| `workshop/exercise2/` | Exercise 2 starting state – comparison feature built + `/docs` context |
| `FACILITATOR.md` | Setup checklist, delivery guide, and recovery scenarios |
| `setup-environment.ps1` | Windows per-user installer (Node, Git, VS Code) |
| `uninstall-environment.ps1` | Reverses only what Windows setup installed |
| `setup-environment.sh` | macOS per-user installer (Node, Git, VS Code) |
| `scripts/` | Shared helpers for the setup scripts |
| `calculator/` | TypeScript smoke-test app to verify the environment setup |

*Northwind Energy is a fictional product created for workshop purposes only.*

---

## Facilitator quick start

1. Clone or download this repository.
2. Run `setup-environment.ps1` on participant Windows machines, or
   `setup-environment.sh` on Macs (see the sections below).
3. Read `FACILITATOR.md` for the complete delivery and recovery guide.
4. Share `workshop/exercise1/` and `workshop/exercise2/` with participants (e.g. as a zip).
5. Participants open **one folder** at a time in VS Code, run `npm install` once, then `npm run dev`.

---

## Windows environment setup

The `setup-environment.ps1` script sets up the following for the current user when it is not already available:

- Node.js 24 LTS with npm (pinned version and checksum-verified download). An existing supported Node.js installation is reused instead.
- Git for Windows with Git Credential Manager.
- VS Code User Setup. VS Code 1.116+ includes Copilot features, so this script does not download Marketplace extensions.

The scripts support Windows x64 and ARM64, require neither WSL nor Docker, and do not change system-wide settings. New Node.js installs are placed under `%LOCALAPPDATA%\AI-Development-Course`; new Git and VS Code installs are per-user. Downloads come from the official vendors: Node and Git are verified with SHA-256, and the VS Code installer with a Microsoft digital signature. Setup records only what it installed or added to your PATH so that uninstall can leave pre-existing software alone.

### 1. Check what's already installed

Download this repository as a ZIP from GitHub and extract it, keeping the `scripts/` folder beside the setup and uninstall scripts. Open **64-bit Windows PowerShell** (not as administrator) in the extracted directory. Check what is already available:

```powershell
node --version
npm.cmd --version
git --version
code --version
```

Errors saying a command is not recognized are expected when a tool is not installed.

### 2. Temporarily allow scripts (if needed)

If PowerShell blocks the setup script, **only if your IT policy allows it**, run this in the same PowerShell window before setup:

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
```

`Process` scope expires when you close the window; it does not change the `LocalMachine` or `CurrentUser` policy and cannot override an IT-enforced `MachinePolicy` or `UserPolicy`. Do not run scripts you have not reviewed or that IT has not approved.

### 3. Run setup

In that PowerShell window, run:

```powershell
.\setup-environment.ps1
```

When setup finishes, open a new terminal and check:

```powershell
node --version
npm.cmd --version
git --version
code --version
```

Open VS Code and sign in with your own GitHub account; confirm Copilot Chat actually works. Your organization must grant Copilot access. Re-running setup uses existing working software instead of downloading it again. It requires Node.js 22.12+ LTS (or a newer even-numbered release) and VS Code 1.116+; update older installations through IT.

**Check with IT first:** the device must allow downloads from `nodejs.org`, `github.com`, and `update.code.visualstudio.com`, including their download CDNs, and must allow the downloaded programs to run. If VS Code/Copilot sign-in reports a certificate or proxy error, ask IT to configure the corporate certificate chain; do not disable TLS verification.

TypeScript, testing, and linting tools belong in the course project as project dependencies with a `package-lock.json`. This script intentionally does not install these packages globally.

### 4. Try the calculator

The [`calculator/`](calculator/) directory contains a small browser app written in plain TypeScript. It checks that npm can install packages, TypeScript can compile, tests can run, and a local app can open in a browser. From a **new PowerShell terminal** after running setup:

```powershell
cd calculator
npm.cmd ci
npm.cmd test
npm.cmd run build
npm.cmd run dev
```

In PowerShell, `npm` may run `npm.ps1`, which some execution policies block. `npm.cmd` calls the standard Windows launcher instead; if `npm` works for you, either command is fine.

Open the local address printed by Vite (normally `http://127.0.0.1:5173/`). Try `0.1 + 0.2 =` and press **Esc** to clear. You can also use the keyboard: digits, `+`, `-`, `*`, `/`, **Enter**, **Backspace** and **Escape**. Edit `calculator/src/` to see the page update automatically.

The app listens on your computer only. IT must also allow access to `registry.npmjs.org` for `npm.cmd ci` and local loopback traffic for the preview. Copilot requires a separate GitHub sign-in in VS Code.

### 5. Uninstall the course environment (optional)

Close VS Code and any apps using Git or Node.js. From **Windows PowerShell** (not as administrator) in the extracted repository, run:

```powershell
.\uninstall-environment.ps1
```

If script execution is blocked, use the same IT-approved, process-only command above in that window first. The uninstaller asks **y/N for each eligible Node.js, Git, and VS Code component before removing any selected components**.

Only apps recorded as installed by this setup are eligible. It removes each selected app and its matching user PATH entry together. If the app is not removed, its PATH is left alone, including when setup added that entry for a pre-existing app. Installations without a setup receipt, personal projects, VS Code settings, and manually installed extensions are left untouched.

After processing your selections, the uninstaller also removes leftover `%TEMP%\ai-course-<random-id>` download folders from previous setup runs. It removes the receipt directory and `%LOCALAPPDATA%\AI-Development-Course` only when they are empty; they remain if another component, receipt, or personal file is still there.

---

## macOS environment setup

The `setup-environment.sh` script sets up the following for the current user when it is not already available:

- Node.js 24 LTS with npm (pinned version and checksum-verified download). An existing supported Node.js installation is reused instead, including one managed by a version manager such as nvm, fnm, asdf or Volta.
- Git. macOS has no per-user silent Git installer, so the script reuses a working `git`, and otherwise installs it with Homebrew when Homebrew is present.
- VS Code. VS Code 1.116+ includes Copilot features, so this script does not download Marketplace extensions.

The script supports Apple Silicon and Intel Macs, requires neither sudo nor Docker, and does not change system-wide settings. New Node.js installs are placed under `~/Library/Application Support/AI-Development-Course`; VS Code is installed into `/Applications`. Downloads come from the official vendors: Node is verified with SHA-256, and the VS Code download with its Apple code signature and Gatekeeper. Setup records only what it installed or added to your PATH, so pre-existing software is left alone.

### 1. Check what's already installed

Download this repository as a ZIP from GitHub and extract it, keeping the `scripts/` folder beside the setup script. Open **Terminal** in the extracted directory and check what is already available:

```bash
node --version
npm --version
git --version
code --version
```

`command not found` errors are expected when a tool is not installed.

If `git --version` opens a dialog asking to install the command line developer tools, accept it, or run `xcode-select --install` and wait for it to finish. Every Mac has a `/usr/bin/git` stub even when Git itself is absent, so that dialog means Git is not really installed yet.

### 2. Run setup

```bash
chmod +x ./setup-environment.sh
./setup-environment.sh
```

Do not run it with `sudo`; the script refuses to run as root because everything it installs is per-user. When setup finishes, open a new terminal and check:

```bash
node --version
npm --version
git --version
code --version
```

Open VS Code and sign in with your own GitHub account; confirm Copilot Chat actually works. Your organization must grant Copilot access. Re-running setup uses existing working software instead of downloading it again. It requires Node.js 22.12+ LTS (or a newer even-numbered release) and VS Code 1.116+; update older installations through IT.

If the script reports that Git is unavailable and you have no Homebrew, run `xcode-select --install`, then run setup again. If it reports that `/Applications` is not writable, ask IT to install VS Code 1.116 or newer and run setup again.

**Check with IT first:** the device must allow downloads from `nodejs.org`, `update.code.visualstudio.com`, and their download CDNs, and must allow the downloaded programs to run. If VS Code/Copilot sign-in reports a certificate or proxy error, ask IT to configure the corporate certificate chain; do not disable TLS verification.

TypeScript, testing, and linting tools belong in the course project as project dependencies with a `package-lock.json`. This script intentionally does not install these packages globally.

### 3. Try the calculator

The [`calculator/`](calculator/) directory contains a small browser app written in plain TypeScript. It checks that npm can install packages, TypeScript can compile, tests can run, and a local app can open in a browser. From a **new terminal** after running setup:

```bash
cd calculator
npm ci
npm test
npm run build
npm run dev
```

Open the local address printed by Vite (normally `http://127.0.0.1:5173/`). Try `0.1 + 0.2 =` and press **Esc** to clear. You can also use the keyboard: digits, `+`, `-`, `*`, `/`, **Enter**, **Backspace** and **Escape**. Edit `calculator/src/` to see the page update automatically.

The app listens on your computer only. IT must also allow access to `registry.npmjs.org` for `npm ci` and local loopback traffic for the preview. Copilot requires a separate GitHub sign-in in VS Code.

### 4. What setup changed, and how to undo it

There is no macOS uninstaller script yet. Setup records what it did in `~/Library/Application Support/AI-Development-Course/setup-receipts/`, one JSON file per component, so you can see exactly what to undo:

```bash
cat ~/Library/Application\ Support/AI-Development-Course/setup-receipts/*.json
```

Each receipt names the `InstallPath` it created, the `PathEntry` it added, and the `ProfilePath` it edited. `Installed: false` means the software was already on the machine and setup only added it to your PATH, so leave the software alone. A component with no receipt was not touched by setup at all.

To undo it by hand, close VS Code and any apps using Git or Node.js, then:

1. Delete the marker block from the profile named in the receipt. It is delimited exactly like this, and nothing outside it was changed:
   ```sh
   # >>> ai-development-course >>>
   export PATH="...:$PATH"
   # <<< ai-development-course <<<
   ```
2. For a receipt with `Installed: true`, delete its `InstallPath` — the Node.js directory under `~/Library/Application Support/AI-Development-Course`, or `/Applications/Visual Studio Code.app`.
3. Delete the receipt, then `~/Library/Application Support/AI-Development-Course` once it is empty.

Git installed through Homebrew is not recorded in a receipt because Homebrew owns it; remove it with `brew uninstall git` if you want it gone. Personal projects, VS Code settings, and manually installed extensions are never touched.

### 5. Tests

`tests/macos-setup.tests.sh` covers the setup lifecycle with stubbed downloads and a sandboxed `HOME`, so it installs nothing:

```bash
/bin/bash tests/macos-setup.tests.sh
```
