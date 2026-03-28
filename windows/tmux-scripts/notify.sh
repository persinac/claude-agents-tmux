#!/usr/bin/env bash
# Sends a Windows balloon/toast notification via PowerShell.
TITLE="${1:-Claude Code}"
MSG="${2:-Agent waiting for input}"

if command -v powershell.exe &>/dev/null; then
  powershell.exe -NoProfile -Command "
    Add-Type -AssemblyName System.Windows.Forms
    \$notify = New-Object System.Windows.Forms.NotifyIcon
    \$notify.Icon = [System.Drawing.SystemIcons]::Information
    \$notify.BalloonTipTitle = '$TITLE'
    \$notify.BalloonTipText = '$MSG'
    \$notify.BalloonTipIcon = 'Info'
    \$notify.Visible = \$true
    \$notify.ShowBalloonTip(5000)
    Start-Sleep -Milliseconds 500
    \$notify.Dispose()
  " 2>/dev/null &
else
  printf '\007' > /dev/tty 2>/dev/null
fi
