# Define the source and destination folders
$sourceFolder = ""
$destinationFolder = ""

# Define the file extension to move (e.g., .txt)
$fileExtension = "*.webp"

# Define the target date for modification and creation
$targetDate = Get-Date "1950-01-01"

# Check if destination folder exists; create it if it doesn't
if (!(Test-Path -Path $destinationFolder)) {
    New-Item -ItemType Directory -Path $destinationFolder
}

# Get all files with the specified extension in the source folder and its subfolders
$files = Get-ChildItem -Path $sourceFolder -Filter $fileExtension -File -Recurse

# Initialize variables for subfolder creation
$subfolderCount = 1
$itemCount = 0
$currentSubfolder = Join-Path -Path $destinationFolder -ChildPath $subfolderCount

# Ensure the first subfolder exists
if (!(Test-Path -Path $currentSubfolder)) {
    New-Item -ItemType Directory -Path $currentSubfolder
}

# Move files to subfolders with a max of 3000 items per subfolder
foreach ($file in $files) {
    # If the current subfolder has reached 3000 items, create a new subfolder
    if ($itemCount -ge 3000) {
        $subfolderCount++
        $currentSubfolder = Join-Path -Path $destinationFolder -ChildPath $subfolderCount
        if (!(Test-Path -Path $currentSubfolder)) {
            New-Item -ItemType Directory -Path $currentSubfolder
        }
        $itemCount = 0
    }
    
    # Move the file to the current subfolder
    $destinationPath = Join-Path -Path $currentSubfolder -ChildPath $file.Name
    Move-Item -Path $file.FullName -Destination $destinationPath
    
    # Change the file's date attributes to the target date
    Set-ItemProperty -Path $destinationPath -Name CreationTime -Value $targetDate
    Set-ItemProperty -Path $destinationPath -Name LastWriteTime -Value $targetDate
    
    $itemCount++
}

Write-Host "Files with the extension '$fileExtension' from '$sourceFolder' and its subfolders have been moved to subfolders in '$destinationFolder' and their date attributes set to $targetDate."
