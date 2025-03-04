param (
    [Parameter(Mandatory=$true)]
    [string]$InputJsonPath,
    
    [Parameter(Mandatory=$true)]
    [string]$OutputDirectory
)

# Display script start information
Write-Host "Processing component file: $InputJsonPath"
Write-Host "Output directory: $OutputDirectory"

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

try {
    # Check if the input file is a component file
    if ($InputJsonPath -match '\.component\.json$') {
        # Read the template file
        $templateContent = Get-Content -Path $componentTemplatePath -Raw
        
        # Read and parse the JSON file
        $jsonContent = Get-Content -Path $InputJsonPath -Raw
        $component = $jsonContent | ConvertFrom-Json
        
        # Extract component properties
        $componentName = $component.name
        $description = $component.description
        $fieldDataType = $component.field_data_type
        
        # If field_data_type is none, don't include the Value field
        if ($fieldDataType -eq "none") {
            # Remove the line with "public int Value;"
            $templateContent = $templateContent -replace "public int Value;", ""
        } else {
            # Replace int with the actual data type
            $templateContent = $templateContent -replace "int", $fieldDataType
        }
        
        # Replace placeholders in the template
        $templateContent = $templateContent -replace "//Description", "// $description"
        $templateContent = $templateContent -replace "ComponentName", $componentName
        
        # Create output file path
        $outputFilePath = Join-Path -Path $OutputDirectory -ChildPath "$componentName.cs"
        
        # Save the processed template to the output file
        $templateContent | Out-File -FilePath $outputFilePath -Encoding utf8
        
        Write-Host "Created component C# file: $outputFilePath"
    } else {
        Write-Warning "Input file is not a component JSON file (doesn't end with .component.json): $InputJsonPath"
    }
} 
catch {
    Write-Error "An error occurred: $_"
    exit 1
}
