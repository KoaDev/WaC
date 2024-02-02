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

        [switch]$Force,

        [switch]$Report
    )

    $null = $PSBoundParameters.Remove('Force')
    $null = $PSBoundParameters.Remove('Report')
    $resources = Get-ResourcesFromYamlFilePathOrResourceCollection @PSBoundParameters

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    $result = [ordered]@{
        InDesiredState = @()
        Set            = @()
        Error          = @()
    }

    $totalResources = $resources.Count

    foreach ($index in 0..($totalResources - 1))
    {
        $resource = $resources[$index]

        $progressPercent = ($index / $totalResources) * 100
        $progressMessage = "Processing resource $index of $totalResources ($([Math]::Floor($progressPercent))%)"
        Write-Progress -Activity 'Processing DSC Resources' -Status $progressMessage -PercentComplete $progressPercent

        if (-not $Force)
        {
            $cacheKey = Get-DscResourceHash -Resource $resource
            $testedResource = Get-CacheEntryOrNull -CacheName 'Test' -Key $cacheKey

            if ($null -ne $testedResource -and $testedResource.InDesiredState)
            {
                $resourceId = Select-DscResourceIdProperties -Resource $resource
                $result.InDesiredState += [PSCustomObject]@{
                    Type       = $resource.Name
                    Identifier = ConvertTo-StringIdentifier $resourceId
                }
                continue
            }
        }

        try
        {
            $setResult = Set-DscResourceState $resource
        
            $result.Set += [PSCustomObject]@{
                Type       = $setResult.Type
                Identifier = ConvertTo-StringIdentifier $setResult.Identifier
            }
        }
        catch
        {
            $resourceId = Select-DscResourceIdProperties -Resource $resource
            $result.Error += [PSCustomObject]@{
                Type       = $resource.Name
                Identifier = ConvertTo-StringIdentifier $resourceId
                Error      = $_
            }
        }
    }

    Write-Progress -Activity 'Processing DSC Resources' -Completed

    $stopwatch.Stop()

    if ($Report)
    {
        Write-Output "$($resources.Count) resources were set in $($stopwatch.Elapsed.TotalSeconds) seconds."

        $countTable = @()
        foreach ($status in $result.Keys)
        {
            $countTable += [PSCustomObject]@{
                Status = $status
                Count  = $result[$status].Count
            }
        }
        $countTable | Format-Table -Property Status, Count
        
        foreach ($status in $result.Keys)
        {
            if ($result[$status].Count -eq 0)
            {
                continue
            }

            Write-Output "-> $status resources:"
            Write-Output $result[$status] | Format-Table -Wrap -AutoSize
        }
    }
    else
    {
        Write-Output $result
    }
}
