Import-Module MyDscResourceState

. $PSScriptRoot\Yaml.ps1
. $PSScriptRoot\Cache.ps1

function Invoke-DscResourceStateBatch
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

    foreach ($resource in $Resources)
    {
        Invoke-DscResourceState -Method $Method -Resource $resource -Force:$Force
    }
}

function Invoke-DscResourceState
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Get', 'Test')]
        [string]$Method,    

        [Parameter(Mandatory = $true)]
        [hashtable]$Resource,
        
        [switch]$Force
    )

    $cacheKey = Get-DscResourceHash -Resource $resource
    $action = { Invoke-Expression "$Method-DscResourceState -resource `$resource" }
    $result = Get-CacheEntry -CacheName $Method -Key $cacheKey -CacheDuration ([timespan]::FromMinutes(5)) `
        -ResourceAction $action `
        -Force:$Force

    Write-Output $result
}
