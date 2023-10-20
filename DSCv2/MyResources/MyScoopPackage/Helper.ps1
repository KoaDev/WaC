function Get-ScoopPackageInfo([string] $packageName) {
    $installedPackages = & scoop list | Out-String
    $scoopListRows = $installedPackages -split "\r?\n"

    $headerRow = $scoopListRows | Where-Object { $_ -like "*Name*" -and $_ -like "*Version*" }
    $headerColumns = $headerRow -split '\s+'

    $nameColumnIndex = $headerColumns.IndexOf('Name')
    $versionColumnIndex = $headerColumns.IndexOf('Version')

    foreach ($row in $scoopListRows) {
        $columns = $row -split '\s+'
        if ($columns.Count -gt [math]::Max($nameColumnIndex, $versionColumnIndex)) {
            if ($columns[$nameColumnIndex] -eq $packageName) {
                return @{
                    IsInstalled = $true
                    Version     = $columns[$versionColumnIndex]
                }
            }
        }
    }

    return @{
        IsInstalled = $false
        Version     = $null
    }
}
