@{
    RootModule        = 'Hashtable-Helpers.psm1'
    ModuleVersion     = '0.0.1'
    GUID              = 'a1485411-e984-496e-87da-2603f265508c'
    Author            = 'Guy Lescalier'
    CompanyName       = 'SopraSteria'
    Copyright         = '(c) Guy Lescalier. All rights reserved.'
    FunctionsToExport = @(
        'Split-Hashtable'
        'Select-HashtableKeys'
        'ConvertTo-Hashtable'
        'Remove-EmptyArrayProperties'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
