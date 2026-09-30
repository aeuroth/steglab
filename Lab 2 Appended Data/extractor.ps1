$ErrorActionPreference = "Stop"

# Dynamically resolve directory for both .ps1 and .exe environments
$scriptDir = if ($PSScriptRoot) { 
    $PSScriptRoot 
} else { 
    Split-Path ([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName) 
}

$embeddedPath = Join-Path $scriptDir "embedded.png"
$originalPath = Join-Path $scriptDir "image.png"
$outputPath   = Join-Path $scriptDir "extracted_payload.ps1"

Write-Host "Embedded image: $embeddedPath"
Write-Host "Original image: $originalPath"
Write-Host "Output script:  $outputPath"
Write-Host ""

$embedded = [System.IO.File]::ReadAllBytes($embeddedPath)
$original = [System.IO.File]::ReadAllBytes($originalPath)

if ($embedded.Length -le $original.Length) {
    throw "No appended payload was found."
}

$payloadOffset = $original.Length
$payloadLength = $embedded.Length - $payloadOffset

$payloadBytes = New-Object byte[] $payloadLength

[Array]::Copy(
    $embedded,
    $payloadOffset,
    $payloadBytes,
    0,
    $payloadLength
)

$scriptText = [System.Text.Encoding]::UTF8.GetString($payloadBytes)

[System.IO.File]::WriteAllText(
    $outputPath,
    $scriptText,
    [System.Text.UTF8Encoding]::new($false)
)

Write-Host "Extraction successful."
Write-Host "Original image size: $($original.Length) bytes"
Write-Host "Payload size:        $payloadLength bytes"
Write-Host "Output:              $outputPath"
