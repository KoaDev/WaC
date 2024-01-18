function Compare-Deep
{
    [CmdletBinding()]
    param (
        $object1,
        $object2,
        [boolean]$strict = $false
    )

    if ($null -eq $object1 -and $null -eq $object2)
    {
        return $true
    }
    elseif ($null -eq $object1 -or $null -eq $object2)
    {
        Write-Verbose 'One object is null and the other is not.'
        return $false
    }

    if ($object1 -is [collections.IDictionary] -and $object2 -is [collections.IDictionary])
    {
        $result = Compare-Hashtable $object1 $object2 $strict -Verbose:($PSBoundParameters['Verbose'] -eq $true)
        if (-not $result)
        {
            Write-Verbose 'Hashtables are different.'
        }
        return $result
    }
    
    if ($object1 -is [array] -and $object2 -is [array])
    {
        $result = Compare-Array $object1 $object2 $strict -Verbose:($PSBoundParameters['Verbose'] -eq $true)
        if (-not $result)
        {
            Write-Verbose 'Arrays are different.'
        }
        return $result
    }

    if ($object1 -is [Enum] -or $object2 -is [Enum])
    {
        $result = $object1 -eq $object2
        if (-not $result)
        {
            if ($object1 -is [Enum])
            {
                Write-Verbose "Value $object2 is not a $($object1.GetType()) enum ($(-join ([enum]::GetNames($object1.GetType())), ', '))."
            }
            elseif ($object2 -is [Enum])
            {
                Write-Verbose "Value $object1 is not a $($object2.GetType()) enum ($(-join ([enum]::GetNames($object2.GetType())), ', '))."
            }
            else
            {
                Write-Verbose 'Enums are different.'
            }
        }
        return $result
    }

    if (($object1 -is [ValueType] -or $object1 -is [string]) -and ($object2 -is [ValueType] -or $object2 -is [string]))
    {
        $result = $object1 -eq $object2
        if (-not $result)
        {
            Write-Verbose 'Value types are different.'
        }
        return $result
    }

    Write-Verbose "Objects types were not handled ($($object1.GetType()) vs $($object2.GetType()))."
    return $false
}

function Compare-Hashtable
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $Hashtable1,

        [Parameter(Mandatory = $true)]
        $Hashtable2,

        [boolean]$strict = $false
    )

    if ($strict -and $Hashtable1.Count -ne $Hashtable2.Count)
    {
        Write-Verbose 'Hashtable counts are different.'
        return $false
    }

    foreach ($key in $Hashtable1.Keys)
    {
        if (-not $Hashtable2.ContainsKey($key))
        {
            Write-Verbose "Hashtable2 does not contain key $key from Hashtable1."
            return $false
        }

        if (-not (Compare-Deep $Hashtable1[$key] $Hashtable2[$key] $strict -Verbose:($PSBoundParameters['Verbose'] -eq $true)))
        {
            Write-Verbose "Difference found at key $key - $(Get-ObjectComparisonString $Hashtable1[$key] $Hashtable2[$key])."
            return $false
        }
    }

    return $true
}

function Compare-Array
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $array1,

        [Parameter(Mandatory = $true)]
        $array2,

        [boolean]$strict = $false
    )

    if ($strict -and $array1.Count -ne $array2.Count)
    {
        Write-Verbose 'Array lengths are different.'
        return $false
    }

    $maxShift = $array2.Count - $array1.Count
    $shift = 0

    for ($i = 0; $i -lt $array1.Count; $i++)
    {
        for ($shift; $shift -le $maxShift; $shift++)
        {
            if (Compare-Deep $array1[$i] $array2[$i + $shift] $strict -Verbose:($PSBoundParameters['Verbose'] -eq $true))
            {
                break
            }
        }
        if ($shift -gt $maxShift)
        {
            Write-Verbose "Difference found at index $i - $(Get-ObjectComparisonString $array1[$i] $array2[$i + $shift - 1])."
            return $false
        }
    }

    # for ($i = 0; $i -lt $array1.Count; $i++)
    # {
    #     while ($shift -le $maxShift -and -not (Compare-Deep $array1[$i] $array2[$i + $shift] $strict -Verbose:($PSBoundParameters['Verbose'] -eq $true)))
    #     {
    #         $shift++
    #     }
    #     if ($shift -gt $maxShift)
    #     {
    #         Write-Verbose "Difference found at index $i - $(Get-ObjectComparisonString $Array1[$i] $Array2[$i + $shift - 1])."
    #         return $false
    #     }
    # }

    return $true
}

function Get-ObjectComparisonString
{
    [CmdletBinding()]
    param (
        $Object1,
        $Object2
    )

    return "$($Object1 | ConvertTo-Json -Depth 100 -Compress) vs $($Object2 | ConvertTo-Json -Depth 100 -Compress)"
}