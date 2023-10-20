enum MyEnsure {
    Absent
    Present
}

[DscResource()]
class MyScoopPackage {
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

    hidden static [DateTime] $LastScoopListRefreshed
    hidden static [hashtable] $ScoopListCache
    hidden static [DateTime] $LastScoopStatusRefreshed
    hidden static [hashtable] $ScoopStatusCache

    hidden [TimeSpan] $CacheDuration = [TimeSpan]::FromMinutes(5)

    hidden [hashtable] GetScoopPackageInfo([string] $packageName) {
        if ([MyScoopPackage]::ScoopListCache -and ((Get-Date) - [MyScoopPackage]::LastScoopListRefreshed) -lt $this.CacheDuration) {
            $packages = [MyScoopPackage]::ScoopListCache
        }
        else {
            $scoopList = & scoop list | Out-String
            $packages = Convert-AsciiTableToHashtable -asciiTable $scoopList -packageNameHeader 'Name'
            [MyScoopPackage]::ScoopListCache = $packages
            [MyScoopPackage]::LastScoopListRefreshed = Get-Date
        }
        
        if ($packages.ContainsKey($packageName)) {
            return @{
                Ensure  = [MyEnsure]::Present
                Version = $packages[$packageName]['Version']
            }
        }
    
        return @{
            Ensure  = [MyEnsure]::Absent
            Version = $null
        }
    }

    hidden [string] GetLatestAvailableVersion([string] $packageName) {
        if ([MyScoopPackage]::ScoopStatusCache -and ((Get-Date) - [MyScoopPackage]::LastScoopStatusRefreshed) -lt $this.CacheDuration) {
            $packages = [MyScoopPackage]::ScoopStatusCache
        }
        else {
            $scoopStatus = & scoop status | Out-String
            $packages = Convert-AsciiTableToHashtable -asciiTable $scoopStatus -packageNameHeader 'Name'
            [MyScoopPackage]::ScoopStatusCache = $packages
            [MyScoopPackage]::LastScoopStatusRefreshed = Get-Date
        }
    
        if ($packages.ContainsKey($packageName)) {
            return $packages[$packageName]['Latest Version']
        }
    
        return $null
    }

    [MyScoopPackage] Get() {
        $current = [MyScoopPackage]::new()
        $current.PackageName = $this.PackageName

        $packageInfo = $this.GetScoopPackageInfo($this.PackageName)

        $current.Ensure = $packageInfo.Ensure
        $current.Version = $packageInfo.Version
    
        $latestAvailableVersion = $this.GetLatestAvailableVersion($this.PackageName)
        if ($latestAvailableVersion) {
            $current.LatestVersion = $latestAvailableVersion
        }
        else {
            $current.LatestVersion = $current.Version
        }

        if ($current.Version -and $current.LatestVersion) {
            if ($current.Version -eq $current.LatestVersion) {
                $current.State = 'Current'
            }
            else {
                $current.State = 'Stale'
            }
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

        if ($this.Version -eq 'latest') {
            return $current.Version -eq $current.LatestVersion
        }
        else {
            return $current.Version -eq $this.Version
        }
    }

    [void] Set() {
        if ($this.Test()) {
            return
        }

        $current = $this.CachedCurrent

        if ($this.Ensure -eq [MyEnsure]::Present) {
            if ($this.Version -eq 'latest') {
                $target = $this.PackageName
            }
            else {
                $target = "$($this.PackageName)@$($this.Version)"
            }

            if ($current.Ensure -eq [MyEnsure]::Present -and $this.Version -eq 'latest') {
                & scoop update $target
            }
            else {
                & scoop install $target
            }
        }
        elseif ($this.Ensure -eq [MyEnsure]::Absent) {
            if ($current.Ensure -eq [MyEnsure]::Present) {
                & scoop uninstall $this.PackageName
            }
        }
        
        # Invalidate the caches
        [MyScoopPackage]::ScoopListCache = $null
        [MyScoopPackage]::ScoopStatusCache = $null
    }
}

function Convert-AsciiTableToHashtable {
    param (
        [Parameter(Mandatory = $true)]
        [string] $asciiTable,
        [Parameter(Mandatory = $true)]
        [string] $packageNameHeader
    )

    $rows = ($asciiTable -split "\r?\n") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
    $underlineRow = $rows | Where-Object { $_ -match "(-+\s+)+" }
    $underlineRowIndex = $rows.IndexOf($underlineRow)
    $headerRow = $rows[$underlineRowIndex - 1]

    $columnUnderlines = [regex]::Matches($underlineRow, "-+")
    $columnHeaders = @()

    for ($i = 0; $i -lt $columnUnderlines.Count; $i++) {
        $start = $columnUnderlines[$i].Index
        $header = $headerRow.Substring($start, $columnUnderlines[$i].Length).Trim()
        if ($i + 1 -lt $columnUnderlines.Count) {
            $end = $columnUnderlines[$i + 1].Index - 1  # Set end as the start of the next column - 1
        }
        else {
            $end = $underlineRow.Length  # For the last column, use the end of the underline row
        }
        $columnHeaders += @{
            Header = $header
            Start  = $start
            End    = $end
        }
    }

    $result = @{}

    for ($i = $underlineRowIndex + 1; $i -lt $rows.Count; $i++) {
        $row = $rows[$i]

        $packageName = $null
        $packageInfo = @{}

        for ($j = 0; $j -lt $columnHeaders.Count; $j++) {
            $start = $columnHeaders[$j].Start
            $end = $columnHeaders[$j].End  # Use pre-computed end index
            
            # Ensure both indices are within bounds
            if ($start -ge $row.Length) { break }
            $end = [Math]::Min($end, $row.Length)

            $value = $row.Substring($start, $end - $start).Trim()
            if ($columnHeaders[$j].Header -eq $packageNameHeader) {
                $packageName = $value
            }
            else {
                $packageInfo[$columnHeaders[$j].Header] = $value
            }
        }

        if ($packageName) {
            $result[$packageName] = $packageInfo
        }
    }

    return $result
}
