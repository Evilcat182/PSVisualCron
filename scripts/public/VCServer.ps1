function Connect-VCServer
{
     <#
    .SYNOPSIS
        Connects a VC Server

    .DESCRIPTION
        Will connect to a VCServer.
        Connection can be local or Remote.
        Connection can use a local VCUser or a ADUser

    .PARAMETER Computername
        Remote Server Address

    .PARAMETER Port
        Port to connect to

    .PARAMETER Username
        Name of local VCUser used for Login
    
    .PARAMETER Password
        Password of local VCUser used for Login
    
    .PARAMETER Credential
        PSCredentialObject of local VCUser used for Login.
        Does not work with AD Credentials

    .PARAMETER UseADLogon
        Connection will use AD Logon with current Credentials the script is running with

    .PARAMETER UseVCLogon
        Connection will use a local VC User for Login

    .PARAMETER UseCompression
        Connection will be compressed

    .OUTPUTS
        VisualCronAPI.Server

    .EXAMPLE
        Connect-VCServer

    .EXAMPLE
        Connect-VCServer -Computername lhgsvserver01

    .EXAMPLE
        Connect-VCServer -Username "test" -Password "test"
    #>

    [CmdLetBinding(
        DefaultParameterSetName='ADLogonSSO'
    )]
    [OutputType([VisualCronAPI.Server])]
    Param(
        [Parameter(ParameterSetName='ADLogonSSO',Position = 0)]
        [Parameter(ParameterSetName='VCLogonUserPass', Position = 0)]
        [Parameter(ParameterSetName='VCLogonCredential',Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Computername,

        [ValidateNotNullOrEmpty()]
        [int]$Port = 16444,

        [Parameter(ParameterSetName='VCLogonUserPass')]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        [Parameter(ParameterSetName='VCLogonUserPass')]
        [AllowEmptyString()]
        [string]$Password,

        [Parameter(ParameterSetName='VCLogonCredential')]
        [ValidateNotNullOrEmpty()]
        [PSCredential]$Credential,

        [Parameter(ParameterSetName='ADLogonSSO')]
        [switch]$UseADLogon,

        [Parameter(ParameterSetName='ADLogonSSO')]
        [ValidateSet("DnsIdentity","DefaultIdentity","UpnIdentity","SpnIdentity")]
        [string]$IdentityType = 'SpnIdentity',

        [Parameter(ParameterSetName='ADLogonSSO')]
        [string]$PrincipalName = '.',

        [Parameter(ParameterSetName='VCLogonCredential')]
        [Parameter(ParameterSetName='VCLogonUserPass')]
        [switch]$UseVCLogon,

        [switch]$UseCompression
    )

    $vcConn = New-Object VisualCronAPI.Connection
    $vcConn.Port = $Port
    $vcConn.UseCompression = $UseCompression
    
    if($PSBoundParameters.ContainsKey("ComputerName")) {
        $vcConn.ConnectionType = "Remote"
        $vcConn.Address = $Computername   
    } else {
        $vcConn.ConnectionType = "Local"
        $Computername = $env:COMPUTERNAME  
    }

    ### CREATE NAME ###
    $Name = if($PSCmdlet.ParameterSetName -eq 'VCLogonUserPass') {
        "$($vcConn.UserName)@$($vcConn.Address)"    
    } else {
        "$([Environment]::UserName)@$($vcConn.Address)"
    }
    ### TEST IF CONNECTION WITH GIVEN NAME IS ALREADY ESTABLISHED ###
    if(Get-VCServer -Name $Name) {
        Write-Error "VC-Server connection `"$Name`" already exists."
        return
    }

    if(@('VCLogonCredential') -contains $PSCmdlet.ParameterSetName) {
        
        $vcConn.UserName = $Credential.UserName
        $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password)
        $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
        $vcConn.PassWord = $Password
        $vcConn.UseADLogon = $false
    }
    elseif($PSCmdlet.ParameterSetName -eq 'VCLogonUserPass') {
        $vcConn.UserName = $Username
        $vcConn.PassWord = $Password
        $vcConn.UseADLogon = $false
    }
    else {
        $vcConn.UseADLogon = $true
        $vcConn.AuthType = "AD"
        $vcConn.EndpointIdentityType = $IdentityType
        $vcConn.PrincipalName = $PrincipalName
    }
   
    Try {
        $vcServer = $script:_VCClient.Connect($vcConn)
    } catch {
         throw
    }

    $vcServer = $Script:_VCClient.Servers.GetByServerId($vcServer.ServerId)
    $vcServer | Add-Member -Force -NotePropertyName Name -NotePropertyValue $Name
    $vcServer | Add-Member -Force -MemberType AliasProperty -Name Id -Value ServerId
    $vcServer | Add-Member -Force -MemberType ScriptProperty -Name Address -Value {$this.Connection.Address}

    $Script:_VCSelectedServer = $vcServer
    $vcServer | Write-Output
}

function Disconnect-VCServer
{
     <#

    .SYNOPSIS
        Disconnect a VC Server

    .DESCRIPTION
        Will disconnect a connection to a VCServer.
        If no specifiv VCServer is given, using the -VCServer Parameter, the default
        selected VCServer will be disconnected

    .PARAMETER VCServer
        The VCServer that will be disconnected

    .PARAMETER Name
        The VCServer with that Name will be disconnected
    
    .PARAMETER Id
        The VCServer with that Id will be disconnected

    .INPUTS
        VisualCronAPI.Server

    .OUTPUTS
        VisualCronAPI.Server

    .EXAMPLE
        Disconnect-VCServer

    .EXAMPLE
        Disconnect-VCServer -Id 1

    .EXAMPLE
        Get-VCServer | Disconnect-VCServer

    #>

    [CmdLetBinding(
        DefaultParameterSetName='ByObject'
    )]
    [OutputType([VisualCronAPI.Server[]])]
    Param(
        [Parameter(ValueFromPipeline,ParameterSetName='ByObject')]
        [VisualCronAPI.Server[]]$VCServer = $Script:_VCSelectedServer,

        [Parameter(ParameterSetName='ByName')]
        [string[]]$Name,

        [Parameter(ParameterSetName='ByID')]
        [GUID[]]$ID
    )

    Begin 
    {
        if($PSCmdlet.ParameterSetName -eq "ByName") {
            $VCServer = $Script:_VCClient.Servers.GetAllArray | Where-Object {$Name -contains $_.Name}
        } elseif($PSCmdlet.ParameterSetName -eq "ByID") {
            $VCServer = $Script:_VCClient.Servers.GetAllArray | Where-Object {$ID -contains $_.ID}   
        }
    }

    Process
    {
        foreach ($_vcServer in $VCServer)
        {
            $disconnected = $_vcServer.Disconnect()
            
            if($disconnected) {
                Write-Verbose "VC-Server `"$($_vcServer.Connection.Address)`" disconnected"
                $obj | Write-Output
            }
        }
    }

    End 
    {
        $allSrv = @(Get-VCServer)
        if($allSrv.Count -ne 0) {
            if(-Not (Get-VCSelectedServer)) {
                Set-VCSelectedServer -VCServer $allSrv[0]
                Write-Warning "Selected VC-Server was disconnected. New selected Server automatically set to `"$($allSrv[0].Name)`".`nTo change selected Server use `"Set-VCSelectedServer`" CmdLet."    
            }  
        }
    }
}

function Get-VCServer
{
    <#

    .SYNOPSIS
        Get all VCServers you have connected

    .DESCRIPTION
        If a VCServer is Connected using Connect-VCServer, it will be added to a VCServer List.
        With Get-VCServer you can see this List

    .PARAMETER Name
        Get only VCServer with the specified Name

    .PARAMETER Id
        Get only VCServer with the specified Id

    .PARAMETER Connected
        Get only connected VCServers

    .OUTPUTS
        VisualCronAPI.Server

    .EXAMPLE
        Get-VCServer

    .EXAMPLE
        Get-VCServer -Id 1 -Connected

    #>

    [CmdLetBinding(
        DefaultParameterSetName='All'
    )]
    [OutputType([VisualCronAPI.Server[]])]
    Param(
        [Parameter(ParameterSetName='ByName')]
        [string[]]$Name,

        [Parameter(ParameterSetName='ByID')]
        [Guid[]]$Id,

        [switch]$Connected
    )
    
    if($PSCmdlet.ParameterSetName -eq "ByName") {
        $srv = $_VCClient.Servers.GetAllArray | Where-Object {$Name -contains $_.Name}
    } elseif($PSCmdlet.ParameterSetName -eq "ByID") {
        $srv = $_VCClient.Servers.GetAllArray | Where-Object {$ID -contains $_.Id}
    } else {
        $srv = $_VCClient.Servers.GetAllArray
    }

    if($Connected) {
        $srv = $srv | Where-Object {$_.Connected}
    }

    $srv | Write-Output
}

function Start-VCServer
{
    <#

    .SYNOPSIS
        Starts a VC Server

    .DESCRIPTION
        Set Serverstate to Server ON. All Jobs will trigger as usual

    .PARAMETER VCServer
        Connected VC Server

    .INPUTS
        VisualCronAPI.Server

    .OUTPUTS
        System.Boolean

    .EXAMPLE
        Connect-VCServer | Start-VCServer

    #>

    [CmdLetBinding()]
    [OutputType([Boolean])]
    Param(
        [Parameter(ValueFromPipeline)]
        [ValidateScript({$_.Connected})]
        [VisualCronAPI.Server[]]$VCServer = $Script:_VCSelectedServer
    )
   
    Process
    {
        foreach ($_vcServer in $VCServer)
        {
            if($_vcServer.On) {
                Write-Warning "VC Server `"$($_vcServer.Address)`" already was started"
                $result = $true
            } else {
                $result = $_vcServer.Start() # Will return True on success
            }
            $result | Write-Output
        }
    }
}

function Stop-VCServer
{
    <#

    .SYNOPSIS
        Stops a VC Server

    .DESCRIPTION
        Set Serverstate to Server OFF. Running Jobs will finish, but no new Jobs will trigger when Server is Off.

    .PARAMETER VCServer
        Connected VC Server

    .INPUTS
        VisualCronAPI.Server

    .OUTPUTS
        System.Boolean

    .EXAMPLE
        Connect-VCServer | Stop-VCServer

    #>

    [CmdLetBinding()]
    [OutputType([Boolean])]
    Param(
        [Parameter(ValueFromPipeline)]
        [ValidateScript({$_.Connected})]
        [VisualCronAPI.Server[]]$VCServer = $Script:_VCSelectedServer
    )
   
    Process
    {
        foreach ($_vcServer in $VCServer)
        {
            if($_vcServer.On) {
                $result = -Not $_vcServer.Stop() # Will return False on success
            } else {
                Write-Warning "VC Server `"$($_vcServer.Address)`" already was stopped"
                $result = $true
            }
            
            $result | Write-Output
        }
    }
}