GITHUB TOOLKIT - STEP BY STEP (teaching guide)
=================================================
Upload a project from ANY Windows laptop to YOUR GitHub profile.
You only type the repository name. New repositories are created PUBLIC.

BEFORE YOU START
  - Extract this ZIP to a folder (right-click > Extract All). Keep all files together.
  - Internet connection + a web browser.
  - Git and GitHub CLI are needed. The scripts offer to install them with winget
    (or install manually: https://git-scm.com/download/win and https://cli.github.com/).
    After installing, CLOSE the window and run the BAT file again.

QUICK WAY (one file does everything)
  Double-click: 00-FULL-Automatic-Login-Create-Push.bat
    1. Logs in (browser) if needed
    2. Opens a window - choose the project folder
    3. Type repository name
    4. New name  -> creates public repo + pushes
       Existing  -> merges GitHub history + pushes (no force push)
    5. Asks whether to log out (say Y on a friend's laptop)

STEP BY STEP WAY (to teach)
  STEP 1  01-Login-to-My-GitHub.bat
          - A one-time code appears. Copy it, press Enter, paste it in the browser,
            click Authorize. Wait for "Login successful".
  STEP 2  02-Create-New-Public-Repository.bat
          - Choose project folder, type a NEW repository name.
          - Script runs: git init > add > commit > create public repo > push.
  STEP 3  03-Push-Existing-Repository-Merge.bat   (only when the repo already exists)
          - Choose project folder, type the existing repository name.
          - Script: commit > fetch > merge GitHub history > push. Never force-pushes.
  STEP 4  04-Logout-From-GitHub.bat
          - ALWAYS run this on a friend's laptop when finished.

NAMING RULES
  Letters, numbers, dash (-), underscore (_), dot (.). No spaces.
  You can also type owner/repository for a repo under another account/organisation.

SAFETY
  - Your .gitignore is respected. Put node_modules, .env, build folders there.
  - Public means EVERYONE can see the files. The script warns if it sees .env,
    .pem, .key, id_rsa style files and asks you to type YES to continue.
  - Git identity is set only inside the project (not on the whole laptop).

TROUBLESHOOTING
  "Name already exists"        -> use STEP 3, or pick another name.
  "Merge conflict"             -> same file edited in GitHub and locally. The script cancels
                                  the merge safely. Easy fix: open the file on GitHub,
                                  copy what you need, edit your local file, run STEP 3 again.
  "Repository not found"       -> check spelling / that you are logged in to the right account.
  Window closes immediately    -> right-click the BAT > Run as administrator is NOT needed;
                                  make sure you extracted the ZIP first (do not run inside the ZIP).
  Wrong account                -> run 04-Logout, then 01-Login again.
  Make a public repo private   -> GitHub > repo > Settings > Danger Zone > Change visibility.
