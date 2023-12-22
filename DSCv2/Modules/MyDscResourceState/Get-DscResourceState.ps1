Import-Module PSDesiredStateConfiguration

$defaultModuleName = 'PSDscResources'

function Split-Hashtable
{
    param (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]$OriginalHashtable,

        [Parameter(Mandatory = $true)]
        [string[]]$KeysArray
    )

    # Create two new empty hashtables
    $includedKeysHashtable = @{}
    $excludedKeysHashtable = @{}

    # Iterate through the original hashtable
    foreach ($key in $OriginalHashtable.Keys)
    {
        if ($KeysArray -contains $key)
        {
            # If the key is in the KeysArray, add it to the includedKeysHashtable
            $includedKeysHashtable[$key] = $OriginalHashtable[$key]
        }
        else
        {
            # If the key is not in the KeysArray, add it to the excludedKeysHashtable
            $excludedKeysHashtable[$key] = $OriginalHashtable[$key]
        }
    }

    # Return the two hashtables
    return @($includedKeysHashtable, $excludedKeysHashtable)
}

function ConvertTo-Hashtable
{
    param (
        [Parameter(ValueFromPipeline = $true)]
        $object
    )

    process
    {
        # If the object is already a hashtable, return it directly
        if ($object -is [hashtable])
        {
            return $object
        }

        # If the object is null, return an empty hashtable
        if ($null -eq $object)
        {
            return @{}
        }

        # If the object is not an object, throw an exception
        if ($object -isnot [object])
        {
            throw 'The input must be an object.'
        }

        # If the object is a regular object, convert it to a hashtable
        $hashtable = @{}
        foreach ($property in $object.PSObject.Properties)
        {
            $hashtable[$property.Name] = $property.Value
        }

        return $hashtable
    }
}

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

    $idProperties = $resourceIdProperties[$resource.Name]
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
