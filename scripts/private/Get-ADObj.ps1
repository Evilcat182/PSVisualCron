function Get-ADObj
{
    [CmdLetBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateLength(1,63)]
        [string]$SamAccountName,

        [string[]]$Properties
    )

    $searcher = New-Object system.DirectoryServices.DirectorySearcher
    $Properties | ForEach-Object { $searcher.PropertiesToLoad.Add($_) > $null }
    $searcher.PropertiesToLoad.Add("objectclass") > $null
    $searcher.filter = "(SamAccountName=$SamAccountName)"
    #$searcher.SearchRoot = [adsi]::new("LDAP://DC=hau,DC=liebherr,DC=i")
    $searcher.FindAll() | Write-Output
}