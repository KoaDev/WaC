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
    if ($DscResourcesWithoutEnsure -notcontains $resourceClone.Name)
    {
        $resourceClone.Property.Ensure = $resourceClone.Property.Ensure ?? 'Present'
    }
    
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

            if ($DscResourcesPostInvokeAction.ContainsKey($resourceClone.Name))
            {
                & $DscResourcesPostInvokeAction[$resourceClone.Name] $actual
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

    return [PSCustomObject]@{
        Type         = $resourceClone.Name
        Identifier   = $identifier
        Status       = $status
        Diff         = $diff
        ErrorMessage = $errorMessage
    }
}
