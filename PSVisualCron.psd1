#
# Module manifest for module 'PSVisualCron'
#
# Generated by: Schmid Thomas
#
# Generated on: 14/08/2020
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'PSVisualCron.psm1'

# Version number of this module.
ModuleVersion = '1.9910.0.3'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = '4576696c-44e4-4732-a61b-f8bd2d0bc808'

# Author of this module
Author = 'Schmid Thomas'

# Company or vendor of this module
# CompanyName = ''

# Copyright statement for this module
Copyright = '(c) Schmid Thomas. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Manage VisualCron Servers'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '5.0.0.0'

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
RequiredAssemblies = @(
    'assamblies\VisualCron.dll'
    'assamblies\VisualCronAPI.dll'
    'assamblies\CommServer.dll'
    'assamblies\CommClient.dll'
    'assamblies\CommClientCore.dll'
)

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
#ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
FormatsToProcess = @(
    'format/VisualCronAPI.Server.ps1xml',
    'format/VisualCron.JobClass.ps1xml',
    'format/VisualCron.TaskClass.ps1xml',
    'format/VisualCron.ConnectionClass.ps1xml',
    'format/VisualCron.SecUserClass.ps1xml',
    'format/VisualCron.SecGroupClass.ps1xml',
    'format/VisualCron.NetworkCredentialClass.ps1xml',
    'format/VisualCron.TaskRepositoryObjectClass.ps1xml',
    'format/VisualCron.ConditionSetClass.ps1xml',
    'format/VisualCron.UserVariableClass.ps1xml'
)

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @(
    "Add-VCUser"
    "Connect-VCServer"
    "Copy-VCCondition"
    "Copy-VCConnection"
    "Copy-VCCredential"
    "Copy-VCJob"
    "Copy-VCTaskRepository"
    "Copy-VCUser"
    "Copy-VCUserGroup"
    "Disconnect-VCServer"
    "Get-VCCondition"
    "Get-VCConnection"
    "Get-VCCredential"
    "Get-VCJob"
    "Get-VCJobVariable"
    "Get-VCSelectedServer"
    "Get-VCServer"
    "Get-VCServerSetting"
    "Get-VCTask"
    "Get-VCTaskRepository"
    "Get-VCUser"
    "Get-VCUserGroup"
    "Get-VCUserVariable"
    "Get-VCStatus"
    "New-VCUserVariable"
    "Set-VCJob"
    "Set-VCJobVariable"
    "Set-VCSelectedServer"
    "Set-VCServerSetting"
    "Set-VCUser"
    "Set-VCUserVariable"
    "Start-VCJob"
    "Start-VCServer"
    "Stop-VCServer"
    "Stop-VCJob"
    "Remove-VCJob"
    "Remove-VCUser"
)

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
# CmdletsToExport = @()

# Variables to export from this module
# VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
# AliasesToExport = @()

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        # Tags = @()

        # A URL to the license for this module.
        # LicenseUri = ''

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/Evilcat182/PSVisualCron'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        # ReleaseNotes = ''

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}