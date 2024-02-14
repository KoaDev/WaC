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

    $identifier = Select-DscResourceIdProperties -Resource $resourceClone
    $state = Select-DscResourceStateProperties -Resource $getResult -ResourceName $resourceClone.Name

    return [ordered]@{
        Type       = $resource.Name
        Identifier = $identifier
        State      = $state
    }
}
