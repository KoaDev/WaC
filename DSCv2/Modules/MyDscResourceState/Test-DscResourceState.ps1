Import-Module PSDesiredStateConfiguration
Import-Module Hashtable-Helpers

. $PSScriptRoot\Constants.ps1
. $PSScriptRoot\Get-DeepClone.ps1

function Test-DscResourceState
{
    [CmdletBinding()]
    param ([hashtable]$Resource)

    Write-Verbose "Testing DSC Resource State for $($Resource | ConvertTo-Json -Depth 100)"

    $resourceClone = Get-DeepClone $Resource
    $resourceClone.ModuleName = $resourceClone.ModuleName ?? $DefaultDscResourceModuleName
    $resourceClone.Property = $resourceClone.Property ?? @{}
    if ($DscResourcesDefaultProperties.ContainsKey($resourceClone.Name))
    {
        $resourceClone.Property = $DscResourcesDefaultProperties[$resourceClone.Name] + $resourceClone.Property
    }
    $resourceClone.Property.Ensure = $resourceClone.Property.Ensure ?? 'Present'

    $testResult = Invoke-DscResource @resourceClone -Method Test -Verbose:($VerbosePreference -eq 'Continue')

    $idProperties = $DscResourcesIdProperties[$resourceClone.Name]
    $identifier = Select-HashtableKeys $resourceClone.Property $idProperties

    return @{
        Type           = $resourceClone.Name
        Identifier     = $identifier
        InDesiredState = $testResult.InDesiredState
    }
}
