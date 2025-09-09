@{
    RootModule        = 'MyDscResourceState.psm1'
    ModuleVersion     = '0.0.1'
    GUID              = '6b484118-5ce9-411a-a4dc-c74fe7f36607'
    Author            = 'Guy Lescalier'
    CompanyName       = 'SopraSteria'
    Copyright         = '(c) Guy Lescalier. All rights reserved.'
    FunctionsToExport = @(
        'Get-DscResourceState'
        'Test-DscResourceState'
        'Set-DscResourceState'
        'Compare-DscResourceState'
        'Select-DscResourceIdProperties'
        'Select-DscResourceStateProperties'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    # VariablesToExport = @('DscResourcesIdProperties')
    AliasesToExport   = @()
    RequiredModules   = @(
        @{
            ModuleName    = 'PSDesiredStateConfiguration'
            ModuleVersion = '2.0.7'
        }
        'Hashtable-Helpers'
        'CompareDiff-Helpers'
    )
}
