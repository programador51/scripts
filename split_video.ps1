Add-Type -AssemblyName System.Windows.Forms

# 1. Seleccionar archivo de video
$videoDialog = New-Object System.Windows.Forms.OpenFileDialog
$videoDialog.Title = "Selecciona el video"
$videoDialog.Filter = "Videos MP4|*.mp4|Todos los archivos|*.*"
$videoDialog.Multiselect = $false

if ($videoDialog.ShowDialog() -ne "OK") {
    Write-Host "❌ No se seleccionó ningún archivo de video. Saliendo..."
    exit
}

$videoPath = $videoDialog.FileName

# 2. Seleccionar carpeta de salida
$folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
$folderDialog.Description = "Selecciona la carpeta donde se guardarán los frames"

if ($folderDialog.ShowDialog() -ne "OK") {
    Write-Host "❌ No se seleccionó carpeta de salida. Saliendo..."
    exit
}

$outputFolder = $folderDialog.SelectedPath
$outputPattern = Join-Path $outputFolder "output_%04d.png"

# 3. Ejecutar FFmpeg
$ffmpegArgs = @(
    "-y",
    "-i", "`"$videoPath`"",
    "-vf", "fps=30",
    "`"$outputPattern`""
)

Write-Host "🟡 Extrayendo frames de: $videoPath"
Write-Host "📁 Carpeta destino: $outputFolder"

& ffmpeg @ffmpegArgs

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Frames extraídos exitosamente a: $outputFolder"
} else {
    Write-Host "❌ Hubo un error ejecutando ffmpeg"
}
