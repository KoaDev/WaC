Import-Module PSDesiredStateConfiguration
Import-Module Hashtable-Helpers

. $PSScriptRoot\Constants.ps1
. $PSScriptRoot\Get-DeepClone.ps1

function Test-DscResourceState
{
    [CmdletBinding()]
    param ([hashtable]$Resource)

    Write-Verbose "Testing DSC Resource State for $($Resource | ConvertTo-Json -EnumsAsStrings -Depth 100)"

    $resourceClone = Get-DeepClone $Resource
    $resourceClone.ModuleName = $resourceClone.ModuleName ?? $DefaultDscResourceModuleName
    $resourceClone.Property = $resourceClone.Property ?? @{}
    if ($DscResourcesDefaultProperties.ContainsKey($resourceClone.Name))
    {
        $resourceClone.Property = $DscResourcesDefaultProperties[$resourceClone.Name] + $resourceClone.Property
    }
    $resourceClone.Property.Ensure = $resourceClone.Property.Ensure ?? 'Present'

    if ($DscResourcesPropertyCleanupAction.ContainsKey($resourceClone.Name))
    {
        & $DscResourcesPropertyCleanupAction[$resourceClone.Name] $resourceClone.Property
    }

    try
    {
        $originalProgressPreference = $global:ProgressPreference
        $global:ProgressPreference = 'SilentlyContinue'
        $testResult = Invoke-DscResource @resourceClone -Method Test -Verbose:($VerbosePreference -eq 'Continue')
    }
    finally
    {
        $global:ProgressPreference = $originalProgressPreference
    }

    $idProperties = $DscResourcesIdProperties[$resourceClone.Name]
    $identifier = Select-HashtableKeys $resourceClone.Property $idProperties

    return [PSCustomObject]@{
        Type           = $resourceClone.Name
        Identifier     = $identifier
        InDesiredState = $testResult.InDesiredState
    }
}
