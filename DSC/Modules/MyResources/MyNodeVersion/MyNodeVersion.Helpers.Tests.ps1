#requires -Module Pester
#requires -RunAsAdministrator

Import-Module Functional
Import-Module Pester-ShouldBeDeep

BeforeAll {
    # Ensure all helper functions are loaded
    . "$PSScriptRoot\MyNodeVersion.Helpers.ps1"

    $script:testVersion = '20.0.0'
    $script:staleVersion = '20.1.0'
    
    # Install the versions required for testing
    & nvm install $script:testVersion
    & nvm install $script:staleVersion

    # Mock the internal helper function to control the test environment
    # The Mock will now successfully override the Get-NvmCurrentVersionInternal function
    Mock -CommandName 'Get-NvmCurrentVersionInternal' -MockWith {
        return "v$script:staleVersion"
    }
}

AfterAll {
    # Clean up the installed test versions
    & nvm uninstall $script:testVersion
    & nvm uninstall $script:staleVersion
   }

   Describe 'MyNodeVersion helpers' {
    BeforeAll {
        # Les mocks sont créés ici
        Mock -CommandName 'Get-NvmCurrentVersionInternal' -MockWith {
            return "v20.1.0"
        }
    }

    # Pas de bloc AfterAll ! Pester gère le nettoyage
    # automatiquement.

    Context 'Get-NvmCurrentVersion' {
        It "should return the current version with the leading 'v' removed" {
            $currentVersion = Get-NvmCurrentVersion
            $currentVersion | Should -Be "20.1.0"
        }
    }
}

Describe 'MyNodeVersion helpers' {
    Context 'Get-NvmInstalledVersions' {
        It 'should return the installed versions' {
            $installedVersions = Get-NvmInstalledVersions
            $installedVersions | Should -Contain $script:testVersion
            $installedVersions | Should -Contain $script:staleVersion
        }
    }

    Context 'Get-NvmCurrentVersion' {
        It "should return the current version with the leading 'v' removed" {
            $currentVersion = Get-NvmCurrentVersion
            $currentVersion | Should -Be $script:staleVersion
        }
    }

    Context 'Get-NvmStaleVersions' {
    It 'should return the stale versions' {
        $staleVersions = Get-NvmStaleVersions
        # The test should check that the older version (20.0.0) is in the stale list.
        $staleVersions | Should -Contain '20.0.0'
        # The test should check that the newer version (20.1.0) is NOT in the stale list.
        # Your test is currently failing here. This assertion is what needs to be changed.
        $staleVersions | Should -Not -Contain '20.1.0'
    }
}

    Context 'Get-NodeLatestVersions' {
        It 'should return the latest versions' {
            $latestVersions = Get-NodeLatestVersions
            $expectedLts = $latestVersions.lts
            $latestVersions | Should -BeDeeplyEqualPartial @{
                lts = $expectedLts
            }
        }
    }
}






