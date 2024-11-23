# Specify the root folder path to search for files
$rootFolderPath = ""

# Specify the target base folder path
$targetBasePath = ""

# Load the .NET System.Drawing assembly for images
Add-Type -AssemblyName System.Drawing

# Initialize counters
$filesMoved = 0
$filesWithDate = 0  # Counter for files that had a valid DateTimeOriginal

# Define the default date to use for files without metadata
$defaultDate = [DateTime]::ParseExact("1900:01:01 00:00:00", "yyyy:MM:dd HH:mm:ss", $null)

# Function to process a single file
function Process-File {
    param (
        [string]$filePath
    )

    # Initialize date variable
    $fileDate = $null

    try {
        if ($filePath -match '\.(jpg|jpeg|png|tiff|gif|bmp|JPG|JPEG|PNG|TIFF|GIF|BMP)$') {
            # Handle image files with EXIF metadata
            try {
                $image = [System.Drawing.Image]::FromFile($filePath)
                $propertyItems = $image.PropertyItems
                $dateTimeOriginalTag = 0x9004 # EXIF CreateDate

                # Extract the EXIF DateTimeOriginal property
                $dateTimeOriginalItem = $propertyItems | Where-Object { $_.Id -eq $dateTimeOriginalTag }

                if ($dateTimeOriginalItem) {
                    $dateTimeOriginalString = [System.Text.Encoding]::ASCII.GetString($dateTimeOriginalItem.Value).Trim([char]0)
                    try {
                        $fileDate = [DateTime]::ParseExact($dateTimeOriginalString, "yyyy:MM:dd HH:mm:ss", $null)
                        $global:filesWithDate++
                    } catch {
                        Write-Host "Invalid DateTimeOriginal format in EXIF for: $filePath. Using default date."
                        $fileDate = $defaultDate
                    }
                } else {
                    Write-Host "DateTimeOriginal not found in EXIF data for: $filePath. Using default date."
                    $fileDate = $defaultDate
                }

                # Dispose of the image object
                $image.Dispose()
            } catch {
                Write-Host "Failed to load image or read EXIF: $filePath. Exception: $($_.Exception.Message)"
                $fileDate = $defaultDate
            }
        } else {
            # Handle non-image files (videos, etc.)
            Write-Host "Processing non-image file: $filePath"
            $fileDate = $defaultDate
        }

        # If file date is still null, use the default date
        if (-not $fileDate) {
            $fileDate = $defaultDate
        }

        # Update file timestamps
        Set-ItemProperty -Path $filePath -Name CreationTime -Value $fileDate
        Set-ItemProperty -Path $filePath -Name LastWriteTime -Value $fileDate

        # Extract year and month from file date
        $year = $fileDate.Year
        $month = $fileDate.Month.ToString("D2") # Format as two digits

        # Construct target folder path
        $targetFolder = Join-Path -Path $targetBasePath -ChildPath "$year\$month"

        # Ensure the target folder exists
        if (-Not (Test-Path -Path $targetFolder)) {
            New-Item -ItemType Directory -Path $targetFolder | Out-Null
            Write-Host "Created folder: $targetFolder"
        }

        # Move the file to the target folder
        $targetPath = Join-Path -Path $targetFolder -ChildPath (Split-Path -Leaf $filePath)
        Move-Item -Path $filePath -Destination $targetPath -Force
        Write-Host "Moved file to: $targetPath"

        # Increment the total counter for moved files
        $global:filesMoved++
    } catch {
        Write-Host "Error processing file ${filePath}: $($_.Exception.Message)"
    }
}

# Process all files in the folder and subfolders
Get-ChildItem -Path $rootFolderPath -Recurse -File |
    Where-Object { $_.Extension -match '\.(jpg|jpeg|png|tiff|gif|bmp|avi|wmv|mov|3gp|JPG|JPEG|AVI|WMV|MOV|3GP|mkv|mp4|mpg)$' } |
    ForEach-Object { Process-File $_.FullName }

# Output the total number of files moved and files with DateTimeOriginal
Write-Host "Total files moved: $filesMoved"
Write-Host "Total files with valid metadata: $filesWithDate"
