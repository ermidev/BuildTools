#This method is used specifically with service Health Check API response content (XML)
function Get_ServiceVersion_XML
{
    <#
	    .SYNOPSIS
	    Begins the nuget rollback workflow
	
	    .DESCRIPTION
	    This is specifically meant to install a previous version of a nuget package to a windows destination.
    #>

    param(
        [xml]$xmlContent = $(throw "Please pass xmlContent")
    )

    #Required to take the string and convert it to an xml object, which allows us to use the full xpath.
    [string]$currentVersion = $xmlContent.HealthCheckReport.ServiceVersion

    if(![version]::TryParse($currentVersion, [ref]$currentVersion))
    {
        throw "Failed to retreive version of service using API!"
    }

    return $currentVersion
}

#This method is used specifically with service Health Check API response content (XML)
function Get_IsServiceRunning_XML
{
    <#
	    .SYNOPSIS
	    Begins the nuget rollback workflow
	
	    .DESCRIPTION
	    This is specifically meant to install a previous version of a nuget package to a windows destination.
    #>

    param(
        [xml]$xmlContent = $(throw "Please pass xmlContent")
    )

    #Required to take the string and convert it to an xml object, which allows us to use the full xpath.
    [bool]$serviceIsRunning = $xmlContent.HealthCheckReport.IsServiceRunning

    return $serviceIsRunning
}

function Get_APIResponse
{
    <#
	    .SYNOPSIS
	    Receives the response from an API call to a URI endpoint
	
	    .DESCRIPTION
	    This method is specifically meant for retrieving data using an API
    #>

    param(
        [uri]$targetUri = $(throw "Please pass targetUri.")
    )

    Write-Host "Getting information from Health Check API..."
    Write-Host "Creating web request using URL '$targetUri'..."
    [System.Net.HttpWebRequest]$request = [System.Net.HttpWebRequest]::Create($targetUri)
	$request.Method = "Get"
    $request.Accept = "text/xml"
	$response = $request.GetResponse()
		
    $requestStream = $response.GetResponseStream()
    $readStream = New-Object System.IO.StreamReader $requestStream
    $content=$readStream.ReadToEnd()
             
	$readStream.Close()
	$response.Close() 
        
    return $content
}

function Get_WebContent
{
    <#
	    .SYNOPSIS
	    Used to get HTML content of a web page
	
	    .DESCRIPTION
	    This method is specifically meant to retrieve parts of a web page so it can be parsed later
    #>

    param(
        [uri]$targetUri = $(throw "Please pass targetUri.")
    )

    [Microsoft.PowerShell.Commands.WebResponseObject]$requestResult = (Invoke-WebRequest -Uri $targetUri -UseBasicParsing)
  
    return $requestResult
}

function Show_APIResponse
{
    param(
        [xml]$xmlContent = $("Please pass xmlContent.")
    )

    Write-Host ""
    Write-Host "HEALTH CHECK INFO RECIEVED"
    Write-Host "--------------------------"
    Select-Xml -xml $xmlContent -xpath "." | foreach {$_.node.InnerXML} | Write-Host
    Write-Host ""
}