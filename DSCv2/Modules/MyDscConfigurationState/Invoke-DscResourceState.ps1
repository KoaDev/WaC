Import-Module MyDscResourceState

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
        
        [switch]$Force
    )

    $totalResources = $resources.Count

    foreach ($index in 0..($totalResources - 1))
    {
        $resource = $resources[$index]
        
        $progressPercent = ($index / $totalResources) * 100
        $progressMessage = "Processing resource $index of $totalResources ($([Math]::Floor($progressPercent))%)"
        Write-Progress -Activity 'Processing DSC Resources' -Status $progressMessage -PercentComplete $progressPercent
    
        Invoke-DscResourceState -Method $Method -Resource $resource -Force:$Force
    }
    
    # Ensure to complete the progress bar when the loop is done
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
        
        [switch]$Force
    )

    $cacheKey = Get-DscResourceHash -Resource $resource
    $action = { Invoke-Expression "$Method-DscResourceState -resource `$resource" }
    $result = Get-CacheEntry -CacheName $Method -Key $cacheKey -CacheDuration ([timespan]::FromMinutes(5)) `
        -ResourceAction $action `
        -Force:$Force

    switch ($Method)
    {
        'Get'
        {
            $result = [PSCustomObject]@{
                Type       = $result.Type
                Identifier = ConvertTo-StringIdentifier $result.Identifier
                State      = $result.State
            }
        }
        'Test'
        {
            $result = [PSCustomObject]@{
                Type           = $result.Type
                Identifier     = ConvertTo-StringIdentifier $result.Identifier
                InDesiredState = $result.InDesiredState
            }
        }
    }

    Write-Output $result
}
