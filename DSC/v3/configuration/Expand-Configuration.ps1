function Expand-ResourceName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [object]$Properties
    )
    
    if ($null -eq $Properties) {
        $Properties = @{}
    }
    
    if (-not $Name) {
        return $Name
    }
    
    $pattern = '\[([^\]]+)\]'
    $expanded = [regex]::Replace($Name, $pattern, {
        param($m)
        $key = $m.Groups[1].Value
        if ($Properties.ContainsKey($key)) {
            return [string]$Properties[$key]
        } else {
            return $m.Value
        }
    })
    
    return $expanded
}

function Expand-Configuration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path $_ })]
        [string]$InputFilePath,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputFilePath
    )
    
    Import-Module powershell-yaml
    
    $compressedResources = Get-Content -Raw -Path $InputFilePath | ConvertFrom-Yaml
    
    $expandedResources = @()
    foreach ($resource in $compressedResources) {
        $propSets = @($resource.properties ?? @{}) 
        
        foreach ($propSet in $propSets) {

            $expandedName = Expand-ResourceName -Name $resource.name -Properties $propSet
            $propSet.Remove('resourceName')

            $expandedResource = [ordered]@{
                name       = $expandedName
                type       = $resource.type
                properties = $propSet
            }

            $expandedResources += $expandedResource
        }
    }
    
    $finalDocument = [ordered]@{
        '$schema' = 'https://raw.githubusercontent.com/PowerShell/DSC/main/schemas/v3/bundled/config/document.json'
        resources = $expandedResources
    }
    
    $yamlOut = ConvertTo-Yaml -Data $finalDocument
    Set-Content -Path $OutputFilePath -Value $yamlOut -Encoding UTF8
    
    Write-Host "Le fichier de configuration a été développé avec succès dans '$OutputFilePath'." -ForegroundColor Green
}
