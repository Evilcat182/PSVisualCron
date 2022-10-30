function Get-VCStatus
{
    [CmdLetBinding()]
    Param()

    $svc = Get-WmiObject -Query "SELECT * FROM Win32_Service WHERE Name = '$($script:_VCClient.InstallHelper.ServiceName)'"
    if($svc)
    {
        $isClientOnly = $svc.StartMode -eq 'Disabled'
        $startUpFinished = $null

        $exe = if($svc.PathName -like '"*') { 
            [RegEx]::Match($svc.PathName, '\"(.*?)\"').Groups[1].Value ### GET EXE PATH - EXE PATH IS BETWEEN ""
        } else {
            $svc.PathName.SubString(0,($svc.PathName).Length -2)   
        }

        $version = (Get-Item $exe).VersionInfo.ProductVersion

        $installFolder = Split-Path -Path $exe -Parent

        if(-Not $isClientOnly) {
            $lastLine = Get-Content "$installFolder\log\server_startup.txt" -Tail 1
            $startUpFinished = ($lastLine -split "`t")[2] -match "^Startup finished -*"    
        }


        [PSCustomObject]@{
            IsClientOnly = $isClientOnly
            ServiceState = $svc.State
            StartupCompleted = $startUpFinished
            InstallFolder = $installFolder
            Version = $version
        } | Write-Output   
    }
    else {
        Write-Error "No VisualCron Installation found" -Category NotInstalled
    }
}