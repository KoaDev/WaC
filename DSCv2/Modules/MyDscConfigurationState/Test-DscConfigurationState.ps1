Import-Module MyDscResourceState

. $PSScriptRoot\Invoke-DscResourceState.ps1

function Test-DscConfigurationState
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

    Invoke-DscResourceStateBatch -Method Test -Resources $resources -Force:$Force
}
