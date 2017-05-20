function Validate_PowershellVersion
{
    param(
        [version]$expectedVersion = $(throw "Please pass expectedVersion.")
    )

    Write-Output "Validating version of powershell installed on machine '$env:COMPUTERNAME'..."
    [version]$installedVersion = (Get-Host | Select-Object Version).Version

    #Check for highest version     
    if($installedVersion -lt $expectedVersion)
    {
        throw ("FAIL:  Detected installed version '{0}' is not greater than expected version '{1}'!  Exiting..." -f $installedVersion.ToString(),$expectedVersion.ToString())
    }
    else
    {
        Write-Output "PASS:  Powershell version '$installedVersion' matches or exceeds expected version of '$expectedVersion'!"
    }
}

function Register_PackageProvider_Nuget
{
    if(!((Get-PackageProvider | Select-Object Name) -match "nuget"))
    {
        Write-output ""
        Write-Warning "Failed to find package provider 'nuget'!  Installing required package provider..."
        Install-PackageProvider -Name NuGet -Force
    }
}

function Register_NugetSource_Local
{
    param(
        [string]$nugetSourceName = $(throw "Please pass nugetSourceName"),
        [uri]$nugetPackageSource = $(throw "Please pass nugetPackageSource.")
    )

    if(!((Get-PackageSource | Select-Object Location) -match $nugetPackageSource))
    {
        Write-output ""
        Write-Warning "Failed to find package source `"$nugetSourceName`" on local environment.  Registering source..."
        Register-PackageSource -Name "$nugetSourceName" -Location $nugetPackageSource -ProviderName nuget
    }
}