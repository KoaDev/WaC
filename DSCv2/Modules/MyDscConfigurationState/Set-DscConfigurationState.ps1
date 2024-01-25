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
        [hashtable[]]$Resources
    )

    $resources = Get-ResourcesFromYamlFilePathOrResourceCollection @PSBoundParameters

    $result = @()
    foreach ($resource in $resources)
    {
        $setResult = Set-DscResourceState $resource
        
        $result += $setResult
    }

    return $result
}
