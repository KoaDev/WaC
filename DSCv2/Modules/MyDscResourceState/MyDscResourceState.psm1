Import-Module PSDesiredStateConfiguration

Get-ChildItem -Path "$PSScriptRoot\*.ps1" -Exclude '*.Tests.ps1' | ForEach-Object { . $_.FullName }

$defaultModuleName = 'PSDscResources'

# Define a dictionary with string keys and script block values
$propertyNameSelector = @{
    'Registry'                   = 'ValueName'
    'VSComponents'               = { 'Visual Studio' }
    'WindowsOptionalFeature'     = 'Name'
    'WingetPackage'              = 'Id'
    'MyCertificate'              = { param($dscProperties) Get-ShortenedPath -Path $dscProperties.Path -MaxLength 45 }
    'MyChocolatey'               = { 'Chocolatey' }
    'MyChocolateyPackage'        = 'PackageName'
    'MyHosts'                    = 'Name'
    'MyNodeVersion'              = 'Version'
    'MyScoop'                    = { 'Scoop' }
    'MyScoopPackage'             = 'PackageName'
    'MyWindowsDefenderExclusion' = { param($dscProperties) $dscProperties.Type + ' - ' + $dscProperties.Value }
    'MyWindowsFeature'           = 'Name'
    'MyWindowsOptionalFeatures'  = { param($dscProperties) $dscProperties.FeatureNames -join ',' }
}

function Get-DscResourcePropertyName
{
    [CmdletBinding()]
    param ([hashtable]$resource)    

    if ($propertyNameSelector.ContainsKey($resource.Name))
    {
        $selector = $propertyNameSelector[$resource.Name]
        if ($selector -is [scriptblock])
        {
            return & $selector $resource.Property
        }
        elseif ($selector -is [string])
        {
            return $resource.Property.$selector
        }
    }

    throw "No suitable property found for resource $($resource.Name)."
}

function Set-DscResourceState
{
    [CmdletBinding()]
    param ([hashtable]$resource)

    Write-Verbose "Setting DSC Resource State for $($resource | ConvertTo-Json -Depth 100)"

    # Clone the hashtable to prevent modifying the original
    $dscResource = $resource.Clone()
    $dscResource.ModuleName = $dscResource.ModuleName ?? $defaultModuleName
    
    $dscResource.Property.Ensure = $dscResource.Property.Ensure ?? 'Present'

    $result = Invoke-DscResource @dscResource -Method Set -Verbose:($VerbosePreference -eq 'Continue')
    return $result
}

function Test-DscResourceState
{
    [CmdletBinding()]
    param ([hashtable]$resource)

    Write-Verbose "Testing DSC Resource State for $($resource | ConvertTo-Json -Depth 100)"

    $dscResource = $resource.Clone()
    $dscResource.ModuleName = $dscResource.ModuleName ?? $defaultModuleName
    if (-not $dscResource.Property)
    {
        $dscResource.Property = @{}
    }
    $dscProperties = $dscResource.Property
    
    $isCurrent = Invoke-DscResource @dscResource -Method Test -Verbose:($VerbosePreference -eq 'Continue')

    # Return the necessary fields as an array
    return @(
        $resource.Name
        switch ($resource.Name)
        {
            'Registry'
            {
                $dscProperties.ValueName 
            }
            'VSComponents'
            {
                'Visual Studio'
            }
            'WindowsOptionalFeature'
            {
                $dscProperties.Name 
            }
            'WingetPackage'
            {
                $dscProperties.Id 
            }
            'MyCertificate'
            {
                Get-ShortenedPath -Path $dscProperties.Path -MaxLength 45 
            }
            'MyChocolatey'
            {
                'Chocolatey' 
            }
            'MyChocolateyPackage'
            {
                $dscProperties.PackageName 
            }
            'MyHosts'
            {
                $dscProperties.Name
            }
            'MyNodeVersion'
            {
                $dscProperties.Version 
            }
            'MyScoop'
            {
                'Scoop' 
            }
            'MyScoopPackage'
            {
                $dscProperties.PackageName 
            }
            'MyWindowsDefenderExclusion'
            {
                $dscProperties.Type + ' - ' + $dscProperties.Value 
            }
            'MyWindowsFeature'
            {
                $dscProperties.Name 
            }
            'MyWindowsOptionalFeatures'
            {
                $dscProperties.FeatureNames -join ',' 
            }
            default
            {
                'Not handled' 
            }
        }
        $isCurrent.InDesiredState
    )
}

Export-ModuleMember -Function Set-DscResourceState, Get-DscResourceState, Test-DscResourceState
