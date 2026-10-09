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
| `uninstall-environment.ps1` | Reverses only what setup installed |
| `calculator/` | TypeScript smoke-test app to verify the environment setup |

*Northwind Energy is a fictional product created for workshop purposes only.*

---

## Facilitator quick start

1. Clone or download this repository.
2. Run `setup-environment.ps1` on participant Windows machines (see section below).
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
