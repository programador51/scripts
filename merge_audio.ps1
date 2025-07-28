Add-Type -AssemblyName System.Windows.Forms

# Function to open file dialog
function Select-File($title) {
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = $title
    $dialog.Filter = "MP4 Video|*.mp4|All files|*.*"
    if ($dialog.ShowDialog() -eq 'OK') {
        return $dialog.FileName
    } else {
        Write-Host "Cancelled."
        exit
    }
}

# Function to save output file
function Select-SaveFile($title) {
    $dialog = New-Object System.Windows.Forms.SaveFileDialog
    $dialog.Title = $title
    $dialog.Filter = "MP4 Video|*.mp4|All files|*.*"
    if ($dialog.ShowDialog() -eq 'OK') {
        return $dialog.FileName
    } else {
        Write-Host "Cancelled."
        exit
    }
}

# Prompt for files
$sourceVideo = Select-File "Select the SOURCE video (to extract audio from)"
$targetVideo = Select-File "Select the TARGET video (to receive the audio)"
$outputVideo = Select-SaveFile "Select the OUTPUT video file name"

# Temp audio file
$tempAudio = "$env:TEMP\extracted_audio.aac"

# Extract audio
Write-Host "Extracting audio from $sourceVideo..."
ffmpeg -y -i "$sourceVideo" -vn -acodec copy "$tempAudio"

# Merge audio into target video
Write-Host "Merging audio into $targetVideo..."
ffmpeg -y -i "$targetVideo" -i "$tempAudio" -c:v copy -map 0:v:0 -map 1:a:0 -shortest "$outputVideo"

# Cleanup
Remove-Item "$tempAudio" -Force

[System.Windows.Forms.MessageBox]::Show("✅ Audio merged successfully into:`n$outputVideo", "Done", 'OK', 'Information')
