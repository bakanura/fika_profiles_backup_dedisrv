package main

import (
	"fmt"
	"io"
	"os"
	"path/filepath"
	"time"
)

func main() {
	// Define source and destination directories
	sourceDir := "F:\\dedicated\\SPTDedicated_v3.9.8\\user\\profiles"
	destDir := "D:\\dedicated_backups\\savefiles\\spt_profiles"

	// Get the current date to create a timestamped backup folder
	dateStr := time.Now().Format("2006-01-02")
	backupFolder := fmt.Sprintf("%s\\backup_1_%s", destDir, dateStr)

	// Create the backup folder if it doesn't exist
	if err := os.MkdirAll(backupFolder, 0755); err != nil {
		fmt.Println("ERROR creating backup folder:", err)
		return
	}

	// Open the source directory
	files, err := os.ReadDir(sourceDir)
	if err != nil {
		fmt.Println("ERROR reading source directory:", err)
		return
	}

	// Process each file in the source directory
	for _, file := range files {
		sourceFile := filepath.Join(sourceDir, file.Name())
		destFile := filepath.Join(backupFolder, file.Name())

		// Log file processing
		fmt.Println("Processing file:", sourceFile)

		// Check if the file exists in the destination (and check if it's modified since last sync)
		sourceFileInfo, err := os.Stat(sourceFile)
		if err != nil {
			fmt.Println("ERROR getting source file info:", err)
			continue
		}

		// Log file info (modification time)
		fmt.Println("Last modified:", sourceFileInfo.ModTime())

		// Check if the file should be moved (only modified files)
		if shouldMove(sourceFileInfo) {
			// Move the file
			err := moveFile(sourceFile, destFile)
			if err != nil {
				fmt.Println("ERROR moving file:", err)
			} else {
				fmt.Println("Moved file:", sourceFile, "to", destFile)
			}
		} else {
			fmt.Println("File not moved (not modified since last sync):", sourceFile)
		}
	}
}

// Function to check if the file should be moved (based on modification date or other criteria)
func shouldMove(fileInfo os.FileInfo) bool {
	// Example: Only move files modified in the last 24 hours
	// You can customize this to match your synchronization requirements
	return time.Since(fileInfo.ModTime()) < 24*time.Hour
}

// Function to move the file to the backup location
func moveFile(source string, dest string) error {
	// Open the source file
	srcFile, err := os.Open(source)
	if err != nil {
		return err
	}
	defer srcFile.Close()

	// Create the destination file
	destFile, err := os.Create(dest)
	if err != nil {
		return err
	}
	defer destFile.Close()

	// Copy the contents of the source file to the destination file
	_, err = io.Copy(destFile, srcFile)
	if err != nil {
		return err
	}

	// Remove the source file after copying
	err = os.Remove(source)
	if err != nil {
		return err
	}

	return nil
}
