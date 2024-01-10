Import-Module Hashtable-Helpers

. $PSScriptRoot\Constants.ps1

# TODO : Remplace les appels à Select-HashtableKeys par un appel à Get-DscResourceId
# TODO : Faire la même chose pour Get-DscResourceState
function Get-DscResourceId
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Resource
    )

    $idProperties = $DscResourcesIdProperties[$resource.Name]    
    return $resource.Property | Select-HashtableKeys -KeysArray $idProperties
}
