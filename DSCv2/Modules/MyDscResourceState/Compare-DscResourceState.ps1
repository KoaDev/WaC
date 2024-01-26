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

    Write-Verbose "Comparing DSC Resource State for $($Resource | ConvertTo-Json -EnumsAsStrings -Depth 100)"

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

        try
        {
            $originalProgressPreference = $global:ProgressPreference
            $global:ProgressPreference = 'SilentlyContinue'
            $getResult = Invoke-DscResource @resourceArg -Method Get -Verbose:($VerbosePreference -eq 'Continue') | ConvertTo-Hashtable
        }
        finally
        {
            $global:ProgressPreference = $originalProgressPreference
        }

        $shouldBePresent = $resourceClone.Property.Ensure -ne 'Absent'
        if ($DscResourcesIsPresentAction.ContainsKey($resourceClone.Name))
        {
            $isPresent = (& $DscResourcesIsPresentAction[$resourceClone.Name] $getResult)
        }
        else
        {
            $isPresent = $getResult.Ensure -ne 'Absent'
        }

        if ($shouldBePresent -and -not $isPresent)
        {
            $status = 'Missing'
            $diff = @{}
        }
        elseif (-not $shouldBePresent -and $isPresent)
        {
            $status = 'Unexpected'
            $diff = @{}
        }
        else
        {
            $expected = Select-DscResourceStateProperties -Resource $resourceClone
            $actual = Select-DscResourceStateProperties -Resource $getResult -ResourceName $resourceClone.Name
            if ($DscResourcesExpectedActualCleanupAction.ContainsKey($resourceClone.Name))
            {
                & $DscResourcesExpectedActualCleanupAction[$resourceClone.Name] $expected $actual
            }

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
        $errorMessage = $_.Exception.Message
        $diff = @{}
    }

    $identifier = Select-DscResourceIdProperties -Resource $resourceClone

    $result = [ordered]@{
        Type       = $resourceClone.Name
        Identifier = $identifier
        Status     = $status
        Diff       = $diff
    }

    if ($errorMessage)
    {
        $result.ErrorMessage = $errorMessage
    }

    return $result
}
