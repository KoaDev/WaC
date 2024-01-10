Import-Module MyDscResourceState

. $PSScriptRoot\Get-DscResourcesFromYaml.ps1
. $PSScriptRoot\Cache.ps1

function Invoke-DscResourceState
{
    [CmdletBinding(DefaultParameterSetName = 'YamlFilePath')]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Get', 'Test')]
        [string]$Method,    

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

    Invoke-DscResourceStateFromResources -Method $Method -Resources $resources -Force:$Force
}

function Invoke-DscResourceStateFromResources
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Get', 'Test')]
        [string]$Method,    

        [Parameter(Mandatory = $true)]
        [hashtable[]]$Resources,
        
        [switch]$Force
    )

    Write-Verbose 'Getting DSC Configuration'

    foreach ($resource in $Resources)
    {
        $cacheKey = Get-DscResourceHash -Resource $resource
        $action = { Invoke-Expression "$Method-DscResourceState -resource `$resource" }
        $result = Get-CacheEntry -CacheName $Method -Key $cacheKey -CacheDuration ([timespan]::FromMinutes(5)) `
            -ResourceAction $action `
            -Force:$Force

        Write-Output $result
    }
}
