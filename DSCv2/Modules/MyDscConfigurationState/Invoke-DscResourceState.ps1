. $PSScriptRoot\Yaml.ps1
. $PSScriptRoot\Cache.ps1
. $PSScriptRoot\ConvertTo-Result.ps1

function Invoke-DscResourceStateBatch
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Get', 'Test')]
        [string]$Method,    

        [Parameter(Mandatory = $true)]
        [hashtable[]]$Resources,
        
        [switch]$WithInDesiredState,
        
        [switch]$Force
    )

    $totalResources = $resources.Count

    foreach ($index in 0..($totalResources - 1))
    {
        $resource = $resources[$index]
        
        $progressPercent = ($index / $totalResources) * 100
        $progressMessage = "Processing resource $index of $totalResources ($([Math]::Floor($progressPercent))%)"
        Write-Progress -Activity 'Processing DSC Resources' -Status $progressMessage -PercentComplete $progressPercent
    
        Invoke-DscResourceState -Method $Method -Resource $resource -Force:$Force -WithInDesiredState:$WithInDesiredState
    }
    
    Write-Progress -Activity 'Processing DSC Resources' -Completed
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

        [switch]$WithInDesiredState,
        
        [switch]$Force
    )

    $cacheKey = Get-DscResourceHash -Resource $resource
    $verboseArg = $VerbosePreference -eq 'Continue' ? '-Verbose' : ''
    $action = { Invoke-Expression "$Method-DscResourceState -Resource `$resource $verboseArg" }
    $result = Get-CacheEntry -CacheName $Method -Key $cacheKey -CacheDuration ([timespan]::FromMinutes(5)) `
        -ResourceAction $action `
        -Force:$Force

    switch ($Method)
    {
        'Get'
        {
            Write-Output ([PSCustomObject]@{
                    Type       = $result.Type
                    Identifier = ConvertTo-StringIdentifier $result.Identifier
                    State      = $result.State
                })
        }
        'Test'
        {
            if ($WithInDesiredState -or -not $result.InDesiredState)
            {
                Write-Output ([PSCustomObject]@{
                        Type           = $result.Type
                        Identifier     = ConvertTo-StringIdentifier $result.Identifier
                        InDesiredState = $result.InDesiredState
                    })
            }
        }
    }
}
