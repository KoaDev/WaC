Import-Module MyDscResourceState

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
        
        [switch]$Force
    )

    $PSBoundParameters.Remove('WithCompliant')
    $PSBoundParameters.Remove('Force')
    $resources = Get-ResourcesFromYamlFilePathOrResourceCollection @PSBoundParameters

    $result = @{
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

    Write-Output $result
}
