. $PSScriptRoot\MyScoopPackage.ps1

enum MyEnsure
{
    Absent
    Present
}

# TODO: Same properties as WinGetPackage
# Ensure, IsUpdateAvailable, MatchOption, UseLatest, InstallMode, Source, IsInstalled, InstalledVersion, Version
[DscResource()]
class MyScoopPackage
{
    [DscProperty(Key)]
    [string] $PackageName

    [DscProperty()]
    [string] $Version = 'latest'

    [DscProperty()]
    [MyEnsure] $Ensure = [MyEnsure]::Present

    [DscProperty(NotConfigurable)]
    [string] $LatestVersion

    [DscProperty(NotConfigurable)]
    [string] $State = 'Unknown'

    hidden [MyScoopPackage] $CachedCurrent

    [MyScoopPackage] Get() {
        # Toujours ré-émettre la clé telle que demandée
        $this.PackageName = $this.PackageName

        $packageInfo = Get-ScoopPackageInfo $this.PackageName
        $this.Ensure   = $packageInfo.Ensure
        $this.Version  = $packageInfo.Version

        if ($this.Version) {
            if ($PSBoundParameters.ContainsKey('Version') -and $this.Version -ne 'latest') {
                # Cible une version spécifique
                $this.LatestVersion = 'NotApplicable'
                $this.State         = ($packageInfo.Version -eq $this.Version) ? 'Current' : 'Stale'
            } else {
                # Mode 'latest' (par défaut quand non spécifiée dans le document)
                $lv = Get-ScoopPackageLatestAvailableVersion $this.PackageName
                $this.LatestVersion = $lv ? $lv : $packageInfo.Version
                $this.State         = ($packageInfo.Version -eq $this.LatestVersion) ? 'Current' : 'Stale'
            }
        } else {
            $this.LatestVersion = $null
            $this.State         = 'NotInstalled'
        }

        return $this
    }

    [bool] Test()
    {
        $current = $this.Get()

        if ($this.Ensure -eq [MyEnsure]::Absent)
        {
            return ($current.Ensure -eq $this.Ensure)
        }
        
        if ($current.Ensure -eq [MyEnsure]::Absent)
        {
            return $false
        }

        if ($this.Version -eq 'latest')
        {
            return $current.Version -eq $current.LatestVersion
        }
        else
        {
            return $current.Version -eq $this.Version
        }
    }

    [void] Set()
    {
        if ($this.Test())
        {
            return
        }

        $current = $this.CachedCurrent

        if ($this.Ensure -eq [MyEnsure]::Present)
        {
            $target = $this.PackageName
            if ($this.Version -ne 'latest')
            {
                $target += "@$($this.Version)"
            }

            if ($current.Ensure -eq [MyEnsure]::Present -and $this.Version -eq 'latest')
            {
                Update-ScoopPackage $target
            }
            else
            {
                Install-ScoopPackage $target
            }
        }
        elseif ($this.Ensure -eq [MyEnsure]::Absent)
        {
            if ($current.Ensure -eq [MyEnsure]::Present)
            {
                Uninstall-ScoopPackage $this.PackageName
            }
        }
    }
}
