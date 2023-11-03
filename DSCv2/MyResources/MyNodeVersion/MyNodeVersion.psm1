enum MyEnsure {
    Absent
    Present
    Used
}

[DscResource()]
class MyNodeVersion {
    [DscProperty(Key)]
    [string]$Version

    [DscProperty()]
    [MyEnsure]$Ensure = [MyEnsure]::Present

    [DscProperty(NotConfigurable)]
    [string]$LatestVersion

    [DscProperty(NotConfigurable)]
    [string]$State = 'Unknown'

    hidden [MyNodeVersion] $CachedCurrent

    [MyNodeVersion] Get() {
        if (-not ($this.Version -in @('lts', 'latest') -or $this.Version -match '^\d+$')) {
            throw "Version must be 'lts', 'latest', or an integer representing the major version."
        }
    
        $current = [MyNodeVersion]::new()

        $latestVersions = Get-NodeLatestVersions
    
        if ($this.Version -in 'lts', 'latest') {
            $current.LatestVersion = $latestVersions[$this.Version]
            $majorVersion = $current.LatestVersion -replace '\.\d+\.\d+$', ''
        }
        else {
            $majorVersion = [int]($this.Version -split '\.')[0]
            if ($latestVersions.ContainsKey($majorVersion)) {
                $current.LatestVersion = $latestVersions[$majorVersion]
            }
            else {
                throw "Major version $majorVersion is not available."
            }
        }

        $installedVersions = Get-InstalledVersions
        $versionInstalled = $installedVersions | Where-Object { $_.StartsWith("$majorVersion.") } | Select-Object -First 1
        if ($null -ne $versionInstalled) {
            $current.Version = $versionInstalled

            $currentVersion = Get-CurrentVersion
            $current.Ensure = $currentVersion -eq $current.LatestVersion ? [MyEnsure]::Used : [MyEnsure]::Present
    
            if ($current.Version -and $current.LatestVersion) {
                $current.State = $current.Version -eq $current.LatestVersion ? 'Current' : 'Stale'
            }
        }
        else {
            $current.Ensure = [MyEnsure]::Absent
        }

        $this.CachedCurrent = $current

        return $current
    }

    [bool] Test() {
        $current = $this.Get()

        if ($this.Ensure -eq [MyEnsure]::Absent) {
            return ($current.Ensure -eq $this.Ensure)
        }

        if ($current.Ensure -eq [MyEnsure]::Absent) {
            return $false
        }

        if ($this.Ensure -eq [MyEnsure]::Used -and $current.Ensure -ne $this.Ensure) {
            return $false
        }
        
        return $current.LatestVersion -eq $current.Version
    }

    [void] Set() {
        if ($this.Test()) {
            return
        }
        
        if ($this.Ensure -eq [MyEnsure]::Absent) {
            & nvm uninstall $this.CachedCurrent.Version
            return
        }
        
        if ($this.CachedCurrent.Ensure -eq [MyEnsure]::Absent -or $this.CachedCurrent.Version -ne $this.CachedCurrent.LatestVersion) {
            & nvm install $this.CachedCurrent.LatestVersion
        }
        
        if ($this.CachedCurrent.Ensure -ne $this.Ensure) {
            & nvm use $this.CachedCurrent.LatestVersion
        }

        # Cleanup old unused versions
        $staleVersions = Get-StaleVersions
        $currentVersion = Get-CurrentVersion
        $versionsToRemove = $staleVersions | Where-Object { $_ -ne $currentVersion }
        $versionsToRemove | ForEach-Object {
            & nvm uninstall $_
        }
    }
}

function Get-InstalledVersions {
    $nvmList = & nvm list
    $installedVersions = $nvmList -split "\r?\n" | Where-Object { $_.Trim() -ne '' } | ForEach-Object { if ($_ -match "\d+\.\d+\.\d+") { $matches[0] } }

    return $installedVersions
}

function Get-CurrentVersion {
    return (nvm current) -Replace '^v'
}

function Get-StaleVersions {
    $installedVersions = Get-InstalledVersions
    $latestVersions = @{}
    $staleVersions = @()

    foreach ($version in $installedVersions) {
        $splitVersion = $version -split '\.'
        $majorVersion = [int]$splitVersion[0]
        $minorVersion = [int]$splitVersion[1]
        $patchVersion = [int]$splitVersion[2]

        if ($latestVersions.ContainsKey($majorVersion)) {
            $latestSplitVersion = $latestVersions[$majorVersion] -split '\.'
            $latestMinorVersion = [int]$latestSplitVersion[1]
            $latestPatchVersion = [int]$latestSplitVersion[2]

            if (($minorVersion -gt $latestMinorVersion) -or (($minorVersion -eq $latestMinorVersion) -and ($patchVersion -gt $latestPatchVersion))) {
                # Current version is newer, add the older version to staleVersions and update latestVersions
                $staleVersions += $latestVersions[$majorVersion]
                $latestVersions[$majorVersion] = $version
            }
            else {
                # Current version is older or equal, add it to staleVersions
                $staleVersions += $version
            }
        }
        else {
            # This is the first version of this major version, add it to latestVersions
            $latestVersions[$majorVersion] = $version
        }
    }

    # Output stale versions
    return $staleVersions
}

$script:CacheDurationMinutes = 5
function Get-NodeLatestVersions {
    if (-not $script:nodeLatestVersionsCache -or (Get-Date) -gt $script:LastNodeLatestVersionsRefreshed.AddMinutes($script:CacheDurationMinutes)) {
        # Get the HTML content of the Node.js downloads page
        $url = "https://nodejs.org/en/download/releases/"
        $pageContent = Invoke-WebRequest -Uri $url
    
        # Find all matches for the version numbers
        $regexPattern = '<td data-label="Version">Node.js <!-- -->(.*?)<\/td><td data-label="LTS">(.*?)<\/td>'
        $versionMatches = [regex]::Matches($pageContent, $regexPattern)

        $versionsHashTable = @{}
        $ltsVersion = 0
        $latestVersion = 0
        foreach ($match in $versionMatches) {
            $fullVersion = $match.Groups[1].Value
            $majorVersion = [int]($fullVersion -split '\.')[0]
            $isLTS = $match.Groups[2].Value -ne ''
            if ($isLTS -and $majorVersion -gt $ltsVersion) {
                $ltsVersion = $majorVersion
            }
            if ($majorVersion -gt $latestVersion) {
                $latestVersion = $majorVersion
            }
            $versionsHashTable[$majorVersion] = $fullVersion
        }
        $versionsHashTable['lts'] = $versionsHashTable[$ltsVersion]
        $versionsHashTable['latest'] = $versionsHashTable[$latestVersion]

        # Update the cache variable and set the expiry time
        $script:nodeLatestVersionsCache = $versionsHashTable
        $script:LastNodeLatestVersionsRefreshed = Get-Date
    }

    # Return the cached result
    return $script:nodeLatestVersionsCache
}
