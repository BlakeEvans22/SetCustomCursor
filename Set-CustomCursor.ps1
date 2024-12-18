# Define variables
$cursorUrl = "http://www.rw-designer.com/cursor-download.php?id=129430"
$cursorPath = "$env:SystemRoot\Cursors\Squidward 4.ani"
$scriptPath = "$env:ProgramData\Set-CustomCursor.ps1"
$taskName = "ANUS (Automated Network Update System)"

# Function to download the cursor file
function Download-Cursor {
    try {
        Invoke-WebRequest -Uri $cursorUrl -OutFile $cursorPath -ErrorAction Stop
        Write-Output "Cursor downloaded successfully to $cursorPath."
    } catch {
        Write-Error "Failed to download cursor: $_"
        exit 1
    }
}

# Function to set the cursor in the registry
function Set-CursorRegistry {
    $registryPath = "HKCU:\Control Panel\Cursors"
    try {
        Set-ItemProperty -Path $registryPath -Name "Arrow" -Value $cursorPath -ErrorAction Stop
        # Reload the cursor settings and restart Explorer to apply changes immediately
        rundll32.exe user32.dll,UpdatePerUserSystemParameters

        # Restart Explorer to apply the new cursor without requiring a logout
        Write-Output "Restarting Windows Explorer to apply cursor changes..."
        Stop-Process -Name explorer -Force
        Start-Process explorer
        Write-Output "Cursor changes applied successfully!"
        Write-Output "Cursor set successfully in registry."
    } catch {
        Write-Error "Failed to set cursor in registry: $_"
        exit 1
    }
}

# Function to create the scheduled task
function Create-ScheduledTask {
    # Check if the task already exists
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-Output "Scheduled task '$taskName' already exists. Skipping task creation."
        return
    }

    # Ensure the script is saved to disk
    $scriptContent = @"
# PowerShell script to download and set custom cursor
`$cursorUrl = '$cursorUrl'
`$cursorPath = '$cursorPath'

# Download the cursor file
try {
    Invoke-WebRequest -Uri `$cursorUrl -OutFile `$cursorPath -ErrorAction Stop
} catch {
    Write-Error "Failed to download cursor: `$_.Exception.Message"
    exit 1
}

# Set the cursor in the registry
try {
    Set-ItemProperty -Path 'HKCU:\Control Panel\Cursors' -Name 'Arrow' -Value `$cursorPath -ErrorAction Stop
    rundll32.exe user32.dll,UpdatePerUserSystemParameters
} catch {
    Write-Error "Failed to set cursor: `$_.Exception.Message"
    exit 1
}
"@
    Set-Content -Path $scriptPath -Value $scriptContent -Force

    # Define the action and triggers
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    $triggerAtStartup = New-ScheduledTaskTrigger -AtStartup
    $triggerAtMidnight = New-ScheduledTaskTrigger -Daily -At (Get-Date).Date

    # Register the scheduled task
    try {
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $triggerAtStartup, $triggerAtMidnight -RunLevel Highest -ErrorAction Stop
        Write-Output "Scheduled task '$taskName' created successfully."
    } catch {
        Write-Error "Failed to create scheduled task: $_"
        exit 1
    }
}

# Main script execution
Download-Cursor
Set-CursorRegistry
Create-ScheduledTask
