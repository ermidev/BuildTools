function Execute_RemoteCommand
{
    <#
        .SYNOPSIS
        Establishes a remote session with a machine using the specified credentials and executes a script block (function) on that environment
	    
	    .DESCRIPTION
	    This is intended for use in scenarios where what you require remotely executed tasks, but cannot maintain a constant session with the machine (i.e. needing to execute remote commands on the same machine, but using different scripts)
    #>

    param(
        [string]$targetMachineName,
        [ValidateScript({ ($_.GetType() -eq [ScriptBlock]) -or ($_.GetType() -ieq [String]) })]
        $command = $(throw "Please pass command."),
        [parameter(Mandatory=$false)]
        $commandArguments,
        [System.Management.Automation.PSCredential]$credential = $(throw "Please pass credential."),
        [parameter(Mandatory=$false)]
        [string]$commandErrorAction = "Continue",
        [parameter(Mandatory=$false, ParameterSetName="RunAsJob")]
        [switch]$runAsJob,
        [parameter(Mandatory=$false, ParameterSetName="NoJob")]
        [parameter(Mandatory=$true, ParameterSetName="RunAsJob")]
        [switch]$returnResult
    )

    [System.Management.Automation.Runspaces.PSSession]$s

    try
    {
        $s = New-PSSession -ComputerName $targetMachineName -Credential $credential -ErrorAction Stop

        if(!$runAsJob.IsPresent)
        {
            Invoke-Command -Session $s -ScriptBlock $command -ArgumentList $commandArguments -ErrorAction $commandErrorAction
        }
        else
        {
            $commandJob = Invoke-Command -Session $s -ScriptBlock $command -ArgumentList $commandArguments -AsJob -ErrorAction $commandErrorAction
            Receive-Job -Job $commandJob -Session $s -Wait -ErrorAction $commandErrorAction
        
            if($commandJob.State -ieq "Failed")
            {
                Write-Warning "Remote job failed with the following error: "
                Write-Output $Error[0]
            }

            if($returnResult.IsPresent)
            {
                return $CommandJob.State
            }
        }
    }
    finally
    {
        # Dispose of session if it's not null
        if($s)
        {
            Remove-PSSession -Session $s
        }
    }
}