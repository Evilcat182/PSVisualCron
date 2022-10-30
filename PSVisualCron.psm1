### SAVE ERRORACTIONPREFERENCE AND SET ERRORACTIONPREFERENCE TO STOP ###
$oldEA = $ErrorActionPreference
$ErrorActionPreference = "Stop"

### LOAD PUBLIC + PRIVATE FUNCTIONS USING DOT SOURCING ###
$publicScripts = @(Get-ChildItem -Path $PSScriptRoot\scripts\public\*.ps1 -ErrorAction SilentlyContinue)
$privateScripts = @(Get-ChildItem -Path $PSScriptRoot\scripts\private\*.ps1 -ErrorAction SilentlyContinue)
@($publicScripts + $privateScripts) | ForEach-Object {
    . $_.FullName
}

### MODULE VARIABLES ###
$script:_VCClient = New-Object VisualCronAPI.Client
$script:_VCSelectedServer = $null

### SET ERRORACTIONPREFERENCE TO OLD VALUE ###
$ErrorActionPreference = $oldEA