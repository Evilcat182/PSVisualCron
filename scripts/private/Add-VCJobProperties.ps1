function Add-VCJobProperties
{
    [CmdLetBinding()]
    Param(
        [Parameter(
            Mandatory,
            Position=0, 
            ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [ref[]]$InputObject
    )

    Process
    {
        for ($i = 0; $i -lt $InputObject.Count; $i++) 
        { 
            $InputObject[$i].Value | Add-Member -Force -MemberType ScriptProperty -Name Enabled -Value { $this.Stats.Active }

            $InputObject[$i].Value | Add-Member -Force -MemberType ScriptProperty -Name Started -Value {
                $proc = $this.GetVCServer().Processes.GetJobProcessesArray($this)
                if($proc) { $proc.Started } else { $null }
            }
            $InputObject[$i].Value | Add-Member -Force -MemberType ScriptProperty -Name Status -Value {
                $proc = $this.GetVCServer().Processes.GetJobProcessesArray($this)
                if($proc) { $proc.Status } else { 'NotRunning' }
            }
            $InputObject[$i].Value | Add-Member -Force -MemberType ScriptProperty -Name LastRun -Value {
                if($this.Stats.DateLastExecution.Year -eq 1) { $null }
                else { $this.Stats.DateLastExecution }
            }
            $InputObject[$i].Value | Add-Member -Force -MemberType ScriptProperty -Name NextRun -Value {
                if($this.Stats.DateNextExecution.Year -eq 1) { $null }
                else { $this.Stats.DateNextExecution }
            }
        }
    }
}