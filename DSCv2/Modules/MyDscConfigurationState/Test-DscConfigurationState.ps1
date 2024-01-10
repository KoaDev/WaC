Import-Module MyDscResourceState

. $PSScriptRoot\Get-DscResourcesFromYaml.ps1
. $PSScriptRoot\Cache.ps1

function Test-DscConfigurationState
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

    Test-DscConfigurationStateFromResources -Resources $resources -Force:$Force
}

function Test-DscConfigurationStateFromResources
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
        $cacheKey = Get-DscResourceHash -Resource $resource
        $resourceInDesiredState = Get-CacheEntry -CacheName 'InDesiredState' -Key $cacheKey -CacheDuration ([timespan]::FromMinutes(5)) `
            -ResourceAction { Test-DscResourceState -resource $resource } `
            -Force:$Force

        Write-Output $resourceInDesiredState
    }
}
