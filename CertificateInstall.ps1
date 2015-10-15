#  Script name:    CertificateInstall.ps1
#  Purpose:        Installs user certificates with passwords from a network location.
 
# Define network paths for certificate and password files
$CertLocation = "\\server\Certs\"
$PasswordFileLocation = "\\server\Cert Passwords\"
 
# Get the currently logged on users username
$UserName = $env:UserName
 
# Check to make sure that the current user has a certificate and a password file in the above locations
$CheckUserHasCert = Test-Path $CertLocation$Username.p12
$CheckUserCertPasswordFile = Test-Path $PasswordFileLocation$Username.txt
 
# If the current user has a certificate AND a password file then process removal and installation
# If one of both of these files is missing or incorrectly named then do nothing
if ($CheckUserHasCert -ne $False -and $CheckUserCertPasswordFile -ne $False) {
 
# Look in the current users certificate store and find their currently installed certificate
# THIS SECTION IS REQUIRED FOR THE REMOVE-ITEM METHOD WHICH DOES NOT WORK FOR WINXP
#$CurrentCertificate = Get-Childitem -path Cert:\CurrentUser\My | Where-Object {$_.Subject -like "*$UserName*"}
#$CurrentCertificateThumbprint = $CurrentCertificate.Thumbprint
 
# If no certificate was found then do nothing, if a certificate was found then delete it
if ($CurrentCertificateThumbprint -ne $null) {
$store = New-Object System.Security.Cryptography.x509Certificates.x509Store("My","CurrentUser")
$store.Open("ReadWrite")
$certs = $store.Certificates | Where {$_.Subject -like "*$UserName*"}
 
# If a cert was found then remove it, or else do nothing
if ($Certs -ne $Null) {
ForEach ($cert in $certs)
{
  $store.Remove($cert)
}
}
$store.Close()
 
# Below is the cmdlet string (which does not work with XP)
#Remove-Item -Path "cert:\CurrentUser\My\$CurrentCertificateThumbprint"
}
 
# Read users certificate password from password file location
$CertPassword = Get-Content "$PasswordFileLocation$Username.txt"
 
# Convert password found in certificate file to a secure string
$SecurePassword = ConvertTo-SecureString -String $CertPassword -Force -AsPlainText
 
# Define variable containing the full path to the users certificate (required for the Import-PFXCertificate command)
$CertFullPath = "$CertLocation$Username.p12"
 
# Install the current user certificate
# Below is a long-winded way of installing the certificate as XP does not support the Import-PFXCertificate cmdlet
$pfx = new-object System.Security.Cryptography.X509Certificates.X509Certificate2
$pfx.import($CertFullPath,$SecurePassword,“PersistKeySet”)
$store = new-object System.Security.Cryptography.X509Certificates.X509Store("My","currentuser")
$store.open(“MaxAllowed”)
$store.add($pfx)
$store.close()
 
# Below is the cmdlet string (which does not work with XP)
#Import-PfxCertificate -FilePath $CertFullPath -Password $SecurePassword -CertStoreLocation Cert:\CurrentUser\My –Exportable
}
