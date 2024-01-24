function Split-Hashtable
{
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$OriginalHashtable,

        [Parameter(Mandatory = $true)]
        [string[]]$KeysArray
    )

    # Create two new empty hashtables
    $includedKeysHashtable = @{}
    $excludedKeysHashtable = @{}

    # Iterate through the original hashtable
    foreach ($key in $OriginalHashtable.Keys)
    {
        if ($KeysArray -contains $key)
        {
            # If the key is in the KeysArray, add it to the includedKeysHashtable
            $includedKeysHashtable[$key] = $OriginalHashtable[$key]
        }
        else
        {
            # If the key is not in the KeysArray, add it to the excludedKeysHashtable
            $excludedKeysHashtable[$key] = $OriginalHashtable[$key]
        }
    }

    # Return the two hashtables
    return @($includedKeysHashtable, $excludedKeysHashtable)
}

function Select-HashtableKeys
{
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable]$OriginalHashtable,
        
        [Parameter(Mandatory = $true)]
        [string[]]$KeysArray,
        
        [switch]$InvertSelection
    )

    process
    {
        if ($InvertSelection)
        {
            $resultHashtable = $OriginalHashtable.Clone()
            foreach ($key in $KeysArray)
            {
                $resultHashtable.Remove($key)
            }
        }
        else
        {
            $resultHashtable = @{}
            foreach ($key in $KeysArray)
            {
                if ($OriginalHashtable.ContainsKey($key))
                {
                    $resultHashtable[$key] = $OriginalHashtable[$key]
                }
                else
                {
                    Write-Error "Key '$key' not found in the original hashtable."
                }
            }
        }

        return $resultHashtable
    }
}

function ConvertTo-Hashtable
{
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $object
    )

    process
    {
        # If the object is already a hashtable, return it directly
        if ($object -is [hashtable])
        {
            return $object
        }

        # If the object is null, return an empty hashtable
        if ($null -eq $object)
        {
            return @{}
        }

        # If the object is not an object, throw an exception
        if ($object -isnot [object])
        {
            throw 'The input must be an object.'
        }

        # If the object is a regular object, convert it to a hashtable
        $hashtable = @{}
        foreach ($property in $object.PSObject.Properties)
        {
            $hashtable[$property.Name] = $property.Value
        }

        return $hashtable
    }
}

function Remove-EmptyArrayProperties
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable]$Hashtable
    )

    process
    {
        foreach ($key in $Hashtable.Keys)
        {
            if ($Hashtable[$key] -is [array] -and $Hashtable[$key].Count -eq 0)
            {
                $Hashtable.Remove($key)
            }
        }
        return $Hashtable
    }
}
