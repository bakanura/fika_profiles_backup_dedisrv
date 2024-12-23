# Define the Go executable and source file paths
$goExecutable = "C:\Program Files\Go\bin\go.exe"  # Path to Go executable
$goSourceFile = "F:\dedicated\SPTDedicated_v3.9.8\moveFiles.go"  # Path to your Go source file
$logFile = "F:\dedicated\SPTDedicated_v3.9.8\script_log.txt"  # Log file for capturing all output

# Function to write logs and print to the console
function Write-Log {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $message"
    $logMessage | Out-File -Append $logFile
    Write-Host $logMessage  # Output to the shell as well
}

# Ensure the script is running as administrator (only once)
if (-Not [System.Security.Principal.WindowsIdentity]::GetCurrent().Owner.IsWellKnown([System.Security.Principal.WellKnownSidType]::BuiltinAdministratorsSid)) {
    Write-Log "This script requires elevated privileges. Re-launching as Administrator..."
    Start-Process powershell.exe -ArgumentList "-File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Function to install a package using winget
function Install-Package {
    param(
        [string]$packageId
    )
    Write-Log "Installing $packageId..."
    try {
        winget install --id=$packageId -e
        Write-Log "$packageId installed successfully."
    } catch {
        Write-Log "ERROR: Failed to install $packageId. $_"
    }
}

# Function to install all required packages
function Install-AllPackages {
    Write-Log "Checking and installing necessary packages..."

    # Install necessary packages using winget
    Install-Package "Microsoft.Sysinternals.Handle"  # Handle (for file locks)
    Install-Package "GoLang.Go"  # Go (for Go program)
    Install-Package "7zip.7zip"  # Optional: 7zip (for compression tasks)
    Install-Package "Git.Git"  # Optional: Git (for version control)
    Install-Package "Microsoft.PowerShell"  # Optional: PowerShell 7 (latest version)
    Install-Package "Microsoft.VCRedist.2015+.x64"  # Optional: Visual C++ Redistributables

    Write-Log "Package installation completed."
}

# Function to find handle.exe by checking common paths and system PATH
function Find-HandleExecutable {
    $commonPaths = @(
        "C:\Program Files\Handle\handle.exe",  # Sysinternals default install path
        "C:\Tools\Sysinternals\handle.exe",    # Custom install path
        "C:\Windows\System32\handle.exe"       # Check if handle.exe is in system PATH
    )

    # Check if handle.exe exists in any of the common paths
    foreach ($path in $commonPaths) {
        if (Test-Path -Path $path) {
            Write-Log "Found handle.exe at $path"
            return $path
        }
    }

    # Check if handle.exe is in the system PATH environment variable
    $handleInPath = Get-Command handle -ErrorAction SilentlyContinue
    if ($handleInPath) {
        Write-Log "Found handle.exe in system PATH: $($handleInPath.Source)"
        return $handleInPath.Source
    }

    # If handle.exe is not found in any path, return null
    Write-Log "ERROR: handle.exe is not found."
    return $null
}

# Function to run the Go program (move files logic)
function Run-GoProgram {
    # Check if Go is installed
    if (-Not (Test-Path -Path $goExecutable)) {
        Write-Log "ERROR: Go is not installed at '$goExecutable'. Please install Go."
        exit 1
    }

    # Check if the Go source file exists
    if (-Not (Test-Path -Path $goSourceFile)) {
        Write-Log "ERROR: Go source file '$goSourceFile' not found."
        exit 1
    }

    # Run the Go program
    Write-Log "Running Go program..."
    try {
        # Start the Go process (without capturing the output)
        $process = Start-Process -FilePath $goExecutable -ArgumentList "run", $goSourceFile -Wait -PassThru

        # Check if the Go program executed successfully
        if ($process.ExitCode -eq 0) {
            Write-Log "Go program ran successfully."
        } else {
            Write-Log "ERROR: Go program execution failed with exit code $($process.ExitCode)."
            exit 1
        }
    } catch {
        Write-Log "ERROR: An exception occurred while running the Go program. $_"
        exit 1
    }
}

# Function to check if handle.exe is available and exit if not
function Check-HandleExecutable {
    $handleExecutable = Find-HandleExecutable

    # If handle.exe is not found, display an error and exit
    if (-Not $handleExecutable) {
        Write-Log "ERROR: handle.exe is not found. Please ensure Sysinternals Handle is installed."
        exit 1
    } else {
        Write-Log "handle.exe found at '$handleExecutable'."
    }
}

# Function to create a scheduled task that runs when SPT.Server.exe closes
function Create-ScheduledTask {
    $taskName = "MoveFilesTask"
    $taskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "F:\dedicated\SPTDedicated_v3.9.8\runMove.ps1" -Verb "RunAs"

    # Define the WMI event filter to detect when SPT.Server.exe closes
    $taskTrigger = New-ScheduledTaskTrigger -AtStartup
    $eventFilter = New-Object -ComObject "Schedule.Service"
    $eventFilter.Query = "SELECT * FROM __InstanceDeletionEvent WITHIN 1 WHERE TargetInstance ISA 'Win32_Process' AND TargetInstance.Name = 'SPT.Server.exe'"

    # Create an EventTrigger based on the WMI event query
    $taskTrigger.EventTrigger = $eventFilter

    try {
        # Register the scheduled task with elevated privileges using the action and trigger defined
        Register-ScheduledTask -Action $taskAction -Trigger $taskTrigger -TaskName $taskName -Description "Runs the move files script when SPT.Server.exe closes" -RunLevel Highest
        Write-Log "Scheduled task '$taskName' created successfully."
    } catch {
        Write-Log "ERROR: Failed to create scheduled task. $_"
        $_ | Out-File "scheduled_task_error_log.txt"
        return  # Continue running other tasks
    }
}

# Main function to orchestrate the entire process
function Main {
    # Step 1: Install necessary packages
    Install-AllPackages

    # Step 2: Check if handle.exe is installed
    Check-HandleExecutable

    # Step 3: Run the Go program
    Run-GoProgram

    # Step 4: Create the scheduled task
    Create-ScheduledTask
}

# Call the main function
Main
