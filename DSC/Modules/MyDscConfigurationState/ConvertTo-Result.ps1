function ConvertTo-JsonDiff
{
    param (
        [Parameter(Mandatory = $true)]
        [object]$Object
    )

    if ($Object.Count -eq 0)
    {
        return $null
    }

    return ConvertTo-Json -EnumsAsStrings -Depth 100 $Object
}

function ConvertTo-StringIdentifier
{
    param (
        [Parameter(Mandatory = $true)]
        [object]$Object
    )

    if ($Object.Count -eq 1)
    {
        $Object.Values[0]
    }
    else
    {
        ($Object.GetEnumerator() | ForEach-Object { "$($_.Key): $($_.Value)" }) -join "`n"
    }
}
