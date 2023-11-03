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
