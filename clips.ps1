Add-Type -AssemblyName System.Windows.Forms

# ==============================
# Select video
# ==============================
$videoDialog = New-Object System.Windows.Forms.OpenFileDialog
$videoDialog.Filter = "Video Files (*.mp4;*.mkv;*.mov;*.avi)|*.mp4;*.mkv;*.mov;*.avi"
$videoDialog.Title = "Select a video"

if ($videoDialog.ShowDialog() -ne "OK") {
    Write-Host "No video selected."
    exit
}

$inputVideo = $videoDialog.FileName
Write-Host "Selected video: $inputVideo"

# ==============================
# Ask parameters
# ==============================
$clipCount = [int](Read-Host "How many clips do you want to generate?")
$clipDuration = [int](Read-Host "Duration of each clip (in seconds)")

if ($clipCount -le 0 -or $clipDuration -le 0) {
    Write-Host "Invalid values."
    exit
}

# ==============================
# Choose output folder
# ==============================
$folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
$folderDialog.Description = "Select folder where clips will be saved"

if ($folderDialog.ShowDialog() -ne "OK") {
    Write-Host "No output folder selected."
    exit
}

$outputFolder = $folderDialog.SelectedPath

# Optional: create subfolder with timestamp
$timestampFolder = Join-Path $outputFolder ("clips_" + (Get-Date -Format "yyyyMMdd_HHmmss"))
New-Item -ItemType Directory -Path $timestampFolder | Out-Null

Write-Host "Clips will be saved in: $timestampFolder"

# ==============================
# Get video duration
# ==============================
$videoDuration = & ffprobe -v error -show_entries format=duration `
-of default=noprint_wrappers=1:nokey=1 "$inputVideo"

$videoDuration = [math]::Floor([double]$videoDuration)

Write-Host "Video duration: $videoDuration seconds"

if (($clipCount * $clipDuration) -gt $videoDuration) {
    Write-Host "Not enough video length to generate non-overlapping clips."
    exit
}

# ==============================
# Generate non-overlapping segments
# ==============================
$random = New-Object System.Random
$usedRanges = @()

function Is-Overlapping($start, $end, $ranges) {
    foreach ($range in $ranges) {
        if ($start -lt $range.End -and $end -gt $range.Start) {
            return $true
        }
    }
    return $false
}

for ($i = 1; $i -le $clipCount; $i++) {

    do {
        $startTime = $random.Next(0, $videoDuration - $clipDuration)
        $endTime = $startTime + $clipDuration
    } while (Is-Overlapping $startTime $endTime $usedRanges)

    $usedRanges += [PSCustomObject]@{
        Start = $startTime
        End   = $endTime
    }

    $outputFile = Join-Path $timestampFolder ("clip_$i.mp4")

    Write-Host "Generating clip $i from $startTime to $endTime..."

    & ffmpeg -y -ss $startTime -i "$inputVideo" -t $clipDuration `
    -c:v libx264 -preset fast -crf 18 `
    -c:a aac -b:a 192k `
    "$outputFile"
}

Write-Host ""
Write-Host "All clips generated successfully 🎬"
Write-Host "Saved in: $timestampFolder"
