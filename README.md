# pre-commit

This project provides an automated setup for a **Git pre-commit hook** that uses [Gitleaks](https://github.com/gitleaks/gitleaks) to detect secrets like **Telegram bot tokens** before you commit code.

## Installation

First, `cd` into the root of your GitHub repository and run one of the following commands depending on your system:

### **Linux / macOS**

```bash
curl -sSL https://raw.githubusercontent.com/ipostnikov/pre-commit/main/setup.sh | sh
```

### **Windows**

Please use **Git Bash** or **Git CMD**, then run the same command:

```bash
curl -sSL https://raw.githubusercontent.com/ipostnikov/pre-commit/main/setup.sh | sh
```

⚠️ **Note:** On Windows, native PowerShell or CMD without Git Bash is not supported for this script.

---

## Usage Example

```bash
➜  newcom git:(master) ✗ curl -sSL https://raw.githubusercontent.com/ipostnikov/pre-commit/main/setup.sh | sh
Creating gitleaks configuration with Telegram bot token rule...
Creating pre-commit hook...
Setup complete. Pre-commit hook is active.
```

Once installed, when you try to commit a file containing a secret, the hook will automatically run:

```bash
➜  newcom git:(master) ✗ git add TELE_TOKEN
➜  newcom git:(master) ✗ git commit -m "test commit"
Running gitleaks to check for secrets...

    ○
    │╲
    │ ○
    ○ ░
    ░    gitleaks

Finding:     TELE_TOKEN=7304244298:AAFYsVfKSLTh9uroBAitiuDKXlTuGaksmCw
Secret:      7304244298:AAFYsVfKSLTh9uroBAitiuDKXlTuGaksmCw
RuleID:      telegram-bot-token
Entropy:     4.952591
Tags:        [telegram secret]
File:        TELE_TOKEN
Line:        1
Fingerprint: TELE_TOKEN:telegram-bot-token:1

11:04AM INF 0 commits scanned.
11:04AM INF scanned ~58 bytes (58 bytes) in 1.83ms
11:04AM WRN leaks found: 1
Error: gitleaks detected secrets. Commit rejected.
```

---

## Notes

- The pre-commit hook prevents commits containing secrets based on the `.gitleaks.toml` config.
- You can edit `.gitleaks.toml` to add more rules or customize behavior.
- To temporarily disable the hook:

```bash
git config --bool hooks.gitleaks.enable false
```

To enable it again:

```bash
git config --bool hooks.gitleaks.enable true
```

---

## Requirements

- **Git** installed.
- **curl** and **tar** available in your system's PATH.
- On Windows, **Git Bash** or **Git CMD** is required for the hook to work properly.
