@echo off
setlocal
set "HERE=%~dp0"
set "ROOT=%HERE%.."
powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\tools\install-agent-skills.ps1" %*
