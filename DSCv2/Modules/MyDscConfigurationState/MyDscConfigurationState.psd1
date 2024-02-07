@{
    RootModule        = 'MyDscConfigurationState.psm1'
    ModuleVersion     = '0.0.1'
    GUID              = '1cc74871-1725-4821-84f8-d1345362d581'
    Author            = 'Guy Lescalier'
    CompanyName       = 'SopraSteria'
    Copyright         = '(c) Guy Lescalier. All rights reserved.'
    FunctionsToExport = @(
        'Get-DscConfigurationState'
        'Test-DscConfigurationState'
        'Set-DscConfigurationState'
        'Compare-DscConfigurationState'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
