# Set-Variable -Name 'defaultModuleName' -Value 'PSDscResources' -Option Constant

$defaultModuleName = 'PSDscResources'

$resourceIdProperties = @{}
$resourceIdProperties['MyCertificate'] = @('Path')
$resourceIdProperties['MyChocolatey'] = @('ResourceName')
$resourceIdProperties['MyChocolateyPackage'] = @('PackageName')
$resourceIdProperties['MyHosts'] = @('Name', 'Path')
$resourceIdProperties['MyNodeVersion'] = @('Version')
$resourceIdProperties['MyScoop'] = @('ResourceName')
$resourceIdProperties['MyScoopPackage'] = @('PackageName')
$resourceIdProperties['MyWindowsDefenderExclusion'] = @('Type', 'Value')
$resourceIdProperties['Registry'] = @('ValueName', 'Key')
$resourceIdProperties['VSComponents'] = @('productId', 'channelId')
$resourceIdProperties['WindowsOptionalFeature'] = @('Name')
$resourceIdProperties['WinGetPackage'] = @('Id')
