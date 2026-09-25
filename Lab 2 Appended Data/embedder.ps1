param(
    [Parameter(Mandatory)]
    [string]$TargetFile,

    [Parameter(Mandatory)]
    [string]$PayloadFile,

    [Parameter(Mandatory)]
    [string]$OutputFile
)

$target  = [System.IO.File]::ReadAllBytes($TargetFile)
$payload = [System.IO.File]::ReadAllBytes($PayloadFile)

$combined = New-Object byte[] ($target.Length + $payload.Length)

[Array]::Copy($target, 0, $combined, 0, $target.Length)
[Array]::Copy($payload, 0, $combined, $target.Length, $payload.Length)

[System.IO.File]::WriteAllBytes($OutputFile, $combined)

Write-Host "Embedding complete."
Write-Host "Original size: $($target.Length) bytes"
Write-Host "Payload size:  $($payload.Length) bytes"
Write-Host "Output size:   $($combined.Length) bytes"
Write-Host "Output file:   $OutputFile"


#Usage: .\embed.ps1 -TargetFile .\original.png -PayloadFile .\payload.ps1 -OutputFile .\combined.png