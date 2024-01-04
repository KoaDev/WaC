Import-Module PSDesiredStateConfiguration
Import-Module Hashtable-Helpers

. $PSScriptRoot\Constants.ps1

function Test-DscResourceState
{
    [CmdletBinding()]
    param ([hashtable]$resource)

    Write-Verbose "Testing DSC Resource State for $($resource | ConvertTo-Json -Depth 100)"

    # Clone the hashtable to prevent modifying the original
    $dscResource = $resource.Clone()
    $dscResource.ModuleName = $dscResource.ModuleName ?? $defaultModuleName
    if (-not $dscResource.Property)
    {
        $dscResource.Property = @{}
    }
    
    $testResult = Invoke-DscResource @dscResource -Method Test -Verbose:($VerbosePreference -eq 'Continue')

    $idProperties = $resourceIdProperties[$dscResource.Name]
    $identifier = Select-HashtableKeys $dscResource.Property $idProperties

    return @{
        Type           = $resource.Name
        Identifier     = $identifier
        InDesiredState = $testResult.InDesiredState
    }
}
