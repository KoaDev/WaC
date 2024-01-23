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
    $isOutdated = $isInCache -and (Get-Date) - $script:cache[$CacheName][$cacheKey].Time -gt $CacheDuration

    if ($Force -or -not $isInCache -or $isOutdated)
    {
        $result = & $ResourceAction
        $script:cache[$CacheName][$cacheKey] = @{
            Result = $result
            Time   = Get-Date
        }
    }

    return $script:cache[$CacheName][$cacheKey].Result
}
