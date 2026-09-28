# Windows setup without administrator rights

The `setup-environment.ps1` script sets up the following for the current user:

- Node.js 24 LTS with npm (pinned version and checksum-verified download).
- Git for Windows with Git Credential Manager, unless Git is already available.
- VS Code User Setup, unless VS Code is already available.
- VS Code extensions: GitHub Copilot, ESLint, and Prettier.

The script supports Windows x64 and ARM64, requires neither WSL nor Docker, and does not change system-wide settings. Node.js is placed under `%LOCALAPPDATA%\AI-Development-Course`; Git and VS Code are installed for the current user. Downloads come from the official vendors: Node and Git are verified with SHA-256, and the VS Code installer with a Microsoft digital signature.

## Run

Download this repository as a ZIP from GitHub and extract it. Open **64-bit Windows PowerShell** (not as administrator) in the extracted directory:

```powershell
.\setup-environment.ps1
```

When the script finishes, open a new terminal and check:

```powershell
node --version
npm --version
git --version
code --version
```

Open VS Code and sign in with your own GitHub account to use Copilot. Your organization must grant Copilot access. Re-running the script skips software and extensions that are already installed.

**Check with IT first:** the device must allow downloads from `nodejs.org`, `github.com`, `update.code.visualstudio.com`, and the VS Code Marketplace, including redirects to GitHub and Microsoft download CDNs. It must also allow this PowerShell script and the downloaded programs to run. The script does not bypass execution or security policies; IT must approve the setup if a policy blocks it.

TypeScript, testing, and linting tools belong in the course project as project dependencies with a `package-lock.json`. Use `npm ci` there; this script intentionally does not install these packages globally.
