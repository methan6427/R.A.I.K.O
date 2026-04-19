# R.A.I.K.O Agent GUI Setup
# Creates a visual setup window for Windows users

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "R.A.I.K.O Agent Setup"
$form.Size = New-Object System.Drawing.Size(500, 350)
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$form.ForeColor = [System.Drawing.Color]::White

# Title
$title = New-Object System.Windows.Forms.Label
$title.Text = "R.A.I.K.O Agent Setup"
$title.Location = New-Object System.Drawing.Point(20, 20)
$title.Size = New-Object System.Drawing.Size(400, 30)
$title.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($title)

# Backend URL Label
$label1 = New-Object System.Windows.Forms.Label
$label1.Text = "Backend WebSocket URL:"
$label1.Location = New-Object System.Drawing.Point(20, 70)
$label1.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($label1)

# Backend URL Input
$urlInput = New-Object System.Windows.Forms.TextBox
$urlInput.Location = New-Object System.Drawing.Point(20, 95)
$urlInput.Size = New-Object System.Drawing.Size(450, 30)
$urlInput.Text = "ws://192.168.1.103:8080/ws"
$urlInput.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
$urlInput.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($urlInput)

# Auth Token Label
$label2 = New-Object System.Windows.Forms.Label
$label2.Text = "Auth Token:"
$label2.Location = New-Object System.Drawing.Point(20, 140)
$label2.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($label2)

# Auth Token Input
$tokenInput = New-Object System.Windows.Forms.TextBox
$tokenInput.Location = New-Object System.Drawing.Point(20, 165)
$tokenInput.Size = New-Object System.Drawing.Size(450, 30)
$tokenInput.Text = "raiko-dev"
$tokenInput.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
$tokenInput.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($tokenInput)

# Start Button
$startBtn = New-Object System.Windows.Forms.Button
$startBtn.Text = "Start Agent"
$startBtn.Location = New-Object System.Drawing.Point(20, 220)
$startBtn.Size = New-Object System.Drawing.Size(450, 40)
$startBtn.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 200)
$startBtn.ForeColor = [System.Drawing.Color]::White
$startBtn.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$startBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat

$startBtn.Add_Click({
  try {
    $backendUrl = $urlInput.Text.Trim()
    $authToken = $tokenInput.Text.Trim()

    if (-not $backendUrl) {
      [System.Windows.Forms.MessageBox]::Show("Backend URL cannot be empty", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
      return
    }

    if (-not $authToken) {
      [System.Windows.Forms.MessageBox]::Show("Auth Token cannot be empty", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
      return
    }

    # Get the directory where the script or exe is located
    $scriptDir = $PSScriptRoot
    if (-not $scriptDir) { $scriptDir = (Get-Location).Path }

    $configPath = Join-Path $scriptDir "config.json"
    $exePath = Join-Path $scriptDir "raiko-agent.exe"

    $config = @{
      backendWsUrl = $backendUrl
      authToken = $authToken
      agentId = "agent-$($env:COMPUTERNAME)"
      agentName = "RAIKO Agent ($env:COMPUTERNAME)"
      dryRun = $false
      heartbeatMs = 15000
      reconnectMs = 5000
    } | ConvertTo-Json

    $config | Out-File -FilePath $configPath -Encoding UTF8 -ErrorAction Stop

    [System.Windows.Forms.MessageBox]::Show("Config saved! Agent starting...", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)

    # Run the exe
    if (Test-Path $exePath) {
      & $exePath
    } else {
      [System.Windows.Forms.MessageBox]::Show("raiko-agent.exe not found in $scriptDir", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }

    $form.Close()
  }
  catch {
    [System.Windows.Forms.MessageBox]::Show("Error: $($_.Exception.Message)", "Setup Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
  }
})

$form.Controls.Add($startBtn)

# Show form
[void]$form.ShowDialog()
