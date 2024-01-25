Import-Module PSDesiredStateConfiguration
Import-Module Hashtable-Helpers

. $PSScriptRoot\Constants.ps1

function Set-DscResourceState
{
    [CmdletBinding()]
    param ([hashtable]$Resource)

    Write-Verbose "Setting DSC Resource State for $($Resource | ConvertTo-Json -Depth 100)"

    $resourceClone = Get-DeepClone $Resource
    $resourceClone.ModuleName = $resourceClone.ModuleName ?? $DefaultDscResourceModuleName
    $resourceClone.Property = $resourceClone.Property ?? @{}
    if ($DscResourcesDefaultProperties.ContainsKey($resourceClone.Name))
    {
        $resourceClone.Property = $DscResourcesDefaultProperties[$resourceClone.Name] + $resourceClone.Property
    }
    $resourceClone.Property.Ensure = $resourceClone.Property.Ensure ?? 'Present'

    $setResult = Invoke-DscResource @resourceClone -Method Set -Verbose:($VerbosePreference -eq 'Continue')
    
    return $setResult
}
