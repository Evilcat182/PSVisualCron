function Get-VCUserGroup
{
    [CmdLetBinding(DefaultParameterSetName='none')]
    [OutputType([VisualCron.SecGroupClass])]
    Param(
        [Parameter(Position=0)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Name,

        [ValidateLength(36,36)]
        [string[]]$Id,

        [Parameter(ParameterSetName='defaultGroups')]
        [switch]$DefaultGroups,

        [Parameter(ParameterSetName='customGroups')]
        [switch]$CustomGroups,

        [Parameter(ValueFromPipeline)]
        [ValidateScript({$_.Connected})]
        [VisualCronAPI.Server[]]$VCServer = (Get-VCSelectedServer)
    )

    Process
    {
        foreach ($_vCServer in $VCServer)
        {
            # Get all Usergroups and filter result, based on given Parameters
            $allUserGroups = $_vCServer.Permissions.GetAllUserGroups()

            if($PSBoundParameters.Keys -contains "Name") {  # Filter by Name
                $allUserGroups = $allUserGroups | Where-Object -FilterScript {$Name -contains $_.Name}
            }

            if($PSBoundParameters.Keys -contains "Id") {  # Filter by Id
                $allUserGroups = $allUserGroups | Where-Object -FilterScript {$Id -contains $_.Id}
            }

            if($DefaultGroups) {  # Filter only show default Usergroups
                $allUserGroups = $allUserGroups | Where-Object -FilterScript {$_.DefaultGroup}  
            }

            if($CustomGroups) { # Filter only show non default Usergroups
                $allUserGroups = $allUserGroups | Where-Object -FilterScript {-Not $_.DefaultGroup}  
            }

            $allUserGroups | Add-GetVCServerMethod -VCServer $_vCServer
            # Output Users
            $allUserGroups | Write-Output
        }
    }
}

function Copy-VCUserGroup
{
    [CmdLetBinding()]
    Param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [VisualCron.SecGroupClass[]]$VCUserGroup,
        
        [Parameter(Mandatory)]
        [ValidateScript({$_.Connected})]
        [VisualCronAPI.Server[]]$DestinationVCServer
    )

    Process
    {
        foreach ($_vCUserGroup in $VCUserGroup)
        {
            $clone = $_vCUserGroup.CloneType()
            $DestinationVCServer | ForEach-Object -Process {
                $_.Permissions.UpdateGroup($clone)
            }
        }
    }
}
