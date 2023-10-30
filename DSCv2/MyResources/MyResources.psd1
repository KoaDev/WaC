# https://github.com/craig-martin/TestModule/tree/master

@{
    ModuleVersion        = '0.0.1'
    GUID                 = 'f8618f7b-413c-4464-a391-584c6129c651'
    Author               = 'Guy Lescalier'
    CompanyName          = 'Unknown'
    Copyright            = '(c) Guy Lescalier. All rights reserved.'
    NestedModules        = @(
        'MyChocolatey\MyChocolatey.psd1'
        'MyChocolateyPackage\MyChocolateyPackage.psd1'
        'MyScoop\MyScoop.psd1'
        'MyScoopPackage\MyScoopPackage.psd1'
        'MyWindowsFeature\MyWindowsFeature.psd1'
        'MyWindowsOptionalFeatures\MyWindowsOptionalFeatures.psd1'
    )
    FunctionsToExport    = @()
    CmdletsToExport      = '*'
    VariablesToExport    = @()
    AliasesToExport      = @()
    DscResourcesToExport = @(
        'MyChocolatey'
        'MyChocolateyPackage'
        'MyScoop'
        'MyScoopPackage'
        'MyWindowsFeature'
        'MyWindowsOptionalFeatures'
    )
    PrivateData          = @{
        PSData = @{
            Tags = @(
                'DSC'
                'Resources'
            )
        }
    }
}
