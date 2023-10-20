#Requires -RunAsAdministrator

. .\Get-DscResourcesFromYaml.ps1

if (-not (Get-Module -ListAvailable -Name PSDesiredStateConfiguration)) {
    Write-Error "The PSDesiredStateConfiguration module is not installed."
    return $null
}

Import-Module PSDesiredStateConfiguration

$defaultModuleName = 'PSDesiredStateConfiguration'

function Set-DscResourceState {
    [CmdletBinding()]
    param ([hashtable]$resource)

    # Clone the hashtable to prevent modifying the original
    $dscResource = $resource.Clone()
    $dscResource.ModuleName = $dscResource.ModuleName ?? $defaultModuleName
    
    $dscResource.Property.Ensure = 'Present'

    $result = Invoke-DscResource @dscResource -Method Set
    return $result
}

function Get-DscResourceState {
    [CmdletBinding()]
    param ([hashtable]$resource)

    # Clone the hashtable to prevent modifying the original
    $dscResource = $resource.Clone()
    $dscResource.ModuleName = $dscResource.ModuleName ?? $defaultModuleName
    $dscProperties = $dscResource.Property
    
    $currentValue = Invoke-DscResource @dscResource -Method Get

    switch ($resource.Name) {
        'Registry' {
            return "$($resource.Name) $($dscProperties.ValueName) current value: $($currentValue.ValueData)."
        }
        'MyWindowsFeature' {
            return "$($resource.Name) $($dscProperties.Name) is currently $($currentValue.Ensure)."
        }
        'MyScoopPackage' {
            return "$($resource.Name) $($dscProperties.PackageName) is currently $($currentValue.Ensure) - current version: $($currentValue.Version)."
        }
    }
}

function Test-DscResourceState {
    [CmdletBinding()]
    param ([hashtable]$resource)

    # Clone the hashtable to prevent modifying the original
    $dscResource = $resource.Clone()
    $dscResource.ModuleName = $dscResource.ModuleName ?? $defaultModuleName
    $dscProperties = $dscResource.Property
    
    $isCurrent = Invoke-DscResource @dscResource -Method Test

    switch ($resource.Name) {
        'Registry' {
            if ($isCurrent.InDesiredState) {
                return "$($resource.Name) $($dscProperties.ValueName) is in desired state."
            }
            else {
                return "$($resource.Name) $($dscProperties.ValueName) is not in desired state."
            }
        }
        'MyWindowsFeature' {
            if ($isCurrent.InDesiredState) {
                return "$($resource.Name) $($dscProperties.Name) is in desired state."
            }
            else {
                return "$($resource.Name) $($dscProperties.Name) is not in desired state."
            }
        }
        'MyScoopPackage' {
            if ($isCurrent.InDesiredState) {
                return "$($resource.Name) $($dscProperties.PackageName) is in desired state."
            }
            else {
                return "$($resource.Name) $($dscProperties.PackageName) is not in desired state."
            }
        }
    }
}

function Compare-DscResource {
    [CmdletBinding()]
    param ([hashtable]$resource)

    # Clone the hashtable to prevent modifying the original
    $dscResource = $resource.Clone()
    $dscResource.ModuleName = $dscResource.ModuleName ?? $defaultModuleName
    $dscProperties = $dscResource.Property
    
    $currentValue = Invoke-DscResource @dscResource -Method Get

    switch ($resource.Name) {
        'Registry' {
            if ($currentValue.ValueData -ne $dscProperties.ValueData) {
                return "$($resource.Name) $($dscProperties.ValueName) current value: $($currentValue.ValueData) - Desired value: $($dscProperties.ValueData)."
            }
            else {
                return "$($resource.Name) $($dscProperties.ValueName) is in desired state."
            }
        }
        'MyWindowsFeature' {
            if ($currentValue.Ensure -ne ($dscProperties.Ensure ?? 'Present')) {
                return "$($resource.Name) $($dscProperties.Name) is currently $($currentValue.Ensure) but desired state is $($dscProperties.Ensure ?? 'Present')."
            }
            else {
                return "$($resource.Name) $($dscProperties.Name) is in desired state."
            }
        }
        'MyScoopPackage' {
            if ($currentValue.Ensure -ne ($dscProperties.Ensure ?? 'Present')) {
                return "$($resource.Name) $($dscProperties.PackageName) is currently $($currentValue.Ensure) but desired state is $($dscProperties.Ensure ?? 'Present')."
            }
            elseif ($currentValue.Version -ne $dscProperties.Version -and $currentValue.State -eq 'Stale') {
                return "$($resource.Name) $($dscProperties.PackageName) current version: $($currentValue.Version) - Desired value: $($currentValue.LatestVersion)."
            }
            else {
                return "$($resource.Name) $($dscProperties.PackageName) is in desired state."
            }
        }
    }
}

function Set-DscConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$YamlFilePath
    )

    $resources = Get-DscResourcesFromYaml -YamlFilePath $YamlFilePath

    foreach ($resource in $resources) {
        $result = Set-DscResourceState -resource $resource
        Write-Output $result
    }
}

function Get-DscConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$YamlFilePath
    )

    $resources = Get-DscResourcesFromYaml -YamlFilePath $YamlFilePath

    foreach ($resource in $resources) {
        $result = Get-DscResourceState -resource $resource
        Write-Output $result
    }
}

function Test-DscConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$YamlFilePath
    )

    $resources = Get-DscResourcesFromYaml -YamlFilePath $YamlFilePath

    foreach ($resource in $resources) {
        $result = Test-DscResourceState -resource $resource
        Write-Output $result
    }
}

function Compare-DscConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$YamlFilePath
    )

    $resources = Get-DscResourcesFromYaml -YamlFilePath $YamlFilePath

    foreach ($resource in $resources) {
        $result = Compare-DscResource -resource $resource
        Write-Output $result
    }
}
