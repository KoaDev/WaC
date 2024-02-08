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
        foreach ($key in $DscResourcesDefaultProperties[$resourceClone.Name].Keys)
        {
            if (-not $resourceClone.Property.ContainsKey($key))
            {
                $resourceClone.Property[$key] = $DscResourcesDefaultProperties[$resourceClone.Name][$key]
            }
        }
    }
    if ($DscResourcesWithoutEnsure -notcontains $resourceClone.Name)
    {
        $resourceClone.Property.Ensure = $resourceClone.Property.Ensure ?? 'Present'
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

    $identifier = Select-DscResourceIdProperties $resourceClone

    return [PSCustomObject]@{
        Type           = $resourceClone.Name
        Identifier     = $identifier
        InDesiredState = $testResult.InDesiredState
    }
}
