function Get-VCJob
{
     <#

    .SYNOPSIS
        Get a VC Job

    .DESCRIPTION
        Will return VCJob on given VCServer

    .PARAMETER Name
        Only get VCJobs that match given Name

    .PARAMETER Group
        Only get VCJobs that are Member of given Group
    
    .PARAMETER Id
        Only get VCJobs with specific Id

    .PARAMETER Running
        Only get running VC Jobs
    
    .PARAMETER VCServer
        Specify the VCServer from where the VCJobs will be listed

    .INPUTS
        VisualCronAPI.Server

    .OUTPUTS
        VisualCronAPI.JobClass

    .EXAMPLE
        Get-VCJob
        Gets all VCJobs from last connected VCServer

    .EXAMPLE
       Get-VCJob -Group 'Test' -Running
       Gets all running VCJobs from Group 'Test' from last connected VCServer

    .EXAMPLE
        Get-VCServer -Id 2 | Get-VCJob -Name 'Maintenance','Startup'
        Get VCJob with Name 'Maintenance' or 'Startup' from VCServer with Id 2

    #>

    [CmdLetBinding()]
    [OutputType([VisualCron.JobClass])]
    Param(
        [Parameter(Position=0)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Name,

        [Parameter(Position=1)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Group,

        [ValidateLength(36,36)]
        [string[]]$Id,

        [switch]$Running,

        [Parameter(ValueFromPipeline)]
        [ValidateScript({$_.Connected})]
        [VisualCronAPI.Server[]]$VCServer = (Get-VCSelectedServer)
    )

    Process
    {
        foreach ($_vCServer in $VCServer)
        {
            # Get all VCJobs and filter result, based on given Parameters
            $allJobs = $_vCServer.Jobs.GetAllArray()

            if($PSBoundParameters.Keys -contains "Name") { # Filter by Name
                $allJobs = $allJobs | Where-Object -FilterScript {$Name -contains $_.Name}
            }

            if($PSBoundParameters.Keys -contains "Group") { # Filter by Group
                $allJobs = $allJobs | Where-Object -FilterScript {$Group -contains $_.Group}
            }

            if($PSBoundParameters.Keys -contains "Id") { # Filter by Id
                $allJobs = $allJobs | Where-Object -FilterScript {$Id -contains $_.Id}
            }

            $allJobs | Add-GetVCServerMethod -VCServer $_vCServer
            $allJobs | Add-VCJobProperties

            # If Param Running is set, filter Output for Jobs that a currently running
            if($Running) {
                $allJobs = $allJobs | Where-Object -FilterScript {$_.Status -eq 'Running'}    
            }

            # Output Jobs
            $allJobs | Write-Output
        }
    }
}

function Set-VCJob
{
    [CmdLetBinding()]
    [OutputType([VisualCron.JobClass])]
    Param(
        [Parameter(Position=0)]
        [ValidateNotNullOrEmpty()]
        [ValidateLength(1,256)]
        [string]$Name,

        [Parameter(Position=1)]
        [ValidateNotNullOrEmpty()]
        [ValidateLength(1,256)]
        [string]$Group,

        [bool]$Enabled,

        [Parameter(Mandatory,ValueFromPipeline)]
        [VisualCron.JobClass[]]$Job
    )

    Process
    {
        foreach ($_job in $Job)
        {
            $vcServer = $_job.GetVCServer()
            $_job.Name = if($PSBoundParameters.Keys -contains 'Name') { $Name } else { $_job.Name }
            $_job.Group = if($PSBoundParameters.Keys -contains 'Group') { $Group } else { $_job.Group }

            $vcServer.Jobs.Update($_job) | Out-Null

            if($PSBoundParameters.Keys -contains 'Enabled') {
                if($Enabled) {$vcServer.Jobs.Activate($_job) | Out-Null}
                else {$vcServer.Jobs.Deactivate($_job) | Out-Null }
            }

            $vcServer | Get-VCJob -Id $_job.Id | Write-Output
        }
    }
}

function Remove-VCJob
{
    [CmdLetBinding( )]
    Param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [VisualCron.JobClass[]]$Job
    )

    Process 
    {
        foreach ($_job in $Job)
        {
            $ErrorActionPreference = 'Stop'
            $vcServer = $_job.GetVCServer()
            $vcServer.Jobs.Remove($_job)
        }        
    }
}

function Start-VCJob
{
    [CmdLetBinding()]
    [OutputType([VisualCron.JobRunResultClass])]
    Param(
        [Parameter(ValueFromPipeline,Mandatory)]
        [VisualCron.JobClass[]]$Job,

        [switch]$WithoutConditions,

        [switch]$Async,

        [ValidateLength(36,36)]
        [string]$FromTaskId,

        [ValidateLength(36,36)]
        [string]$ToTaskId
    )

    Process 
    {
        foreach ($_job in $Job)
        {
            # Refresh Job and get VCServer from JOB
            $_job = Get-VCJob -id $_job.Id
            $vCServer = $_job.GetVCServer()
            
            if($PSBoundParameters.Keys -contains "FromTaskId" -and $PSBoundParameters.Keys -contains "ToTaskId") {
                # Run Job, From and To Task ID is given
                $vCServer.Jobs.Run($_job,(-Not $WithoutConditions.IsPresent),(-Not $Async),$true,$FromTaskId,$true,$ToTaskId) | Write-Output
            } 
            elseif($PSBoundParameters.Keys -contains "FromTaskId") {
                # Run Job, From Task ID is given
                $VCServer.Jobs.Run($_job,(-Not $WithoutConditions.IsPresent),(-Not $Async),$true,$FromTaskId) | Write-Output    
            } 
            else {
                # Run Job, wether From nor To Task ID is given
                $VCServer.Jobs.Run($_job,(-Not $WithoutConditions.IsPresent),(-Not $Async)) | Write-Output   
            }   
        }
    }
}

function Stop-VCJob
{
    [CmdLetBinding()]
    [OutputType([VisualCron.JobRunResultClass])]
    Param(
        [Parameter(ValueFromPipeline,Mandatory)]
        [VisualCron.JobClass[]]$Job
    )

    Process 
    {
        foreach ($_job in $Job)
        {
            $vcServer = $_job.GetVCServer()
            $vcServer.Jobs.Stop($_job.Id) | Write-Output
        }
    }
}

function Copy-VCJob
{
    [CmdLetBinding()]
    Param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [VisualCron.JobClass[]]$Job,
        
        [switch]$KeepDestinationStats,

        [Parameter(Mandatory)]
        [ValidateScript({$_.Connected})]
        [VisualCronAPI.Server[]]$DestinationVCServer
    )

    Process
    {
        foreach ($_job in $Job)
        {
            foreach ($destSrv in $DestinationVCServer)
            {
                $clone = $_job.CloneType()
                
                if($KeepDestinationStats) {
                    
                    # If -KeepDestinationStats Switch is set, Get Job on Destination Server.
                    # Get all Tasks of Job on Destination Server
                    # Check if Task esists on Source & Destination Server
                    # Clone Task.Stats, so Statistiks of cloned Task is same as Statistics of Task on Destination Server
                    # Clone Statistics of Job aswell
                    
                    $destJob = $destSrv | Get-VCJob -Id $_job.Id
                    if($null -ne $destJob) {
                        # Job does exist on Desitnation Server
                        $allDestTask = $destJob | Get-VCTask
                        
                        # Loop through each Task of cloned Job
                        foreach ($t in $clone.Tasks)
                        {
                            # CHeck if Task also exists on Destination Server
                            $destTask = $allDestTask | Where-Object {$_.Id -eq $t.id}
                            if($null -ne $destTask) {
                                # Task exists, Clone statistics
                                $t.Stats = $destTask.Stats.CloneType()
                            }
                        }

                        # Clone Statistics of whole Job
                        $clone.Stats = $destJob.Stats
                    }
                }

                # Sync Clone to Destination Server
                $destSrv.Jobs.Update($clone)      
            }
        }
    }
}
