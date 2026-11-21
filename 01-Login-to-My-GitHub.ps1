# 01-Login-to-My-GitHub
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
Write-Title "STEP 1: LOGIN TO GITHUB"
Confirm-Tools
Confirm-Login
Write-Host ""
gh auth status
Write-Host ""
Write-Host "Login successful. Next: run 02-Create-New-Public-Repository.bat" -ForegroundColor Green
Close-Window 0
