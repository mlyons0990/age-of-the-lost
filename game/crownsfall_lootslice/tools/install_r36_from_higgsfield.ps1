param(
    [Parameter(Mandatory=$true)]
    [string]$ExportUrl,
    [string]$ProjectRoot = "",
    [ValidateSet("AOTL_Warrior_R36.glb","AOTL_Warrior_R37.glb","AOTL_Warrior_R39.glb","AOTL_Warrior_R40.glb")]
    [string]$TargetFileName = "AOTL_Warrior_R40.glb",
    [switch]$RunImportAudit
)

# Download a signed Higgsfield Warrior GLB and invoke the already backup-safe installer.
# Signed links expire; request a fresh one immediately before running.
$ErrorActionPreference = "Stop"
$tools = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = (Resolve-Path (Join-Path $tools "..")).Path
}
if (-not $ExportUrl.StartsWith("https://", [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "HTTPS Higgsfield export URL required."
}
$parsed = [uri]$ExportUrl
if (-not $parsed.Host.EndsWith(".r2.cloudflarestorage.com")) {
    throw "Unexpected export host: $($parsed.Host). Use the signed URL from the Higgsfield scene export."
}
if (-not $parsed.AbsolutePath.EndsWith(".glb")) {
    throw "Expected a .glb download path."
}
$downloadPath = Join-Path ([System.IO.Path]::GetTempPath()) ("AOTL_R36_" + [guid]::NewGuid().ToString("N") + ".glb")
try {
    Invoke-WebRequest -Uri $ExportUrl -OutFile $downloadPath -MaximumRedirection 3 -TimeoutSec 120
    if (-not (Test-Path $downloadPath)) {
        throw "Download did not produce a GLB."
    }
    $expectedMagic = [System.Text.Encoding]::ASCII.GetString([System.IO.File]::ReadAllBytes($downloadPath), 0, 4)
    if ($expectedMagic -ne "glTF") {
        throw "Downloaded file is not a GLB. Confirm the signed link has not expired."
    }
    $installer = Join-Path $tools "install_r36_warrior.ps1"
    & $installer -SourceGlb $downloadPath -ProjectRoot $ProjectRoot -TargetFileName $TargetFileName -RunImportAudit:$RunImportAudit
    if (-not $?) {
        throw "Local Warrior installer did not succeed."
    }
} finally {
    if (Test-Path $downloadPath) {
        Remove-Item $downloadPath -Force
    }
}
