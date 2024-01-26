Import-Module MyDscResourceState
Import-Module Hashtable-Helpers

. $PSScriptRoot\Yaml.ps1

function Compare-DscConfigurationState
{
    [CmdletBinding(DefaultParameterSetName = 'YamlFilePath')]
    param (
        [Parameter(ParameterSetName = 'YamlFilePath', Mandatory = $true)]
        [string]$YamlFilePath,

        [Parameter(ParameterSetName = 'ResourceCollection', Mandatory = $true)]
        [hashtable[]]$Resources,
        
        [switch]$WithCompliant,
        
        [switch]$Force,

        [switch]$Report
    )

    $null = $PSBoundParameters.Remove('WithCompliant')
    $null = $PSBoundParameters.Remove('Force')
    $null = $PSBoundParameters.Remove('Report')
    $resources = Get-ResourcesFromYamlFilePathOrResourceCollection @PSBoundParameters

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
        Write-Progress -Activity 'Comparing DSC Resource States' -Status $progressMessage -PercentComplete $progressPercent
    
        $comparison = Compare-DscResourceState $resource
        
        $result[$comparison.Status] += $comparison
        $comparison.remove('Status')
    }
    
    # Ensure to complete the progress bar when the loop is done
    Write-Progress -Activity 'Comparing DSC Resource States' -Completed

    $result = Remove-EmptyArrayProperties $result

    if ($Report)
    {
        # Write-Output $result | ConvertTo-Json -EnumsAsStrings -Depth 100

        Write-Output "$($resources.Count) resources were compared."

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

            Write-Output "$status resources:"
            Write-Output $result[$status] | ForEach-Object {
                [PSCustomObject]@{
                    Type       = $_.Type
                    Identifier = ConvertTo-Json -EnumsAsStrings -Depth 100 $_.Identifier
                    Diff       = ConvertTo-Json -EnumsAsStrings -Depth 100 $_.Diff
                }
            } | Format-Table -Wrap -AutoSize
        }
    }
    else
    {
        Write-Output $result
    }
}
