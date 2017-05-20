Import-Module "$PSScriptRoot\WebRequest.psm1"

function Get_Version_LatestNugetPackage
{
    <#
        .SYNOPSIS
        Obtains highest version from a nuget repository URL containing a list of version numbers
	    
	    .DESCRIPTION
	    Uses the Nuget tool to request a list of latest package versions, of which the package name filters and the version is selected as being the last item in the collection
    #>

    param(
        [string]$nugetToolDir = $("Please pass nugetToolDir"),
        [string]$packageSource = $("Please pass packageSource"),
        [string]$packageName = $("Please pass packageName")

    )

    #Return value is expected to be in a format of 'PackageName N.N.N.N'.
    [string]$searchPattern = "^$packageName\W\d+.\d+.\d+.\d+$"
    Write-Host "Attempting to find nuget package '$packageName' using the following pattern:  $searchPattern"

    [string]$packageDetails = & "$nugetToolDir\nuget.exe" list -source "$packageSource" | Select-String "$searchPattern"

    if([string]::IsNullOrEmpty($packageDetails))
    {
        throw "Failed to find any packages with the name '$packageName' from the source '$packageSource'!"
    }

    Write-Host "Latest package found: $packageDetails"

    [string[]]$packageDetailsList = $packageDetails.Split(' ')
    [string]$packageVersion = $packageDetailsList[$packageDetailsList.Count - 1]

    return $packageVersion
}

function Confirm_NugetPackage_Version
{
    <#
        .SYNOPSIS
        Confirms specified version exists on a web page containing a list of version numbers (specifically Nexus)
	    
	    .DESCRIPTION
	    Issues a http web request to get the content of a web page containing a list of version numbers (specifically from Nexus), then parses the specified version number
    #>

    param(
        [string]$nugetVersionUri = $("Please pass nugetVersionUri"),
        [string]$packageVersion = $("Please pass packageVersion")
    )

    $nugetPackageUrlList = (Get_WebContent -targetUri $targetUri).links | Select-Object href

    if($nugetPackageUrlList.Count -eq 0)
    {
        throw ("Detected {0} items listed within the given location '$nugetVersionUri'" -f $nugetPackageUrlList.Count)
    }

    foreach($url in $nugetPackageUrlList)
    {
        if($url -ne $null -and $url -ne '')
        {
            [string]$url = $url.TrimEnd('/')
            [string[]]$urlList = $url.Split('/')
            [string]$versionNumber = $urlList[$urlList.Count -1]
        
            if($versionNumber -imatch "^\d+.\d+.\d+[.\d+]*$")
            {
                Write-Output "VERSION: $versionNumber"

                if($versionNumber -eq $targetVersion)
                {
                    return $true
                }
            }
        }
    }

    return $false
}

function Create_NugetPackage
{
    <#
        .SYNOPSIS
        Simply uses Nuget.exe to create a nuget package using the specified .nuspec file
	    
	    .DESCRIPTION
	    Simply uses Nuget.exe to create a nuget package using the specified .nuspec file
    #>

    param(
        [string]$outputDir = $(throw "Please pass rootDir."),
        [string]$nugetFilePath = $(throw "Please pass nugetFilePath."),
        [string]$nuspecFilePath = $(throw "Please pass nuspecFilePath.")
    )

    Write-Output "Attempting to build a nuget package using nuspec file '$nuspecFilePath'..."
    Invoke-Expression ("$nugetFilePath pack $nuspecFilePath -OutputDirectory $outputDir")
}

function Delete_NugetPackage_Nexus
{
    <#
        .SYNOPSIS
        Uses Nuget.exe to remove an existing package from a Nuget repo (specifically Nexus) using an API key as the authentication
	    
	    .DESCRIPTION
	    Uses Nuget.exe to remove an existing package from a Nuget repo (specifically Nexus) using an API key as the authentication
    #>

    param(
        [string]$nugetFilePath = $(throw "Please pass nugetFilePath."),
        [string]$nugetSourceUrl = $(throw "Please pass nugetSourceUrl."),
        [string]$nugetPackageName = $(throw "Please pass nugetPackageName."),
        [ValidateScript({ {$_ -imatch "^\d+.\d+.\d+[.\d+]*$"} })]
        [string]$nugetPackageVersion = $(throw "Please pass nugetPackageVersion."),
        [string]$nexusApiKey = $(throw "Please pass nexusApiKey.")
    )
    
    Write-Output ("Deleting package '{0}' of version '{1}' from repo '{2}'..." -f $nugetPackageName,$nugetPackageVersion,$nexusURL)
    Invoke-Expression("$nugetFilePath delete $nugetPackageName '$nugetPackageVersion' '$nexusApiKey' -Source '$nugetSourceUrl' -NonInteractive") -ErrorAction Stop
}

function Delete_NugetPackage_Local
{
    <#
        .SYNOPSIS
        Deletes the Nuget package from the installed directory.  If specified, will clean out all files/folders from this installation directory as well.
	    
	    .DESCRIPTION
	    Deletes the Nuget package from the installed directory.  If specified, will clean out all files/folders from this installation directory as well.
    #>

    param(
        [string]$packageFilePath = $("Please pass packageFilePath")
    )
        
    if(Test-Path $packageFilePath -ErrorAction SilentlyContinue)
    {
        $packageRootPath = (Get-Item $packageFilePath).Directory

        Write-Warning "Removing nuget package installation at '$packageRootPath'..."
        Get-ChildItem "$packageRootPath\*" | remove-item -Force -recurse
        Write-Output ""
    }
}

function Publish_NugetPackage
{
    <#
        .SYNOPSIS
        Uses Nuget.exe to push an existing package from a specified location to an endpoint (specifically Nexus) using an API key as the authentication
	    
	    .DESCRIPTION
	    Uses Nuget.exe to push an existing package from a specified location to an endpoint (specifically Nexus) using an API key as the authentication
    #>

    param(
        [string]$packageFilePath = $(throw "Please pass packageFilePath."),
        [string]$nugetFilePath = $(throw "Please pass nugetFilePath."),
        [string]$nexusURL = $(throw "Please pass nexusURL."),
        [string]$nexusApiKey = $(throw "Please pass nexusApiKey.")
    )

    [System.IO.FileInfo]$package = (Get-Item $packageFilePath -ErrorAction Stop)

    Write-Output ("Pushing package '{0}' to repo destination '{1}'..." -f $package.Name,$nexusURL)
    Invoke-Expression ("$nugetFilePath push {0} -Source $nexusURL -ApiKey $nexusApiKey" -f $package.FullName) -ErrorAction Stop
}

function Publish_NugetPackages
{
    <#
	    .SYNOPSIS
	    Pushes the specified nuget package to provided endpoint (designed to be used with Nexus) using an API key
	
	    .DESCRIPTION
	    Uses Nuget.exe tool to push nuget package to destination (specifically Nexus) using an API key
    #>

    param(
        [string]$rootDir = $(throw "Please pass rootDir."),
        [string]$nugetFilePath = $(throw "Please pass nugetFilePath."),
        [string]$nexusURL = $(throw "Please pass nexusURL."),
        [string]$apiKey = $(throw "Please pass apiKey.")
    )

    foreach($package in (Get-ChildItem -Path $rootDir -Filter "*.nupkg"))
    {
        Publish_NugetPackage -packageFilePath ($package).FullName -nugetFilePath $nugetFilePath -nexusURL $nexusURL -nexusApiKey $apiKey
    }
}

function Create_NuspecFile
{   
    <#
        .SYNOPSIS
        Simply uses Nuget.exe to create a .nuspec file with default (tokenized) values
	    
	    .DESCRIPTION
	    Simply uses Nuget.exe to create a .nuspec file with default (tokenized) values
    #>

    param(
        [string]$nugetFilePath = $(throw "Please pass nugetFilePath."),
        [string]$nuspecFileName = $(throw "Please pass nuspecFileName.")
    )
    
    Write-Output "Creating nuspec file '$nuspecFileName'..."
    Invoke-Expression("$nugetFilePath '$nuspecFileName' spec -f")
}

function Install_NugetPackage
{
    <#
        .SYNOPSIS
        Targets a nuget package repo to pull from
	    
	    .DESCRIPTION
	    Simply uses Nuget.exe to create a .nuspec file with default (tokenized) values
    #>

    param(
        [string]$targetNugetDir = $("Please pass targetNugetDir"),
        [string]$nugetPackageName = $("Please pass nugetPackageName"),
        [string]$nugetSource = $("Please pass nugetSource"),
        [string]$installPath = $("Please pass installPath"),
        [string]$packageVersion = $("Please pass packageVersion")
    )

    try
    {
        [string]$installCommand = "$targetNugetDir\nuget.exe install `"$nugetPackageName`" -Source $nugetSource -OutputDirectory $installPath -ExcludeVersion -NoCache -NonInteractive"

        Write-Output ""

        if(!([string]::IsNullOrEmpty($packageVersion)))
        {
            $installCommand = "$installCommand -Version $packageVersion"
            Write-Output "NUGET INSTALL:  Installing Nuget package '$nugetPackageName' from source '$nugetSource' with version '$packageVersion'..."
        }
        else
        {
            Write-Warning "No nuget package version specified!"
            Write-Output "NUGET INSTALL:  Installing latest Nuget package '$nugetPackageName' from source '$nugetSource'..."
        }
        
        Invoke-Expression ($installCommand)
    }
    catch [exception]
    {
        throw $_.exception.message
    }
}