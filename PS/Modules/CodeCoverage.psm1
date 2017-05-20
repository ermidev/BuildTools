function Get_CodeCoverage_LineCoverage
{
    <#
	    .SYNOPSIS
	    Reads a file to obtain integer/decimal values within specific lines of code coverage files
	
	    .DESCRIPTION
	    Selects lines in a file that match a specific pattern and parses the line with a specific pattern to obtain an integer/decimal value
    #>

    param(
        [string]$coverageFilePath = $(throw "Please pass coverageFilePath")
    )

    [double]$lineCount = 0

    #Find all lines that match the "Line coverage:(Non-digit)(digit).(digit)%" format
    $coverageContent_lineCount = Select-String -Path $coverageFilePath -Pattern ('Line coverage:\D+\d+\.*\d+\%')

    #Replace all text that does not match a "(digit).(digit)" OR "(digit)" format
    $coverageContent_lineCount = $coverageContent_lineCount.Line -replace [regex]"[^\d+\.*\d*]", ''
    [double]::TryParse($coverageContent_lineCount, [ref]$lineCount) | Out-Null
    
    return $lineCount
}