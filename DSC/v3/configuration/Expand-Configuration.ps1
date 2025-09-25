# .\Expand-Configuration.ps1 -InputFilePath ".\configuration.dsc.yaml" -OutputFilePath ".\expanded-configuration.dsc.yaml"

param(
    [Parameter(Mandatory = $true)]
    [string] $InputFilePath,
    [Parameter(Mandatory = $true)]
    [string] $OutputFilePath
)

Import-Module powershell-yaml

$compressedResources = Get-Content -Raw -Path $InputFilePath | ConvertFrom-Yaml

function ConvertToHashtable {
    param([object]$InputObject)

    if ($null -eq $InputObject) {
        return @{}
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        return $InputObject
    }

    $hash = @{}
    foreach ($p in $InputObject.PSObject.Properties) {
        $hash[$p.Name] = $p.Value
    }
    return $hash
}

function GetPropertySets {
    param([object]$Properties)

    $result = @()

    if ($null -eq $Properties) {
        $result = $result + @(@{})
        return $result
    }

    $isEnumerable = $Properties -is [System.Collections.IEnumerable]
    $isString = $Properties -is [string]

    if ($isEnumerable -and (-not $isString)) {
        foreach ($p in $Properties) {
            $converted = ConvertToHashtable $p
            $result = $result + @($converted)
        }
        return $result
    }

    $single = ConvertToHashtable $Properties
    $result = $result + @($single)
    return $result
}

function ExpandResourceName {
    param(
        [Parameter(Mandatory = $true)] [string]$Name,
        [object]$Properties
    )

    if ($null -eq $Properties) {
        $Properties = @{}
    }

    $props = ConvertToHashtable $Properties

    if (-not $Name) {
        return $Name
    }

    $pattern = '\[([^\]]+)\]'
    $expanded = [regex]::Replace($Name, $pattern, {
        param($m)
        $key = $m.Groups[1].Value
        if ($props.ContainsKey($key)) {
            return [string]$props[$key]
        } else {
            return $m.Value
        }
    })

    return $expanded
}

function RemoveResourceNameKey {
    param([object]$InputObject)

    $ht = ConvertToHashtable $InputObject
    $out = [ordered]@{}

    foreach ($k in $ht.Keys) {
        if ($k -ne 'resourceName') {
            $out[$k] = $ht[$k]
        }
    }

    return $out
}

$expandedResources = @()

foreach ($resource in $compressedResources) {
    $propSets = GetPropertySets -Properties $resource.properties

    foreach ($propSet in $propSets) {
        $expandedItem = [ordered]@{
            name       = ExpandResourceName -Name $resource.name -Properties $propSet
            type       = $resource.type
            properties = RemoveResourceNameKey -InputObject $propSet
        }

        $expandedResources = $expandedResources + @($expandedItem)
    }
}

$finalDocument = [ordered]@{
    '$schema' = 'https://raw.githubusercontent.com/PowerShell/DSC/main/schemas/v3/bundled/config/document.json'
    resources = $expandedResources
}

$yamlOut = ConvertTo-Yaml -Data $finalDocument
Set-Content -Path $OutputFilePath -Value $yamlOut -Encoding UTF8

Write-Host "Le fichier de configuration a été développé avec succès dans '$OutputFilePath'."
