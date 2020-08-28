@{
    ModuleVersion = '1.2.0'
    GUID = 'e3e7850e-2f24-4173-8268-c2a29ec35750'
    ModuleToProcess = 'icinga-powershell-plugins.psm1'
    Author = 'Lord Hepipud'
    CompanyName = 'Icinga GmbH'
    Copyright = '(c) 2020 Icinga GmbH | GPLv2'
    Description = 'A collection of Icinga PowerShell Plugins for the Icinga PowerShell Framework'
    PowerShellVersion = '4.0'
    RequiredModules = @(@{ModuleName = 'icinga-powershell-framework'; ModuleVersion = '1.2.0' })
    FunctionsToExport = @('*')
    CmdletsToExport = @('*')
    VariablesToExport = '*'
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @( 'icinga','icinga2','monitoringplugins','icingaplugins','icinga2plugins','windowsplugins','icingawindows')
            LicenseUri = 'https://github.com/Icinga/icinga-powershell-plugins/blob/master/LICENSE'
            ProjectUri = 'https://github.com/Icinga/icinga-powershell-plugins'
            ReleaseNotes = 'https://github.com/Icinga/icinga-powershell-plugins/releases'
        };
        Version = 'v1.2.0';
    }
    HelpInfoURI = 'https://github.com/Icinga/icinga-powershell-plugins'
}
