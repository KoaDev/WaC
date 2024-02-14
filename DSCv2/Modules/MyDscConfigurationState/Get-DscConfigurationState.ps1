. $PSScriptRoot\Yaml.ps1
. $PSScriptRoot\Invoke-DscResourceState.ps1

function Get-DscConfigurationState
{
    [CmdletBinding(DefaultParameterSetName = 'YamlFilePath')]
    param (
        [Parameter(ParameterSetName = 'YamlFilePath', Mandatory = $true)]
        [string]$YamlFilePath,

        [Parameter(ParameterSetName = 'ResourceCollection', Mandatory = $true)]
        [hashtable[]]$Resources,
        
        [switch]$Force
    )

    $resources = Get-ResourcesFromYamlFilePathOrResourceCollection @PSBoundParameters

    Invoke-DscResourceStateBatch -Method Get -Resources $resources -Force:$Force -Verbose:($VerbosePreference -eq 'Continue')
}
