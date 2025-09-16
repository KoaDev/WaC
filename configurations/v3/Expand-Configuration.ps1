# .\Expand-Configuration.ps1 -InputFilePath ".\configuration.dsc.yaml" -OutputFilePath ".\expanded-configuration.dsc.yaml"

param(
  [Parameter(Mandatory=$true)][string]$InputFilePath,
  [Parameter(Mandatory=$true)][string]$OutputFilePath
)

Import-Module powershell-yaml

$compressedResources = Get-Content -Raw $InputFilePath | ConvertFrom-Yaml

function Expand-Name($name, $properties) {
  if (-not $name -or -not ($properties -is [System.Collections.IDictionary])) {
    return $name
  }
  return [regex]::Replace($name, '\[([^\]]+)\]', {
    param($match)
    $key = $match.Groups[1].Value
    if ($properties.ContainsKey($key)) {
      return [string]$properties[$key]
    }
    return $match.Value
  })
}

$expandedResources = foreach ($resource in $compressedResources) {
  
  $props = $resource.properties
  
  if ($props -is [System.Collections.IEnumerable] -and -not ($props -is [string]) -and -not ($props -is [System.Collections.IDictionary])) {
    
    foreach ($propSet in $props) {
      [ordered]@{
        name       = Expand-Name $resource.name $propSet
        type       = $resource.type
        properties = $propSet
      }
    }
  }
  else {
    # Cette partie pour les ressources non-compressées reste la même
    [ordered]@{
      name       = Expand-Name $resource.name $props
      type       = $resource.type
      properties = $props ?? [ordered]@{}
    }
  }
}

$finalDocument = [ordered]@{
  '$schema'   = 'https://raw.githubusercontent.com/PowerShell/DSC/main/schemas/v3/bundled/config/document.json'
  resources = $expandedResources
}

$finalDocument | ConvertTo-Yaml | Set-Content -Path $OutputFilePath -Encoding UTF8

Write-Host "Le fichier de configuration a été développé avec succès dans '$OutputFilePath'."