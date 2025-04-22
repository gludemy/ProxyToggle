# Proxy Toggle Application (Standalone version)
# This script will be converted to an EXE file using PS2EXE

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Proxy Settings
$proxyServer = "10.147.17.29"
$proxyPort = "808"
$proxyAddress = "$proxyServer`:$proxyPort"
$proxyExceptions = "localhost;127.0.0.1;<local>"

# Registry paths
$internetSettingsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"

# Create context menu
$contextMenu = New-Object System.Windows.Forms.ContextMenuStrip
$toggleMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$settingsMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$exitMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem

# Create notification icon
$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Text = "Proxy Toggle"
$notifyIcon.ContextMenuStrip = $contextMenu
$notifyIcon.Visible = $true

# Function to create a better looking icon
function Create-ColoredIcon {
    param (
        [System.Drawing.Color]$mainColor
    )
    
    $bitmap = New-Object System.Drawing.Bitmap(16, 16)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    
    # Fill background with transparency
    $graphics.Clear([System.Drawing.Color]::Transparent)
    
    # Create a gradient brush for a more polished look
    $rect = New-Object System.Drawing.Rectangle(0, 0, 16, 16)
    $gradientBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $rect, 
        [System.Drawing.Color]::FromArgb(255, $mainColor.R, $mainColor.G, $mainColor.B),
        [System.Drawing.Color]::FromArgb(220, [Math]::Min(255, $mainColor.R + 40), [Math]::Min(255, $mainColor.G + 40), [Math]::Min(255, $mainColor.B + 40)),
        45
    )
    
    # Draw a filled circle with gradient
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.FillEllipse($gradientBrush, 1, 1, 14, 14)
    
    # Add a light border
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(100, 255, 255, 255), 1)
    $graphics.DrawEllipse($pen, 1, 1, 14, 14)
    
    # Add a highlight effect
    $graphics.FillEllipse(
        (New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(70, 255, 255, 255))),
        4, 3, 5, 3
    )
    
    # Create icon from bitmap
    $icon = [System.Drawing.Icon]::FromHandle($bitmap.GetHicon())
    
    # Clean up
    $gradientBrush.Dispose()
    $pen.Dispose()
    $graphics.Dispose()
    
    return $icon
}

# Function to check proxy status
function Get-ProxyStatus {
    $proxyEnabled = Get-ItemProperty -Path $internetSettingsPath -Name "ProxyEnable" -ErrorAction SilentlyContinue
    
    if ($proxyEnabled -ne $null -and $proxyEnabled.ProxyEnable -eq 1) {
        return $true
    } else {
        return $false
    }
}

# Function to enable proxy
function Enable-Proxy {
    Set-ItemProperty -Path $internetSettingsPath -Name "ProxyEnable" -Value 1
    Set-ItemProperty -Path $internetSettingsPath -Name "ProxyServer" -Value $proxyAddress
    Set-ItemProperty -Path $internetSettingsPath -Name "ProxyOverride" -Value $proxyExceptions
    
    # Refresh DNS cache
    Start-Process "ipconfig" -ArgumentList "/flushdns" -WindowStyle Hidden
    
    $toggleMenuItem.Text = "Disable Proxy"
    $notifyIcon.Icon = Create-ColoredIcon -mainColor ([System.Drawing.Color]::FromArgb(80, 200, 100))
    $notifyIcon.Text = "Proxy Enabled: $proxyAddress"
    
    $notifyIcon.ShowBalloonTip(
        3000,
        "Proxy Enabled",
        "Proxy has been set to $proxyAddress",
        [System.Windows.Forms.ToolTipIcon]::Info
    )
}

# Function to disable proxy
function Disable-Proxy {
    Set-ItemProperty -Path $internetSettingsPath -Name "ProxyEnable" -Value 0
    
    # Refresh DNS cache
    Start-Process "ipconfig" -ArgumentList "/flushdns" -WindowStyle Hidden
    
    $toggleMenuItem.Text = "Enable Proxy"
    $notifyIcon.Icon = Create-ColoredIcon -mainColor ([System.Drawing.Color]::FromArgb(220, 80, 80))
    $notifyIcon.Text = "Proxy Disabled"
    
    $notifyIcon.ShowBalloonTip(
        3000,
        "Proxy Disabled",
        "System proxy has been disabled",
        [System.Windows.Forms.ToolTipIcon]::Info
    )
}

# Toggle proxy event handler
$toggleMenuItem.Add_Click({
    if (Get-ProxyStatus) {
        Disable-Proxy
    } else {
        Enable-Proxy
    }
})

# Settings menu handler
$settingsMenuItem.Add_Click({
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Proxy Settings"
    $form.Size = New-Object System.Drawing.Size(300, 200)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    
    $labelServer = New-Object System.Windows.Forms.Label
    $labelServer.Location = New-Object System.Drawing.Point(10, 20)
    $labelServer.Size = New-Object System.Drawing.Size(100, 20)
    $labelServer.Text = "Proxy Server:"
    $form.Controls.Add($labelServer)
    
    $textBoxServer = New-Object System.Windows.Forms.TextBox
    $textBoxServer.Location = New-Object System.Drawing.Point(110, 20)
    $textBoxServer.Size = New-Object System.Drawing.Size(160, 20)
    $textBoxServer.Text = $proxyServer
    $form.Controls.Add($textBoxServer)
    
    $labelPort = New-Object System.Windows.Forms.Label
    $labelPort.Location = New-Object System.Drawing.Point(10, 50)
    $labelPort.Size = New-Object System.Drawing.Size(100, 20)
    $labelPort.Text = "Proxy Port:"
    $form.Controls.Add($labelPort)
    
    $textBoxPort = New-Object System.Windows.Forms.TextBox
    $textBoxPort.Location = New-Object System.Drawing.Point(110, 50)
    $textBoxPort.Size = New-Object System.Drawing.Size(160, 20)
    $textBoxPort.Text = $proxyPort
    $form.Controls.Add($textBoxPort)
    
    $labelExceptions = New-Object System.Windows.Forms.Label
    $labelExceptions.Location = New-Object System.Drawing.Point(10, 80)
    $labelExceptions.Size = New-Object System.Drawing.Size(100, 20)
    $labelExceptions.Text = "Exceptions:"
    $form.Controls.Add($labelExceptions)
    
    $textBoxExceptions = New-Object System.Windows.Forms.TextBox
    $textBoxExceptions.Location = New-Object System.Drawing.Point(110, 80)
    $textBoxExceptions.Size = New-Object System.Drawing.Size(160, 20)
    $textBoxExceptions.Text = $proxyExceptions
    $form.Controls.Add($textBoxExceptions)
    
    $buttonSave = New-Object System.Windows.Forms.Button
    $buttonSave.Location = New-Object System.Drawing.Point(110, 120)
    $buttonSave.Size = New-Object System.Drawing.Size(75, 23)
    $buttonSave.Text = "Save"
    $buttonSave.Add_Click({
        $script:proxyServer = $textBoxServer.Text
        $script:proxyPort = $textBoxPort.Text
        $script:proxyAddress = "$proxyServer`:$proxyPort"
        $script:proxyExceptions = $textBoxExceptions.Text
        
        if (Get-ProxyStatus) {
            # Update current proxy if it's enabled
            Set-ItemProperty -Path $internetSettingsPath -Name "ProxyServer" -Value $proxyAddress
            Set-ItemProperty -Path $internetSettingsPath -Name "ProxyOverride" -Value $proxyExceptions
            $notifyIcon.Text = "Proxy Enabled: $proxyAddress"
            $notifyIcon.ShowBalloonTip(2000, "Settings Updated", "New proxy settings applied: $proxyAddress", [System.Windows.Forms.ToolTipIcon]::Info)
        } else {
            $notifyIcon.ShowBalloonTip(2000, "Settings Saved", "New settings will apply when proxy is enabled", [System.Windows.Forms.ToolTipIcon]::Info)
        }
        
        $form.Close()
    })
    $form.Controls.Add($buttonSave)
    
    $buttonCancel = New-Object System.Windows.Forms.Button
    $buttonCancel.Location = New-Object System.Drawing.Point(195, 120)
    $buttonCancel.Size = New-Object System.Drawing.Size(75, 23)
    $buttonCancel.Text = "Cancel"
    $buttonCancel.Add_Click({ $form.Close() })
    $form.Controls.Add($buttonCancel)
    
    $form.Add_Shown({ $form.Activate() })
    $form.ShowDialog()
})

# Exit event handler
$exitMenuItem.Add_Click({
    $notifyIcon.Visible = $false
    [System.Windows.Forms.Application]::Exit()
})

# Set initial menu items
$toggleMenuItem.Text = "Toggle Proxy"
$settingsMenuItem.Text = "Settings"
$exitMenuItem.Text = "Exit"
$contextMenu.Items.Add($toggleMenuItem)
$contextMenu.Items.Add($settingsMenuItem)
$contextMenu.Items.Add("-") # Separator
$contextMenu.Items.Add($exitMenuItem)

# Set initial icon based on current proxy status
if (Get-ProxyStatus) {
    $toggleMenuItem.Text = "Disable Proxy"
    $notifyIcon.Icon = Create-ColoredIcon -mainColor ([System.Drawing.Color]::FromArgb(80, 200, 100))
    $notifyIcon.Text = "Proxy Enabled: $proxyAddress"
} else {
    $toggleMenuItem.Text = "Enable Proxy"
    $notifyIcon.Icon = Create-ColoredIcon -mainColor ([System.Drawing.Color]::FromArgb(220, 80, 80))
    $notifyIcon.Text = "Proxy Disabled"
}

# Also allow left-click to toggle
$notifyIcon.Add_Click({
    if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        if (Get-ProxyStatus) {
            Disable-Proxy
        } else {
            Enable-Proxy
        }
    }
})

# Show notification on startup
$notifyIcon.ShowBalloonTip(
    2000,
    "Proxy Toggle",
    "Left-click to toggle proxy, right-click for menu",
    [System.Windows.Forms.ToolTipIcon]::Info
)

# Add to startup instructions
function Add-ToStartup {
    $appPath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
    $startupPath = [System.IO.Path]::Combine([Environment]::GetFolderPath("Startup"), "ProxyToggle.lnk")
    
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($startupPath)
    $Shortcut.TargetPath = $appPath
    $Shortcut.Save()
    
    $notifyIcon.ShowBalloonTip(
        2000,
        "Added to Startup",
        "ProxyToggle will start automatically with Windows",
        [System.Windows.Forms.ToolTipIcon]::Info
    )
}

# Keep the application running
$appContext = New-Object System.Windows.Forms.ApplicationContext
[System.Windows.Forms.Application]::Run($appContext)