function Get-VCCredential
{
    [CmdLetBinding()]
    [OutputType([VisualCron.NetworkCredentialClass], ParameterSetName = 'AsNetworkCredentialClass')]
    [OutputType([System.Management.Automation.PSCredential], ParameterSetName = 'AsPSCredential')]
    Param(
        [Parameter(Position=0)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Username,

        [string[]]$Domain,

        [ValidateLength(36,36)]
        [string[]]$Id,

        [switch]$MSA,

        [Parameter(ParameterSetName='AsPSCredential')]
        [switch]$AsPSCredential,

        [Parameter(ParameterSetName='AsPSCredential')]
        [switch]$UPNFormat,

        [Parameter(ValueFromPipeline)]
        [ValidateScript({$_.Connected})]
        [VisualCronAPI.Server]$VCServer = (Get-VCSelectedServer)
    )

    Process
    {
        foreach ($_vCServer in $VCServer)
        {
            $allCredentials = $_vCServer.Credentials.GetAllArray()
            
            # Decrypt Propertys 'Username','Domain' with .Decrypt Method of vcServer
            # Add as new Property called 'PSUsername','PSDomain'
            $decryptProps = @('Username','Domain')
            $allCredentials | ForEach-Object -Process {
                foreach ($prop in $decryptProps) {
                    $_ | Add-Member -NotePropertyName "PS$prop" -NotePropertyValue $_vCServer.Decrypt($_.$prop) -Force
                }
            }
            
            if($PSBoundParameters.Keys -contains "Username") {  # Filter by Username
                $allCredentials = $allCredentials | Where-Object -FilterScript {$Username -contains $_.PSUsername}
            }

            if($PSBoundParameters.Keys -contains "Domain") {  # Filter by Username
                $allCredentials = $allCredentials | Where-Object -FilterScript {$Domain -contains $_.PSDomain}
            }

            if($PSBoundParameters.Keys -contains "Id") {  # Filter by Id
                $allCredentials = $allCredentials | Where-Object -FilterScript {$Id -contains $_.Id}
            }

            if($MSA) { # Filter by IsMSA
                $allCredentials = $allCredentials | Where-Object -FilterScript {$_.IsMSA}    
            }

            # If Switch -AsPSCredential or -UPNFormat is set, convert VisualCron.NetworkCredentialClass to PSCredential
            if( $PSCmdlet.ParameterSetName -eq 'AsPSCredential') {
                
                $allCredentials = $allCredentials | ForEach-Object -Process {                    
                    
                    if($UPNFormat) {
                        # If Domain is given, add "@DOMAIN" as username postfix
                        $postfix = ''
                        if(-Not [String]::IsNullOrEmpty($_.PSDomain)) {
                            $postfix = "@$($_.PSDomain)"
                        }
                        $username = "$($_.PSUsername)$($postfix)"
                    } else {
                        # If Domain is given, add "DOAMIN\" as username prefix
                        $prefix = ''
                        if(-Not [String]::IsNullOrEmpty($_.PSDomain)) {
                            $prefix = "$($_.PSDomain)\"
                        }
                        $username = "$($prefix)$($_.PSUsername)"   
                    }
                    
                    # Decrpyt Credential Password using VCServer .Decrypt method and copnvert it to secure string
                    $secPwd = (ConvertTo-SecureString -AsPlainText ($_vCServer.Decrypt($_.Password)) -Force)
                    
                    # create PSCredential obj
                    New-Object System.Management.Automation.PSCredential($username, $secPwd)   
                }    
            }
            # Output Credentials
            $allCredentials | Add-GetVCServerMethod -VCServer $_vCServer
            $allCredentials | Write-Output
        }
    }
}

function Copy-VCCredential
{
    [CmdLetBinding()]
    Param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [VisualCron.NetworkCredentialClass[]]$VCCredential,
        
        [Parameter(Mandatory)]
        [ValidateScript({$_.Connected})]
        [VisualCronAPI.Server[]]$DestinationVCServer
    )

    Process
    {
        foreach ($_vCCredential in $VCCredential)
        {
            $clone = $_vCCredential.CloneType()
            $DestinationVCServer | ForEach-Object -Process {
                $_.Credentials.Update($clone)
            }
        }
    }
}