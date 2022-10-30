function Add-GetVCServerMethod
{
    [CmdLetBinding()]
    Param(
        [Parameter(
            Mandatory,
            Position=0, 
            ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [ref[]]$InputObject,

        [Parameter(Mandatory)]
        [ValidateScript({$_.Connected})]
        [VisualCronAPI.Server]$VCServer
    )

    Process
    {
        for ($i = 0; $i -lt $InputObject.Count; $i++) 
        { 
            $InputObject[$i].Value | Add-Member -Force -NotePropertyName VCServerId -NotePropertyValue $VCServer.Id
            $InputObject[$i].Value | Add-Member -Force -MemberType ScriptMethod -Name GetVCServer -Value {Get-VCServer -ID $this.VCServerId}
        }
    }
}