#Requires -RunAsAdministrator

. .\Get-DscResourcesFromYaml.ps1
. .\Get-ShortenedPath.ps1

if (-not (Get-Module -ListAvailable -Name PSDesiredStateConfiguration)) {
    Write-Error "The PSDesiredStateConfiguration module is not installed."
    return $null
}

Import-Module PSDesiredStateConfiguration

$defaultModuleName = 'PSDscResources'

function Set-DscResourceState {
    [CmdletBinding()]
    param ([hashtable]$resource)

    Write-Verbose "Setting DSC Resource State for $($resource | ConvertTo-Json)"

    # Clone the hashtable to prevent modifying the original
    $dscResource = $resource.Clone()
    $dscResource.ModuleName = $dscResource.ModuleName ?? $defaultModuleName
    
    $dscResource.Property.Ensure = $dscResource.Property.Ensure ?? 'Present'

    $result = Invoke-DscResource @dscResource -Method Set -Verbose:($VerbosePreference -eq 'Continue')
    return $result
}

function Get-DscResourceState {
    [CmdletBinding()]
    param ([hashtable]$resource)

    Write-Verbose "Getting DSC Resource State for $($resource | ConvertTo-Json)"

    # Clone the hashtable to prevent modifying the original
    $dscResource = $resource.Clone()
    $dscResource.ModuleName = $dscResource.ModuleName ?? $defaultModuleName
    if (-not $dscResource.Property) {
        $dscResource.Property = @{}
    }
    $dscProperties = $dscResource.Property
    
    $currentValue = Invoke-DscResource @dscResource -Method Get -Verbose:($VerbosePreference -eq 'Continue')

    switch ($resource.Name) {
        'Registry' {
            return "$($resource.Name) $($dscProperties.ValueName) current value: $($currentValue.ValueData)."
        }
        'WindowsOptionalFeature' {
            return "$($resource.Name) $($dscProperties.Name) is currently $($currentValue.Ensure)."
        }
        'WingetPackage' {
            return "$($resource.Name) $($dscProperties.Id) is currently $($currentValue.IsInstalled ? 'Present' : 'Absent') - current version: $($currentValue.InstalledVersion)."
        }
        'MyCertificate' {
            return "$($resource.Name) $($dscProperties.Path) is currently $($currentValue.Ensure)."
        }
        { $_ -in 'MyChocolateyPackage', 'MyScoopPackage' } {
            return "$($resource.Name) $($dscProperties.PackageName) is currently $($currentValue.Ensure) - current version: $($currentValue.Version)."
        }
        'MyNodeVersion' {
            return "$($resource.Name) $($dscProperties.Version) is currently $($currentValue.Ensure) - current version: $($currentValue.Version)$($currentValue.Use ? ' used' : '')."
        }
        'MyWindowsDefenderExclusion' {
            return "$($resource.Name) $($dscProperties.Type + ' - ' + $dscProperties.Value) is currently $($currentValue.Ensure)."
        }
        'MyWindowsFeature' {
            return "$($resource.Name) $($dscProperties.Name) is currently $($currentValue.Ensure)."
        }
        'MyWindowsOptionalFeatures' {
            return "$($resource.Name) $($dscProperties.Name) is currently $($currentValue.States | ConvertTo-Json)."
        }
    }
}

function Test-DscResourceState {
    [CmdletBinding()]
    param ([hashtable]$resource)

    Write-Verbose "Testing DSC Resource State for $($resource | ConvertTo-Json)"

    $dscResource = $resource.Clone()
    $dscResource.ModuleName = $dscResource.ModuleName ?? $defaultModuleName
    if (-not $dscResource.Property) {
        $dscResource.Property = @{}
    }
    $dscProperties = $dscResource.Property
    
    $isCurrent = Invoke-DscResource @dscResource -Method Test -Verbose:($VerbosePreference -eq 'Continue')

    # Return the necessary fields as an array
    return @(
        $resource.Name
        switch ($resource.Name) {
            'Registry' { $dscProperties.ValueName }
            'WindowsOptionalFeature' { $dscProperties.Name }
            'WingetPackage' { $dscProperties.Id }
            'MyCertificate' { Get-ShortenedPath -Path $dscProperties.Path -MaxLength 45 }
            'MyChocolatey' { 'Chocolatey' }
            'MyChocolateyPackage' { $dscProperties.PackageName }
            'MyNodeVersion' { $dscProperties.Version }
            'MyScoop' { 'Scoop' }
            'MyScoopPackage' { $dscProperties.PackageName }
            'MyWindowsDefenderExclusion' { $dscProperties.Type + ' - ' + $dscProperties.Value }
            'MyWindowsFeature' { $dscProperties.Name }
            'MyWindowsOptionalFeatures' { $dscProperties.FeatureNames -join ',' }
            default { 'Not handled' }
        }
        $isCurrent.InDesiredState
    )
}

function Compare-DscResource {
    [CmdletBinding()]
    param (
        [hashtable]$resource,
        [switch]$DifferentOnly
    )

    Write-Verbose "Comparing DSC Resource State for $($resource | ConvertTo-Json)"

    # Clone the hashtable to prevent modifying the original
    $dscResource = $resource.Clone()
    $dscResource.ModuleName = $dscResource.ModuleName ?? $defaultModuleName
    if (-not $dscResource.Property) {
        $dscResource.Property = @{}
    }
    $dscProperties = $dscResource.Property
    
    $currentValue = Invoke-DscResource @dscResource -Method Get -Verbose:($VerbosePreference -eq 'Continue')

    $dscProperties.Ensure = $dscProperties.Ensure ?? 'Present'

    switch ($resource.Name) {
        'Registry' {
            if ($currentValue.ValueData -ne $dscProperties.ValueData) {
                return "$($resource.Name) $($dscProperties.ValueName) current value: $($currentValue.ValueData) - Desired value: $($dscProperties.ValueData)."
            }
            elseif (-not $DifferentOnly) {
                return "$($resource.Name) $($dscProperties.ValueName) is in desired state."
            }
        }
        { $_ -in 'MyChocolateyPackage', 'MyScoopPackage' } {
            if ($currentValue.Ensure -ne $dscProperties.Ensure) {
                return "$($resource.Name) $($dscProperties.PackageName) is currently $($currentValue.Ensure) but desired state is $($dscProperties.Ensure)."
            }
            elseif ($currentValue.Version -ne $dscProperties.Version -and $currentValue.State -eq 'Stale') {
                return "$($resource.Name) $($dscProperties.PackageName) current version: $($currentValue.Version) - Desired value: $($currentValue.LatestVersion)."
            }
            elseif (-not $DifferentOnly) {
                return "$($resource.Name) $($dscProperties.PackageName) is in desired state."
            }
        }
        'MyNodeVersion' {
            if (($currentValue.Ensure -eq 'Absent' -xor $dscProperties.Ensure -eq 'Absent') -or ($currentValue.Ensure -eq 'Present' -and $dscProperties.Ensure -eq 'Used')) {
                return "$($resource.Name) $($dscProperties.Version) is currently $($currentValue.Ensure) but desired state is $($dscProperties.Ensure)."
            }
            elseif ($currentValue.Version -ne $dscProperties.Version -and $currentValue.State -eq 'Stale') {
                return "$($resource.Name) $($dscProperties.Version) current version: $($currentValue.Version) - Desired value: $($currentValue.LatestVersion)."
            }
            elseif (-not $DifferentOnly) {
                return "$($resource.Name) $($dscProperties.Version) is in desired state."
            }
        }
        'MyWindowsFeature' {
            if ($currentValue.Ensure -ne $dscProperties.Ensure) {
                return "$($resource.Name) $($dscProperties.Name) is currently $($currentValue.Ensure) but desired state is $($dscProperties.Ensure)."
            }
            elseif (-not $DifferentOnly) {
                return "$($resource.Name) $($dscProperties.Name) is in desired state."
            }
        }
        default {
            if (-not $DifferentOnly) {
                return "*** $($resource.Name) *** is not handled."
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

    Write-Verbose "Setting DSC Configuration"

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

    Write-Verbose "Getting DSC Configuration"

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

    Write-Verbose "Testing DSC Configuration"

    $resources = Get-DscResourcesFromYaml -YamlFilePath $YamlFilePath

    # Define column widths based on the longest expected strings.
    $colWidths = @{
        'Resource Type'       = 30
        'Resource Name'       = 50
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

        Write-Host "|" -NoNewline
        Write-Host "$($result[0].ToString().PadRight($colWidths['Resource Type']))" -NoNewline
        Write-Host "|" -NoNewline
        Write-Host "$($result[1].ToString().PadRight($colWidths['Resource Name']))" -NoNewline
        Write-Host "|" -NoNewline
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
        [string]$YamlFilePath,
        [switch]$DifferentOnly
    )

    Write-Verbose "Comparing DSC Configuration"

    $resources = Get-DscResourcesFromYaml -YamlFilePath $YamlFilePath

    foreach ($resource in $resources) {
        $result = Compare-DscResource -resource $resource -DifferentOnly:$DifferentOnly
        Write-Output $result
    }
}
