# ---------------- shared helpers (Windows PowerShell 5.1 safe) ----------------
# NOTE: "Continue" (not "Stop") on purpose. In PS 5.1, "Stop" turns normal
# git/gh messages into fatal errors. We check $LASTEXITCODE ourselves instead.
$ErrorActionPreference = "Continue"

function Write-Title([string]$text) {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host " $text" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
}
function Write-Step([string]$text) { Write-Host ""; Write-Host ">> $text" -ForegroundColor Yellow }
function Write-Ok([string]$text)   { Write-Host "   OK: $text" -ForegroundColor Green }

function Close-Window([int]$code) {
    Write-Host ""
    Read-Host "Press Enter to close this window" | Out-Null
    exit $code
}
function Stop-WithError([string]$message) {
    Write-Host ""
    Write-Host "ERROR: $message" -ForegroundColor Red
    Write-Host "Nothing was force-pushed and no files were deleted." -ForegroundColor DarkYellow
    Close-Window 1
}
function Test-Command([string]$name) { return [bool](Get-Command $name -ErrorAction SilentlyContinue) }

function Confirm-Tools {
    Write-Step "Checking Git and GitHub CLI"
    $missing = @()
    if (-not (Test-Command "git")) { $missing += "Git" }
    if (-not (Test-Command "gh"))  { $missing += "GitHub CLI" }
    if ($missing.Count -eq 0) { Write-Ok "Git and GitHub CLI are installed"; return }
    Write-Host "Missing: $($missing -join ', ')" -ForegroundColor Red
    if (Test-Command "winget") {
        $answer = Read-Host "Install the missing tools now with winget? (Y/N)"
        if ($answer -match '^[Yy]') {
            if (-not (Test-Command "git")) { winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements }
            if (-not (Test-Command "gh"))  { winget install --id GitHub.cli -e --source winget --accept-package-agreements --accept-source-agreements }
            Write-Host ""
            Write-Host "Installation finished. CLOSE this window and double-click the BAT file again." -ForegroundColor Green
            Close-Window 0
        }
    }
    Stop-WithError "Install Git (https://git-scm.com/download/win) and GitHub CLI (https://cli.github.com/), then run again."
}

function Test-LoggedIn {
    gh auth status *> $null
    return ($LASTEXITCODE -eq 0)
}

function Confirm-Login {
    Write-Step "Checking GitHub login"
    if (-not (Test-LoggedIn)) {
        Write-Host "You are not logged in. Browser login will start now." -ForegroundColor Yellow
        Write-Host "1) Copy the one-time code shown below  2) Press Enter  3) Paste it in the browser  4) Click Authorize" -ForegroundColor Gray
        Write-Host ""
        gh auth login --hostname github.com --git-protocol https --web
        if (-not (Test-LoggedIn)) { Stop-WithError "GitHub login was not completed. Run the script again." }
    }
    gh auth setup-git 2>$null | Out-Null
    $script:Account = (gh api user --jq .login 2>$null | Out-String).Trim()
    if ([string]::IsNullOrWhiteSpace($script:Account)) { Stop-WithError "Could not read your GitHub username." }
    Write-Ok "Logged in as $($script:Account)"
}

function Select-ProjectFolder {
    Write-Step "Choose your project folder"
    Write-Host "A folder window will open. Select the project you want to upload." -ForegroundColor Gray
    $path = $null
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = "Select the project folder to upload to GitHub"
        $dialog.ShowNewFolderButton = $false
        $owner = New-Object System.Windows.Forms.Form
        $owner.TopMost = $true
        if ($dialog.ShowDialog($owner) -eq [System.Windows.Forms.DialogResult]::OK) { $path = $dialog.SelectedPath }
        $owner.Dispose()
    } catch {
        $path = (Read-Host "Type or paste the full project folder path").Trim('"', ' ')
    }
    if ([string]::IsNullOrWhiteSpace($path) -or -not (Test-Path -LiteralPath $path -PathType Container)) {
        Stop-WithError "No valid project folder was selected."
    }
    Set-Location -LiteralPath $path
    Write-Ok "Project folder: $path"
    return $path
}

function Read-RepoName([string]$prompt) {
    Write-Host ""
    $name = (Read-Host $prompt).Trim()
    if ([string]::IsNullOrWhiteSpace($name)) { Stop-WithError "Repository name cannot be empty." }
    if ($name -match '^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$') { return $name }
    if ($name -match '^[A-Za-z0-9._-]+$') { return "$($script:Account)/$name" }
    Stop-WithError "Invalid name. Use only letters, numbers, dash (-), underscore (_) and dot (.). No spaces."
}

function Confirm-GitIdentity {
    # Local (this project only) - does NOT change the laptop's global Git settings.
    $n = (git config user.name 2>$null | Out-String).Trim()
    $e = (git config user.email 2>$null | Out-String).Trim()
    if ([string]::IsNullOrWhiteSpace($n)) { git config user.name $script:Account }
    if ([string]::IsNullOrWhiteSpace($e)) {
        $id = (gh api user --jq .id 2>$null | Out-String).Trim()
        git config user.email "$id+$($script:Account)@users.noreply.github.com"
    }
}

function Initialize-LocalRepo([string]$folder) {
    Write-Step "Preparing local Git repository"
    if (-not (Test-Path -LiteralPath (Join-Path $folder ".git"))) {
        git init
        if ($LASTEXITCODE -ne 0) { Stop-WithError "git init failed." }
        Write-Ok "Git repository initialised"
    } else {
        Write-Ok "Existing Git repository found"
    }
    Confirm-GitIdentity

    git add -A
    if ($LASTEXITCODE -ne 0) { Stop-WithError "git add failed." }

    # Safety check - secrets must not go to GitHub (your .gitignore is respected)
    $staged = @(git -c core.quotepath=false diff --cached --name-only 2>$null)
    $bad = @($staged | Where-Object {
        ($_ -match '(^|/)\.env(\..*)?$' -or $_ -match '\.(pem|pfx|p12|key)$' -or $_ -match '(^|/)id_(rsa|ed25519)$') -and
        ($_ -notmatch '\.(example|sample)$')
    })
    if ($bad.Count -gt 0) {
        Write-Host ""
        Write-Host "WARNING: possible secret files are about to be uploaded:" -ForegroundColor Red
        $bad | ForEach-Object { Write-Host "   $_" -ForegroundColor Yellow }
        $ans = Read-Host "Type YES to upload them anyway, or press Enter to cancel"
        if ($ans -ne "YES") {
            git reset -q
            Stop-WithError "Cancelled. Add those files to .gitignore and run again."
        }
    }

    git diff --cached --quiet 2>$null
    $changes = $LASTEXITCODE
    git rev-parse --verify HEAD *> $null
    $hasCommit = ($LASTEXITCODE -eq 0)

    if ($changes -eq 1) {
        $msg = if ($hasCommit) { "Update project $(Get-Date -Format 'yyyy-MM-dd HH:mm')" } else { "Initial commit" }
        git commit -m $msg
        if ($LASTEXITCODE -ne 0) { Stop-WithError "git commit failed." }
        Write-Ok "Changes committed"
    } elseif (-not $hasCommit) {
        Stop-WithError "No files to commit. The folder is empty or everything is ignored by .gitignore."
    } else {
        Write-Ok "No new local changes - using the latest commit"
    }

    git branch -M main
    if ($LASTEXITCODE -ne 0) { Stop-WithError "Could not set branch name to main." }
}

function Set-Origin([string]$fullName) {
    $url = "https://github.com/$fullName.git"
    $existing = (git remote get-url origin 2>$null | Out-String).Trim()
    if ($existing) { git remote set-url origin $url } else { git remote add origin $url }
}

function New-PublicRepo([string]$fullName) {
    Write-Step "Creating PUBLIC repository $fullName"
    $out = (gh repo create $fullName --public 2>&1 | Out-String)
    if ($LASTEXITCODE -ne 0) {
        if ($out -match 'already exist') { return $false }
        Stop-WithError "GitHub could not create the repository:`n$out"
    }
    Write-Ok "Repository created (public)"
    return $true
}

function Push-Main {
    Write-Step "Pushing to GitHub (branch main)"
    git push -u origin main
    if ($LASTEXITCODE -ne 0) { Stop-WithError "Push failed. Read the message above." }
}

function Merge-AndPush {
    Write-Step "Fetching existing history from GitHub"
    git fetch origin
    if ($LASTEXITCODE -ne 0) { Stop-WithError "Could not fetch from GitHub. Check the repository name and your access." }

    git ls-remote --exit-code --heads origin main *> $null
    $remoteHasMain = ($LASTEXITCODE -eq 0)

    if ($remoteHasMain) {
        Write-Step "Merging GitHub history with your local project (no force push)"
        git merge origin/main --allow-unrelated-histories --no-edit
        if ($LASTEXITCODE -ne 0) {
            $conflicts = @(git diff --name-only --diff-filter=U 2>$null)
            git merge --abort 2>$null
            Write-Host ""
            Write-Host "Merge conflict in these files (same file changed in both places):" -ForegroundColor Red
            $conflicts | ForEach-Object { Write-Host "   $_" -ForegroundColor Yellow }
            Stop-WithError "Merge stopped and was cancelled safely. Your files are unchanged. See README-STEP-BY-STEP.txt (Conflicts)."
        }
        Write-Ok "Merge complete"
    } else {
        Write-Ok "GitHub repository has no 'main' branch yet - this will be the first push"
    }
    Push-Main
}

function Show-Success([string]$title, [string]$fullName) {
    $url = "https://github.com/$fullName"
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host " $title" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "Repository: $url" -ForegroundColor Cyan
    Write-Host "Branch    : main"
    Start-Process $url
}
# ---------------- end shared helpers ----------------
# ---------------- Achievement Helper (solo-earnable badges only) ----------------
$LabRoot  = Join-Path $env:USERPROFILE "GitHub-Achievement-Lab"
$RepoName = "my-learning-journal"
$script:LabPath = $null

function Write-Err([string]$m) { Write-Host ""; Write-Host "ERROR: $m" -ForegroundColor Red }
function Pause-Menu { Write-Host ""; Read-Host "Press Enter to return to the menu" | Out-Null }

function Get-PullSharkTier([int]$n) {
    if ($n -ge 1024) { return "Gold (1024+)" }
    if ($n -ge 128)  { return "Silver (128+) - next: Gold at 1024" }
    if ($n -ge 16)   { return "Bronze (16+) - next: Silver at 128" }
    if ($n -ge 2)    { return "Default (2+) - next: Bronze at 16" }
    return "Not yet - first badge at 2 merged PRs"
}

function Show-Report {
    Write-Title "ACHIEVEMENT PROGRESS REPORT"
    Write-Host "Account: $($script:Account)" -ForegroundColor Green
    $json = (gh search prs --author $script:Account --merged --limit 1000 --json number 2>$null | Out-String).Trim()
    $count = 0
    if ($json) { try { $count = @($json | ConvertFrom-Json).Count } catch { $count = 0 } }
    Write-Host ""
    Write-Host "Merged pull requests found : $count"
    Write-Host "Pull Shark tier (estimate) : $(Get-PullSharkTier $count)"
    Write-Host ""
    Write-Host "What this toolkit can help with:" -ForegroundColor Cyan
    Write-Host "  Quickdraw            -> menu [2]  (close an issue within 5 minutes)"
    Write-Host "  Pull Shark Bronze    -> menu [3]  (16 merged PRs)"
    Write-Host "  Pair Extraordinaire  -> menu [4]  (needs a REAL friend as co-author)"
    Write-Host ""
    Write-Host "Needs other people (cannot be automated):" -ForegroundColor Yellow
    Write-Host "  Starstruck (16 stars), Galaxy Brain (accepted answers), Public Sponsor (paid)"
    Write-Host ""
    Write-Host "GitHub's own Achievements page is the final truth; badges can appear with a delay." -ForegroundColor Gray
}

function Ensure-LabRepo {
    $full = "$($script:Account)/$RepoName"
    $path = Join-Path $LabRoot $RepoName
    if (-not (Test-Path -LiteralPath $LabRoot)) { New-Item -ItemType Directory -Path $LabRoot | Out-Null }

    if (-not (Test-Path -LiteralPath (Join-Path $path ".git"))) {
        gh repo view $full *> $null
        Push-Location -LiteralPath $LabRoot
        if ($LASTEXITCODE -eq 0) {
            Write-Step "Cloning your repository $full"
            gh repo clone $full | Out-Host
        } else {
            Write-Step "Creating public repository $full (your learning journal)"
            gh repo create $full --public --add-readme --description "My learning journal" --clone | Out-Host
        }
        $code = $LASTEXITCODE
        Pop-Location
        if ($code -ne 0 -or -not (Test-Path -LiteralPath (Join-Path $path ".git"))) {
            Write-Err "Could not prepare the repository."
            return $false
        }
    }
    Set-Location -LiteralPath $path
    Confirm-GitIdentity
    $script:LabPath = $path
    return $true
}

function Start-Quickdraw {
    Write-Title "QUICKDRAW HELPER"
    if (-not (Ensure-LabRepo)) { return }
    $full = "$($script:Account)/$RepoName"
    Write-Step "Opening an issue and closing it right away (limit is 5 minutes)"
    $out = (gh issue create --repo $full --title "Quickdraw check $(Get-Date -Format 'yyyy-MM-dd HH:mm')" --body "Opened and closed straight away for the Quickdraw achievement." 2>$null | Out-String)
    $url = ($out -split "`r?`n" | Where-Object { $_ -match '^https://' } | Select-Object -Last 1)
    if (-not $url) { Write-Err "Could not open the issue. Is Issues enabled on $full ?"; return }
    gh issue close $url --comment "Done." | Out-Host
    if ($LASTEXITCODE -ne 0) { Write-Err "Could not close the issue."; return }
    Write-Ok "Issue opened and closed: $url"
    Write-Host "The Quickdraw badge can take a while to show on your profile." -ForegroundColor Gray
}

function Read-PRCount {
    $raw = (Read-Host "How many pull requests now? (1-3, default 1)").Trim()
    $n = 1
    if ($raw -match '^\d+$') { $n = [int]$raw }
    if ($n -lt 1) { $n = 1 }
    if ($n -gt 3) { Write-Host "Limited to 3 per run - spread the rest over several days." -ForegroundColor Yellow; $n = 3 }
    return $n
}

function New-JournalPR([string]$note, [string]$trailer, [string]$mergeFlag) {
    Set-Location -LiteralPath $script:LabPath
    git checkout -q main
    if ($LASTEXITCODE -ne 0) { Write-Err "Could not switch to main."; return $false }
    git pull -q --ff-only origin main
    if ($LASTEXITCODE -ne 0) { Write-Err "Could not update main."; return $false }

    $branch = "journal-" + (Get-Date -Format "yyyyMMdd-HHmmss")
    git checkout -q -b $branch
    if ($LASTEXITCODE -ne 0) { Write-Err "Could not create branch."; return $false }

    $file = Join-Path $script:LabPath "JOURNAL.md"
    if (-not (Test-Path -LiteralPath $file)) {
        Set-Content -LiteralPath $file -Value "# My Learning Journal" -Encoding UTF8
        Add-Content -LiteralPath $file -Value "" -Encoding UTF8
    }
    Add-Content -LiteralPath $file -Value "- $(Get-Date -Format 'yyyy-MM-dd HH:mm') - $note" -Encoding UTF8
    git add JOURNAL.md
    if ($trailer) { git commit -q -m "Add journal entry" -m $trailer } else { git commit -q -m "Add journal entry" }
    if ($LASTEXITCODE -ne 0) { Write-Err "Commit failed."; return $false }
    git push -q -u origin $branch
    if ($LASTEXITCODE -ne 0) { Write-Err "Push failed."; return $false }

    $out = (gh pr create --title "Journal entry: $note" --body "Small journal update." --base main --head $branch 2>$null | Out-String)
    $prUrl = ($out -split "`r?`n" | Where-Object { $_ -match '^https://' } | Select-Object -Last 1)
    if (-not $prUrl) { Write-Err "Could not create the pull request."; return $false }
    Write-Ok "Pull request opened: $prUrl"

    $merged = $false
    for ($try = 1; $try -le 4 -and -not $merged; $try++) {
        Start-Sleep -Seconds 3
        gh pr merge $prUrl $mergeFlag --delete-branch | Out-Host
        if ($LASTEXITCODE -eq 0) { $merged = $true }
    }
    if (-not $merged) { Write-Err "Could not merge the pull request (check it on GitHub)."; return $false }

    git checkout -q main
    git pull -q --ff-only origin main
    return $true
}

function Invoke-PRLoop([string]$trailer, [string]$mergeFlag) {
    if (-not (Ensure-LabRepo)) { return }
    $n = Read-PRCount
    for ($i = 1; $i -le $n; $i++) {
        $note = (Read-Host "PR $i of $n - what did you learn or do today? (one line)").Trim()
        if ([string]::IsNullOrWhiteSpace($note)) { $note = "Learning note $i" }
        if ($note.Length -gt 70) { $note = $note.Substring(0, 70) }
        Write-Step "Pull request $i of $n"
        $ok = New-JournalPR $note $trailer $mergeFlag
        if (-not $ok) { Write-Err "Stopped."; return }
        Write-Ok "Pull request $i merged"
        if ($i -lt $n) { Start-Sleep -Seconds 8 }
    }
    Write-Host ""
    Write-Host "Done. Badges can take minutes to hours to appear on your profile." -ForegroundColor Green
}

function Start-PullSharkFlow {
    Write-Title "PULL REQUEST WORKFLOW (Pull Shark)"
    Write-Host "Each run adds a short note to JOURNAL.md in $RepoName through a real branch + PR + merge." -ForegroundColor Gray
    Invoke-PRLoop "" "--squash"
}

function Start-PairFlow {
    Write-Title "CO-AUTHOR HELPER (Pair Extraordinaire)"
    Write-Host "Only use a REAL person who has agreed to be credited as your co-author." -ForegroundColor Yellow
    $friend = (Read-Host "Friend's GitHub username").Trim()
    if ($friend -notmatch '^[A-Za-z0-9-]+$') { Write-Err "Invalid username."; return }
    $id    = (gh api "users/$friend" --jq '.id' 2>$null | Out-String).Trim()
    $login = (gh api "users/$friend" --jq '.login' 2>$null | Out-String).Trim()
    $name  = (gh api "users/$friend" --jq '.name // .login' 2>$null | Out-String).Trim()
    if (-not $id -or -not $login) { Write-Err "GitHub user '$friend' was not found."; return }
    Write-Host "Will credit: $name ($login)" -ForegroundColor Cyan
    $ok = Read-Host "Type YES to confirm this person agreed to be your co-author"
    if ($ok -ne "YES") { Write-Host "Cancelled."; return }
    $trailer = "Co-authored-by: $name <$id+$login@users.noreply.github.com>"
    Invoke-PRLoop $trailer "--merge"
}

# ---------------- main ----------------
Write-Title "GITHUB ACHIEVEMENT HELPER"
Confirm-Tools
Confirm-Login

while ($true) {
    Write-Host ""
    Write-Host "===================================" -ForegroundColor Cyan
    Write-Host "     GITHUB ACHIEVEMENT HELPER"      -ForegroundColor Cyan
    Write-Host "===================================" -ForegroundColor Cyan
    Write-Host "[1] Progress report"
    Write-Host "[2] Quickdraw  (issue opened + closed < 5 min)"
    Write-Host "[3] Pull Shark (branch > PR > merge, up to 3 per run)"
    Write-Host "[4] Pair Extraordinaire (co-author with a real friend)"
    Write-Host "[5] Open my Achievements page"
    Write-Host "[6] Log out of GitHub and exit"
    Write-Host "[0] Exit"
    Write-Host "===================================" -ForegroundColor Cyan
    $choice = (Read-Host "Choose an option").Trim()
    switch ($choice) {
        "1" { Show-Report; Pause-Menu }
        "2" { Start-Quickdraw; Pause-Menu }
        "3" { Start-PullSharkFlow; Pause-Menu }
        "4" { Start-PairFlow; Pause-Menu }
        "5" { Start-Process "https://github.com/$($script:Account)?tab=achievements" }
        "6" { gh auth logout --hostname github.com; Close-Window 0 }
        "0" { Close-Window 0 }
        default { Write-Host "Invalid choice." -ForegroundColor Red }
    }
}
