function Get-VCJobVariable
{
    [CmdLetBinding()]
    [OutputType([System.Management.Automation.PSCustomObject])]
    Param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [VisualCron.JobClass[]]$Job,

        [Parameter(Position=0)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Name,

        [string[]]$Value
    )

    Process
    {
        foreach ($_job in $Job)
        {
            # Refresh Job and get VCServer from JOB
            $_job = Get-VCJob -id $_job.Id
            $vCServer = $_job.GetVCServer()

            # Create list of PSCustomobjects with Property 'Name' and 'Value'
            # Value must be decrypted using the VCCServer .Decrypt Method
            $allJobVars = $_job.Variables | ForEach-Object -Process {
                [pscustomobject]@{
                    Name=$_.Key
                    Value=($vcServer.Decrypt($_.ValueObject))
                }
            }

            if($PSBoundParameters.Keys -contains "Name") { # Filter by Name
                $allJobVars = $allJobVars | ? {$Name -contains $_.Name}
            }

            if($PSBoundParameters.Keys -contains "Value") { # Filter by Value
                $allJobVars = $allJobVars | ? {$Value -contains $_.Value}
            }

            # Output JobVariables 
            $allJobVars | Write-Output
        }
    }
}

function Set-VCJobVariable
{
    [CmdLetBinding(
        DefaultParameterSetName='NoPassthrough')]
    [OutputType([Boolean],ParameterSetName='NoPassthrough')]
    [OutputType([System.Management.Automation.PSCustomObject],ParameterSetName='Passthrough')]
    Param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [VisualCron.JobClass[]]$Job,

        [Parameter(Mandatory,Position=0)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Name,

        [Parameter(Mandatory,Position=1)]
        [string]$Value,

        [Parameter(ParameterSetName='Passthrough')]
        [switch]$Passthrough
    )

    Process
    {
        foreach ($_job in $Job)
        {
            # Refresh Job and get VCServer from JOB
            $_job = Get-VCJob -Id $_job.Id
            $vCServer = $_job.GetVCServer()

            foreach ($_name in $Name) 
            {
                # Set new Job Var
                $result = $vCServer.Jobs.JobVariables.AddUpdate($_job.Id,$_name,$Value)
              
                # Result = True = Successfully
                if($result) {
                    Start-Sleep -Milliseconds 10 # Time needed till update takes effect
                    
                    # if Passthrough is set, get new VCJobVariable and return
                    # otherwise return $result (True)
                    if($Passthrough) {
                        $_job | Get-VCJobVariable -Name $_name | Write-Output
                    } else {
                        $result | Write-Output
                    }
                } else {
                    # Result != True = Write Error
                    Write-Error "Error while setting VCJobVariable"

                    $result | Write-Output
                }
            }
        }
    }
}