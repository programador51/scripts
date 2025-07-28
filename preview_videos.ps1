Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Select-Videos {
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = "Video Files (*.mp4;*.mov;*.avi)|*.mp4;*.mov;*.avi"
    $dialog.Title = "Select Video Files"
    $dialog.Multiselect = $true
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $dialog.FileNames
    } else {
        return $null
    }
}

function Select-OutputFolder {
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.CheckFileExists = $false
    $dialog.FileName = "Select Folder"
    $dialog.Title = "Select Output Folder"
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return Split-Path $dialog.FileName
    } else {
        return $null
    }
}

function Get-RandomTimestamps {
    param($duration, $count, $clipLength)
    $maxStart = [Math]::Max(0, $duration - $clipLength)
    $rand = New-Object System.Random
    $timestamps = @()
    while ($timestamps.Count -lt $count) {
        $ts = [Math]::Round($rand.NextDouble() * $maxStart, 2)
        if (-not ($timestamps | Where-Object { [Math]::Abs($_ - $ts) -lt $clipLength })) {
            $timestamps += $ts
        }
    }
    return $timestamps
}

$videos = Select-Videos
if (-not $videos) { Write-Host "No videos selected."; exit }

$outputFolder = Select-OutputFolder
if (-not $outputFolder) { Write-Host "No output folder selected."; exit }

foreach ($video in $videos) {
    $durationStr = ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "`"$video`""
    $duration = [double]::Parse($durationStr.Trim(), [System.Globalization.CultureInfo]::InvariantCulture)
    $timestamps = Get-RandomTimestamps -duration $duration -count 5 -clipLength 2

    $tempListFile = [System.IO.Path]::GetTempFileName()
    $tempListPath = "$tempListFile-list.txt"
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($video)
    $outputPath = Join-Path $outputFolder "${baseName}_preview.mp4"

    $parts = @()
    for ($i = 0; $i -lt $timestamps.Count; $i++) {
        $start = $timestamps[$i]
        $part = "$tempListFile-part$i.mp4"
        # Re-encode clip to avoid glitches
        ffmpeg -ss $start -i "`"$video`"" -t 2 -c:v libx264 -preset veryfast -crf 23 -c:a aac -b:a 128k "`"$part`"" -y
        Add-Content -Path $tempListPath -Value "file '$part'"
        $parts += $part
    }

    ffmpeg -f concat -safe 0 -i "$tempListPath" -c copy "`"$outputPath`"" -y

    # Clean up temporary files
    Remove-Item $parts
    Remove-Item $tempListPath
}

Write-Host "Previews generated in $outputFolder"
