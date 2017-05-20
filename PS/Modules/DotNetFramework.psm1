function Verify_DotNetFrameworkVersion
{
    <#
	    .SYNOPSIS
	    Gets a list of .NET Framework versions and confirms if the specified one is installed
	
	    .DESCRIPTION
	    Queries a registry path for a list of known key name formats for .NET version values and matches against the provided version number
    #>

    param(
        [string]$targetFrameworkVersion = $(throw "Please pass frameworkVersion")
    )

    [bool]$versionMatch = $false
    [string]$rootRegistryPath = "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP"
    [int]$targetVersionMajor = $targetFrameworkVersion.Split('.')[0]
    [int]$targetVersionMinor = $targetFrameworkVersion.Split('.')[1]
    
    Write-Output "Searching for .NET Framework version '$targetFrameworkVersion' or greater..."
    if(Test-Path $rootRegistryPath -PathType Container)
    {
        #Uses regex pattern to get all key names that start with v
        $frameworkVersionsExisting = Get-ChildItem -Path "$rootRegistryPath\v*"
        
        #Loop through each version key found
        foreach($frameworkVersion in $frameworkVersionsExisting)
        {            
            #Get rid of the v in the name and break up each value for comparison
            [int[]]$currentVersionList = $frameworkVersion.PSChildName.Replace('v','').split('.')
            [int]$currentVersionMajor = $currentVersionList[0]
            [int]$currentVersionMinor = $currentVersionList[1]

            #Windows registry naming is funky and different between versions.  Depending on the version we have to target the key diferently.
            if($currentVersionMajor -lt 4)
            {
                $frameworkVersionNumber = $frameworkVersion.GetValue("Version")
            }
            elseif(($currentVersionMajor -eq 4) -and ($currentVersionMinor -ne $NULL -and $currentVersionMinor -eq 0))
            {
                $frameworkVersionNumber = (Get-Item -Path (("$rootRegistryPath\{0}\Client") -f $frameworkVersion.PSChildName)).GetValue("Version")
            }
            else
            {
                $frameworkVersionNumber = (Get-Item -Path (("$rootRegistryPath\{0}\Full") -f $frameworkVersion.PSChildName)).GetValue("Version")
            }

            #If we found something in the registry, split it up and see if the version number is equal to or greater than the expected version.
            if(($frameworkVersionNumber -ne $NULL) -and ($frameworkVersionNumber -ne ''))
            {
                [int[]]$currentVersionList = $frameworkVersionNumber.split('.')
                [int[]]$targetVersionList = $targetFrameworkVersion.Split('.')
            
                for([int]$i = 0; ($i -lt $currentVersionList.Count) -and ($i -lt $targetVersionList.Count); $i++)
                {                        
                    if($currentVersionList[$i] -gt $targetVersionList[$i])
                    {
                        $versionMatch = $true
                        break
                    }
                    elseif($targetVersionList[$i] -gt $currentVersionList[$i])
                    {
                        break
                    }

                    #If no lesser/greater versions were found, that means it's an exact match!
                    $versionMatch = $true
                }
            }
            else
            {
                Write-Warning "Detected Framework registry path that is not supported by this script!  If necessary, please update this script to ensure it is working properly!"
            }
        }
        
        if($versionMatch)
        {
            Write-Output ("PASS:  Framework version '$targetFrameworkVersion' or greater has been found on this machine ({0})." -f $env:ComputerName)
        }
        else
        {
            throw "FAIL:  Framework version '$targetFrameworkVersion' or greater was not found!"
        }
    }
    else
    {
        throw ("FAIL:  Framework root registry path was not found on this machine ({0})!" -f $env:ComputerName)
    }
}