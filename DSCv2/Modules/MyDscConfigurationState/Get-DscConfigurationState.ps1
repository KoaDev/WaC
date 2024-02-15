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
        
        [switch]$Force,

        [switch]$Minimal
    )

    $resources = Get-ResourcesFromYamlFilePathOrResourceCollection -YamlFilePath $YamlFilePath -Resources $Resources

    Invoke-DscResourceStateBatch -Method Get -Resources $resources -Force:$Force -Minimal:$Minimal -Verbose:($VerbosePreference -eq 'Continue')
}
