Import-Module PSDscResources

[DscResource()]
class MyWindowsOptionalFeatures {
    [DscProperty(Key)]
    [string] $Name = 'WindowsOptionalFeatureCollection'

    [DscProperty(Mandatory)]
    [string[]] $FeatureNames

    [DscProperty()]
    [string] $Ensure = 'Present'

    [DscProperty(NotConfigurable)]
    [hashtable] $States = @{}

    hidden [MyWindowsOptionalFeatures] $CachedCurrent

    [MyWindowsOptionalFeatures] Get() {
        $current = [MyWindowsOptionalFeatures]::new()
        $current.FeatureNames = $this.FeatureNames
    
        $current.States = @{}
        foreach ($featureName in $this.FeatureNames) {
            try {
                $result = Invoke-DscResource -Name WindowsOptionalFeature -Method Get -Property @{Name = $featureName } -ModuleName PSDscResources
                if ($result.Ensure -eq 'Present') {
                    $current.States[$featureName] = 'Enabled'
                }
                else {
                    $current.States[$featureName] = 'Disabled'
                }
            }
            catch {
                $current.States[$featureName] = 'NotPresent'
            }
        }
    
        return $current
    }

    [bool] Test() {
        $current = $this.Get()
    
        foreach ($featureName in $this.FeatureNames) {
            $currentState = $current.States[$featureName] -eq 'Enabled' ? 'Present' : 'Absent'

            if ($currentState -ne $this.Ensure) {
                return $false
            }
        }
    
        return $true
    }

    [void] Set() {
        if ($this.Test()) {
            return
        }
    
        $current = $this.CachedCurrent
    
        foreach ($featureName in $this.FeatureNames) {
            $desiredState = $this.Ensure
            $currentState = $current.States[$featureName]
    
            if ($currentState -eq 'NotPresent') {
                throw "Windows optional feature '$($featureName)' is not present on this machine"
            }
    
            $windowsOptionalFeature = @{
                Name   = $featureName
                Ensure = $desiredState
            }
    
            DSC\WindowsOptionalFeature @windowsOptionalFeature
        }
    }    
}
