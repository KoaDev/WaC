Import-Module MyDscResourceState

. $PSScriptRoot\Yaml.ps1
. $PSScriptRoot\Invoke-DscResourceState.ps1

function Compare-DscConfigurationState
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

    $Comparison = @()

    foreach ($resource in $resources)
    {
        $actual = (Invoke-DscResourceState -Method $Method -Resource $resource -Force:$Force).State

        $idProperties = $DscResourcesIdProperties[$resource.Name]    
        $expected = $resource.Property | Select-HashtableKeys -KeysArray $idProperties -InvertSelection

        $diff = Get-Diff $expected $actual

        $Comparison += @{
            Name = $resource.Name
            Id   = $resource.Id
            Diff = $diff
        }
    }

    Write-Output $Comparison
}
