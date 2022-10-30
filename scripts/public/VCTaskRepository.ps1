function Get-VCTaskRepository
{
    [CmdLetBinding(
        DefaultParameterSetName='none')]
    [OutputType([VisualCron.TaskRepositoryObjectClass])]
    Param(
        [Parameter(Position=0)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Name,

        [ValidateSet('Powershell','DotNetExecute')]
        [string]$TaskType,

        [ValidateLength(36,36)]
        [string[]]$Id,

        [Parameter(ValueFromPipeline)]
        [ValidateScript({$_.Connected})]
        [VisualCronAPI.Server[]]$VCServer = (Get-VCSelectedServer)
    )

    Process
    {
        foreach ($_vCServer in $VCServer)
        {
            # Get all Usergroups and filter result, based on given Parameters
            $allTaskRepos = $_vCServer.TaskRepository.GetAllArray()

            if($PSBoundParameters.Keys -contains "Name") {  # Filter by Name
                $allTaskRepos = $allTaskRepos | Where-Object -FilterScript {$Name -contains $_.Task.Name}
            }

            if($PSBoundParameters.Keys -contains "TaskType") {  # Filter by TaskType
                $allTaskRepos = $allTaskRepos | Where-Object -FilterScript {$_.Task.TaskType -eq $TaskType}
            }

            if($PSBoundParameters.Keys -contains "Id") {  # Filter by Id
                $allTaskRepos = $allTaskRepos | Where-Object -FilterScript {$Id -contains $_.Task.Id}
            }

            $allTaskRepos | ForEach-Object -Process {
                $_ | Add-Member -MemberType ScriptProperty -Name Name -Value {$this.Task.Name} -Force
                $_ | Add-Member -MemberType ScriptProperty -Name Description -Value {$this.Task.Description} -Force
                $_ | Add-Member -MemberType ScriptProperty -Name Id -Value {$this.Task.Id} -Force
                $_ | Add-Member -MemberType ScriptProperty -Name TaskType -Value {$this.Task.TaskType} -Force
            }

            $allTaskRepos | Add-GetVCServerMethod -VCServer $_VCServer
            # Output Users
            $allTaskRepos | Write-Output
        }
    }
}

function Copy-VCTaskRepository
{
    [CmdLetBinding()]
    Param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [VisualCron.TaskRepositoryObjectClass[]]$VCTaskRepository,
        
        [Parameter(Mandatory)]
        [ValidateScript({$_.Connected})]
        [VisualCronAPI.Server[]]$DestinationVCServer
    )

    Process
    {
        foreach ($_vCTaskRepository in $VCTaskRepository)
        {
            $clone = $_vCTaskRepository.CloneType()
            $DestinationVCServer | ForEach-Object -Process {
                $_.TaskRepository.Update($clone)
            }
        }
    }
}