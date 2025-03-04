param (
    [Parameter(Mandatory=$true)]
    [string]$OutputCsvPath,
    
    [Parameter(Mandatory=$true)]
    [array]$Components
)

# Display script start information
Write-Host "Generating CSV file: $OutputCsvPath"

try {
    # Create the directory if it doesn't exist
    $outputDir = Split-Path -Parent $OutputCsvPath
    if (-not (Test-Path $outputDir)) {
        Write-Host "Creating output directory: $outputDir"
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    # Create a string builder for the CSV content
    $csvContent = "Name,DataType,Description`r`n"
    
    # Process each component
    foreach ($component in $Components) {
        # Validate component has required fields
        if (-not $component.name) {
            Write-Warning "Skipping component with missing name"
            continue
        }
        
        # Get component properties, handling potential missing properties
        $name = $component.name
        $dataType = if ($component.field_data_type) { $component.field_data_type } else { "none" }
        
        # Handle description - escape any commas and quotes to avoid CSV parsing issues
        $description = if ($component.description) {
            # Escape quotes by doubling them and wrap in quotes if it contains commas or quotes
            $escapedDesc = $component.description -replace '"', '""'
            if ($escapedDesc -match '[,"]') {
                """$escapedDesc"""
            } else {
                $escapedDesc
            }
        } else {
            ""
        }
        
        # Add the component to the CSV content
        $csvContent += "$name,$dataType,$description`r`n"
    }
    
    # Write the CSV content to the file
    $csvContent | Out-File -FilePath $OutputCsvPath -Encoding utf8
    
    Write-Host "Successfully generated CSV file with $($Components.Count) components: $OutputCsvPath"
    return $true
} 
catch {
    Write-Error "An error occurred while generating the CSV file: $_"
    return $false
}
