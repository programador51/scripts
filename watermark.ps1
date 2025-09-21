# ======================== INICIO DEL SCRIPT ========================

# Seleccionar la imagen de watermark
Add-Type -AssemblyName System.Windows.Forms
$watermarkDialog = New-Object System.Windows.Forms.OpenFileDialog
$watermarkDialog.Title = "Selecciona la imagen de la marca de agua (PNG)"
$watermarkDialog.Filter = "Imagen PNG|*.png"
if ($watermarkDialog.ShowDialog() -ne "OK") {
    Write-Host "❌ No se seleccionó marca de agua."
    exit
}
$watermarkPath = $watermarkDialog.FileName

# Pedir al usuario el porcentaje de ancho para el watermark
$percentageInput = Read-Host "Introduce el ancho del watermark como porcentaje (por ejemplo, 25 para 25%)"
if (-not ([double]::TryParse($percentageInput, [ref]$null)) -or [double]$percentageInput -le 0 -or [double]$percentageInput -gt 100) {
    Write-Host "❌ Porcentaje inválido. Debe ser un número entre 1 y 100."
    exit
}
$scaleFactor = [double]$percentageInput / 100.0

# Seleccionar imágenes o videos
$dialog = New-Object System.Windows.Forms.OpenFileDialog
$dialog.Multiselect = $true
$dialog.Filter = "Imágenes y Videos|*.jpg;*.jpeg;*.png;*.bmp;*.mp4;*.mov;*.avi;*.mkv"
if ($dialog.ShowDialog() -ne "OK") {
    Write-Host "❌ No se seleccionaron archivos."
    exit
}
$selectedFiles = $dialog.FileNames
$outputDir = Join-Path (Split-Path $selectedFiles[0]) "output"
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

# Función para obtener ancho de video/imagen con ffprobe
function Get-MediaWidth($mediaPath) {
    $args = @(
        "-v", "error",
        "-select_streams", "v:0",
        "-show_entries", "stream=width",
        "-of", "csv=p=0",
        "`"$mediaPath`""
    )
    $width = & ffprobe @args
    if ([int]::TryParse($width.Trim(), [ref]$null)) {
        return [int]$width.Trim()
    } else {
        Write-Host "⚠️ No se pudo obtener el ancho de $mediaPath"
        return $null
    }
}

# Procesar cada archivo
foreach ($file in $selectedFiles) {
    $mediaWidth = Get-MediaWidth $file
    if (-not $mediaWidth) {
        Write-Host "❌ Omitiendo: $file"
        continue
    }

    $watermarkWidth = [math]::Floor($mediaWidth * $scaleFactor)
    $fileName = [IO.Path]::GetFileNameWithoutExtension($file)
    $ext = [IO.Path]::GetExtension($file)
    $outputPath = Join-Path $outputDir "$fileName-watermarked$ext"

    $filterComplex = "[1:v]scale=${watermarkWidth}:-1[wm];[0:v][wm]overlay=W-w-10:H-h-10"

    $ffmpegArgs = @(
        "-y",
        "-i", "`"$file`"",
        "-i", "`"$watermarkPath`"",
        "-filter_complex", "`"$filterComplex`""
    )

    # Si es imagen, output directo; si es video, copiar el audio
    if ($ext -match "\.jpg|\.jpeg|\.png|\.bmp") {
        $ffmpegArgs += "`"$outputPath`""
    } else {
        $ffmpegArgs += @("-c:a", "copy", "`"$outputPath`"")
    }

    Write-Host "▶️ Procesando $file con watermark de $watermarkWidth px..."
    & ffmpeg @ffmpegArgs

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Guardado: $outputPath"
    } else {
        Write-Host "❌ Falló: $file"
    }
}

Write-Host "`n✅ Listo. Archivos guardados en: $outputDir"
