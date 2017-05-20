Param(
    [parameter(HelpMessage="The Full Path to the file to be build with MsBuild")]
    [string]$solutionPath = $(throw "Please pass solution path"),

    [parameter(HelpMessage="The path to the Nuget.exe")]
    [string]$nugetPath = (get-item $PSScriptRoot).parent.FullName + "\Nuget\Nuget.exe",

    [parameter(HelpMessage="Nuget source")]
    [string]$nugetSource = "https://nexus.sb.karmalab.net/nexus/service/local/nuget/nuget.org/"
)

Import-Module "$PSScriptRoot\Modules\System.psm1"

function main {
     #Restore nuget packages for solution
     NugetRestore_Vdrive -nugetPath $nugetPath -nugetSource $nugetSource -solutionPath $solutionPath
}

function NugetRestore
{
    <#
	    .SYNOPSIS
        Restores all nuget packages and their dependencies from specified source(s)
	    
	    .DESCRIPTION
	    Allows current solution to download/update all required nuget packages to their targeted versions in each project's package.config file(s)
    #>

    param(
        [parameter(HelpMessage="The path to the NuGet.exe")]
        [string]$nugetPath = $(throw "NugetRestore: Please pass nugetPath"),

        [parameter(HelpMessage="The comma seperated list of URL(s) which will be used to find all packages referenced in the solution")]
        [string]$nugetSource = $(throw "NugetRestore: Please pass nugetSource"),

        [parameter(HelpMessage="The comma seperated list of URL(s) which will be used to find all packages referenced in the solution")]
        [string]$solutionPath = $(throw "NugetRestore: Please pass solutionPath") # Full path to the solution
    )

    try
    {
        Write-Output ""
        Write-Output "=== NUGET PACKAGE RESTORE START ==="
        Write-Output "NuGet.exe PATH : " $nugetPath
        Write-Output "NuGet PACKAGE SOURCE : " $nugetSource
        Write-Output "SOLUTION: " $solutionPath
        Write-Output ""

        [string]$nugetRestoreCommand = "$nugetPath restore"

        foreach($source in $nugetSource.Split(","))  
        {   
	        $nugetRestoreCommand += " -source " + $source 
        } 

        $nugetRestoreCommand += " $solutionPath"

        Invoke-Expression($nugetRestoreCommand)
    }
    finally
    {
        Write-Output "=== NUGET PACKAGE RESTORE END ==="
        Write-Output ""        
    }
}

function NugetRestore_Vdrive
{    
    <#
	    .SYNOPSIS
        Restores all nuget packages and their dependencies from specified source(s) using a virtual drive
	    
	    .DESCRIPTION
	    Utilizes a virtual drive mapped to a physical path to restore nuget packages for a specified solution
    #>

    param(
        [string]$nugetPath = $(throw "Please pass nugetPath"),
        [string]$nugetSource = $(throw "Please pass nugetSource"),
        [string]$solutionPath = $(throw "Please pass solutionPath")
    )
    [string]$tempDrive = (Get_AvailableDrives | Select -First 1)

    try
    {
        #Need to map a virtual drive to physical path (assuming root of workspace), due to path length issues during build process (specifically nuget restore)
        Write-Warning ("Attempting to map virtual drive '$tempDrive' to physical path '{0}'..." -f (Get-Location).Path)
        New_VirtualDrive -driveLetter $tempDrive -targetPath (Get-Location).Path

        Push-Location
        Set-Location "$tempDrive`:\"

        NugetRestore -nugetPath $nugetPath -nugetSource $nugetSource -solutionPath $solutionPath
    }
    finally
    {
        Remove_VirtualDrive -driveLetterList $tempDrive
        Pop-Location
    }
}
#entry point
main
