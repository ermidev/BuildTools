function Get_AssemblyVersion
{
    <#
	    .SYNOPSIS
	    Retrieves a specified AssemblyInfo file's AssemblyFileInfo property value (version number)
	
	    .DESCRIPTION
	    Uses a regex pattern to target and retreive a specified AssemblyInfo file's AssemblyFileInfo property value (version number)
    #>

    param(
        [ValidateNotNullOrEmpty()]
        [System.IO.FileInfo]$assemblyInfoFile = $(throw "Please pass assemblyInfoFile"),
        [parameter(Mandatory=$FALSE,HelpMessage="Indicator for pom.xml")]
        [bool]$IsPom = $FALSE
    )

    Write-Host "Get_AssemblyVersion :"
    Write-Host "        AssemblyInfoFile : '$assemblyInfoFile' "
    Write-Host "        IsPom : '$IsPom' "

    if($IsPom)
    {
        [xml]$xml = (gc $assemblyInfoFile.FullName -enc UTF8)
        [version]$versionNumber = $xml.project.properties.Parent_Version
        return $versionNumber
    }
    else 
    {
        #Searches for this line:  [assembly: AssemblyFileVersion("1.0.0.0")]
        [regex]$versionPattern = Get_AssemblyVersion_Pattern
        [string]$currentLine = (Select-String -Path $assemblyInfoFile.FullName -Pattern $versionPattern).Line
        [version]$versionNumber = [string]$currentLine -replace "[^\d+\.\d+\.\d+\.\d+]",""   
        return $versionNumber 
    }
}

function Increment_VersionNumber
{
    <#
	    .SYNOPSIS
	    Increments version number
	
	    .DESCRIPTION
	    Returns incremented version number, from the existing versionNumber
    #>

    param(
        [ValidateNotNullOrEmpty()]
        [version]$versionNumberToIncrement = $(throw "Please pass versionNumber")
    )

    return [version]::new($versionNumberToIncrement.Major, $versionNumberToIncrement.Minor, $versionNumberToIncrement.Build, $versionNumberToIncrement.Revision + 1);
}

function Set_AssemblyVersion
{
    <#
	    .SYNOPSIS
	    Sets a specified AssemblyInfo file's AssemblyFileInfo property value
	
	    .DESCRIPTION
	    Uses a regex pattern to target and update a specified AssemblyInfo file's AssemblyFileInfo property value
    #>

    param(
        [System.IO.FileInfo]$assemblyInfoFile = $(throw "Please pass AssemblyInfoFile."),
        [version]$newVersionNumber = $(throw "Please pass NewVersionNumber."),
        [parameter(Mandatory=$FALSE,HelpMessage="Indicator for pom.xml")]
        [bool]$IsPom = $FALSE
    )

    Write-Host "Set_AssemblyVersion :"
    Write-Host "        AssemblyInfoFile : '$assemblyInfoFile' "
    Write-Host "        NewVersionNumber : '$newVersionNumber' "
    Write-Host "        IsPom : '$IsPom' "

    if($IsPom)
    {   
        [xml]$xml = [xml] (gc $assemblyInfoFile.FullName -enc UTF8)
        $xml.project.properties.Parent_Version = $newVersionNumber.ToString()
        $xml.Save($assemblyInfoFile.FullName)
    }
    else
    {
        [regex]$versionPattern = Get_AssemblyVersion_Pattern
        (Get-Content $assemblyInfoFile.FullName) | ForEach-Object {$_ -replace $versionPattern, "[assembly: AssemblyFileVersion(`"$newVersionNumber`")]"} | Set-Content $assemblyInfoFile.FullName
    }
}

function Get_AssemblyVersion_Pattern
{
    [regex]$versionPattern = "\[assembly: AssemblyFileVersion\(`"\d+\.\d+\.\d+\.\d+`"\)\]"

    return $versionPattern
}