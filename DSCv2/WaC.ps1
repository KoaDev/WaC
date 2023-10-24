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

    $dscResource = $resource.Clone()
    $dscResource.ModuleName = $dscResource.ModuleName ?? $defaultModuleName
    $dscProperties = $dscResource.Property
    
    $isCurrent = Invoke-DscResource @dscResource -Method Test

    # Return the necessary fields as an array
    return @(
        $resource.Name
        switch ($resource.Name) {
            'Registry' { $dscProperties.ValueName }
            'MyWindowsFeature' { $dscProperties.Name }
            'MyScoopPackage' { $dscProperties.PackageName }
            default { $null }
        }
        $isCurrent.InDesiredState
    )
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

    # Define column widths based on the longest expected strings.
    $colWidths = @{
        'Resource Type'       = 20
        'Resource Name'       = 40
        'Is in desired state' = 20
    }

    # Generate the header
    $header = "+$('-' * $colWidths['Resource Type'])+$('-' * $colWidths['Resource Name'])+$('-' * $colWidths['Is in desired state'])+"
    $titleRow = "|$('Resource Type'.PadRight($colWidths['Resource Type']))|$('Resource Name'.PadRight($colWidths['Resource Name']))|$('Is in desired state'.PadRight($colWidths['Is in desired state']))|"

    # Output the header
    Write-Output $header
    Write-Output $titleRow
    Write-Output $header

    foreach ($resource in $resources) {
        $result = Test-DscResourceState -resource $resource
        $color = if ($result[2]) { 'green' } else { 'red' }

        Write-Host "|$($result[0].PadRight($colWidths['Resource Type']))|$($result[1].PadRight($colWidths['Resource Name']))|" -NoNewline
        Write-Host "$($result[2].ToString().PadRight($colWidths['Is in desired state']))" -ForegroundColor $color -NoNewline
        Write-Host "|"
    }

    # Output the footer
    Write-Output $header
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
