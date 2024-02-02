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

        [switch]$WithInDesiredState,
        
        [switch]$Force
    )

    # TODO: Find a better way to remove these parameters
    $null = $PSBoundParameters.Remove('WithInDesiredState')
    $resources = Get-ResourcesFromYamlFilePathOrResourceCollection @PSBoundParameters

    Invoke-DscResourceStateBatch -Method Test -Resources $resources -Force:$Force -WithInDesiredState:$WithInDesiredState
}
