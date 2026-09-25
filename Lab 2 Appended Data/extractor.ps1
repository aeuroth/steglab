param(
    [Parameter(Mandatory)]
    [string]$EmbeddedImage,

    [Parameter(Mandatory)]
    [string]$OriginalImage,

    [Parameter(Mandatory)]
    [string]$OutputScript
)

$embedded = [System.IO.File]::ReadAllBytes($EmbeddedImage)
$original = [System.IO.File]::ReadAllBytes($OriginalImage)

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
    $OutputScript,
    $scriptText,
    [System.Text.UTF8Encoding]::new($false)
)

Write-Host "Extraction successful."
Write-Host "Payload size: $payloadLength bytes"
Write-Host "Output: $OutputScript"

#Usage: .\extract.ps1 -EmbeddedImage .\combined.png -OriginalImage .\original.png -OutputScript .\extracted_payload.ps1  