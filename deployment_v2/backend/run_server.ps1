# Starts the ReadmitGuard API on all interfaces so a phone on the same Wi-Fi can reach it.
# Usage (from this folder):  .\run_server.ps1
$python = "$env:USERPROFILE\anaconda3\envs\myenv\python.exe"
if (-not (Test-Path $python)) { $python = "python" }
$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '127.*' -and $_.PrefixOrigin -ne 'WellKnown' } | Select-Object -First 1).IPAddress
Write-Host "API docs:        http://localhost:8000/docs"
Write-Host "Phone / LAN URL: http://${ip}:8000   (enter this in the app's Server settings)"
& $python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
