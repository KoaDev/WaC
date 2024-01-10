Get-ChildItem -Path "$PSScriptRoot\*.ps1" -Exclude '*.Tests.ps1' | ForEach-Object { . $_.FullName }

# function Set-DscResourceState
# {
#     [CmdletBinding()]
#     param ([hashtable]$resource)

#     Write-Verbose "Setting DSC Resource State for $($resource | ConvertTo-Json -Depth 100)"

#     # Clone the hashtable to prevent modifying the original
#     $dscResource = $resource.Clone()
#     $dscResource.ModuleName = $dscResource.ModuleName ?? $DefaultDscResourceModuleName
    
#     $dscResource.Property.Ensure = $dscResource.Property.Ensure ?? 'Present'

#     $result = Invoke-DscResource @dscResource -Method Set -Verbose:($VerbosePreference -eq 'Continue')
#     return $result
# }


# function Compare-DscResource
# {
#     [CmdletBinding()]
#     param (
#         [hashtable]$resource,
#         [switch]$DifferentOnly
#     )

#     Write-Verbose "Comparing DSC Resource State for $($resource | ConvertTo-Json -Depth 100)"

#     # Clone the hashtable to prevent modifying the original
#     $dscResource = $resource.Clone()
#     $dscResource.ModuleName = $dscResource.ModuleName ?? $DefaultDscResourceModuleName
#     if (-not $dscResource.Property)
#     {
#         $dscResource.Property = @{}
#     }
#     $dscProperties = $dscResource.Property
    
#     # try {
#     #     Import-Module -Name $dscResource.ModuleName
#     #     $resourceInstance = New-Object -TypeName $dscResource.Name
#     #     $dscResource.Property.GetEnumerator() | ForEach-Object {
#     #         $resourceInstance.$($_.Key) = $_.Value
#     #     }

#     #     return "N/A"
#     # }
#     # catch {
#     $currentValue = Invoke-DscResource @dscResource -Method Get -Verbose:($VerbosePreference -eq 'Continue')
#     # }

#     $dscProperties.Ensure = $dscProperties.Ensure ?? 'Present'

#     switch ($resource.Name)
#     {
#         'Registry'
#         {
#             if ($currentValue.ValueData -ne $dscProperties.ValueData)
#             {
#                 return "$($resource.Name) $($dscProperties.ValueName) current value: $($currentValue.ValueData) - Desired value: $($dscProperties.ValueData)."
#             }
#             elseif (-not $DifferentOnly)
#             {
#                 return "$($resource.Name) $($dscProperties.ValueName) is in desired state."
#             }
#         }
#         { $_ -in 'MyChocolateyPackage', 'MyScoopPackage' }
#         {
#             if ($currentValue.Ensure -ne $dscProperties.Ensure)
#             {
#                 return "$($resource.Name) $($dscProperties.PackageName) is currently $($currentValue.Ensure) but desired state is $($dscProperties.Ensure)."
#             }
#             elseif ($currentValue.Version -ne $dscProperties.Version -and $currentValue.State -eq 'Stale')
#             {
#                 return "$($resource.Name) $($dscProperties.PackageName) current version: $($currentValue.Version) - Desired value: $($currentValue.LatestVersion)."
#             }
#             elseif (-not $DifferentOnly)
#             {
#                 return "$($resource.Name) $($dscProperties.PackageName) is in desired state."
#             }
#         }
#         'MyHosts'
#         {
#             if ($currentValue.Ensure -ne $dscProperties.Ensure)
#             {
#                 return "$($resource.Name) $($dscProperties.Name) is currently $($currentValue.Ensure) but desired state is $($dscProperties.Ensure)."
#             }
#             elseif (-not $DifferentOnly)
#             {
#                 return "$($resource.Name) $($dscProperties.Name) is in desired state."
#             }
#         }
#         'MyNodeVersion'
#         {
#             if (($currentValue.Ensure -eq 'Absent' -xor $dscProperties.Ensure -eq 'Absent') -or ($currentValue.Ensure -eq 'Present' -and $dscProperties.Ensure -eq 'Used'))
#             {
#                 return "$($resource.Name) $($dscProperties.Version) is currently $($currentValue.Ensure) but desired state is $($dscProperties.Ensure)."
#             }
#             elseif ($currentValue.Version -ne $dscProperties.Version -and $currentValue.State -eq 'Stale')
#             {
#                 return "$($resource.Name) $($dscProperties.Version) current version: $($currentValue.Version) - Desired value: $($currentValue.LatestVersion)."
#             }
#             elseif (-not $DifferentOnly)
#             {
#                 return "$($resource.Name) $($dscProperties.Version) is in desired state."
#             }
#         }
#         'MyWindowsFeature'
#         {
#             if ($currentValue.Ensure -ne $dscProperties.Ensure)
#             {
#                 return "$($resource.Name) $($dscProperties.Name) is currently $($currentValue.Ensure) but desired state is $($dscProperties.Ensure)."
#             }
#             elseif (-not $DifferentOnly)
#             {
#                 return "$($resource.Name) $($dscProperties.Name) is in desired state."
#             }
#         }
#         default
#         {
#             if (-not $DifferentOnly)
#             {
#                 return "*** $($resource.Name) *** is not handled."
#             }
#         }
#     }
# }

Export-ModuleMember `
    -Function Get-DscResourceState, Test-DscResourceState, Set-DscResourceState, Get-DscResourceId `
    -Variable DscResourcesIdProperties
