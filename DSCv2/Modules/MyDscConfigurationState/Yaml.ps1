function Get-ResourcesFromYamlFilePathOrResourceCollection
{
    [CmdletBinding()]
    param (
        [string]$YamlFilePath,
        [hashtable[]]$Resources
    )

    if ($YamlFilePath)
    {
        return Get-DscResourcesFromYaml -YamlFilePath $YamlFilePath
    }
    elseif ($Resources)
    {
        return $Resources
    }
    else
    {
        throw 'Either the YamlFilePath or Resources parameter must be specified.'
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
        throw 'The powershell-yaml module is not installed.'
    }

    if (-not (Test-Path $YamlFilePath))
    {
        throw 'The specified YAML file does not exist.'
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
        throw 'The powershell-yaml module is not installed.'
    }

    Import-Module powershell-yaml

    $yamlContent = $DscResources | ConvertTo-Yaml
    Set-Content -Path $YamlFilePath -Value $yamlContent
}
