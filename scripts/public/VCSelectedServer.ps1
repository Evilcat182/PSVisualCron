function Get-VCSelectedServer
{
    <#

    .SYNOPSIS
        Get VC Default Server

    .DESCRIPTION
        The VC Default or VC SelectedServer is the last successfull connected VCServer.
        If Get-VCJob is executed without specifying the -VCServer Parameter, VCServer is set to VCSelectedServer

    .OUTPUTS
        VisualCronAPI.Server

    .EXAMPLE
        Get-VCSelectedServer

    #>

    [CMDletBinding()]
    [OutputType([VisualCronAPI.Server])]
    Param()

    Get-VCServer -ID $script:_VCSelectedServer.ID | Select -First 1 | Write-Output
}

function Set-VCSelectedServer
{
    <#

    .SYNOPSIS
        Set VC Default Server

    .DESCRIPTION
        The VC Default or VC SelectedServer is the last successfull connected VCServer.
        With this CMDLet you can change the VC SelectedServer
        If Get-VCJob is executed without specifying the -VCServer Parameter, VCServer is set to VCSelectedServer

    .PARAMETER VCServer
        THe VCServer you would like to set as the default VC Server
    
    .INPUTS
        VisualCronAPI.Server

    .OUTPUTS
        VisualCronAPI.Server

    .EXAMPLE
        Get-VCServer -Id 3 | Set-VCSelectedServer

    #>

    [CMDLetBinding()]
    Param(
        [Parameter(Mandatory,Position=0,ValueFromPipeline)]
        [VisualCronAPI.Server]$VCServer
    )

    $srv = Get-VCServer -ID $VCServer.ServerId | Select -First 1

    if(-Not $srv) {
        Write-Error "VC Server `"$($VCServer.Name)`" does not exist."
        return
    }

    $script:_VCSelectedServer = $srv
    $script:_VCSelectedServer | Write-Output
}