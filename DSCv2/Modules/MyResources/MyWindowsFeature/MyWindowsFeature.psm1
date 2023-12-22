# . $PSScriptRoot\Common.psm1
# using module .\Common.ps1
# Import-Module -Name  (Join-Path -Path $PSScriptRoot -ChildPath 'Common.psm1')
enum MyEnsure {
    Absent
    Present
}

[DscResource()]
class MyWindowsFeature {
    [DscProperty(Key)]
    [string] $Name

    [DscProperty()]
    [MyEnsure] $Ensure = [MyEnsure]::Present

    [DscProperty(NotConfigurable)]
    [string] $State = 'Unknown'

    hidden [MyWindowsFeature] $CachedCurrent

    [MyWindowsFeature] Get() {
        $current = [MyWindowsFeature]::new()
        $current.Name = $this.Name

        $feature = Get-WindowsOptionalFeature -Online -FeatureName $this.Name

        if (-not $feature) {
            $current.Ensure = [MyEnsure]::Absent
            $current.State = 'NotPresent'
        }
        else {
            $current.Ensure = ($feature.State -eq 'Enabled') ? [MyEnsure]::Present : [MyEnsure]::Absent
            $current.State = $feature.State
        }

        $this.CachedCurrent = $current

        return $current
    }

    [bool] Test() {
        $current = $this.Get()

        if ($this.Ensure -ne $current.Ensure) {
            return $false
        }

        return $true
    }

    [void] Set() {
        if ($this.Test()) {
            return
        }

        $current = $this.CachedCurrent

        if ($current.State -eq 'NotPresent') {
            throw "Windows optional feature '$($this.Name)' is not present on this machine"
        }

        if ($this.Ensure -eq [MyEnsure]::Present) {
            Enable-WindowsOptionalFeature -Online -FeatureName $this.Name -NoRestart -All
        }
        elseif ($this.Ensure -eq [MyEnsure]::Absent) {
            Disable-WindowsOptionalFeature -Online -FeatureName $this.Name -NoRestart
        }
    }
}
