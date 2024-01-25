Import-Module PSDesiredStateConfiguration
Import-Module Hashtable-Helpers

. $PSScriptRoot\Constants.ps1
. $PSScriptRoot\Get-DeepClone.ps1

function Get-DscResourceState
{
    [CmdletBinding()]
    param ([hashtable]$Resource)

    Write-Verbose "Getting DSC Resource State for $($Resource | ConvertTo-Json -EnumsAsStrings -Depth 100)"

    $resourceClone = Get-DeepClone $Resource
    $resourceClone.ModuleName = $resourceClone.ModuleName ?? $DefaultDscResourceModuleName
    $resourceClone.Property = $resourceClone.Property ?? @{}

    try
    {
        $originalProgressPreference = $global:ProgressPreference
        $global:ProgressPreference = 'SilentlyContinue'
        $getResult = Invoke-DscResource @resourceClone -Method Get -Verbose:($VerbosePreference -eq 'Continue') | ConvertTo-Hashtable
    }
    finally
    {
        $global:ProgressPreference = $originalProgressPreference
    }

    $idProperties = $DscResourcesIdProperties[$resourceClone.Name]
    $identifier, $state = Split-Hashtable -OriginalHashtable $getResult -KeysArray $idProperties

    return @{
        Type       = $resource.Name
        Identifier = $identifier
        State      = $state
    }
}
