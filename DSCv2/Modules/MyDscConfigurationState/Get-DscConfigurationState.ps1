Import-Module MyDscResourceState

. $PSScriptRoot\Get-DscResourcesFromYaml.ps1

$script:cache = @{}
$script:CacheDuration = [timespan]::FromMinutes(5)

function Get-DscConfigurationState
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$YamlFilePath,
        
        [switch]$Force
    )

    Write-Verbose 'Getting DSC Configuration'

    $resources = Get-DscResourcesFromYaml -YamlFilePath $YamlFilePath

    foreach ($resource in $resources)
    {
        $idProperties = $DscResourcesIdProperties[$resource.Name]
        $cacheKey = $resource.Property | Select-HashtableKeys -KeysArray $idProperties | ConvertTo-Json -Depth 100 -Compress
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

        # $result = Get-DscResourceState -resource $resource
        # Write-Output $result
    }
}
