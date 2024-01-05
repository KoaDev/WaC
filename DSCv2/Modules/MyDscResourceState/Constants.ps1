$DefaultDscResourceModuleName = 'PSDscResources'

$DscResourcesIdProperties = @{}
$DscResourcesIdProperties['MyCertificate'] = @('Path')
$DscResourcesIdProperties['MyChocolatey'] = @('ResourceName')
$DscResourcesIdProperties['MyChocolateyPackage'] = @('PackageName')
$DscResourcesIdProperties['MyHosts'] = @('Name', 'Path')
$DscResourcesIdProperties['MyNodeVersion'] = @('Version')
$DscResourcesIdProperties['MyScoop'] = @('ResourceName')
$DscResourcesIdProperties['MyScoopPackage'] = @('PackageName')
$DscResourcesIdProperties['MyWindowsDefenderExclusion'] = @('Type', 'Value')
$DscResourcesIdProperties['Registry'] = @('ValueName', 'Key')
$DscResourcesIdProperties['VSComponents'] = @('productId', 'channelId')
$DscResourcesIdProperties['WindowsOptionalFeature'] = @('Name')
$DscResourcesIdProperties['WinGetPackage'] = @('Id')
