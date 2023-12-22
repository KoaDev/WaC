#Requires -RunAsAdministrator

. .\Get-DscResourcesFromYaml.ps1
. .\Get-ShortenedPath.ps1

if (-not (Get-Module -ListAvailable -Name PSDesiredStateConfiguration))
{
    Write-Error 'The PSDesiredStateConfiguration module is not installed.'
    return $null
}

Import-Module PSDesiredStateConfiguration
Import-Module MyDscResourceState

$defaultModuleName = 'PSDscResources'

function Compare-DscResource
{
    [CmdletBinding()]
    param (
        [hashtable]$resource,
        [switch]$DifferentOnly
    )

    Write-Verbose "Comparing DSC Resource State for $($resource | ConvertTo-Json -Depth 100)"

    # Clone the hashtable to prevent modifying the original
    $dscResource = $resource.Clone()
    $dscResource.ModuleName = $dscResource.ModuleName ?? $defaultModuleName
    if (-not $dscResource.Property)
    {
        $dscResource.Property = @{}
    }
    $dscProperties = $dscResource.Property
    
    # try {
    #     Import-Module -Name $dscResource.ModuleName
    #     $resourceInstance = New-Object -TypeName $dscResource.Name
    #     $dscResource.Property.GetEnumerator() | ForEach-Object {
    #         $resourceInstance.$($_.Key) = $_.Value
    #     }

    #     return "N/A"
    # }
    # catch {
    $currentValue = Invoke-DscResource @dscResource -Method Get -Verbose:($VerbosePreference -eq 'Continue')
    # }

    $dscProperties.Ensure = $dscProperties.Ensure ?? 'Present'

    switch ($resource.Name)
    {
        'Registry'
        {
            if ($currentValue.ValueData -ne $dscProperties.ValueData)
            {
                return "$($resource.Name) $($dscProperties.ValueName) current value: $($currentValue.ValueData) - Desired value: $($dscProperties.ValueData)."
            }
            elseif (-not $DifferentOnly)
            {
                return "$($resource.Name) $($dscProperties.ValueName) is in desired state."
            }
        }
        { $_ -in 'MyChocolateyPackage', 'MyScoopPackage' }
        {
            if ($currentValue.Ensure -ne $dscProperties.Ensure)
            {
                return "$($resource.Name) $($dscProperties.PackageName) is currently $($currentValue.Ensure) but desired state is $($dscProperties.Ensure)."
            }
            elseif ($currentValue.Version -ne $dscProperties.Version -and $currentValue.State -eq 'Stale')
            {
                return "$($resource.Name) $($dscProperties.PackageName) current version: $($currentValue.Version) - Desired value: $($currentValue.LatestVersion)."
            }
            elseif (-not $DifferentOnly)
            {
                return "$($resource.Name) $($dscProperties.PackageName) is in desired state."
            }
        }
        'MyHosts'
        {
            if ($currentValue.Ensure -ne $dscProperties.Ensure)
            {
                return "$($resource.Name) $($dscProperties.Name) is currently $($currentValue.Ensure) but desired state is $($dscProperties.Ensure)."
            }
            elseif (-not $DifferentOnly)
            {
                return "$($resource.Name) $($dscProperties.Name) is in desired state."
            }
        }
        'MyNodeVersion'
        {
            if (($currentValue.Ensure -eq 'Absent' -xor $dscProperties.Ensure -eq 'Absent') -or ($currentValue.Ensure -eq 'Present' -and $dscProperties.Ensure -eq 'Used'))
            {
                return "$($resource.Name) $($dscProperties.Version) is currently $($currentValue.Ensure) but desired state is $($dscProperties.Ensure)."
            }
            elseif ($currentValue.Version -ne $dscProperties.Version -and $currentValue.State -eq 'Stale')
            {
                return "$($resource.Name) $($dscProperties.Version) current version: $($currentValue.Version) - Desired value: $($currentValue.LatestVersion)."
            }
            elseif (-not $DifferentOnly)
            {
                return "$($resource.Name) $($dscProperties.Version) is in desired state."
            }
        }
        'MyWindowsFeature'
        {
            if ($currentValue.Ensure -ne $dscProperties.Ensure)
            {
                return "$($resource.Name) $($dscProperties.Name) is currently $($currentValue.Ensure) but desired state is $($dscProperties.Ensure)."
            }
            elseif (-not $DifferentOnly)
            {
                return "$($resource.Name) $($dscProperties.Name) is in desired state."
            }
        }
        default
        {
            if (-not $DifferentOnly)
            {
                return "*** $($resource.Name) *** is not handled."
            }
        }
    }
}

function Set-DscConfiguration
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$YamlFilePath
    )

    Write-Verbose 'Setting DSC Configuration'

    $resources = Get-DscResourcesFromYaml -YamlFilePath $YamlFilePath

    foreach ($resource in $resources)
    {
        $result = Set-DscResourceState -resource $resource
        Write-Output $result
    }
}

function Get-DscConfiguration
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

function Test-DscConfiguration
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$YamlFilePath
    )

    Write-Verbose 'Testing DSC Configuration'

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

    foreach ($resource in $resources)
    {
        $result = Test-DscResourceState -resource $resource
        $color = if ($result[2])
        {
            'green' 
        }
        else
        {
            'red' 
        }

        Write-Host '|' -NoNewline
        Write-Host "$($result[0].ToString().PadRight($colWidths['Resource Type']))" -NoNewline
        Write-Host '|' -NoNewline
        Write-Host "$($result[1].ToString().PadRight($colWidths['Resource Name']))" -NoNewline
        Write-Host '|' -NoNewline
        Write-Host "$($result[2].ToString().PadRight($colWidths['Is in desired state']))" -ForegroundColor $color -NoNewline
        Write-Host '|'
    }

    # Output the footer
    Write-Output $header
}

function Compare-DscConfiguration
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$YamlFilePath,
        [switch]$DifferentOnly
    )

    Write-Verbose 'Comparing DSC Configuration'

    $resources = Get-DscResourcesFromYaml -YamlFilePath $YamlFilePath

    foreach ($resource in $resources)
    {
        $result = Compare-DscResource -resource $resource -DifferentOnly:$DifferentOnly
        Write-Output $result
    }
}
