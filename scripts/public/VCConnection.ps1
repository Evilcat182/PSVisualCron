function Get-VCConnection
{
    [CmdLetBinding()]
    [OutputType([VisualCron.ConnectionClass])]
    
    Param(
        [Parameter(Position=0)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Name,

        [Parameter(Position=1)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Group,

        [Parameter(Position=2)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Protocol,
        
        [ValidateNotNullOrEmpty()]
        [string[]]$Id,

        [Parameter(ValueFromPipeline)]
        [ValidateScript({$_.Connected})]
        [VisualCronAPI.Server[]]$VCServer = (Get-VCSelectedServer)
    )

    Process
    {
        foreach ($_vCServer in $VCServer)
        {
            # Get all Connections from Server
            $allConn = $_vCServer.Connections.GetAllArray()
            
            # Filter for Name if Parameter is given
            if($PSBoundParameters.Keys -contains "Name") {
                $allConn = $allConn | Where-Object -FilterScript {$Name -contains $_.Name}
            }

            # Filter for Group if Parameter is given
            if($PSBoundParameters.Keys -contains "Group") {
                $allConn = $allConn | Where-Object -FilterScript {$Group -contains $_.Group}
            }

            # Filter for Group if Parameter is given
            if($PSBoundParameters.Keys -contains "Protocol") {
                $allConn = $allConn | Where-Object -FilterScript {$Protocol -contains $_.ProtocolType}
            }

            # Filter for Id if Parameter is given
            if($PSBoundParameters.Keys -contains "Id") {
                $allConn = $allConn | Where-Object -FilterScript {$Id -contains $_.Id}
            }
            $allConn | Add-GetVCServerMethod -VCServer $_vCServer
            $allConn | Write-Output
        }
    }
}

function Copy-VCConnection
{
    [CmdLetBinding( )]
    Param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [VisualCron.ConnectionClass[]]$VCConnection,
        
        [Parameter(Mandatory)]
        [ValidateScript({$_.Connected})]
        [VisualCronAPI.Server[]]$DestinationVCServer
    )

    Process
    {
        foreach ($_VCConnection in $VCConnection)
        {
            $clone = $_VCConnection.CloneType()
            $DestinationVCServer | ForEach-Object -Process {
                $_.Connections.Update($clone)
            }
        }
    }
}