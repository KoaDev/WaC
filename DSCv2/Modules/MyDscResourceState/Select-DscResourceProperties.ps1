. $PSScriptRoot\Constants.ps1

function Select-DscResourceIdProperties
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Resource,

        [string]$ResourceName
    )

    $ResourceName = $ResourceName ? $ResourceName : $Resource.Name

    if (-not $DscResourcesIdProperties.ContainsKey($ResourceName))
    {
        throw "The resource '$ResourceName' is not supported."
    }
    $idProperties = $DscResourcesIdProperties[$ResourceName]

    $properties = $Resource.ContainsKey('Property') ? $resource.Property : $resource

    $mergedProperties = @{}
    if ($DscResourcesDefaultProperties.ContainsKey($ResourceName))
    {
        foreach ($key in $DscResourcesDefaultProperties[$ResourceName].Keys)
        {
            $mergedProperties[$key] = $DscResourcesDefaultProperties[$ResourceName][$key]
        }
    }
    foreach ($key in $properties.Keys)
    {
        $mergedProperties[$key] = $properties[$key]
    }

    return $mergedProperties | Select-HashtableKeys -KeysArray $idProperties
}

function Select-DscResourceStateProperties
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Resource,

        [string]$ResourceName
    )

    $ResourceName = $ResourceName ? $ResourceName : $Resource.Name

    if (-not $DscResourcesIdProperties.ContainsKey($ResourceName))
    {
        throw "The resource '$ResourceName' is not supported."
    }
    $idProperties = $DscResourcesIdProperties[$ResourceName]
    
    $properties = $Resource.ContainsKey('Property') ? $resource.Property : $resource

    $mergedProperties = @{}
    if ($DscResourcesDefaultProperties.ContainsKey($ResourceName))
    {
        foreach ($key in $DscResourcesDefaultProperties[$ResourceName].Keys)
        {
            $mergedProperties[$key] = $DscResourcesDefaultProperties[$ResourceName][$key]
        }
    }
    foreach ($key in $properties.Keys)
    {
        $mergedProperties[$key] = $properties[$key]
    }

    return $mergedProperties | Select-HashtableKeys -KeysArray $idProperties -InvertSelection
}
