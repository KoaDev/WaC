. $PSScriptRoot\MyScoopPackage.ps1

enum MyEnsure
{
    Absent
    Present
}

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

    [MyScoopPackage] Get()
    {
        $current = [MyScoopPackage]::new()
        $current.PackageName = $this.PackageName

        $packageInfo = Get-ScoopPackageInfo $this.PackageName

        $current.Ensure = $packageInfo.Ensure
        $current.Version = $packageInfo.Version
    
        $current.LatestVersion = Get-ScoopPackageLatestAvailableVersion $this.PackageName

        if ($current.Version -and $current.LatestVersion)
        {
            if ($current.Version -eq $current.LatestVersion)
            {
                $current.State = 'Current'
            }
            else
            {
                $current.State = 'Stale'
            }
        }

        $this.CachedCurrent = $current

        return $current
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
                $output = & scoop update $target *>&1
                if (-not $?)
                {
                    $outputString = $output | Out-String
                    throw "Failed to update scoop package '$target'.`nDetails: $outputString"
                }
            }
            else
            {
                & scoop install $target
                if (-not $?)
                {
                    throw "Failed to install scoop package '$target'"
                }
            }
        }
        elseif ($this.Ensure -eq [MyEnsure]::Absent)
        {
            if ($current.Ensure -eq [MyEnsure]::Present)
            {
                & scoop uninstall $this.PackageName
                if (-not $?)
                {
                    throw "Failed to uninstall scoop package '$($this.PackageName)'"
                }
            }
        }
        
        # Invalidate the caches
        [MyScoopPackage]::ScoopListCache = $null
        [MyScoopPackage]::ScoopStatusCache = $null
    }
}
