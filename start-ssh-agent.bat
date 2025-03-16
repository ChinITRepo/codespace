@echo off
echo ===== SSH Agent Setup =====
echo This script will set up SSH agent to remember your passphrase.

REM Check if OpenSSH is available
where ssh >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Error: OpenSSH not found. Please install OpenSSH.
    goto :error
)

REM Start SSH Agent
echo Starting SSH agent...
for /f "tokens=1,2,3 delims==;" %%A in ('ssh-agent') do (
    if "%%A"=="SSH_AUTH_SOCK" set SSH_AUTH_SOCK=%%B
    if "%%A"=="SSH_AGENT_PID" set SSH_AGENT_PID=%%B
)

echo SSH_AUTH_SOCK=%SSH_AUTH_SOCK%
echo SSH_AGENT_PID=%SSH_AGENT_PID%

REM Set environment variables for the current session
setx SSH_AUTH_SOCK "%SSH_AUTH_SOCK%" >nul
setx SSH_AGENT_PID "%SSH_AGENT_PID%" >nul

REM Add SSH Key
echo.
echo Adding your SSH key to the agent...
echo You may be prompted for your passphrase (only needed once per session).
ssh-add %USERPROFILE%\.ssh\id_ed25519

echo.
echo If no errors occurred, your SSH key is now loaded in the agent.
echo You can now use Git with SSH without entering your passphrase repeatedly.
echo.
echo To test your connection, run: ssh -T git@github.com

goto :end

:error
echo Setup failed. Please check error messages above.

:end
pause
