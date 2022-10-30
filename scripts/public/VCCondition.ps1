function Get-VCCondition
{
    [CmdLetBinding()]
    [OutputType([VisualCron.ConditionSetClass])]
    
    Param(
        [Parameter(Position=0)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Description,

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
            # Get all Conditions and filter result, based on given Parameters
            $allConditions = $_vCServer.Conditions.GetAllArray()

            if($PSBoundParameters.Keys -contains "Description") { # Filter by Description
                $allConditions = $allConditions | Where-Object -FilterScript {$Description -contains $_.Description}
            }

            if($PSBoundParameters.Keys -contains "Id") { # Filter by Id
                $allConditions = $allConditions | Where-Object -FilterScript {$Id -contains $_.Id}
            }
            $allConditions | Add-GetVCServerMethod -VCServer $_vCServer
            $allConditions | Write-Output
        }
    }
}

function Copy-VCCondition
{
    [CmdLetBinding()]
    Param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [VisualCron.ConditionSetClass[]]$VCCondition,
        
        [Parameter(Mandatory)]
        [ValidateScript({$_.Connected})]
        [VisualCronAPI.Server[]]$DestinationVCServer
    )

    Process
    {
        foreach ($_vCCondition in $VCCondition)
        {
            $clone = $_vCCondition.CloneType()
            $DestinationVCServer | ForEach-Object -Process {
                $_.Conditions.Update($clone)
            }
        }
    }
}