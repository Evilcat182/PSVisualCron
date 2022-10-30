function Get-VCTask
{
    [CmdLetBinding()]
    [OutputType([VisualCron.TaskClass])]
    Param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [VisualCron.JobClass[]]$Job,

        [Parameter(Position=0)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Name,

        [ValidateLength(36,36)]
        [string[]]$Id,

        [switch]$Running
    )

    Process 
    {
        foreach ($_job in $Job)
        {
            $vcServer = $_job.GetVCServer()
            $allTasks = $_job.Tasks
            
            if($PSBoundParameters.Keys -contains "Name") {
                $allTasks = $allTasks | Where-Object -FilterScript {$Name -contains $_.Name}
            }

            if($PSBoundParameters.Keys -contains "Id") {
                $allTasks = $allTasks |  Where-Object -FilterScript {$Id -contains $_.Id}
            }

            $allTasks | Add-GetVCServerMethod -VCServer $vcServer
            $allTasks | Add-VCTaskProperties

            # If Param Running is set, filter Output for Tasks that a currently running
            if($Running) {
                $allTasks = $allTasks | Where-Object -FilterScript {$_.Status -eq 'Running'}       
            }

            $allTasks | Write-Output
        }        
    }
}