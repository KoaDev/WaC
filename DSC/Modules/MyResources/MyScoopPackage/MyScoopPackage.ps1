. $PSScriptRoot\Convert-ObjectArrayToHashtable.ps1
. $PSScriptRoot\Invoke-RetryableOperation.ps1

enum MyEnsure
{
    Absent
    Present
}

$script:ScoopListCache
$script:ScoopListCacheExpires
$script:ScoopStatusCache
$script:ScoopStatusCacheExpires
$script:CacheDuration = [TimeSpan]::FromMinutes(5)

function Get-RawScoopList
{
    $result = & scoop list

    if (-not $?)
    {
        throw "Failed to get scoop list: $result"
    }
    
    return $result ? $result : @()
}

function Get-RawScoopStatus
{
    $statusResult = & scoop status 6>&1
    if ($statusResult -match 'WARN.*scoop update')
    {
        & scoop update
    }
    
    $result = & scoop status
    
    if (-not $?)
    {
        throw "Failed to get scoop status: $result"
    }
    
    return $result ? $result : @()
}

function Update-ScoopListCache
{
    Invoke-RetryableOperation {
        $scoopList = Get-RawScoopList

        if (-not $scoopList)
        {
            throw 'Unable to get scoop list'
        }

        try
        {
            $packages = Convert-ObjectArrayToHashtable $scoopList 'Name'
            $script:ScoopListCache = $packages
            $script:ScoopListCacheExpires = (Get-Date) + $script:CacheDuration
        }
        catch
        {
            throw "Failed to convert scoop list '$($scoopList | ConvertTo-Json -EnumsAsStrings -Depth 100 -Compress)' to hashtable.`nDetails: $_"
        }
    }
}

function Get-ScoopPackageInfo
{
    param (
        [string]$PackageName
    )

    if (-not $script:ScoopListCache -or $script:ScoopListCacheExpires -le (Get-Date))
    {
        Update-ScoopListCache
    }

    if ($script:ScoopListCache.ContainsKey($PackageName))
    {
        return @{
            Ensure  = [MyEnsure]::Present
            Version = $script:ScoopListCache[$packageName].Version
        }
    }

    return $null
}

function Get-ScoopPackageInfo()
{
    param(
        [Parameter(Mandatory = $true)]
        [string] $packageName
    )

    if ($script:ScoopListCache -and $script:ScoopListCacheExpires -gt (Get-Date))
    {
        $packages = $script:ScoopListCache
    }
    else
    {
        $scoopList = Get-RawScoopList
        try
        {
            $packages = Convert-ObjectArrayToHashtable $scoopList 'Name'
            $script:ScoopListCache = $packages
            $script:ScoopListCacheExpires = (Get-Date) + $script:CacheDuration
        }
        catch
        {
            throw "Failed to convert scoop list '$($scoopList | ConvertTo-Json -EnumsAsStrings -Depth 100 -Compress)' to hashtable.`nDetails: $_"
        }
    }
    
    if ($packages.ContainsKey($packageName))
    {
        return @{
            Ensure  = [MyEnsure]::Present
            Version = $packages[$packageName].Version
        }
    }

    return @{
        Ensure  = [MyEnsure]::Absent
        Version = $null
    }
}

function Update-ScoopStatusCache
{
    Invoke-RetryableOperation {
        $scoopStatus = Get-RawScoopStatus
            
        if (-not $scoopStatus)
        {
            throw 'Unable to get scoop status'
        }

        try
        {
            $packages = Convert-ObjectArrayToHashtable $scoopStatus 'Name'
            $script:ScoopStatusCache = $packages
            $script:ScoopStatusCacheExpires = (Get-Date) + $script:CacheDuration
        }
        catch
        {
            throw "Failed to convert scoop status '$($scoopStatus | ConvertTo-Json -EnumsAsStrings -Depth 100 -Compress)' to hashtable.`nDetails: $_"
        }
    }
}

function Get-ScoopPackageLatestAvailableVersion
{
    param (
        [string]$PackageName
    )

    if (-not $script:ScoopStatusCache -or $script:ScoopStatusCacheExpires -le (Get-Date))
    {
        Update-ScoopStatusCache
    }

    if ($script:ScoopStatusCache.ContainsKey($PackageName))
    {
        return $script:ScoopStatusCache[$PackageName].'Latest Version'
    }

    return $null
}

function Update-ScoopPackage()
{
    param(
        [Parameter(Mandatory = $true)]
        [string] $packageName
    )

    $output = & scoop update $packageName *>&1
    if (-not $?)
    {
        $outputString = $output | Out-String
        throw "Failed to update scoop package '$packageName'.`nDetails: $outputString"
    }

    Clear-Cache
}

function Install-ScoopPackage()
{
    param(
        [Parameter(Mandatory = $true)]
        [string] $packageName
    )
    
    & scoop install $target
    if (-not $?)
    {
        throw "Failed to install scoop package '$target'"
    }

    Clear-Cache
}

function Uninstall-ScoopPackage()
{
    param(
        [Parameter(Mandatory = $true)]
        [string] $packageName
    )

    & scoop uninstall $this.PackageName
    if (-not $?)
    {
        throw "Failed to uninstall scoop package '$($this.PackageName)'"
    }

    Clear-Cache
}

function Clear-Cache
{
    $script:ScoopListCache = $null
    $script:ScoopListCacheExpires = $null
    $script:ScoopStatusCache = $null
    $script:ScoopStatusCacheExpires = $null
}
