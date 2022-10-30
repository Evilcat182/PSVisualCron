## ABOUT

PSVisualCron is a Powershell module for managing VisualCron Servers.<br>
VisualCron is a Job Schedulling software for windows based computers.<br>
With this software it is possible to automate nearly everything, without having to write 1 line of code, everything is GUI based.
<br>
**So where is the fun in that?**<br><br>
Therefore you can start coding again, using this powershell module.
<br>
If you want more informations about VisualCron and its endless possibilities,<br>
visit the vendors website, just keep in mind, that this is a payed software.<br>
https://www.visualcron.com/
<br><h3>Supported Version: 9.9.10<h3>
<br>
## INSTALLATION

```powershell
Install-Module PSVisualCron
```

Link to PowershellGallery: https://www.powershellgallery.com/packages/PSVisualCron

<br><br><br>
## DESCRIPTION

Powershellmodule to manage VisualCron Servers.<br>
Just like with the Visualcron Client GUI, it is possible for the powershell module to establish and maintain multible connection to different servers.
This is very usefull if you want to compare something or if you want to copy objects from one server to another.<br>
You can list all connected servers with the Get-VCServer CmdLet:
```powershell
Get-VCServer -Connected
```
most CmdLet within this modulw support a -VCServer Parameter, so you can decide on with server or servers the command will be executed.
With this technice, bulk changes are a cakewalk.<br>
For example, the command
```powershell
Get-VCServer | Get-VCJob -Name 'Backup' | Set-VCJob -Enabled $false
```
disables the job calles 'Backup' on every priviously connected vcserver.<br>
<br>
If you execute a PSVisualcron CmdLet without the -VCServer Parameter, the command will be executed on the default/selected VCServer.<br>
Usually this is the last successfull connect VCServer, or a server of your choosing.
 ```powershell
Get-VCServer -Name 'Home' | Set-VCSelectedServer
Get-VCJob
Get-VCSelectedServer
```
In this case, the user decided to set the server with the name "Home" as the default VCServer using the "Set-VCSelectedServer" CmdLet.<br>
Now the user can execute 'Get-VCJob' CmdLet without explicitly setting the VCServer Parameter, and the command will execute on the priviously set 'Home' Server.<br>
The show the defvault/selected VCServer, use the 'Get-VCSelectedServer' CmdLet.


  
Supported Commands:<br>
<br>
![Screenshot](get-command.png)

  <br><br><br><br><br>
<h1>OLD DOCUMENTATION<h1>


## USAGE

Connect to local VC Server using current Session Credentials
```
PS C:\Users\lhgsct3_adm> Connect-VCServer

ID Name             Server           Connected
-- ----             ------           ---------
1  VCServer1                         True
```
Connect remote VC Server using current Session Credentials
```
PS C:\Users\lhgsct3_adm> Connect-VCServer -Computername lhgsverpapp02

ID Name             Server           Connected
-- ----             ------           ---------
2  VCServer2        lhgsverpapp02    True
```
Connect-VCServer Using lokal VC User Credentials
```
PS C:\Users\lhgsct3_adm> Connect-VCServer -Username "test" -Password "test"

ID Name             Server           Connected
-- ----             ------           ---------
1  VCServer1                         True
```
Get all Jobs on Server
```
PS C:\Users\lhgsct3_adm> Get-VCJob

Name             Group
----             -----
Backup settings  Default group
Delete old lo... Default group
Monitor bshell   SYSOP
104 104_COM_I... Infor LN
Server mainte... SYSOP
```
Get specific Job on Server by Name
```
PS C:\Users\lhgsct3_adm> Get-VCJob -Name "Perform Maintenance Mode"

Name             Group
----             -----
Perform Maint... Maintenance Mode
```
Get all Tasks of Job
```
PS C:\Users\lhgsct3_adm> Get-VCJob -Name "Perform Maintenance Mode" | Get-VCTask

Order Name             TaskType
----- ----             --------
1     Send Maintena... Email
2     Set VC Mainte... VariableSet
3     Set-FireWallR... JobTaskControl
4     VC - Server O... JobTaskControl
5     Cleanup Windo... JobTaskControl
6     Cleanup IT-Temp  JobTaskControl
7     Cleanup IT-Log   JobTaskControl
8     Cleanup BSE-tmp  JobTaskControl
9     Cleanup BSE-t... JobTaskControl
10    Cleanup BSE-log  JobTaskControl
11    Cleanup BSE-l... JobTaskControl
12    Cleanup BSE-c... JobTaskControl
13    Cleanup Apach... JobTaskControl
14    Cleanup Apach... JobTaskControl
15    Cleanup LHG E... JobTaskControl
16    Cleanup LHG E... JobTaskControl
23    Autoboot Serv... JobTaskControl
```
