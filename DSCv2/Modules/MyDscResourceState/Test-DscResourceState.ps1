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

function Test-DscResourceState
{
    [CmdletBinding()]
    param ([hashtable]$resource)

    Write-Verbose "Testing DSC Resource State for $($resource | ConvertTo-Json -Depth 100)"

    # Clone the hashtable to prevent modifying the original
    $dscResource = $resource.Clone()
    $dscResource.ModuleName = $dscResource.ModuleName ?? $defaultModuleName
    if (-not $dscResource.Property)
    {
        $dscResource.Property = @{}
    }
    
    $testResult = Invoke-DscResource @dscResource -Method Test -Verbose:($VerbosePreference -eq 'Continue')

    $idProperties = $resourceIdProperties[$dscResource.Name]
    $identifier = Select-HashtableKeys $dscResource.Property $idProperties

    return @{
        Type           = $resource.Name
        Identifier     = $identifier
        InDesiredState = $testResult.InDesiredState
    }
}
