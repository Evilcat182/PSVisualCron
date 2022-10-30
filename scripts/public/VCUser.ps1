function Get-VCUser
{
    [CmdLetBinding()]
    [OutputType([VisualCron.SecUserClass])]
    Param(
        [Parameter(Position=0)]
        [ValidateNotNullOrEmpty()]
        [string[]]$UserName,

        [Parameter(Position=1)][VisualCron.SecUserClass]
        [ValidateNotNullOrEmpty()]
        [string[]]$Name,

        [ValidateNotNullOrEmpty()]
        [string[]]$Domain,

        [ValidateLength(36,36)]
        [string[]]$Id,

        [switch]$ADUser,
        [switch]$ADGroup,

        [Parameter(ValueFromPipeline)]
        [ValidateScript({$_.Connected})]
        [VisualCronAPI.Server[]]$VCServer = (Get-VCSelectedServer)
    )

    Process
    {
        foreach ($_vCServer in $VCServer)
        {
            # Get all Users and filter result, based on given Parameters
            $allUsers = $_vCServer.Permissions.GetAllUsersArray()

            # Decrypt Propertys 'Name','Username','Email' with .Decrypt Method of vcServer
            # Add as new Property called 'PSName','PSUsername','PSEmail'
            $decryptProps = @('Name','Username','Email')
            $allUsers | ForEach-Object -Process {
                foreach ($prop in $decryptProps) {
                    $_ | Add-Member -NotePropertyName "PS$prop" -NotePropertyValue $_vCServer.Decrypt($_.$prop)  
                }
                # Add Domain as AliasProperty for ADDC
                $_ | Add-Member -MemberType AliasProperty -Name Domain -Value ADDC
            }

            if($PSBoundParameters.Keys -contains "Username") { # Filter by Username
                $allUsers = $allUsers | Where-Object -FilterScript {$Username -contains $_.PSUsername}
            }

            if($PSBoundParameters.Keys -contains "Name") { # Filter by Name
                $allUsers = $allUsers | Where-Object -FilterScript {$Name -contains $_.PSName}
            }

            if($PSBoundParameters.Keys -contains "Id") { # Filter by Id
                $allUsers = $allUsers | Where-Object -FilterScript {$Id -contains $_.Id}
            }

            if($PSBoundParameters.Keys -contains "Domain") { # Filter by Domain
                $allUsers = $allUsers | Where-Object -FilterScript {$Domain -contains $_.Domain}
            }

            $allUsers = if($ADUser) { $allUsers | Where-Object {$_.IsAdUser}} else { $allUsers }
            $allUsers = if($ADGroup) { $allUsers | Where-Object {$_.IsADGroup}} else { $allUsers }

            $allUsers | Add-GetVCServerMethod -VCServer $_vCServer

            # Output Users
            $allUsers | Write-Output
        }
    }
}

function Set-VCUser
{
    [CmdLetBinding(DefaultParameterSetName = 'localVCUser')]
    [OutputType([VisualCron.SecUserClass])]
    Param(
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [VisualCron.SecUserClass[]]$VCUser,

        [ValidateNotNullOrEmpty()]
        [ValidateLength(1,320)]
        [ValidatePattern('^[\w-\.]+@([\w-]+\.)+[\w-]{1,4}$')]
        [string]$Email,

        [Parameter(ParameterSetName = 'localVCUser')]
        [ValidateNotNullOrEmpty()]
        [SecureString]$Password,

        [VisualCron.SecGroupClass[]]$VCUserGroup
    )

    Begin
    {
        if($PSCmdlet.ParameterSetName -eq 'localVCUser') 
        {
            if($PSBoundParameters.Keys.Contains('Password')) {
                $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
                $pwdStr = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
            }  
        }
    }

    Process
    {
        foreach ($_vCUser in $VCUser)
        {
            $vcServer = $_vCUser.GetVCServer()
            $_vCUser.Email = if($PSBoundParameters.Keys.Contains('Email')) { $vcServer.Encrypt($Email) } else { $_vCUser.Email }
            
            if($PSBoundParameters.Keys.Contains('VCUserGroup')) {
                $_vCUser.Groups.Clear()
                $VCUserGroup | ForEach-Object { [void]$_vCUser.Groups.Add($_.Id) }  
            }

            if($PSBoundParameters.Keys.Contains('Password')) {
                $vcServer.Permissions.UpdateUserPassword($_vCUser.Id, $pwdStr) | Out-Null
            }

            if($vcServer.Permissions.UpdateUser($_vCUser)) {
                Get-VCUser -Id $_vCUser.Id | Write-Output
            }
        }
    }
}

function Remove-VCUser
{
    [CmdLetBinding()]
    [OutputType([bool])]
    Param(
        [Parameter(Mandatory,
            Position=0,
            ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [VisualCron.SecUserClass[]]$VCUser
    )

    Process
    {
        foreach ($_vCUser in $VCUser) {
            $_vCUser.GetVCServer().Permissions.RemoveUser($_vCUser) | Write-Output
        }
    }
}

function Add-VCUser
{
    [CmdLetBinding( DefaultParameterSetName = 'localVCUser')]
    [OutputType([VisualCron.SecUserClass])]
    Param(
        [Parameter(
            Mandatory, 
            Position=0, 
            ParameterSetName = 'localVCUser')]
        [ValidateNotNullOrEmpty()]
        [ValidateLength(1,64)]
        [string]$UserName,

        [Parameter(
            Mandatory,
            Position=1,
            ParameterSetName = 'localVCUser')]
        [ValidateNotNullOrEmpty()]
        [SecureString]$Password,
        
        [Parameter(ParameterSetName = 'localVCUser')]
        [ValidateNotNullOrEmpty()]
        [ValidateLength(1,256)]
        [string]$Name,

        [Parameter(
            Mandatory, 
            Position=0, 
            ParameterSetName = 'adUser')]
        [ValidateNotNullOrEmpty()]
        [ValidateLength(1,64)]
        [string]$ADIdentity,

        [ValidateNotNullOrEmpty()]
        [ValidateLength(1,64)]
        [string]$ADHostName,

        [ValidateNotNullOrEmpty()]
        [ValidateLength(1,320)]
        [ValidatePattern('^[\w-\.]+@([\w-]+\.)+[\w-]{1,4}$')]
        [string]$Email,

        [VisualCron.SecGroupClass[]]$VCUserGroup,

        [Parameter(ValueFromPipeline)]
        [ValidateScript({$_.Connected})]
        [VisualCronAPI.Server[]]$VCServer = (Get-VCSelectedServer)
    )

    Begin
    {
        if($PSCmdlet.ParameterSetName -eq 'localVCUser') 
        {
            $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
            $pwdStr = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)

            $Name = if($PSBoundParameters.Keys -contains 'Name') { $Name } else { $UserName }    
        }
    }

    Process
    {
        foreach ($_vcServer in $VCServer)
        {
            $userGroupsOK = $true
            foreach ($userGroup in $VCUserGroup) {
                if(-Not $_vcServer.Permissions.ContainsGroup($userGroup.Id)) {
                    Write-Error "Usergroup `"$($userGroup.Name)`" with Id `"$($userGroup.Id)`" does not exist on Server `"$($_vcServer.Name)`""
                    $userGroupsOK = $false
                }  
            }

            if(-Not $userGroupsOK) { continue }

            if($PSCmdlet.ParameterSetName -eq 'localVCUser')
            {
                $alreadyExists = $null -ne ($_vcServer | Get-VCUser -UserName $UserName)
                if($alreadyExists) {
                    Write-Error "User with Username `"$UserName`" already exists on Server `"$($_vcServer.Name)`""
                    continue
                }

                $newUser = [VisualCron.SecUserClass]::new()
                $newUser.Name = $_vcServer.Encrypt($Name)
                $newUser.UserName = $_vcServer.Encrypt($UserName)
                $newUser.PassWord = $_vcServer.Encrypt($pwdStr)
                $newUser.Email = $_vcServer.Encrypt($Email)
                $newUser.Groups = $VCUserGroup.Id
            
                $_vcServer.Permissions.AddUser($newUser) | Out-Null
                
                $newUser = Get-VCUser -Id $newUser.Id
                if($newUser.Groups.Count -eq 0) {
                    Write-Warning "New User `"$Name`" is not part of any UserGroup and is pretty much useless in the current State.`nUse the Set-VCUser CmdLet to assign the User to a UserGroup"    
                }
                $newUser | Write-Output
            }
            elseif($PSCmdlet.ParameterSetName -eq 'adUser')
            {
                $adObj = Get-ADObj -SamAccountName $ADIdentity -Properties Name,GivenName,sn,SamAccountName,mail
                if(-Not $adObj) {
                    Write-Error "Can not resolve ADIdentity `"$ADIdentity`""
                    continue
                }                

                $newUser = [VisualCron.SecUserClass]::new()
                $newUser.ADHostName = if($PSBoundParameters.Keys -contains 'ADHostName') { $ADHostName } else { (Get-VCServerSetting).ADServer }
                $newUser.ADDC = $newUser.ADHostName.Split('.')[0]
                $newUser.IsADGroup = $adObj.Properties["objectclass"] -contains "group"
                $newUser.IsADUser = $adObj.Properties["objectclass"] -contains "user"
                $newUser.Email = if($PSBoundParameters.Keys -contains 'Email') { $_vcServer.Encrypt($Email) } else { $_vcServer.Encrypt($adObj.Properties.mail) }
                $newUser.Groups = $VCUserGroup.Id

                if($newUser.IsADUser) {
                    
                    ### NOT SUPPORTED YET
                    Write-Error "Only AD Groups are supported yet"
                    continue
                    $newUser.Name = $_vcServer.Encrypt("[AD] $($adObj.Properties.givenname) $($adObj.Properties.sn)")
                    $newUser.UserName = $_vcServer.Encrypt($adObj.Properties.samaccountname)
                    $newUser.InheritGroup = $false
                } else {
                    $newUser.Name = $_vcServer.Encrypt($adObj.Properties.name)
                    $newUser.UserName = $_vcServer.Encrypt([String]::Empty)
                    $newUser.ADGroup = $adObj.Properties.name
                    $newUser.InheritGroup = $true
                }

                $_vcServer.Permissions.UpdateUser($newUser) | Out-Null

                $newUser = Get-VCUser -Id $newUser.Id
                if($newUser.Groups.Count -eq 0) {
                    Write-Warning "New User `"$Name`" is not part of any UserGroup and is pretty much useless in the current State.`nUse the Set-VCUser CmdLet to assign the User to a UserGroup"    
                }
                $newUser | Write-Output
            }
        }
    }
}

function Copy-VCUser
{
    [CmdLetBinding()]
    Param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [VisualCron.SecUserClass[]]$VCUser,
        
        [Parameter(Mandatory)]
        [ValidateScript({$_.Connected})]
        [VisualCronAPI.Server[]]$DestinationVCServer
    )

    Process
    {
        foreach ($_vCUser in $VCUser)
        {
            $clone = $_vCUser.CloneType()
            $DestinationVCServer | ForEach-Object -Process {
                $_.Permissions.UpdateUser($clone)
            }
        }
    }
}