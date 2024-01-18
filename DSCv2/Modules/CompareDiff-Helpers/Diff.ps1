. $PSScriptRoot\Compare.ps1
. $PSScriptRoot\Helpers.ps1

function Get-Diff
{
    [CmdletBinding()]
    param (
        $Object1,
        $Object2
    )

    if ($Object1 -is [collections.IDictionary] -and $Object2 -is [collections.IDictionary])
    {
        if (Compare-Deep $Object1 $Object2 -Verbose:($PSBoundParameters['Verbose'] -eq $true))
        {
            return @{}
        }
        else
        {
            return Get-HashtableDiff $Object1 $Object2
        }
    }
    
    if ($Object1 -is [array] -and $Object2 -is [array])
    {
        if (Compare-Array $Object1 $Object2 -Verbose:($PSBoundParameters['Verbose'] -eq $true))
        {
            return @{}
        }
        else
        {
            return Get-BeforeAfter $Object1 $Object2
        }
    }

    if ((Test-IsValueType $Object1) -and (Test-IsValueType $Object2))
    {
        if ($Object1 -eq $Object2)
        {
            return @{}
        }
        else
        {
            return Get-BeforeAfter $Object1 $Object2
        }
    }

    return @{
        Error = 'Unable to compare objects of type ' + $Object1.GetType().FullName + ' and ' + $Object2.GetType().FullName + '.'
    }
}

function Get-HashtableDiff
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $Hashtable1,

        [Parameter(Mandatory = $true)]
        $Hashtable2
    )

    $result = @{
        Added    = @()
        Removed  = @()
        Modified = @{}
    }

    foreach ($key in $Hashtable1.Keys)
    {
        if (-not $Hashtable2.ContainsKey($key))
        {
            $result.Removed += $key
        }
        elseif (-not (Compare-Deep $Hashtable1[$key] $Hashtable2[$key] -Verbose:($PSBoundParameters['Verbose'] -eq $true)))
        {
            $result.Modified[$key] = Get-Diff $Hashtable1[$key] $Hashtable2[$key]
        }
    }

    foreach ($key in $Hashtable2.Keys)
    {
        if (-not $Hashtable1.ContainsKey($key))
        {
            $result.Added += $key
        }
    }

    return $result
}

function Get-ArrayDiff
{
    [CmdletBinding()]
    param (
        [array]$Array1,
        [array]$Array2
    )

    $result = @{
        Added   = @()
        Removed = @()
    }

    $lastMatchI2 = -1

    for ($i1 = 0; $i1 -lt $Array1.Count; $i1++)
    {
        $item1 = $Array1[$i1]
        $hasMatched = $false

        for ($i2 = $lastMatchI2 + 1; $i2 -lt $Array2.Count; $i2++)
        {
            $item2 = $Array2[$i2]

            if (Compare-Deep $item1 $item2 -Verbose:($PSBoundParameters['Verbose'] -eq $true))
            {
                $hasMatched = $true

                for ($j = $lastMatchI2 + 1; $j -lt $i2; $j++)
                {
                    $result.Added += Get-ObjectString $Array2[$j]
                }
                $lastMatchI2 = $i2

                break
            }
        }

        if (-not $hasMatched)
        {
            $result.Removed += Get-ObjectString $item1
        }
    }

    for ($i = $lastMatchI2 + 1; $i -lt $Array2.Count; $i++)
    {
        $result.Added += Get-ObjectString $Array2[$i]
    }

    return $result
}
