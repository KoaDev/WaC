Import-Module PSDesiredStateConfiguration
Import-Module Hashtable-Helpers
Import-Module CompareDiff-Helpers

. $PSScriptRoot\Constants.ps1
. $PSScriptRoot\Get-DeepClone.ps1
. $PSScriptRoot\Select-DscResourceProperties.ps1

function Compare-DscResourceState
{
    [CmdletBinding()]
    param ([hashtable]$Resource)

    Write-Verbose "Comparing DSC Resource State for $($Resource | ConvertTo-Json -Depth 100)"

    $resourceClone = Get-DeepClone $resource
    $resourceClone.ModuleName = $resourceClone.ModuleName ?? $DefaultDscResourceModuleName
    $resourceClone.Property = $resourceClone.Property ?? @{}
    if ($DscResourcesDefaultProperties.ContainsKey($resourceClone.Name))
    {
        $resourceClone.Property = $DscResourcesDefaultProperties[$resourceClone.Name] + $resourceClone.Property
    }
    $resourceClone.Property.Ensure = $resourceClone.Property.Ensure ?? 'Present'
    
    try
    {
        $resourceArg = Get-DeepClone $resourceClone
        $resourceArg.Property.Remove('Ensure')

        $getResult = Invoke-DscResource @resourceArg -Method Get -Verbose:($VerbosePreference -eq 'Continue') | ConvertTo-Hashtable

        $expected = Select-DscResourceStateProperties -Resource $resourceClone
        $actual = Select-DscResourceStateProperties -Resource $getResult -ResourceName $resourceClone.Name

        if ($resourceClone.Property.Ensure -eq 'Absent' -and $getResult.Ensure -ne 'Absent')
        {
            $status = 'Unexpected'
            $diff = @{}
        }
        elseif ($resourceClone.Property.Ensure -ne 'Absent' -and $getResult.Ensure -eq 'Absent')
        {
            $status = 'Missing'
            $diff = @{}
        }
        else
        {
            if ($resourceClone.Name -eq 'Registry')
            {
                $expected.ValueData = @($expected.ValueData)
            }
            $diff = Get-Diff $expected $actual
            $diff.remove('Added')
            $isCompliant = $diff.Count -eq 0
            $status = $isCompliant ? 'Compliant' : 'NonCompliant'
        }
    }
    catch
    {
        $status = 'Error'
        $diff = @{}
    }

    $identifier = Select-DscResourceIdProperties -Resource $resourceClone

    return [ordered]@{
        Type       = $resourceClone.Name
        Identifier = $identifier
        Status     = $status
        Diff       = $diff
    }
}
