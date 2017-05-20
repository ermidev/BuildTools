function Get_CommitRange_Latest
{
    <#
	    .SYNOPSIS
        Takes a GIT commit ID and lists all changes made since then
	    
	    .DESCRIPTION
	    Uses git to determine a list of commits made since the specified GIT commit id
    #>

    param(
        [string]$commitId = $(throw "Please pass GitId_LastCommit")
    )

    return Invoke-Expression("git log $commitId.. --abbrev-commit --pretty=oneline")
}