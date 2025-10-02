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

function Get-NvmCurrentVersion
{
    return (nvm current) -Replace '^v'
}

function Get-NvmStaleVersions
{
    $installedVersions = Get-NvmInstalledVersions
    $latestVersions = @{}
    $staleVersions = @()

    foreach ($version in $installedVersions)
    {
        $splitVersion = $version -split '\.'
        $majorVersion = [int]$splitVersion[0]
        $minorVersion = [int]$splitVersion[1]
        $patchVersion = [int]$splitVersion[2]

        if ($latestVersions.ContainsKey($majorVersion))
        {
            $latestSplitVersion = $latestVersions[$majorVersion] -split '\.'
            $latestMinorVersion = [int]$latestSplitVersion[1]
            $latestPatchVersion = [int]$latestSplitVersion[2]

            if (($minorVersion -gt $latestMinorVersion) -or (($minorVersion -eq $latestMinorVersion) -and ($patchVersion -gt $latestPatchVersion)))
            {
                # Current version is newer, add the older version to staleVersions and update latestVersions
                $staleVersions += $latestVersions[$majorVersion]
                $latestVersions[$majorVersion] = $version
            }
            else
            {
                # Current version is older or equal, add it to staleVersions
                $staleVersions += $version
            }
        }
        else
        {
            # This is the first version of this major version, add it to latestVersions
            $latestVersions[$majorVersion] = $version
        }
    }

    # Output stale versions
    return $staleVersions
}

$script:CacheDurationMinutes = 5
function Get-NodeLatestVersions
{
    if (-not $script:nodeLatestVersionsCache -or (Get-Date) -gt $script:LastNodeLatestVersionsRefreshed.AddMinutes($script:CacheDurationMinutes))
    {
        try {
            $url = 'https://nodejs.org/dist/index.json'

            $resp = Invoke-WebRequest -Uri $url -UseBasicParsing
            $nodeVersions = $resp.Content | ConvertFrom-Json

            $versionsHashTable = @{}
            $latestVersion = $null
            $latestLts = $null

            foreach ($item in $nodeVersions) {
                if ($item.version -match '^v(.+)$') {
                    $versionString = $Matches[1]
                    $version = [version]$versionString
                    $majorVersion = $version.Major
                    if ($null -eq $latestVersion -or
			            $version -gt [version]$latestVersion) {
                        $latestVersion = $versionString
                    }
                    if ($item.lts -and
			            ($null -eq $latestLts -or
			            $version -gt [version]$latestLts)) {
                        $latestLts = $versionString
                    }
                    if (-not $versionsHashTable.ContainsKey($majorVersion) -or
			            $version -gt [version]$versionsHashTable[$majorVersion]) {
                        $versionsHashTable[$majorVersion] = $versionString
                    }
                }
            }
 
            $versionsHashTable['latest'] = $latestVersion
            $versionsHashTable['lts'] = $latestLts

            $script:nodeLatestVersionsCache = $versionsHashTable
            $script:LastNodeLatestVersionsRefreshed = Get-Date
        }
        catch
        {
            Write-Error "Failed to retrieve Node.js versions. Details: $_"
            return $null
        }
    }

    # Return the cached result
    return $script:nodeLatestVersionsCache
}