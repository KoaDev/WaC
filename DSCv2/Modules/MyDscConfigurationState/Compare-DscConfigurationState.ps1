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

    $PSBoundParameters.Remove('WithCompliant')
    $PSBoundParameters.Remove('Force')
    $PSBoundParameters.Remove('Report')
    $resources = Get-ResourcesFromYamlFilePathOrResourceCollection @PSBoundParameters

    $result = [ordered]@{
        Compliant    = @()
        NonCompliant = @()
        Missing      = @()
        Unexpected   = @()
        Error        = @()
    }

    foreach ($resource in $resources)
    {
        $comparison = Compare-DscResourceState $resource
        
        if (-not $WithCompliant -and $comparison.Status -eq 'Compliant')
        {
            continue
        }
        
        $result[$comparison.Status] += $comparison
    }

    $result = Remove-EmptyArrayProperties $result

    if ($Report)
    {
        Write-Output $result | ConvertTo-Json -Depth 100
    }
    else
    {
        Write-Output $result
    }
}
