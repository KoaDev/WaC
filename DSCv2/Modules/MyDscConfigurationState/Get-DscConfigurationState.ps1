Import-Module MyDscResourceState

. $PSScriptRoot\Get-DscResourcesFromYaml.ps1

$script:cache = @{}
$script:CacheDuration = [timespan]::FromMinutes(5)

function Get-DscConfigurationState
{
    [CmdletBinding(DefaultParameterSetName = 'YamlFilePath')]
    param (
        [Parameter(ParameterSetName = 'YamlFilePath', Mandatory = $true)]
        [string]$YamlFilePath,

        [Parameter(ParameterSetName = 'ResourceCollection', Mandatory = $true)]
        [hashtable[]]$Resources,
        
        [switch]$Force
    )

    if ($PSCmdlet.ParameterSetName -eq 'YamlFilePath')
    {
        $resources = Get-DscResourcesFromYaml -YamlFilePath $YamlFilePath
    }
    else
    {
        $resources = $Resources
    }

    Get-DscConfigurationStateFromResources -Resources $resources -Force:$Force
}

function Get-DscConfigurationStateFromResources
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable[]]$Resources,
        
        [switch]$Force
    )

    Write-Verbose 'Getting DSC Configuration'

    foreach ($resource in $Resources)
    {
        $idProperties = $DscResourcesIdProperties[$resource.Name]
        $cacheKey = ($resource.Property | Select-HashtableKeys -KeysArray $idProperties | ConvertTo-Json -Depth 100 -Compress).GetHashCode()
        $isInCache = $script:cache.ContainsKey($cacheKey)
        $isOutdated = $isInCache -and (Get-Date) - $script:cache[$cacheKey].Time -gt $script:CacheDuration

        if ($Force -or -not $isInCache -or $isOutdated)
        {
            $result = Get-DscResourceState -resource $resource
            $script:cache[$cacheKey] = @{
                Result = $result
                Time   = Get-Date
            }
        }

        Write-Output $script:cache[$cacheKey].Result
    }
}
