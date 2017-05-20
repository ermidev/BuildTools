function Confirm_ServiceExists
{
    param(
        [string[]]$serviceNameList
    )

    foreach($serviceName in $serviceNameList)
    {
        Write-Output "Confirming service '$serviceName' exists on the environment '$env:COMPUTERNAME'"
        if(!(Get-Service -Name $serviceName -ErrorAction SilentlyContinue))
        {
            throw "Failed to find service '$serviceName'!  Exiting..."
        }
        else
        {
            Write-Output "Found service '$serviceName' on environment '$env:COMPUTERNAME'."
        }
    }
}

function Invoke_WindowsServiceAction
{
    <#
	    .SYNOPSIS
	    Executes an action supported by windows services, or more specifically, Powershell cmdlets for windows services
	
	    .DESCRIPTION
	    This provides support for manipulating Windows services on an environment
    #>

    param(
        [string]$serviceAction = $(throw "Please pass serviceAction"),
        [string[]]$serviceList = $(throw "Please pass serviceList"),
        [bool]$force
    )

    Write-Output ""
        
    foreach($serviceName in $serviceList)
    {
        Write-Output "Performing the action '$serviceAction' on the service '$serviceName' on the machine '${env:COMPUTERNAME}'"

        switch($serviceAction)
        {
            "Start"
            {
                Start-Service -Name $serviceName -Verbose
            }
            "Stop"
            {
                if($force)
                {
                    Stop-Service -Name $serviceName -Verbose -Force
                }
                else
                {
                    Stop-Service -Name $serviceName -Verbose
                }
            }
            "Restart"
            {
                Restart-Service -Name $serviceName -Verbose
            }
            default
            {
                throw "SERVICE ACTION: Unrecognized service action '$serviceAction'!  Please provide supported service action."
            }
        }
    }
    Write-Output ""
}


function Invoke_IISServiceAction
{
    <#
	    .SYNOPSIS
	    Executes an action supported by windows IIS service, or more specifically, Powershell cmdlets for windows IIS services
	
	    .DESCRIPTION
	    This provides support for manipulating Windows IIS services on an environment
    #>

    param(
        [string]$serviceAction = $(throw "Please pass serviceAction")
    )

    Write-Output ""
    Write-Output "Performing the action '$serviceAction' on the IIS service on the machine '${env:COMPUTERNAME}'"

    switch($serviceAction)
    {
        "Start"
        {
           iisreset /start
        }
        "Stop"
        {
           iisreset /stop
        }
        "Restart"
        {
            iisreset /restart
        }
        default
        {
            throw "SERVICE ACTION: Unrecognized service action '$serviceAction'!  Please provide supported service action."
        }
    }

    if($LASTEXITCODE -ne 0)
    {
        throw "Failure to '$serviceAction' IIS service detected!  Exiting..."
    }
    
    Write-Output ""
}

