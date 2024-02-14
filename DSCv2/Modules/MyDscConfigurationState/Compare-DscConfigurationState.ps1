. $PSScriptRoot\Yaml.ps1
. $PSScriptRoot\ConvertTo-Result.ps1

function Compare-DscConfigurationState
{
    [CmdletBinding(DefaultParameterSetName = 'YamlFilePath')]
    param (
        [Parameter(ParameterSetName = 'YamlFilePath', Mandatory = $true)]
        [string]$YamlFilePath,

        [Parameter(ParameterSetName = 'ResourceCollection', Mandatory = $true)]
        [hashtable[]]$Resources,
        
        [switch]$WithCompliant,
        
        [switch]$Report,

        [switch]$JsonDiff
    )

    $resources = Get-ResourcesFromYamlFilePathOrResourceCollection -YamlFilePath $YamlFilePath -Resources $Resources

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    $result = [ordered]@{
        Compliant    = @()
        NonCompliant = @()
        Missing      = @()
        Unexpected   = @()
        Error        = @()
    }

    $totalResources = $resources.Count

    foreach ($index in 0..($totalResources - 1))
    {
        $resource = $resources[$index]
        
        $progressPercent = ($index / $totalResources) * 100
        $progressMessage = "Processing resource $index of $totalResources ($([Math]::Floor($progressPercent))%)"
        Write-Progress -Activity 'Processing DSC Resources' -Status $progressMessage -PercentComplete $progressPercent
    
        $comparison = Compare-DscResourceState $resource -Verbose:($VerbosePreference -eq 'Continue')

        if (-not $Report)
        {
            if ($comparison.Status -eq 'Compliant' -and -not $WithCompliant)
            {
                continue
            }
            
            $comparison = [PSCustomObject]@{
                Type       = $comparison.Type
                Identifier = ConvertTo-StringIdentifier $comparison.Identifier
                Status     = $comparison.Status
                Diff       = $JsonDiff ? (ConvertTo-JsonDiff $comparison.Diff) : $comparison.Diff
                Error      = $comparison.ErrorMessage
            }

            Write-Output $comparison
        }
        else
        {
            $result[$comparison.Status] += $comparison
        }
    }

    Write-Progress -Activity 'Processing DSC Resources' -Completed

    $stopwatch.Stop()

    if ($Report)
    {
        Write-Output "$($resources.Count) resources were compared in $($stopwatch.Elapsed.TotalSeconds) seconds."

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
            if (-not $WithCompliant -and $status -eq 'Compliant')
            {
                continue
            }

            if ($result[$status].Count -eq 0)
            {
                continue
            }

            Write-Output "-> $status resources:"
            Write-Output $result[$status] | ForEach-Object {
                [PSCustomObject]@{
                    Type       = $_.Type
                    Identifier = ConvertTo-StringIdentifier $_.Identifier
                    Diff       = $JsonDiff ? (ConvertTo-JsonDiff $_.Diff) : $_.Diff
                    Error      = $_.ErrorMessage
                }
            } | Format-Table -Wrap -AutoSize
        }
    }
}
