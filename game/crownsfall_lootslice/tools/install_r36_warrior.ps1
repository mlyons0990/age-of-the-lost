param(
    [Parameter(Mandatory=$true)]
    [string]$SourceGlb,
    [string]$ProjectRoot = "",
    [ValidateSet("AOTL_Warrior_R36.glb","AOTL_Warrior_R37.glb")]
    [string]$TargetFileName = "AOTL_Warrior_R36.glb",
    [switch]$RunImportAudit
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
}
$source = (Resolve-Path $SourceGlb).Path
$models = Join-Path $ProjectRoot 'models'
$destination = Join-Path $models $TargetFileName
$backupDir = Join-Path $ProjectRoot 'backups\models'
New-Item -Path $models -ItemType Directory -Force | Out-Null
New-Item -Path $backupDir -ItemType Directory -Force | Out-Null

$header = [System.IO.File]::ReadAllBytes($source)
if ($header.Length -lt 20 -or [System.Text.Encoding]::ASCII.GetString($header, 0, 4) -ne 'glTF') {
    throw 'Source does not have a GLB glTF header. No existing model was changed.'
}
$bytes = (Get-Item $source).Length
if ($bytes -lt 1000000) {
    throw 'Source GLB is unexpectedly small; refusing replacement.'
}
# Require a real skinned, animated Warrior, not merely any file with glTF magic.
$validator = Join-Path $PSScriptRoot 'verify_r36_glb.py'
if (-not (Test-Path $validator)) {
    throw 'Required GLB validator is missing. No asset replacement was performed.'
}
$py = Get-Command py -ErrorAction SilentlyContinue
$python = Get-Command python -ErrorAction SilentlyContinue
if ($null -ne $py) {
    & $py.Source -3 $validator $source
} elseif ($null -ne $python) {
    & $python.Source $validator $source
} else {
    throw 'Python 3 is required to verify the skeleton and animation clips before installing.'
}
if ($LASTEXITCODE -ne 0) {
    throw 'GLB skeleton/animation validation failed. The installed Warrior was not replaced.'
}
Write-Host 'Warrior GLB skeleton and animation validation PASSED.'

if (Test-Path $destination) {
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $existingSha = (Get-FileHash $destination -Algorithm SHA256).Hash.Substring(0, 12)
    $backupName = "$($TargetFileName.Replace('.glb',''))_$stamp" + "_$existingSha.glb"
    Copy-Item $destination (Join-Path $backupDir $backupName) -ErrorAction Stop
    Write-Host "Previous R36 preserved in backups/models/$backupName"
}

# Stage and rename in the SAME directory; old source and Git LFS proxy remain unchanged.
$staging = Join-Path $models ($TargetFileName + '.incoming')
Copy-Item $source $staging -Force
if ((Get-FileHash $staging -Algorithm SHA256).Hash -ne (Get-FileHash $source -Algorithm SHA256).Hash) {
    Remove-Item $staging -Force
    throw 'Copy checksum mismatch; refusing install.'
}
Move-Item $staging $destination -Force
Write-Host "Installed $destination"
Write-Host "SHA256: $((Get-FileHash $destination -Algorithm SHA256).Hash)"
Write-Host "Original AOTL_Wayfarer_Articulated_Proxy.glb remains untouched."

if ($RunImportAudit) {
    $godot = Get-Command godot -ErrorAction SilentlyContinue
    if ($null -eq $godot) { $godot = Get-Command godot4 -ErrorAction SilentlyContinue }
    if ($null -eq $godot) {
        Write-Warning 'Godot executable not found on PATH. Model installed, import audit not run.'
    } else {
        & $godot.Source --headless --path $ProjectRoot --editor --quit
        if ($LASTEXITCODE -ne 0) { throw 'Godot import failed; prior model backup remains available.' }
        & $godot.Source --headless --path $ProjectRoot --script 'res://tests/verify_warrior_r36_import.gd' -- --model=$TargetFileName
        if ($LASTEXITCODE -ne 0) { throw 'Warrior rig import audit failed; restore from backups/models if needed.' }
    }
}
