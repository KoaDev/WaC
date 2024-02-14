$DefaultDscResourceModuleName = 'PSDscResources'

$DscResourcesIdProperties = @{
    MyCertificate              = @('Path')
    MyChocolatey               = @()
    MyChocolateyPackage        = @('PackageName')
    MyHosts                    = @('Name', 'Path')
    MyNodeVersion              = @('Version')
    MyScoop                    = @()
    MyScoopPackage             = @('PackageName')
    MyWindowsDefenderExclusion = @('Type', 'Value')
    Registry                   = @('ValueName', 'Key')
    VSComponents               = @('productId', 'channelId')
    WindowsOptionalFeature     = @('Name')
    WinGetPackage              = @('Id')
}

$DscResourcesDefaultProperties = @{
    MyChocolateyPackage = @{
        State = 'Current'
    }
    MyNodeVersion       = @{
        State = 'Current'
    }
    MyScoopPackage      = @{
        State = 'Current'
    }
    WinGetPackage       = @{
        UseLatest         = $true
        IsUpdateAvailable = $false
    }
}

$DscResourcesWithoutEnsure = @(
    'VSComponents'
)

$DscResourcesIsPresentAction = @{
    VSComponents = {
        param([hashtable]$Resource)
        $Resource.installedComponents -is [array] -and $Resource.installedComponents.Count -gt 0
    }
}
