# Import the necessary module
Import-Module PSDesiredStateConfiguration

# Define default module name
$defaultModuleName = 'PSDesiredStateConfiguration'

# Define resources in a hashtable
$resources = @(
    # Registry Resources
    @{
        Name     = 'Registry';
        Property = @{
            Key       = 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced';
            ValueName = 'HideFileExt';
            ValueData = '0';
            ValueType = 'DWord';
        }
    },
    @{
        Name     = 'Registry';
        Property = @{
            Key       = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa';
            ValueName = 'DisableLoopbackCheck';
            ValueData = '1';
            ValueType = 'DWord';
        }
    }

    # Windows Features
) + (@(
        'IIS-ApplicationDevelopment',
        'IIS-ASPNET',
        'IIS-ASPNET45',
        'IIS-BasicAuthentication',
        'IIS-CertProvider',
        'IIS-CommonHttpFeatures',
        'IIS-DefaultDocument',
        'IIS-DirectoryBrowsing',
        'IIS-HealthAndDiagnostics',
        'IIS-HostableWebCore',
        'IIS-HttpCompressionDynamic',
        'IIS-HttpCompressionStatic',
        'IIS-HttpErrors',
        'IIS-HttpLogging',
        'IIS-ISAPIExtensions',
        'IIS-ISAPIFilter',
        'IIS-ManagementConsole',
        'IIS-ManagementScriptingTools',
        'IIS-NetFxExtensibility',
        'IIS-NetFxExtensibility45',
        'IIS-Performance',
        'IIS-RequestFiltering',
        'IIS-Security',
        'IIS-StaticContent',
        'IIS-WebServer',
        'IIS-WebServerManagementTools',
        'IIS-WebServerRole',
        'IIS-WebSockets',
        'IIS-WindowsAuthentication',
        'NetFx3',
        'NetFx4-AdvSrvs',
        'NetFx4Extended-ASPNET45',
        'WCF-HTTP-Activation',
        'WCF-HTTP-Activation45',
        'WCF-NonHTTP-Activation',
        'WCF-Services45'
    ) | ForEach-Object {
        @{
            Name       = 'MyWindowsFeature'
            ModuleName = 'MyResources'
            Property   = @{
                Name = $_
            }
        }
    })

function Set-DscResourceState {
    [CmdletBinding()]
    param ([hashtable]$resource)

    # Clone the hashtable to prevent modifying the original
    $dscResource = $resource.Clone()
    $dscResource.ModuleName = $dscResource.ModuleName ?? $defaultModuleName
    
    $dscResource.Property.Ensure = 'Present'

    $result = Invoke-DscResource @dscResource -Method Set
    return $result
}

function Get-DscResourceState {
    [CmdletBinding()]
    param ([hashtable]$resource)

    # Clone the hashtable to prevent modifying the original
    $dscResource = $resource.Clone()
    $dscResource.ModuleName = $dscResource.ModuleName ?? $defaultModuleName
    $dscProperties = $dscResource.Property
    
    $currentValue = Invoke-DscResource @dscResource -Method Get

    switch ($resource.Name) {
        'Registry' {
            return "$($dscProperties.ValueName) current value: $($currentValue.ValueData)."
        }
        'MyWindowsFeature' {
            return "Feature $($dscProperties.Name) is currently $($currentValue.Ensure)."
        }
    }
}

function Get-DscResourceDifference {
    [CmdletBinding()]
    param ([hashtable]$resource)

    # Clone the hashtable to prevent modifying the original
    $dscResource = $resource.Clone()
    $dscResource.ModuleName = $dscResource.ModuleName ?? $defaultModuleName
    $dscProperties = $dscResource.Property
    
    $currentValue = Invoke-DscResource @dscResource -Method Get

    switch ($resource.Name) {
        'Registry' {
            if ($currentValue.ValueData -ne $dscProperties.ValueData) {
                return "$($dscProperties.ValueName) current value: $($currentValue.ValueData) - Desired value: $($dscProperties.ValueData)."
            }
            else {
                return "$($dscProperties.ValueName) is in desired state."
            }
        }
        'MyWindowsFeature' {
            if ($currentValue.Ensure -ne ($resource.Ensure ?? 'Present')) {
                return "Feature $($dscProperties.Name) is currently $($currentValue.Ensure) but desired state is $($resource.Ensure)."
            }
            else {
                return "Feature $($dscProperties.Name) is in desired state."
            }
        }
    }
}

function Set-DscConfigurationState {
    foreach ($resource in $resources) {
        $result = Set-DscResourceState -resource $resource
        Write-Output $result
    }
}

function Get-DscConfigurationState {
    foreach ($resource in $resources) {
        $result = Get-DscResourceState -resource $resource
        Write-Output $result
    }
}

function Get-DscConfigurationDifference {
    foreach ($resource in $resources) {
        $result = Get-DscResourceDifference -resource $resource
        Write-Output $result
    }
}
