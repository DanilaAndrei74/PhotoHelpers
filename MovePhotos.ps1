# Define the root directory to search
$SourceRoot = "F:\path\to\source"
$TargetRoot = "F:\path\to\upload\"
$MaxFilesPerFolder = 1000

# Ensure the target root directory exists
if (!(Test-Path -Path $TargetRoot)) {
    New-Item -Path $TargetRoot -ItemType Directory | Out-Null
}

# Initialize variables
$FolderCounter = 1
$FileCounter = 0
$CurrentTargetFolder = Join-Path -Path $TargetRoot -ChildPath $FolderCounter

# Create the first target folder
if (!(Test-Path -Path $CurrentTargetFolder)) {
    New-Item -Path $CurrentTargetFolder -ItemType Directory | Out-Null
}

# Search files recursively in the source directory
Get-ChildItem -Path $SourceRoot -Recurse -File | ForEach-Object {
    $File = $_

    # Move file to the current target folder
    $TargetPath = Join-Path -Path $CurrentTargetFolder -ChildPath $File.Name
    Move-Item -Path $File.FullName -Destination $TargetPath -Force

    $FileCounter++

    # If the target folder reaches the max file count, create a new folder
    if ($FileCounter -ge $MaxFilesPerFolder) {
        $FileCounter = 0
        $FolderCounter++
        $CurrentTargetFolder = Join-Path -Path $TargetRoot -ChildPath $FolderCounter

        if (!(Test-Path -Path $CurrentTargetFolder)) {
            New-Item -Path $CurrentTargetFolder -ItemType Directory | Out-Null
        }
    }
}

Write-Host "File organization complete."
