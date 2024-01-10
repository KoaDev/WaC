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

    Invoke-DscResourceState -Method Test @PSBoundParameters
}
