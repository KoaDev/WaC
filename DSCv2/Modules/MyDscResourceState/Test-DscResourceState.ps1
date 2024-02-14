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
        $resourceClone.Property = New-MergedHashtable $DscResourcesDefaultProperties[$resourceClone.Name] $resourceClone.Property
    }
    if ($DscResourcesWithoutEnsure -notcontains $resourceClone.Name)
    {
        $resourceClone.Property.Ensure = $resourceClone.Property.Ensure ?? 'Present'
    }

    try
    {
        Write-Verbose "Tested properties: $($resourceClone.Property | ConvertTo-Json -EnumsAsStrings -Depth 100)"

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
