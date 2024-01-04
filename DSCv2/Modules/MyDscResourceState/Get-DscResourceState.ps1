Import-Module PSDesiredStateConfiguration
Import-Module Hashtable-Helpers

. $PSScriptRoot\Constants.ps1

function Get-DscResourceState
{
    [CmdletBinding()]
    param ([hashtable]$resource)

    Write-Verbose "Getting DSC Resource State for $($resource | ConvertTo-Json -Depth 100)"

    # Clone the hashtable to prevent modifying the original
    $dscResource = $resource.Clone()
    $dscResource.ModuleName = $dscResource.ModuleName ?? $defaultModuleName
    if (-not $dscResource.Property)
    {
        $dscResource.Property = @{}
    }
    # $dscProperties = $dscResource.Property
    
    $currentValue = Invoke-DscResource @dscResource -Method Get -Verbose:($VerbosePreference -eq 'Continue') | ConvertTo-Hashtable

    $idProperties = $resourceIdProperties[$dscResource.Name]
    $identifier, $state = Split-Hashtable -OriginalHashtable $currentValue -KeysArray $idProperties

    return @{
        Type       = $resource.Name
        Identifier = $identifier
        State      = $state
    }
}
