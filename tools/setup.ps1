# R.A.I.K.O Standalone Agent Setup
# Run this once to configure and start the agent

$configPath = ".\config.json"

if (Test-Path $configPath) {
  Write-Host "✓ config.json already exists. Starting agent..." -ForegroundColor Green
} else {
  Write-Host ""
  Write-Host "  R.A.I.K.O Agent Setup" -ForegroundColor Cyan
  Write-Host "  =====================" -ForegroundColor Cyan
  Write-Host ""

  $backendUrl = Read-Host "Backend WebSocket URL (e.g., ws://192.168.1.103:8080/ws)"
  $authToken = Read-Host "Auth Token (from your backend)"
  $agentId = Read-Host "Agent ID [agent-$(hostname)] "
  if (-not $agentId) { $agentId = "agent-$(hostname)" }

  $config = @{
    backendWsUrl = $backendUrl
    authToken = $authToken
    agentId = $agentId
    agentName = "RAIKO Agent ($env:COMPUTERNAME)"
    dryRun = $false
    heartbeatMs = 15000
    reconnectMs = 5000
  } | ConvertTo-Json

  $config | Out-File -FilePath $configPath -Encoding UTF8
  Write-Host ""
  Write-Host "✓ config.json created" -ForegroundColor Green
  Write-Host ""
}

Write-Host "Starting R.A.I.K.O Agent..." -ForegroundColor Green
Write-Host ""
& ".\raiko-agent.exe"
