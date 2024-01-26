Import-Module MyDscResourceState

. $PSScriptRoot\Yaml.ps1
. $PSScriptRoot\Invoke-DscResourceState.ps1

function Set-DscConfigurationState
{
    [CmdletBinding(DefaultParameterSetName = 'YamlFilePath')]
    param (
        [Parameter(ParameterSetName = 'YamlFilePath', Mandatory = $true)]
        [string]$YamlFilePath,

        [Parameter(ParameterSetName = 'ResourceCollection', Mandatory = $true)]
        [hashtable[]]$Resources,

        [switch]$Force
    )

    $null = $PSBoundParameters.Remove('Force')
    $resources = Get-ResourcesFromYamlFilePathOrResourceCollection @PSBoundParameters

    $result = @()
    foreach ($resource in $resources)
    {
        if (-not $Force)
        {
            $cacheKey = Get-DscResourceHash -Resource $resource
            $testedResource = Get-CacheEntryOrNull -CacheName 'Test' -Key $cacheKey

            if ($null -ne $testedResource -and $testedResource.InDesiredState)
            {
                continue
            }
        }

        $setResult = Set-DscResourceState $resource
        
        $result += $setResult
    }

    return $result
}
