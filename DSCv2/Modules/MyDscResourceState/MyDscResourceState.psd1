@{
    RootModule        = 'MyDscResourceState.psm1'
    ModuleVersion     = '0.0.1'
    GUID              = '67f40b88-3676-4c2f-81e0-d0613b8c70c7'
    Author            = 'Guy Lescalier'
    CompanyName       = 'Unknown'
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
    VariablesToExport = @('DscResourcesIdProperties')
    AliasesToExport   = @()
}
