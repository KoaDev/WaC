$DefaultDscResourceModuleName = 'PSDscResources'

$DscResourcesIdProperties = @{
    MyCertificate              = @('Path')
    MyChocolatey               = @('ResourceName')
    MyChocolateyPackage        = @('PackageName')
    MyHosts                    = @('Name', 'Path')
    MyNodeVersion              = @('Version')
    MyScoop                    = @('ResourceName')
    MyScoopPackage             = @('PackageName')
    MyWindowsDefenderExclusion = @('Type', 'Value')
    Registry                   = @('ValueName', 'Key')
    VSComponents               = @('productId', 'channelId')
    WindowsOptionalFeature     = @('Name')
    WinGetPackage              = @('Id')
}

$DscResourcesDefaultProperties = @{
    MyChocolatey        = @{
        ResourceName = 'ChocolateyInstallation'
    }
    MyChocolateyPackage = @{
        State = 'UpToDate'
    }
    MyNodeVersion       = @{
        State = 'Current'
    }
    MyScoop             = @{
        ResourceName = 'ScoopInstallation'
    }
    MyScoopPackage      = @{
        State = 'UpToDate'
    }
    WinGetPackage       = @{
        UseLatest         = $true
        IsUpdateAvailable = $false
    }
}

$DscResourcesIsPresentAction = @{
    VSComponents = {
        param([hashtable]$Resource)
        $Resource.installedComponents -is [array] -and $Resource.installedComponents.Count -gt 0
    }
}

$DscResourcesExpectedActualCleanupAction = @{
    VSComponents = {
        param([hashtable]$Expected, [hashtable]$Actual)
        $Expected.Remove('Ensure')
    }
}
