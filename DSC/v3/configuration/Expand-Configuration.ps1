# .\Expand-Configuration.ps1 -InputFilePath ".\configuration.dsc.yaml" -OutputFilePath ".\expanded-configuration.dsc.yaml"

param (
    [Parameter(Mandatory = $true)]
    [string] $InputFilePath,

    [Parameter(Mandatory = $true)]
    [string] $OutputFilePath
)

Import-Module powershell-yaml

$compressedResources = Get-Content -Raw -Path $InputFilePath | ConvertFrom-Yaml

function Expand-Name {
    param (
        [Parameter(Mandatory = $true)]
        [string] $name,

        # properties devient optionnel
        [object] $properties = @{}
    )

    if (-not $name -or -not ($properties -is [System.Collections.IDictionary])) {
        return $name
    }

    return [regex]::Replace(
        $name,
        '\[([^\]]+)\]',
        {
            param ($m)
            $key = $m.Groups[1].Value
            if ($properties.ContainsKey($key)) { return [string] $properties[$key] }
            return $m.Value
        }
    )
}

function Strip-ResourceName {
    param (
        [Parameter(Mandatory = $true)]
        [object] $obj
    )

    if ($null -eq $obj) {
        return [ordered] @{ }
    }

    if ($obj -is [System.Collections.IDictionary]) {
        $out = [ordered] @{ }
        foreach ($k in $obj.Keys) {
            if ($k -ne 'resourceName') {
                $out[$k] = $obj[$k]
            }
        }
        return $out
    }

    return $obj
}

$expandedResources = foreach ($resource in $compressedResources) {
    $props = $resource.properties

    # Normalise toujours en collection de "prop sets"
    $propSets =
        if ($null -eq $props) {
            ,@{}  # properties manquant ou null -> un set vide
        }
        elseif ($props -is [System.Collections.IEnumerable] -and
                $props -isnot [string] -and
                $props -isnot [System.Collections.IDictionary]) {
            $props # déjà une collection (liste d'objets/ht)
        }
        else {
            ,$props # singleton (ht/objet)
        }

    foreach ($propSet in $propSets) {
        # Expand-Name reçoit toujours une ht (au pire {})
        $forExpand = if ($propSet -is [System.Collections.IDictionary]) { $propSet } else { @{} }

        [ordered]@{
            name       = Expand-Name $resource.name $forExpand
            type       = $resource.type
            properties = if ($null -eq $propSet) { @{} } else { Strip-ResourceName $propSet }
        }
    }
}

$finalDocument = [ordered]@{
    '$schema' = 'https://raw.githubusercontent.com/PowerShell/DSC/main/schemas/v3/bundled/config/document.json'
    resources = $expandedResources
}

$finalDocument | ConvertTo-Yaml | Set-Content -Path $OutputFilePath -Encoding UTF8
Write-Host "Le fichier de configuration a été développé avec succès dans '$OutputFilePath'."
