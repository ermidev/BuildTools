function Get_ExistingDrives
{
    (Get-PSDrive -PSProvider FileSystem).Root.Trim('\').Trim(':') | Write-Output
}

function Get_AvailableDrives
{
    [string[]]$existingDrives = Get_ExistingDrives
    [System.Collections.ArrayList]$availableDrives = ("A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z")

    foreach($existingDrive in $existingDrives)
    { $availableDrives.Remove($existingDrive) }

    if($availableDrives.Count -eq 0)
    { throw "No drives available for mapping!" }

    return $availableDrives
}

function New_VirtualDrive
{
    param(
        [string]$driveLetter,
        [string]$targetPath
    )

    Get_ExistingDrives | %{ if($_ -match $driveLetter){ throw "Drive '$driveLetter' already exists on the system.  Please select a different drive letter to map to path '$targetPath'!" } }

    Invoke-Expression("subst `"$driveLetter`:`" `"$targetPath`"")
}

function Remove_VirtualDrive
{
    param(
        [string[]]$driveLetterList
    )

    foreach($driveLetter in $driveLetterList)
    {
        Write-Output "Removing virtual drive:  $driveLetter"
        Invoke-Expression("subst `"$driveLetter`:`" /D")
    }
}

function Validate_DirectoryList
{
    param(
        [string[]]$directoryList = $(throw "Please pass shareList.")
    )
        
    Write-Output "Validating list of directories provided..."
    foreach($directoryPath in $directoryList)
    {
        #Access details for all users
        Write-Output "Finding '$directoryPath'"
        if(!(Test-Path $directoryPath))
        {
            throw "Failed to find directory '$directoryPath'!  Exiting..."
        }
    }
}

function Assign_DirectoryPermissions
{
    param(
        [string]$accountName = $(throw "Please pass accountName."),
        [string]$directoryPath = $(throw "Please pass directoryPath."),
        [System.Security.AccessControl.FileSystemRights]$fileSystemRights = $(throw "Please pass fileSystemRights.")
    )
    
    [System.IO.DirectoryInfo] $directoryInfo = New-Object System.IO.DirectoryInfo($directoryPath)
    [System.Security.AccessControl.DirectorySecurity] $directorySecurity = $directoryInfo.GetAccessControl();

    #Returns a directory detail object that matches a specific account name
    [System.Security.AccessControl.AccessRule]$ShareSecurityDetailsByUser = $directorySecurity.Access | Where-Object { $_.IdentityReference -EQ $accountName }

    if($ShareSecurityDetailsByUser)
    {
        Write-Output ("Directory '$directoryPath' contains '" + $ShareSecurityDetailsByUser.FileSystemRights + "' level access for user '$accountName'")
    }
    else
    {
        Write-Warning "Failed to find user '$accountName' assigned to directory '$directoryPath'!"
        Write-Warning ("Assiging permission level of '" + $fileSystemRights + "' to directory '" + $directoryInfo.FullName + "'...")

        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                $accountName,
                $fileSystemRights,
                ([System.Security.AccessControl.InheritanceFlags]::ContainerInherit, [System.Security.AccessControl.InheritanceFlags]::ObjectInherit),
                [System.Security.AccessControl.PropagationFlags]::None,
                [System.Security.AccessControl.AccessControlType]::Allow)
        $directorySecurity.AddAccessRule($accessRule)
        $directoryInfo.SetAccessControl($directorySecurity);
    }
}