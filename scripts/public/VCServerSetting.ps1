function Get-VCServerSetting
{
    [CmdLetBinding()]
    [OutputType([VisualCron.ServerSettingsClass])]
    Param(
        [Parameter(ValueFromPipeline)]
        [ValidateScript({$_.Connected})]
        [VisualCronAPI.Server[]]$VCServer = (Get-VCSelectedServer)
    )

    Process
    {
        foreach ($_vCServer in $VCServer)
        {
            $_vcServer.Settings | Write-Output
        }
    }
}

function Set-VCServerSetting
{
    [CmdLetBinding()]
    [OutputType([VisualCron.ServerSettingsClass])]
    Param(
        [ValidateNotNullOrEmpty()]
        [string]$ADServer,

        [ValidateNotNullOrEmpty()]
        [bool]$AllowActiveDirectoryLogon,

        [ValidateRange(0,[int]::MaxValue)]
        [int]$MaxOutputSize,

        [ValidateNotNullOrEmpty()]
        [bool]$ExtendedDebugging,

        [ValidateNotNullOrEmpty()]
        [HashTable]$SettingsHashtable = @{},

        [Parameter(ValueFromPipeline)]
        [ValidateScript({$_.Connected})]
        [VisualCronAPI.Server[]]$VCServer = (Get-VCSelectedServer)
    )

    Process
    {
        foreach ($_vcServer in $VCServer)
        {
            # Get all Server Settings
            $srvSettings = $_vcServer | Get-VCServerSetting
            
            # Get all given parameters except 'VCServer','SettingsHashtable'.
            # Loop through all params and add (append) there Prop plus Value to the Hashtable $SettingsHashtable
            $setParams = $PSBoundParameters.Keys | Where-Object -FilterScript {@('VCServer','SettingsHashtable' -notcontains $_)}
            
            $setParams | ForEach-Object -Process {
                $SettingsHashtable.Add($_,$PSBoundParameters[$_])
            }

            # Loop through SettingsHashtable, compare OldVal and NewVal
            # If match, write Warning, if differs, set NewVal
            foreach ($key in $SettingsHashtable.Keys)  {
                
                $oldVal = $srvSettings.$key
                $newVal = $SettingsHashtable[$key]

                if($oldVal -eq $newVal) {
                    Write-Warning "VCServerSetting `"$key`" already was set to `"$newVal`""    
                } else {
                    $srvSettings.$key = $SettingsHashtable[$key]
                }
            }

            # Update ServerSettings, Get ServerSettings and return ServerSettings
            $_vcServer.UpdateServerSettings($srvSettings)
            $_vcServer | Get-VCServerSetting | Write-Output
        }
    }
}