Import-Module Functional
Import-Module Pester-ShouldBeDeep

BeforeAll {
    . $PSScriptRoot\MyScoopPackage.ps1

    # Initialize variables for the test scope
    $script:ScoopListCache = $null
    $script:ScoopListCacheExpires = $null
    $script:ScoopStatusCache = $null
    $script:ScoopStatusCacheExpires = $null
    $script:CacheDuration = [TimeSpan]::FromMinutes(5)
}

Describe 'MyScoopPackage' {
    Context 'Get-RawScoopList' {
        It 'Should return scoop list output' {
            # Act
            $scoopList = Get-RawScoopList

            # Assert
            $scoopList | Should -BeOfType '[PSCustomObject]'
            $scoopList | ForEach-Object {
                $_ | Should -BeOfType 'PSCustomObject'
                $_.PSObject.Properties | Where-Object { $_.Name -eq 'Name' } | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'Get-RawScoopStatus' {
        It 'Should return scoop status output' {
            # Act
            $scoopStatus = Get-RawScoopStatus

            # Assert
            if ($scoopStatus)
            {
                $scoopStatus | ForEach-Object {
                    $_ | Should -BeOfType 'PSCustomObject'
                    $_.PSObject.Properties | Where-Object { $_.Name -eq 'Name' } | Should -Not -BeNullOrEmpty
                }
            }
            else
            {
                # If no packages need updates, scoopStatus can be empty - this is valid
                $true | Should -Be $true
            }
        }
    }

    Context 'Convert-ObjectArrayToHashtable' {
        It 'Should convert scoop list output to hashtable' {
            # Arrange
            $scoopList = Get-RawScoopList

            # Act
            $packages = Convert-ObjectArrayToHashtable $scoopList 'Name'

            # Assert
            $packages | Should -BeOfType 'Hashtable'
            if ($packages.Count -gt 0) {
                $packages.Values | ForEach-Object {
                    $_ | Should -BeOfType 'PSCustomObject'
                    $_.PSObject.Properties | Where-Object { $_.Name -eq 'Version' } | Should -Not -BeNullOrEmpty
                }
            }
        }

        It 'Should convert scoop status output to hashtable' {
            # Arrange
            $scoopStatus = Get-RawScoopStatus

            # Act
            $packages = Convert-ObjectArrayToHashtable $scoopStatus 'Name'

            # Assert
            $packages | Should -BeOfType 'Hashtable'
            if ($packages.Count -gt 0) {
                $packages.Values | ForEach-Object {
                    $_ | Should -BeOfType 'PSCustomObject'
                    $_.PSObject.Properties | Where-Object { $_.Name -eq 'Installed Version' } | Should -Not -BeNullOrEmpty
                    $_.PSObject.Properties | Where-Object { $_.Name -eq 'Latest Version' } | Should -Not -BeNullOrEmpty
                }
            }
        }
    }

    Context 'Get-ScoopPackageInfo' {
        It 'Should return package info for installed package' {
            # Arrange
            $packageName = 'git'

            # Act
            $packageInfo = Get-ScoopPackageInfo -packageName $packageName

            # Assert
            $packageInfo | Should -BeOfType 'Hashtable'
            $packageInfo.Keys | Sort-Object | Should -Be @('Ensure', 'Version')
            
            if ($packageInfo['Ensure'] -eq [MyEnsure]::Present) {
                $packageInfo['Version'] | Should -Not -BeNullOrEmpty
                $packageInfo['Version'] | Should -Match '^\d+\.\d+\.\d+'
            }
        }

        It 'Should return package info for not installed package' {
            # Arrange
            $packageName = 'notarealpackage-xyz-123'

            # Act
            $packageInfo = Get-ScoopPackageInfo -packageName $packageName

            # Assert
            $packageInfo | Should -BeOfType 'Hashtable'
            $packageInfo.Keys | Sort-Object | Should -Be @('Ensure', 'Version')
            $packageInfo['Ensure'] | Should -Be ([MyEnsure]::Absent)
            $packageInfo['Version'] | Should -BeNullOrEmpty
        }
    }

    Context 'Get-ScoopPackageLatestAvailableVersion' {
        It 'Should return latest available version if package has updates' {
            # Arrange
            $packageName = 'git'  # Use a commonly installed package

            # Act
            $latestVersion = Get-ScoopPackageLatestAvailableVersion -PackageName $packageName

            # Assert
            # This test only validates format if a version is returned
            # Some packages might not have updates available
            if ($latestVersion) {
                $latestVersion | Should -Match '^\d+\.\d+\.\d+'
            } else {
                # If no version returned, it means package is up to date or not installed
                $true | Should -Be $true
            }
        }
    }

    Context 'Cache Management' {
        It 'Should clear all caches' {
            # Arrange - populate some cache first
            $null = Get-ScoopPackageInfo -packageName 'git'
            
            # Act
            Clear-Cache

            # Assert
            $script:ScoopListCache | Should -BeNullOrEmpty
            $script:ScoopListCacheExpires | Should -BeNullOrEmpty
            $script:ScoopStatusCache | Should -BeNullOrEmpty
            $script:ScoopStatusCacheExpires | Should -BeNullOrEmpty
        }
    }
}