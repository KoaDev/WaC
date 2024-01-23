Import-Module Hashtable-Helpers

. $PSScriptRoot\Constants.ps1

# TODO : Remplace les appels à Select-HashtableKeys par un appel à Select-DscResourceIdProperties
# TODO : Faire la même chose pour Get-DscResourceState
function Select-DscResourceIdProperties
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Resource,

        [string]$ResourceName
    )

    if (-not $ResourceName)
    {
        $ResourceName = $Resource.Name
    }

    if ($Resource.ContainsKey('Property'))
    {
        $properties = $resource.Property
    }
    else
    {
        $properties = $resource
    }

    $idProperties = $DscResourcesIdProperties[$ResourceName]
    return $properties | Select-HashtableKeys -KeysArray $idProperties
}

function Select-DscResourceStateProperties
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Resource,

        [string]$ResourceName
    )

    if (-not $ResourceName)
    {
        $ResourceName = $Resource.Name
    }

    if ($Resource.ContainsKey('Property'))
    {
        $properties = $resource.Property
    }
    else
    {
        $properties = $resource
    }

    $idProperties = $DscResourcesIdProperties[$ResourceName]
    return $properties | Select-HashtableKeys -KeysArray $idProperties -InvertSelection
}
