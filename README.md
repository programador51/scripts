✅ OPCIÓN RECOMENDADA: Usar PS2EXE (sin instalar nada globalmente)
Puedes hacerlo así:

1. Descarga el módulo ps2exe
Abre PowerShell como administrador y ejecuta:

powershell
Copiar código
Install-Module -Name ps2exe -Scope CurrentUser -Force
Si te pide permisos para instalar desde PSGallery, acepta escribiendo Y.

2. Convierte tu script .ps1 a .exe:
powershell
Copiar código
Invoke-ps2exe "C:\ruta\agregar-watermark.ps1" "C:\ruta\agregar-watermark.exe" -noConsole -icon "icono.ico"
Puedes quitar -icon si no tienes un ícono personalizado.

Si quieres que se vea la consola, quita -noConsole.

✅ ¿No quieres instalar nada?
También puedes usar el script portable desde GitHub:

Ve a: https://github.com/MScholtes/PS2EXE/releases

Descarga el ZIP PS2EXE.zip y extrae su contenido.

Ejecuta ps2exe.ps1 con este comando:

powershell
Copiar código
powershell -ExecutionPolicy Bypass -File .\ps2exe.ps1 -inputFile agregar-watermark.ps1 -outputFile agregar-watermark.exe -noConsole
✅ Resultado
Esto creará un archivo .exe que puedes ejecutar en cualquier equipo con Windows (¡incluso sin necesidad de tener PowerShell abierto!).

📝 Internamente sigue siendo un script de PowerShell empaquetado, así que Windows Defender no lo verá como amenaza mientras no lo modifiques con código malicioso.
