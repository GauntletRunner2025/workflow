param (
    [Parameter(Mandatory=$true)]
    [string]$InputJsonPath,
    
    [Parameter(Mandatory=$true)]
    [string]$OutputDirectory,
    
    [Parameter(Mandatory=$false)]
    [string]$CsvOutputPath
)

# Display script start information
Write-Host "Processing components from: $InputJsonPath"
Write-Host "Output directory for C# files: $OutputDirectory"

# If CsvOutputPath is not provided, create a default one
if (-not $CsvOutputPath) {
    $CsvOutputPath = Join-Path -Path $OutputDirectory -ChildPath "components.csv"
    Write-Host "CSV output path: $CsvOutputPath (default)"
} else {
    Write-Host "CSV output path: $CsvOutputPath"
}

# Check if input file exists
if (-not (Test-Path $InputJsonPath)) {
    Write-Error "Input JSON file not found: $InputJsonPath"
    exit 1
}

# Check if output directory exists, create if not
if (-not (Test-Path $OutputDirectory)) {
    Write-Host "Creating output directory: $OutputDirectory"
    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
}

# Define template paths - fixed to use absolute path
$templatesDir = "C:\gauntletai\bounce\Assets\com.gauntletrunner2025.bounce\Documentation\templates~"
$componentTemplatePath = Join-Path -Path $templatesDir -ChildPath "component.template.cs"

# Check if the template file exists
if (-not (Test-Path $componentTemplatePath)) {
    Write-Error "Component template file not found: $componentTemplatePath"
    exit 1
}

# Get the path to the generate-components-csv.ps1 script
$generateCsvScriptPath = Join-Path -Path (Split-Path -Parent $PSCommandPath) -ChildPath "generate-components-csv.ps1"

# Check if the script exists
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
    
    # Read the template file once
    $templateContent = Get-Content -Path $componentTemplatePath -Raw
    
    # Process each component directly to C# files
    foreach ($component in $components) {
        # Validate component has required fields
        if (-not $component.name) {
            Write-Warning "Skipping component with missing name"
            continue
        }
        
        # Extract component properties
        $componentName = $component.name
        $description = $component.description
        $fieldDataType = $component.field_data_type
        
        # Create a copy of the template for this component
        $componentTemplate = $templateContent
        
        # If field_data_type is none, don't include the Value field
        if ($fieldDataType -eq "none") {
            # Remove the line with "public int Value;"
            $componentTemplate = $componentTemplate -replace "public int Value;", ""
        } else {
            # Replace int with the actual data type
            $componentTemplate = $componentTemplate -replace "int", $fieldDataType
        }
        
        # Replace placeholders in the template
        $componentTemplate = $componentTemplate -replace "//Description", "// $description"
        $componentTemplate = $componentTemplate -replace "ComponentName", $componentName
        
        # Create output file path
        $outputFilePath = Join-Path -Path $OutputDirectory -ChildPath "$componentName.cs"
        
        # Save the processed template to the output file
        $componentTemplate | Out-File -FilePath $outputFilePath -Encoding utf8
        
        Write-Host "Created component C# file: $outputFilePath"
    }
    
    Write-Host "Processing complete. $($components.Count) C# component files created in $OutputDirectory"
    Write-Host "CSV summary created at: $CsvOutputPath"
} 
catch {
    Write-Error "An error occurred: $_"
    exit 1
} 