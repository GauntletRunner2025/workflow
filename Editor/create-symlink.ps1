# Create a symbolic link for Cursor rules
# This script creates a symbolic directory link from ../../.cursor/rules to the .cursor/rules directory in the current script location

# Check if running with administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires administrator privileges to create symbolic links."
    Write-Warning "Please run PowerShell as administrator and try again."
    exit
}

# Get the directory where the script is located
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Define paths
$targetPath = Join-Path -Path $scriptDir -ChildPath ".cursor\rules"
$linkPath = Join-Path -Path (Resolve-Path "../..").Path -ChildPath ".cursor\rules"

# Ensure target path exists
if (-NOT (Test-Path $targetPath)) {
    Write-Error "Target path does not exist: $targetPath"
    exit
}

# Create parent directory for link if it doesn't exist
$linkParent = Split-Path -Parent $linkPath
if (-NOT (Test-Path $linkParent)) {
    New-Item -ItemType Directory -Path $linkParent -Force
    Write-Host "Created parent directory: $linkParent"
}

# Remove existing link if it exists
if (Test-Path $linkPath) {
    Remove-Item -Path $linkPath -Force
    Write-Host "Removed existing link: $linkPath"
}

# Create symbolic link
New-Item -ItemType SymbolicLink -Path $linkPath -Target $targetPath
Write-Host "Created symbolic link from $linkPath to $targetPath"
