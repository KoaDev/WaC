function Test-IsValueType
{
    [CmdletBinding()]
    param (
        $Object
    )

    return $null -eq $Object -or $Object -is [ValueType] -or $Object -is [string] -or $Object -is [Enum]
}

function Test-IsDiffResult
{
    [CmdletBinding()]
    param (
        $Object
    )

    # Define the allowed keys
    $allowedKeys = @('Added', 'Removed', 'Modified')

    # Check if the object is a hashtable
    if ($Object -is [hashtable])
    {
        # Get all keys in the hashtable
        $keys = $Object.Keys

        # Check if all keys in the hashtable are part of the allowed keys
        return ($keys.Count -gt 0) -and ($keys | ForEach-Object { $allowedKeys -contains $_ }) -notcontains $false
    }
    else
    {
        return $false
    }
}

function Get-ObjectString
{
    [CmdletBinding()]
    param (
        $Object
    )

    if (Test-IsValueType $Object)
    {
        return $Object -is [enum] ? $Object.ToString() : $Object
    }

    if (Test-IsDiffResult $Object)
    {
        return $Object
    }

    return $Object | ConvertTo-Json -Depth 100 -Compress
}

function Get-BeforeAfter
{
    [CmdletBinding()]
    param (
        $Before,
        $After
    )

    return @{
        Before = Get-ObjectString $Before
        After  = Get-ObjectString $After
    }
}
