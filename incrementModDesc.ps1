# Define the file path
$filePath = "modDesc.xml"

# Check if the file exists
if (-not (Test-Path $filePath)) {
    Write-Host "Error: File '$filePath' does not exist." -ForegroundColor Red
    exit 1
}

# Load the XML file
[xml]$xml = Get-Content $filePath -Encoding UTF8

# Get the <version> element
$versionNode = $xml.modDesc.version
if (-not $versionNode) {
    Write-Host "Error: <version> tag not found in the XML file." -ForegroundColor Red
    exit 1
}

# Parse the version number and increment the last part
$versionParts = $versionNode -split "\."
if ($versionParts.Length -ne 4) {
    Write-Host "Error: <version> format is not valid. Expected format 'X.Y.Z.W'. versionParts has $($versionParts.Length) parts. versionNode is $($versionNode)" -ForegroundColor Red
    exit 1
}

$versionParts[3] = [int]$versionParts[3] + 1
$newVersion = $versionParts -join "."

# Update the <version> element
$xml.modDesc.version = $newVersion

# Save the updated XML back to the file as UTF-8 without BOM
$encoding = [System.Text.UTF8Encoding]::new($false)
$writer = [System.IO.StreamWriter]::new($filePath, $false, $encoding)
$xml.Save($writer)
$writer.Dispose()

Write-Host "Version updated to $newVersion" -ForegroundColor Green
