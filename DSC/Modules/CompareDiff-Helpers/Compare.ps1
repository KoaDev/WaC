. $PSScriptRoot/Helpers.ps1

function Compare-Deep
{
    [CmdletBinding()]
    param (
        $Object1,
        $Object2,
        [switch]$Partial
    )

    if ($null -eq $Object1 -and $null -eq $Object2)
    {
        return $true
    }
    elseif ($null -eq $Object1 -or $null -eq $Object2)
    {
        Write-Verbose 'One object is null and the other is not.'
        return $false
    }

    if ($Object1 -is [collections.IDictionary] -and $Object2 -is [collections.IDictionary])
    {
        $result = Compare-Hashtable $Object1 $Object2 -Partial:$Partial -Verbose:($PSBoundParameters['Verbose'] -eq $true)
        if (-not $result)
        {
            Write-Verbose 'Hashtables are different.'
        }
        return $result
    }
    
    if ($Object1 -is [array] -and $Object2 -is [array])
    {
        $result = Compare-Array $Object1 $Object2 -Partial:$Partial -Verbose:($PSBoundParameters['Verbose'] -eq $true)
        if (-not $result)
        {
            Write-Verbose 'Arrays are different.'
        }
        return $result
    }

    if ($Object1 -is [Enum] -or $Object2 -is [Enum])
    {
        $result = $Object1 -eq $Object2
        if (-not $result)
        {
            if ($Object1 -is [Enum])
            {
                Write-Verbose "Value $Object2 is not a $($Object1.GetType()) enum ($(-join ([enum]::GetNames($Object1.GetType())), ', '))."
            }
            elseif ($Object2 -is [Enum])
            {
                Write-Verbose "Value $Object1 is not a $($Object2.GetType()) enum ($(-join ([enum]::GetNames($Object2.GetType())), ', '))."
            }
            else
            {
                Write-Verbose "Value '$Object1' of Object1 does not match value '$Object2' of Object2."
            }
        }
        return $result
    }

    if (($Object1 -is [ValueType] -or $Object1 -is [string]) -and ($Object2 -is [ValueType] -or $Object2 -is [string]))
    {
        $result = $Object1 -eq $Object2
        if (-not $result)
        {
            Write-Verbose "Value '$Object1' of Object1 does not match value '$Object2' of Object2."
        }
        return $result
    }

    Write-Verbose "Comparison impossible between Object1 of type '$($Object1.GetType())' and Object2 of type '$($Object2.GetType())'."
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

        [switch]$Partial
    )

    if (-not $Partial -and $Hashtable1.Count -ne $Hashtable2.Count)
    {
        Write-Verbose 'Hashtable lengths are different.'
        return $false
    }

    foreach ($key in $Hashtable1.Keys)
    {
        if (-not $Hashtable2.ContainsKey($key))
        {
            Write-Verbose "Key '$key' from Hashtable1 does not exist in Hashtable2."
            return $false
        }

        if (-not (Compare-Deep $Hashtable1[$key] $Hashtable2[$key] -Partial:$Partial -Verbose:($PSBoundParameters['Verbose'] -eq $true)))
        {
            Write-Verbose "Value '$(Get-ObjectString $Hashtable1[$key])' for key '$key' in Hashtable1 does not match value '$(Get-ObjectString $Hashtable2[$key])' in Hashtable2."
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
        $Array1,

        [Parameter(Mandatory = $true)]
        $Array2,

        [switch]$Partial
    )

    if (-not $Partial -and $Array1.Count -ne $Array2.Count)
    {
        Write-Verbose 'Array lengths are different.'
        return $false
    }

    $maxShift = $Array2.Count - $Array1.Count
    $shift = 0

    for ($i = 0; $i -lt $Array1.Count; $i++)
    {
        for ($shift; $shift -le $maxShift; $shift++)
        {
            if (Compare-Deep $Array1[$i] $Array2[$i + $shift] -Partial:$Partial -Verbose:($PSBoundParameters['Verbose'] -eq $true))
            {
                break
            }
        }
        if ($shift -gt $maxShift)
        {
            Write-Verbose "Value '$(Get-ObjectString $Array1[$i])' at index $i in Array1 does not match value '$(Get-ObjectString $Array2[$i + $shift - 1])' at index $($i + $shift - 1) in Array2."
            return $false
        }
    }

    return $true
}
