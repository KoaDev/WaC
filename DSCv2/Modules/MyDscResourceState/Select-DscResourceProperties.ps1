. $PSScriptRoot\Constants.ps1

function Select-DscResourceIdProperties
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Resource,

        [string]$ResourceName
    )

    return Select-DscResourcePropertiesHelper $Resource $ResourceName -Id
}

function Select-DscResourceStateProperties
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Resource,

        [string]$ResourceName
    )

    return Select-DscResourcePropertiesHelper $Resource $ResourceName
}

function Select-DscResourcePropertiesHelper
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Resource,

        [string]$ResourceName,

        [switch]$Id
    )

    $ResourceName = $ResourceName ? $ResourceName : $Resource.Name

    if (-not $DscResourcesIdProperties.ContainsKey($ResourceName))
    {
        throw "The resource '$ResourceName' is not supported."
    }
    $idProperties = $DscResourcesIdProperties[$ResourceName]
    
    $properties = $Resource.ContainsKey('Property') ? $Resource.Property : $Resource

    if ($DscResourcesDefaultProperties.ContainsKey($ResourceName))
    {
        $properties = New-MergedHashtable $DscResourcesDefaultProperties[$ResourceName] $properties
    }

    if ($Id)
    {
        $resultProperties = $properties | Select-HashtableKeys -KeysArray $idProperties
        if ($resultProperties.Count -eq 0)
        {
            $resultProperties.Id = $ResourceName
        }
    }
    else
    {
        $resultProperties = $properties | Select-HashtableKeys -KeysArray $idProperties -InvertSelection
        $resultProperties.remove("$($ResourceName)Key")
    }

    return $resultProperties
}


function New-MergedHashtable
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromRemainingArguments = $true)]
        [hashtable[]]$Hashtables
    )

    $mergedHashtable = @{}

    foreach ($hashtable in $Hashtables)
    {
        foreach ($key in $hashtable.Keys)
        {
            $mergedHashtable[$key] = $hashtable[$key]
        }
    }

    return $mergedHashtable
}
