$mp4FilePath = "C:\Git\PhotoHelpers\40ce8c05-5e41-48cd-b375-45f074b1abc1.mp4"
$fileInfo = Get-Item -Path $mp4FilePath

# File system metadata
$creationDate = $fileInfo.CreationTime
$lastModifiedDate = $fileInfo.LastWriteTime

Write-Host "File creation date: $creationDate"
Write-Host "Last modified date: $lastModifiedDate"
