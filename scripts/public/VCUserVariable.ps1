function Get-VCUserVariable
{
    [CmdLetBinding()]
    [OutputType([VisualCron.UserVariableClass])]
    Param(
        [Parameter(Position=0)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Name,

        [Parameter(Position=1)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Description,

        [ValidateSet('String','Double','Int32')]
        [string[]]$ObjectType,

        [Parameter(ValueFromPipeline)]
        [ValidateScript({$_.Connected})]
        [VisualCronAPI.Server[]]$VCServer = (Get-VCSelectedServer)
    )

    Process
    {
        foreach ($_vCServer in $VCServer)
        {
            # Get all VCUserVariables and filter result, based on given Parameters
            $allUserVars = $_vCServer.Variables.GetAllArray()

            # Add Value Property to USerVars, that contains Decrypted Value
            # Add Method GetVCServer to Var Object. This MEthod is used to get the VCServer the Variable origins from
            $allUserVars | ForEach-Object -Process {
                $_ | Add-Member -NotePropertyName Value -NotePropertyValue $_vCServer.Variables.GetVariableValue($_.Name) -Force
                $_ | Add-Member -NotePropertyName VCServerId -NotePropertyValue $_vCServer.Id -Force
                $_ | Add-Member -MemberType ScriptMethod -Name GetVCServer -Value {Get-VCServer -ID $this.VCServerId} -Force
            }

            if($PSBoundParameters.Keys -contains "Name") { # Filter by Name
                $allUserVars = $allUserVars | Where-Object -FilterScript {$Name -contains $_.Name}
            }

            if($PSBoundParameters.Keys -contains "Description") { # Filter by Description
                $allUserVars = $allUserVars | Where-Object -FilterScript {$Description -contains $_.Description}
            }

            if($PSBoundParameters.Keys -contains "ObjectType") { # Filter by ObjectType
                $allUserVars = $allUserVars | Where-Object -FilterScript {$ObjectType -contains $_.ObjectType}
            }

            $allUserVars | Add-GetVCServerMethod -VCServer $_vCServer
            # Output Jobs
            $allUserVars | Write-Output
        }
    }
}

function Set-VCUserVariable
{
    [CmdLetBinding(DefaultParameterSetName = 'ByName')]
    [OutputType([VisualCron.UserVariableClass])]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$Name,
        
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'ByUserVariable')]
        [ValidateNotNullOrEmpty()]
        [VisualCron.UserVariableClass[]]$VCUserVariable,

        [ValidateNotNull()]
        [string]$Value,

        [ValidateNotNull()]
        [string]$Description
    )

    Process
    {
        # If -Name Parameter is set, get VCUSerVariable by using the Get-VCUSerVariable CMDLet
        if($PSCmdlet.ParameterSetName -eq 'ByName') {
            $VCUserVariable = Get-VCUserVariable -Name $Name    
        }

        foreach ($_vCUserVariable in $VCUserVariable)
        {
            $vcServer = $_vCUserVariable.GetVCServer()

            if($PSBoundParameters.Keys -contains "Value") {
                $vcServer.Variables.SetVariableValue([ref]$_vCUserVariable,$Value)    
            }

            if($PSBoundParameters.Keys -contains "Description") {
                $_vCUserVariable.Description = $Description    
            }

            [void]$vcServer.Variables.Update($_vCUserVariable)
            Get-VCUserVariable -Name $_vCUserVariable.Name | Write-Output
        }
    }  
}

function New-VCUserVariable
{
    [CmdLetBinding()]
    [OutputType([VisualCron.UserVariableClass])]
    Param(
        [Parameter(Position=0,Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [ValidateNotNull()]
        [string]$Description = '',

        [ValidateNotNull()]
        [string]$Value = '',

        [ValidateSet('String','Double','Int32')]
        [string[]]$ObjectType = 'String',

        [Parameter(ValueFromPipeline)]
        [ValidateScript({$_.Connected})]
        [VisualCronAPI.Server[]]$VCServer = (Get-VCSelectedServer)
    )
    
    Process
    {
        foreach ($_vCServer in $VCServer)
        {
            $oldVar = $_vCServer | Get-VCUserVariable -Name $Name
            if($null -ne $oldVar) {
                Write-Error "UserVariable `"$Name`" already exists"         
            } else {
                Try {
                    $newVar = $_vCServer.Variables.CreateUserVariable($Name,$Description,$Value,[System.TypeCode]::$ObjectType)
                    [void]$_vCServer.Variables.Add($newVar)
                    Get-VCUserVariable -Name $newVar.Name | Write-Output
                } catch {
                    Write-Error $_
                }  
            }
        }
    }  
}