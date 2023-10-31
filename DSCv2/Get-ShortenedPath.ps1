$Ellipsis = '…'

function Get-ShortenedPath {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [int]$MaxLength
    )

    if ($Path.Length -le $MaxLength) { return $Path }

    $root = [System.IO.Path]::GetPathRoot($Path)
    $filename = [System.IO.Path]::GetFileName($Path)
    $dirname = [System.IO.Path]::GetDirectoryName($Path).Substring($root.Length)

    $shortenedPath = $Path

    # Shorten the directory part of the path
    if ($dirname.Length -gt $Ellipsis.Length) {
        $dirParts = $dirname.Split('\')
    
        while ((Join-Path -Path $root -ChildPath ($dirParts + $Ellipsis + $filename -join '\')).Length -gt $MaxLength -and $dirParts.Count -gt 0) {
            $dirParts = $dirParts | Select-Object -SkipLast 1
        }
        
        $shortenedPath = Join-Path -Path $root -ChildPath ($dirParts + @($Ellipsis) + $filename -join '\')
    }

    # If still too long, shorten the file name (excluding extension)
    if ($shortenedPath.Length -gt $MaxLength) {
        $numberOfCharactersToRemove = $shortenedPath.Length - $MaxLength - $Ellipsis.Length
        $filenameMaxLength = $filename.Length - $numberOfCharactersToRemove
        $shortenedFilename = TruncateFileName -FileName $filename -MaxLength $filenameMaxLength
        $shortenedPath = Join-Path -Path $root -ChildPath ($dirParts + @($Ellipsis) + $shortenedFilename -join '\')
    }

    return $shortenedPath
}

function TruncateFileName {
    param(
        [string]$FileName,
        [int]$MaxLength
    )

    if ($FileName.Length -le $MaxLength) {
        return $FileName
    }
    elseif ($MaxLength -le 3) {
        return $FileName.Substring(0, $MaxLength)
    }
    else {
        $halfLength = [math]::floor(($MaxLength - 1) / 2)
        $extraChar = if ($MaxLength % 2 -eq 0) { 1 } else { 0 }
        
        $start = $FileName.Substring(0, $halfLength + $extraChar)
        $end = $FileName.Substring($FileName.Length - $halfLength, $halfLength)
        return "$start$Ellipsis$end"
    }
}
