param (
    [Parameter(Mandatory=$true)]
    [string]$InputJsonPath,
    
    [Parameter(Mandatory=$true)]
    [string]$OutputDirectory,
    
    [Parameter(Mandatory=$false)]
    [string]$CsOutputDirectory,
    
    [Parameter(Mandatory=$false)]
    [string]$CsvOutputPath
)

# Display script start information
Write-Host "Processing components from: $InputJsonPath"
Write-Host "Output directory for JSON files: $OutputDirectory"

# If CsOutputDirectory is not provided, create a default one
if (-not $CsOutputDirectory) {
    $CsOutputDirectory = Join-Path -Path $OutputDirectory -ChildPath "cs"
    Write-Host "Output directory for CS files: $CsOutputDirectory (default)"
} else {
    Write-Host "Output directory for CS files: $CsOutputDirectory"
}

# If CsvOutputPath is not provided, create a default one
if (-not $CsvOutputPath) {
    $csvDir = Split-Path -Parent $OutputDirectory
    $CsvOutputPath = Join-Path -Path $csvDir -ChildPath "components.csv"
    Write-Host "CSV output path: $CsvOutputPath (default)"
} else {
    Write-Host "CSV output path: $CsvOutputPath"
}

# Check if input file exists
if (-not (Test-Path $InputJsonPath)) {
    Write-Error "Input JSON file not found: $InputJsonPath"
    exit 1
}

# Check if output directories exist, create if not
if (-not (Test-Path $OutputDirectory)) {
    Write-Host "Creating output directory for JSON files: $OutputDirectory"
    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path $CsOutputDirectory)) {
    Write-Host "Creating output directory for CS files: $CsOutputDirectory"
    New-Item -Path $CsOutputDirectory -ItemType Directory -Force | Out-Null
}

# Get the path to the generate-component-cs.ps1 script
$generateCsScriptPath = "C:\gauntletai\bounce\PowerShell\generate-component-cs.ps1"

# Get the path to the generate-components-csv.ps1 script
$generateCsvScriptPath = "C:\gauntletai\bounce\PowerShell\generate-components-csv.ps1"

# Check if the scripts exist
if (-not (Test-Path $generateCsScriptPath)) {
    Write-Error "Generate CS script not found: $generateCsScriptPath"
    exit 1
}

if (-not (Test-Path $generateCsvScriptPath)) {
    Write-Error "Generate CSV script not found: $generateCsvScriptPath"
    exit 1
}

try {
    # Read and parse the JSON file
    $jsonContent = Get-Content -Path $InputJsonPath -Raw
    $jsonObject = $jsonContent | ConvertFrom-Json
    
    # Check if the JSON has a 'components' property
    if ($jsonObject.PSObject.Properties.Name -contains "components") {
        $components = $jsonObject.components
    } else {
        # Assume the JSON is already an array of components
        $components = $jsonObject
    }
    
    Write-Host "Found $($components.Count) components to process"
    
    # First, generate the CSV file with all components
    Write-Host "Generating CSV file with all components..."
    $csvResult = & $generateCsvScriptPath -OutputCsvPath $CsvOutputPath -Components $components
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Successfully generated CSV file: $CsvOutputPath"
    } else {
        Write-Warning "Failed to generate CSV file: $CsvOutputPath"
    }
    
    # Process each component
    foreach ($component in $components) {
        # Validate component has required fields
        if (-not $component.name) {
            Write-Warning "Skipping component with missing name"
            continue
        }
        
        # Create output file path for JSON
        $outputJsonPath = Join-Path -Path $OutputDirectory -ChildPath "$($component.name).component.json"
        
        # Convert component to JSON and save to file
        $componentJson = $component | ConvertTo-Json -Depth 10
        $componentJson | Out-File -FilePath $outputJsonPath -Encoding utf8
        
        Write-Host "Created component JSON file: $outputJsonPath"
        
        # Call the generate-component-cs.ps1 script to create the CS file
        & $generateCsScriptPath -InputJsonPath $outputJsonPath -OutputDirectory $CsOutputDirectory
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Successfully generated CS file for component: $($component.name)"
        } else {
            Write-Warning "Failed to generate CS file for component: $($component.name)"
        }
    }
    
    Write-Host "Processing complete. $($components.Count) component files created in $OutputDirectory and $CsOutputDirectory"
    Write-Host "CSV summary created at: $CsvOutputPath"
} 
catch {
    Write-Error "An error occurred: $_"
    exit 1
}
