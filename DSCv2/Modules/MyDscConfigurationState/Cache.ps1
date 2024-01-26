Import-Module MyDscResourceState

$script:cache = @{}

function Get-DscResourceHash
{
    param(
        [hashtable]$Resource
    )

    $resourceId = Select-DscResourceIdProperties -Resource $resource
    $hash = ($resourceId | ConvertTo-Json -Depth 100 -Compress).GetHashCode().ToString()
    return $hash
}

function Get-CacheEntry
{
    param(
        [string]$CacheName,
        [string]$Key,
        [timespan]$CacheDuration,
        [scriptblock]$ResourceAction,
        [switch]$Force
    )

    if (-not $script:cache.ContainsKey($CacheName))
    {
        $script:cache[$CacheName] = @{}
    }

    $isInCache = $script:cache[$CacheName].ContainsKey($cacheKey)
    $isOutdated = $isInCache -and $script:cache[$CacheName][$cacheKey].Expires -lt (Get-Date)

    if ($Force -or -not $isInCache -or $isOutdated)
    {
        $result = & $ResourceAction
        $script:cache[$CacheName][$cacheKey] = @{
            Result  = $result
            Expires = (Get-Date) + $CacheDuration
        }
    }

    return $script:cache[$CacheName][$cacheKey].Result
}

function Get-CacheEntryOrNull
{
    param(
        [string]$CacheName,
        [string]$Key
    )

    if (-not $script:cache.ContainsKey($CacheName))
    {
        return $null
    }

    $isInCache = $script:cache[$CacheName].ContainsKey($cacheKey)

    if (-not $isInCache)
    {
        return $null
    }

    $isOutdated = $isInCache -and $script:cache[$CacheName][$cacheKey].Expires -lt (Get-Date)

    if ($isOutdated)
    {
        return $null
    }

    return $script:cache[$CacheName][$cacheKey].Result
}
