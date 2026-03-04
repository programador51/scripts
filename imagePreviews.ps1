Add-Type -AssemblyName System.Windows.Forms

# ==============================
# Select images
# ==============================
$imgDialog = New-Object System.Windows.Forms.OpenFileDialog
$imgDialog.Filter = "Images (*.jpg;*.jpeg;*.png)|*.jpg;*.jpeg;*.png"
$imgDialog.Title = "Select images for slideshow"
$imgDialog.Multiselect = $true

if ($imgDialog.ShowDialog() -ne "OK") {
    Write-Host "No images selected."
    exit
}

$images = $imgDialog.FileNames

if ($images.Count -eq 0) {
    Write-Host "No images selected."
    exit
}

# ==============================
# Select output folder
# ==============================
$folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
$folderDialog.Description = "Select output folder"

if ($folderDialog.ShowDialog() -ne "OK") {
    Write-Host "No output folder selected."
    exit
}

$outputFolder = $folderDialog.SelectedPath
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

$videoOutput = Join-Path $outputFolder "slideshow_$timestamp.mp4"
$gifOutput   = Join-Path $outputFolder "slideshow_$timestamp.gif"

# ==============================
# Copy images temporarily as numbered sequence
# (required for image2 demuxer)
# ==============================
$tempDir = Join-Path $env:TEMP "slideshow_$timestamp"
New-Item -ItemType Directory -Path $tempDir | Out-Null

$index = 0
foreach ($img in $images) {
    $newName = ("img_{0:D4}.jpg" -f $index)
    Copy-Item $img (Join-Path $tempDir $newName)
    $index++
}

# ==============================
# Create MP4
# ==============================
Write-Host "Creating MP4..."

& ffmpeg -y `
-framerate 1 `
-i "$tempDir\img_%04d.jpg" `
-c:v libx264 `
-pix_fmt yuv420p `
-r 30 `
"$videoOutput"

# ==============================
# Create GIF
# ==============================
Write-Host "Creating GIF..."

$palette = Join-Path $tempDir "palette.png"

# Generate palette
& ffmpeg -y `
-framerate 1 `
-i "$tempDir\img_%04d.jpg" `
-vf "palettegen" `
"$palette"

# Create GIF using palette
& ffmpeg -y `
-framerate 1 `
-i "$tempDir\img_%04d.jpg" `
-i "$palette" `
-filter_complex "paletteuse" `
"$gifOutput"

# ==============================
# Cleanup
# ==============================
Remove-Item $tempDir -Recurse -Force

Write-Host ""
Write-Host "Done 🎬"
Write-Host "Video: $videoOutput"
Write-Host "GIF:   $gifOutput"
