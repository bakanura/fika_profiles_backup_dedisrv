# Backup and File Move Automation

This project automates the process of moving files from one directory to another using a Go program (`moveFiles.go`) and a PowerShell script (`runMove.ps1`). The goal is to move files modified in the last 24 hours from the source directory to a timestamped backup folder in the destination directory.

## Components

### 1. `moveFiles.go`
A Go program that moves files from a source directory to a destination directory. The program checks if the files have been modified within the last 24 hours before moving them. It also creates a backup folder with a timestamp in the destination directory.

#### How it works:
- The program reads the source directory.
- It checks each file's modification date to determine whether it should be moved.
- If the file has been modified within the last 24 hours, it is moved to a backup folder in the destination directory.

### 2. `runMove.ps1`
A PowerShell script that:
- Installs necessary packages (such as Go, Sysinternals tools, etc.) using `winget`.
- Runs the `moveFiles.go` program.
- Creates a scheduled task to run the file move operation when the `SPT.Server.exe` process closes.

#### How it works:
- The script first checks for necessary software and installs them if missing.
- It then executes the Go program to move the files.
- Lastly, it creates a scheduled task to monitor the closing of the `SPT.Server.exe` process and triggers the file move operation upon its closure.

## Prerequisites

Before running these scripts, ensure the following:
1. **Go Programming Language** is installed.
2. **Sysinternals Handle tool** is available (used by the script to check for file locks).
3. **winget** is available to install packages (or install manually).
4. The source directory contains files you want to back up.

## Setup

### Step 1: Install Necessary Packages

The PowerShell script `runMove.ps1` installs the required packages using the `winget` package manager. It checks for the following:
- **Microsoft.Sysinternals.Handle**: To handle file locks.
- **GoLang.Go**: To run the Go program.
- **7zip.7zip**: Optional, for compression.
- **Git.Git**: Optional, for version control.
- **Microsoft.PowerShell**: Optional, for PowerShell 7.
- **Microsoft.VCRedist.2015+.x64**: Optional, for Visual C++ Redistributables.

### Step 2: Ensure Sysinternals Handle is Available

The script checks if `handle.exe` is available on the system, which is used to check file locks during the execution of the file move process.

### Step 3: Run the Go Program

Once all dependencies are installed, the PowerShell script runs the Go program (`moveFiles.go`) to move the files from the source directory to the backup destination directory.

### Step 4: Create Scheduled Task

The PowerShell script also creates a scheduled task that triggers the file move operation when the `SPT.Server.exe` process closes. This task is created using the Windows Task Scheduler with elevated privileges.

## Usage

1. **Run the PowerShell Script:**

   Execute the `runMove.ps1` PowerShell script with administrator privileges. It will:
   - Check for necessary software.
   - Install any missing packages.
   - Run the `moveFiles.go` program.
   - Create a scheduled task to automate the backup when `SPT.Server.exe` closes.

2. **Go Program (`moveFiles.go`) Execution:**
   The Go program will:
   - Backup files from `F:\dedicated\SPTDedicated_v3.9.8\user\profiles` to `D:\dedicated_backups\savefiles\spt_profiles\backup_1_<date>` if they have been modified within the last 24 hours.
   - The backup folder will be named with the format `backup_1_<yyyy-mm-dd>`.

### Example of Log Entries:
- **Log Entries from PowerShell**:
  ```
  2024-12-23 12:00:00 - Running Go program...
  2024-12-23 12:01:00 - Moved file: F:\dedicated\SPTDedicated_v3.9.8\user\profiles\file1.txt to D:\dedicated_backups\savefiles\spt_profiles\backup_1_2024-12-23\file1.txt
  ```

- **Log Entries from Go Program**:
  ```
  Processing file: F:\dedicated\SPTDedicated_v3.9.8\user\profiles\file1.txt
  Last modified: 2024-12-23 10:30:00
  Moved file: F:\dedicated\SPTDedicated_v3.9.8\user\profiles\file1.txt to D:\dedicated_backups\savefiles\spt_profiles\backup_1_2024-12-23\file1.txt
  ```

## Troubleshooting

- If the Go program doesn't execute, ensure that Go is installed and accessible in your system's `PATH`.
- If the PowerShell script fails to create the scheduled task, check for permissions or conflicts with existing tasks.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
