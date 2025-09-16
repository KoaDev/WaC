function Get-NvmInstalledVersions
{
    $nvmList = & nvm list
    $installedVersions = $nvmList -split '\r?\n' |
        Where-Object { $_.Trim() -ne '' } |
        ForEach-Object {
            if ($_ -match '\d+\.\d+\.\d+')
            {
                $matches[0]
            }
        }
    return $installedVersions
}


function Get-NvmCurrentVersion {
    $exe = Join-Path $env:ProgramFiles 'nodejs\node.exe'
    if (Test-Path $exe) {
        try {
            $v = & $exe -v 2>$null
            if ($v -match 'v?(\d+\.\d+\.\d+)') { return $Matches[1] }
        } catch {}
    }
    # Fallback (si le symlink n'existe pas)
    $out = (& nvm current 2>$null) -as [string]
    if ($out -match 'v?(\d+\.\d+\.\d+)') { return $Matches[1] }
    return $null
}


# In MyNodeVersion.Helpers.ps1
function Get-NvmStaleVersions {
    $installed = Get-NvmInstalledVersions
    if (-not $installed) { return @() }
    $stale = @()
    # Grouper par major (20, 22, …), et ne garder que le + grand de chaque major
    $installed | Group-Object { ($_ -split '\.')[0] } | ForEach-Object {
        $latest = $_.Group | Sort-Object {[version]$_} -Descending | Select-Object -First 1
        $stale  += ($_.Group | Where-Object { $_ -ne $latest })
    }
    return $stale
}


function Get-NvmInstalledVersions
{
    $nvmList = & nvm list
    $installedVersions = $nvmList -split '\r?\n' |
        Where-Object { $_.Trim() -ne '' } |
        ForEach-Object {
            if ($_ -match '\d+\.\d+\.\d+')
            {
                $matches[0]
            }
        }
    return $installedVersions
}

# Create a new, simple helper function that we can easily mock.
function Get-NvmCurrentVersionInternal
{
    return (nvm current)
}

function Get-NvmCurrentVersion
{
    # This function now calls the internal, mockable function.
    return (Get-NvmCurrentVersionInternal) -Replace '^v'
}

function Get-NvmStaleVersions
{
    $installedVersions = Get-NvmInstalledVersions
    $staleVersions = @()
    
    # Grouper par version majeure (extraire le premier chiffre)
    $versionsByMajor = $installedVersions | Group-Object { ([version]$_).Major }
    
    foreach ($group in $versionsByMajor) {
        $versionsInGroup = $group.Group | Sort-Object { [version]$_ }
        $latestVersion = $versionsInGroup[-1]
        
        # Ajouter toutes les versions sauf la plus récente
        $staleVersions += $versionsInGroup | Where-Object { $_ -ne $latestVersion }
    }
    
    return $staleVersions
}

$script:CacheDurationMinutes = 5
function Get-NodeLatestVersions
{
    if (-not $script:nodeLatestVersionsCache -or (Get-Date) -gt $script:LastNodeLatestVersionsRefreshed.AddMinutes($script:CacheDurationMinutes))
    {
        try
        {
            $url = 'https://nodejs.org/dist/index.json'
            $versions = Invoke-WebRequest -Uri $url | ConvertFrom-Json
            $versionsHashTable = @{}
            $ltsVersion = $versions | Where-Object { $_.lts } | Sort-Object { $_.version -replace '^v' -as [version] } | Select-Object -Last 1
            $latestVersion = $versions | Sort-Object { $_.version -replace '^v' -as [version] } | Select-Object -Last 1
            $versionsHashTable['lts'] = $ltsVersion.version -replace '^v'
            $versionsHashTable['latest'] = $latestVersion.version -replace '^v'
            $versions | Group-Object { ($_.version -replace '^v' -as [version]).Major } | ForEach-Object {
                $latestInMajor = $_.Group | Sort-Object { $_.version -replace '^v' -as [version] } | Select-Object -Last 1
                $majorVersion = ($latestInMajor.version -replace '^v' -split '\.')[0]
                $versionsHashTable[$majorVersion] = $latestInMajor.version -replace '^v'
            }
            $script:nodeLatestVersionsCache = $versionsHashTable
            $script:LastNodeLatestVersionsRefreshed = Get-Date
        }
        catch
        {
            Write-Error "Failed to retrieve Node.js versions. Details: $_"
            return $null
        }
    }
    return $script:nodeLatestVersionsCache
}