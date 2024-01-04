. $PSScriptRoot\Get-DscResourcesFromYaml.ps1

function Get-DscConfigurationState
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$YamlFilePath
    )

    Write-Verbose 'Getting DSC Configuration'

    $resources = Get-DscResourcesFromYaml -YamlFilePath $YamlFilePath

    foreach ($resource in $resources)
    {
        $result = Get-DscResourceState -resource $resource
        Write-Output $result
    }
}
