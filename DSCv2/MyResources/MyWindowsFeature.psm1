[DscResource()]
class MyWindowsFeature {
    [DscProperty(Key)]
    [string] $Name

    [DscProperty()]
    [MyEnsure] $Ensure = [MyEnsure]::Present

    [DscProperty(NotConfigurable)]
    [string] $State = 'Unknown'

    hidden [MyWindowsFeature] $CachedCurrentState

    [MyWindowsFeature] Get() {
        $currentState = [MyWindowsFeature]::new()
        $currentState.Name = $this.Name

        $feature = Get-WindowsOptionalFeature -Online | Where-Object { $_.FeatureName -eq $this.Name }

        if ($feature) {
            $currentState.Ensure = [MyEnsure]::Present
            $currentState.State = $feature.State
        }
        else {
            $currentState.Ensure = [MyEnsure]::Absent
            $currentState.State = 'NotPresent'
        }

        $this.CachedCurrentState = $currentState

        return $currentState
    }

    [bool] Test() {
        $currentState = $this.Get()

        if ($this.Ensure -ne $currentState.Ensure) {
            return $false
        }

        return $true
    }

    [void] Set() {
        if ($this.Test()) {
            return
        }

        $currentState = $this.CachedCurrentState

        if ($currentState.State -eq 'NotPresent') {
            throw "Windows feature '$($this.Name)' is not present on this machine"
        }

        if ($this.Ensure -eq [MyEnsure]::Present) {
            Enable-WindowsOptionalFeature -Online -FeatureName $this.Name -NoRestart -All
        }
        elseif ($this.Ensure -eq [MyEnsure]::Absent) {
            Disable-WindowsOptionalFeature -Online -FeatureName $this.Name -NoRestart
        }
    }
}

enum MyEnsure {
    Absent
    Present
}
