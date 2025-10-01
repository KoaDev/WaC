BeforeAll {
    . $PSScriptRoot\Expand-Configuration.ps1
}

Describe 'Get-PropertySets' {
 
    It 'null' {
        # Arrange
        $input = $null

        # Act
        $result = Get-PropertySets -Properties $input

        # Assert
        $result | Should -HaveCount 0
    }

    It 'liste' {
        # Arrange
        $input = @(@{ Name = 'A' }, @{ Name = 'B' })

        # Act
        $result = Get-PropertySets -Properties $input

        # Assert
        $result | Should -HaveCount 2
    }

    It "objet unique" {
        # Arrange
        $input = @{ Name = 'Test' }

        # Act
        $result = Get-PropertySets -Properties $input

        # Assert
        $result | Should -HaveCount 1
    }
}