<div align="center">

![header](https://capsule-render.vercel.app/api?type=waving&color=0:0f172a,100:38bdf8&height=275&section=header&text=GITHUB%20ONE-CLICK&fontSize=52&fontColor=ffffff&animation=fadeIn&desc=Push%20Toolkit%20%7C%20Windows%20%E2%80%A2%20BAT%20%E2%80%A2%20PowerShell&descAlignY=65)

[![Typing SVG](https://readme-typing-svg.herokuapp.com?font=Fira+Code&weight=700&size=26&pause=1000&center=true&vCenter=true&width=1000&height=90&lines=Double-click+a+BAT+file+%E2%86%92+your+project+is+on+GitHub;Login+%E2%86%92+Create+Repo+%E2%86%92+Push+%E2%80%94+Fully+Automatic;No+Git+Commands.+No+github.com%2Fnew.+Just+a+repo+name.;Safe+Merge+into+Existing+Repos+%E2%80%94+Never+Force+Push)](https://github.com/ArulAgnes/GitHub-OneClick-Push-Toolkit)

<br>

![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6?style=for-the-badge&logo=windows&logoColor=white)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1-5391FE?style=for-the-badge&logo=powershell&logoColor=white)
![Batch](https://img.shields.io/badge/Batch-.bat-4D4D4D?style=for-the-badge&logo=windowsterminal&logoColor=white)
![Git](https://img.shields.io/badge/Git-Automation-F05032?style=for-the-badge&logo=git&logoColor=white)
![GitHub CLI](https://img.shields.io/badge/GitHub%20CLI-gh-181717?style=for-the-badge&logo=github&logoColor=white)

![Visibility](https://img.shields.io/badge/New%20Repos-Public-38bdf8?style=for-the-badge)
![Force Push](https://img.shields.io/badge/Force%20Push-Never-22c55e?style=for-the-badge)
![Prompts](https://img.shields.io/badge/You%20Type-Repo%20Name%20Only-f59e0b?style=for-the-badge)

</div>

---

## 🚀 What is this?

A small **one-click toolkit for Windows** that takes any project folder and puts it on your GitHub profile.
Double-click a `.bat` file, sign in through the browser, pick your folder, type a repository name — **done**.

Built for people who don't want to remember `git init`, `git add`, `git commit`, `git remote`, `git push`
— and perfect for **uploading a project from a friend's laptop** to your own GitHub account.

---

## ✨ Features

<table>
<tr>
<td width="50%">

### 🔐 Smart Login
Browser-based `gh auth login`, only when needed. Already signed in? It skips straight ahead.

### 📂 Folder Picker
A normal Windows folder window opens — choose your project, no paths to type.

### 🆕 Create + Push
Creates a **public** repository and pushes your whole project to `main`.

</td>
<td width="50%">

### 🔀 Safe Merge Mode
Repo already exists? It fetches, merges the GitHub history with yours and pushes. **No force push, ever.**

### 🛡️ Secret Guard
Warns before uploading `.env`, `.pem`, `.key`, `id_rsa` files. Your `.gitignore` is respected.

### 🧹 Friend-Laptop Friendly
Git identity is set **per project only**, and a one-click **logout** removes your access afterwards.

</td>
</tr>
</table>

---

## 🧩 How it works

```mermaid
flowchart LR
    A([Double-click .bat]) --> B{Git + GitHub CLI installed?}
    B -- No --> C[Offer winget install]
    B -- Yes --> D{Logged in?}
    C --> D
    D -- No --> E[Browser login]
    D -- Yes --> F[Pick project folder]
    E --> F
    F --> G[Type repo name]
    G --> H{Repo exists on GitHub?}
    H -- No --> I[Create PUBLIC repo]
    H -- Yes --> J[Fetch + merge history]
    I --> K[Push to main]
    J --> K
    K --> L([Browser opens your repo])
```

---

## 📦 What's inside

| File | Purpose |
|---|---|
| 🟢 `00-FULL-Automatic-Login-Create-Push.bat` | **Everything in one run** — login → folder → repo name → create or merge → push |
| 🔑 `01-Login-to-My-GitHub.bat` | Login only (browser) |
| 🆕 `02-Create-New-Public-Repository.bat` | Create a **new public** repo and push the project |
| 🔀 `03-Push-Existing-Repository-Merge.bat` | Merge with an **existing** repo and push safely |
| 🚪 `04-Logout-From-GitHub.bat` | Log out — use this on someone else's PC |
| 📘 `README-STEP-BY-STEP.txt` | Plain-text teaching guide |

> Every `.bat` launches the `.ps1` with the same name. **Keep each pair in the same folder.**

<details>
<summary><b>📁 Project structure</b></summary>

```text
GitHub-OneClick-Push-Toolkit/
├── 00-FULL-Automatic-Login-Create-Push.bat / .ps1
├── 01-Login-to-My-GitHub.bat / .ps1
├── 02-Create-New-Public-Repository.bat / .ps1
├── 03-Push-Existing-Repository-Merge.bat / .ps1
├── 04-Logout-From-GitHub.bat / .ps1
├── README-STEP-BY-STEP.txt
└── README.md
```

</details>

---

## ⚡ Quick Start

**1️⃣ Get the toolkit**

```bash
git clone https://github.com/ArulAgnes/GitHub-OneClick-Push-Toolkit.git
```

or click **Code → Download ZIP** and extract it (don't run files from inside the ZIP).

**2️⃣ Run the one-click file**

```text
Double-click  00-FULL-Automatic-Login-Create-Push.bat
```

**3️⃣ Follow the window**

1. Copy the one-time code → press Enter → paste in the browser → **Authorize**
2. Select your project folder
3. Type the repository name
4. Your repo opens in the browser 🎉

---

## 🎓 Step-by-step mode (for teaching)

| Step | Run | Result |
|:---:|---|---|
| **1** | `01-Login-to-My-GitHub.bat` | Signed in to GitHub |
| **2** | `02-Create-New-Public-Repository.bat` | New public repo created and pushed |
| **3** | `03-Push-Existing-Repository-Merge.bat` | Existing repo merged and pushed |
| **4** | `04-Logout-From-GitHub.bat` | Laptop no longer has access to your account |

---

## 📋 Requirements

| Requirement | Link |
|---|---|
| Windows 10 / 11 with PowerShell 5.1 | Built in |
| Git for Windows | [git-scm.com/download/win](https://git-scm.com/download/win) |
| GitHub CLI | [cli.github.com](https://cli.github.com/) |

> 💡 If Git or GitHub CLI is missing, the script offers to install them with `winget`. After installing, close the window and run the BAT again.

---

## 🔒 Safety notes

- 🌍 **New repositories are public** — everyone can see the committed files. Check your project first.
- 🛑 `.env`, `.pem`, `.key`, `.pfx`, `.p12`, `id_rsa`, `id_ed25519` files trigger a warning; you must type `YES` to continue.
- 🙈 Put `node_modules`, build folders and secrets in `.gitignore` — it is always respected.
- 🚫 The scripts **never force-push** and never delete your files.
- ⚠️ On a conflict the merge is cancelled safely and the conflicting files are listed.
- 🚪 On a shared or friend's laptop, always run `04-Logout-From-GitHub.bat` when finished.

<details>
<summary><b>🛠️ Troubleshooting</b></summary>

| Problem | Fix |
|---|---|
| `Name already exists` | Use `03-Push-Existing-Repository-Merge.bat` or choose another name |
| `Repository not found` | Check the spelling and that you are logged in to the right account |
| Merge conflict | Same file changed on GitHub and locally — fix it, then run step 3 again |
| Window closes instantly | Extract the ZIP first, keep `.bat` and `.ps1` together |
| Wrong account | Run `04-Logout`, then `01-Login` |
| Want it private | GitHub → repo → **Settings → Danger Zone → Change visibility** |

</details>

---

## 🛠️ Tech Stack

![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?style=for-the-badge&logo=powershell&logoColor=white)
![Git](https://img.shields.io/badge/Git-F05032?style=for-the-badge&logo=git&logoColor=white)
![GitHub](https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)

---

## 🌐 More from me

<div align="center">

[![Portfolio](https://img.shields.io/badge/🌐%20Live%20Portfolio-Visit%20Now-38bdf8?style=for-the-badge&logo=vercel&logoColor=white)](https://arul-portfolio-taupe.vercel.app/)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Arul%20Agnes-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/arul-agnes-668637269)
[![GitHub](https://img.shields.io/badge/GitHub-ArulAgnes-0f172a?style=for-the-badge&logo=github)](https://github.com/ArulAgnes)

⭐ **If this saved you time, star the repo!** ⭐

![footer](https://capsule-render.vercel.app/api?type=waving&color=0:38bdf8,100:0f172a&height=140&section=footer&text=Made%20by%20ARUL%20AGNES&fontSize=26&fontColor=ffffff&animation=fadeIn&fontAlignY=70)

</div>
