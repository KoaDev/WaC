. $PSScriptRoot\Constants.ps1
. $PSScriptRoot\Get-DeepClone.ps1

function Get-DscResourceState
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Resource,

        [switch]$Minimal
    )

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

    if ($DscResourcesPostInvokeAction.ContainsKey($resourceClone.Name))
    {
        & $DscResourcesPostInvokeAction[$resourceClone.Name] $state
    }

    if ($Minimal -and $DscResourcesMinimalStateProperties.ContainsKey($resourceClone.Name))
    {
        $minimalStateProperties = $DscResourcesMinimalStateProperties[$resourceClone.Name]
        if ($DscResourcesWithoutEnsure -notcontains $resourceClone.Name)
        {
            $minimalStateProperties = $minimalStateProperties + 'Ensure'
        }
        $state = $state | Select-HashtableKeys -KeysArray $minimalStateProperties
    }

    return [ordered]@{
        Type       = $resource.Name
        Identifier = $identifier
        State      = $state
    }
}
