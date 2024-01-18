function Get-ResourcesFromYamlFilePathOrResourceCollection
{
    [CmdletBinding(DefaultParameterSetName = 'YamlFilePath')]
    param (
        [Parameter(ParameterSetName = 'YamlFilePath', Mandatory = $true)]
        [string]$YamlFilePath,

        [Parameter(ParameterSetName = 'ResourceCollection', Mandatory = $true)]
        [hashtable[]]$Resources
    )

    if ($PSCmdlet.ParameterSetName -eq 'YamlFilePath')
    {
        return Get-DscResourcesFromYaml -YamlFilePath $YamlFilePath
    }
    else
    {
        return $Resources
    }
}

function Get-DscResourcesFromYaml
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$YamlFilePath
    )

    if (-not (Get-Module -ListAvailable -Name powershell-yaml))
    {
        Write-Error 'The powershell-yaml module is not installed.'
        return
    }

    if (-not (Test-Path $YamlFilePath))
    {
        Write-Error 'The specified YAML file does not exist.'
        return
    }

    Import-Module powershell-yaml

    $resourcesFromYaml = Get-Content -Path $YamlFilePath | ConvertFrom-Yaml

    foreach ($resource in $resourcesFromYaml)
    {
        if ($resource.Property -is [System.Collections.IList])
        {
            foreach ($item in $resource.Property)
            {
                $clonedResource = $resource.PSObject.Copy()
                $clonedResource.Property = $item
                Write-Output $clonedResource
            }
        }
        else
        {
            Write-Output $resource
        }
    }
}

function Export-DscResourcesToYaml
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$YamlFilePath,

        [Parameter(Mandatory = $true)]
        [Object[]]$DscResources
    )

    if (-not (Get-Module -ListAvailable -Name powershell-yaml))
    {
        Write-Error 'The powershell-yaml module is not installed.'
        return
    }

    Import-Module powershell-yaml

    $yamlContent = $DscResources | ConvertTo-Yaml
    Set-Content -Path $YamlFilePath -Value $yamlContent
}
