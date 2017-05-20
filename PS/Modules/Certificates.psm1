
function Import_Certificates
{
    param(
        [string[]]$certificateList = $(throw "Please pass certificateList.")
    )

    $certStore = "Root"
    $certRootStore = "LocalMachine"
    [System.Security.Cryptography.X509Certificates.X509Store]$store = new-object System.Security.Cryptography.X509Certificates.X509Store($certStore,$certRootStore)
    
    foreach($certificate in $certificateList)
    {
        [string]$certStoreLocation = "cert:\localmachine\root"
        [System.IO.FileInfo]$certificateFile = Get-Item $certificate
        [string]$certificateStorePath = ("$certificateStorePath\{0}" -f $certificateFile.Name)

	    if(!(Test-Path $certificateStorePath))
	    {
            Write-Output "Importing certificate '$certificate' to destination '$certStoreLocation'..."
            
            [System.Security.Cryptography.X509Certificates.X509Certificate2]$newCert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::CreateFromCertFile($certificate)
                        
            $store.open("MaxAllowed")
            $store.add($newCert)  
	        $store.close()          
	    }
        else
        {
            Write-Output "Certificate '$certificate' already exists at destination '$certStoreLocation'!  Skipping..."
        }
    }
}