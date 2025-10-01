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

    $resources = Get-ResourcesFromYamlFilePathOrResourceCollection -YamlFilePath $YamlFilePath -Resources $Resources

    Invoke-DscResourceStateBatch -Method Test -Resources $resources -Force:$Force -WithInDesiredState:$WithInDesiredState -Verbose:($VerbosePreference -eq 'Continue')
}
