Import-Module PSDesiredStateConfiguration
Import-Module Hashtable-Helpers

$defaultModuleName = 'PSDscResources'

# Create an empty hashtable
$resourceIdProperties = @{}

# Adding each resource and its identifying keys
$resourceIdProperties['Registry'] = @('ValueName', 'Key')
$resourceIdProperties['WindowsOptionalFeature'] = @('Name')
$resourceIdProperties['MyScoop'] = @('ResourceName')
$resourceIdProperties['MyScoopPackage'] = @('PackageName')
$resourceIdProperties['MyChocolatey'] = @('ResourceName')
$resourceIdProperties['MyChocolateyPackage'] = @('PackageName')
$resourceIdProperties['WinGetPackage'] = @('Id')
$resourceIdProperties['VSComponents'] = @('productId', 'channelId')
$resourceIdProperties['MyCertificate'] = @('Path')
$resourceIdProperties['MyWindowsDefenderExclusion'] = @('Type', 'Value')
$resourceIdProperties['MyNodeVersion'] = @('Version')
$resourceIdProperties['MyHosts'] = @('Name', 'Path')

function Get-DscResourceState
{
    [CmdletBinding()]
    param ([hashtable]$resource)

    Write-Verbose "Getting DSC Resource State for $($resource | ConvertTo-Json -Depth 100)"

    # Clone the hashtable to prevent modifying the original
    $dscResource = $resource.Clone()
    $dscResource.ModuleName = $dscResource.ModuleName ?? $defaultModuleName
    if (-not $dscResource.Property)
    {
        $dscResource.Property = @{}
    }
    # $dscProperties = $dscResource.Property
    
    $currentValue = Invoke-DscResource @dscResource -Method Get -Verbose:($VerbosePreference -eq 'Continue') | ConvertTo-Hashtable

    $idProperties = $resourceIdProperties[$dscResource.Name]
    $identifier, $state = Split-Hashtable -OriginalHashtable $currentValue -KeysArray $idProperties

    return @{
        Type       = $resource.Name
        Identifier = $identifier
        State      = $state
    }
    
    # switch ($resource.Name)
    # {
    #     'Registry'
    #     {
    #         return "$($resource.Name) $($dscProperties.ValueName) current value: $($currentValue.ValueData)."
    #     }
    #     'VSComponents'
    #     {
    #         return "$($resource.Name) current value: $($currentValue | ConvertTo-Json)."
    #     }
    #     'WindowsOptionalFeature'
    #     {
    #         return "$($resource.Name) $($dscProperties.Name) is currently $($currentValue.Ensure)."
    #     }
    #     'WingetPackage'
    #     {
    #         return "$($resource.Name) $($dscProperties.Id) is currently $($currentValue.IsInstalled ? 'Present' : 'Absent') - current version: $($currentValue.InstalledVersion)."
    #     }
    #     'MyCertificate'
    #     {
    #         return "$($resource.Name) $($dscProperties.Path) is currently $($currentValue.Ensure)."
    #     }
    #     { $_ -in 'MyChocolateyPackage', 'MyScoopPackage' }
    #     {
    #         return "$($resource.Name) $($dscProperties.PackageName) is currently $($currentValue.Ensure) - current version: $($currentValue.Version)."
    #     }
    #     'MyHosts'
    #     {
    #         return "$($resource.Name) $($dscProperties.Name) is currently $($currentValue.Ensure)."
    #     }
    #     'MyNodeVersion'
    #     {
    #         return "$($resource.Name) $($dscProperties.Version) is currently $($currentValue.Ensure) - current version: $($currentValue.Version)$($currentValue.Use ? ' used' : '')."
    #     }
    #     'MyWindowsDefenderExclusion'
    #     {
    #         return "$($resource.Name) $($dscProperties.Type + ' - ' + $dscProperties.Value) is currently $($currentValue.Ensure)."
    #     }
    #     'MyWindowsFeature'
    #     {
    #         return "$($resource.Name) $($dscProperties.Name) is currently $($currentValue.Ensure)."
    #     }
    #     'MyWindowsOptionalFeatures'
    #     {
    #         return "$($resource.Name) $($dscProperties.Name) is currently $($currentValue.States | ConvertTo-Json)."
    #     }
    # }
}
