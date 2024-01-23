Get-ChildItem -Path "$PSScriptRoot\*.ps1" -Exclude '*.Tests.ps1' | ForEach-Object { . $_.FullName }

# function Set-DscConfigurationState
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

# function Test-DscConfigurationState
# {
#     [CmdletBinding()]
#     param ([hashtable]$resource)

#     Write-Verbose "Testing DSC Resource State for $($resource | ConvertTo-Json -Depth 100)"

#     $dscResource = $resource.Clone()
#     $dscResource.ModuleName = $dscResource.ModuleName ?? $DefaultDscResourceModuleName
#     if (-not $dscResource.Property)
#     {
#         $dscResource.Property = @{}
#     }
#     $dscProperties = $dscResource.Property
    
#     $isCurrent = Invoke-DscResource @dscResource -Method Test -Verbose:($VerbosePreference -eq 'Continue')

#     # Return the necessary fields as an array
#     return @(
#         $resource.Name
#         switch ($resource.Name)
#         {
#             'Registry'
#             {
#                 $dscProperties.ValueName 
#             }
#             'VSComponents'
#             {
#                 'Visual Studio'
#             }
#             'WindowsOptionalFeature'
#             {
#                 $dscProperties.Name 
#             }
#             'WingetPackage'
#             {
#                 $dscProperties.Id 
#             }
#             'MyCertificate'
#             {
#                 Get-ShortenedPath -Path $dscProperties.Path -MaxLength 45 
#             }
#             'MyChocolatey'
#             {
#                 'Chocolatey' 
#             }
#             'MyChocolateyPackage'
#             {
#                 $dscProperties.PackageName 
#             }
#             'MyHosts'
#             {
#                 $dscProperties.Name
#             }
#             'MyNodeVersion'
#             {
#                 $dscProperties.Version 
#             }
#             'MyScoop'
#             {
#                 'Scoop' 
#             }
#             'MyScoopPackage'
#             {
#                 $dscProperties.PackageName 
#             }
#             'MyWindowsDefenderExclusion'
#             {
#                 $dscProperties.Type + ' - ' + $dscProperties.Value 
#             }
#             'MyWindowsFeature'
#             {
#                 $dscProperties.Name 
#             }
#             'MyWindowsOptionalFeatures'
#             {
#                 $dscProperties.FeatureNames -join ',' 
#             }
#             default
#             {
#                 'Not handled' 
#             }
#         }
#         $isCurrent.InDesiredState
#     )
# }

Export-ModuleMember `
    -Function Get-DscConfigurationState, Test-DscConfigurationState, Set-DscConfigurationState, Compare-DscConfigurationState
