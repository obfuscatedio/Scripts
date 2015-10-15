#  Script name:    ChangeProfileLocations.ps1
#  Purpose:        Bulk replaces profile location paths in AD user accounts.
 
# Set the location of the log file for this script.
$outputfile = "C:\Scripts\ChangeProfileLocations.txt"
 
# Define the location of the old and the new profile paths. The script will ONLY replace profile locations that are currently
# pointed to the old location, and leave users with other locations set alone.
$oldprofilepath = "\\oldserver\Profiles\"
$newprofilepath = "\\newserver\Profiles\"
 
# Define a function to run later against each user to set the properties once we have discovered which users need changing.
function SetTSProperties()
{
 $user = [adsi]"LDAP://$userDN"
 $user.psbase.invokeSet("profilePath",$ppValue)
 $user.setinfo()
}
 
# Create an Active Directory searcher object to locate users.
# This method is used instead of Get-ADUser to retain compatibility with Server 2003 / 2008.
$searcher = New-Object adsisearcher
$searcher.Filter = "(&(objectCategory=person)(objectClass=user))"
$searcher.PageSize = 1000
$results = $searcher.FindAll()
 
# For each user found.
foreach ($result in $results) {
    # Bind to the object path returned by the DirectorySearcher
    $user = [adsi]$result.Path
   
    # Try to call InvokeGet for TerminalServicesProfilePath.  If
    # we get a "property not found in the cache" error, ignore it.
    # If we get DISP_E_UNKNOWNNAME, that means tsuserex.dll isn't
    # registered, so just bail on processing the rest of the loop.
    # For any other errors, output it to the screen and continue.
 
    $ProfilePath = $null
 
    try {
        $ProfilePath = $user.PSBase.InvokeGet("TerminalServicesProfilePath")
    } catch [System.Management.Automation.MethodInvocationException] {
        if ($_.Exception.InnerException -ne $null -and
            $_.Exception.InnerException.ErrorCode -eq 0x80020006) {
 
            # This error means tsuserex.dll isn't registered, and you're getting
            # DISP_E_UNKNOWNNAME when trying to query for Terminal Services
            # attributes.
 
            $_
            break
        } elseif ($_.Exception.InnerException -ne $null -and
                  $_.Exception.InnerException.ErrorCode -ne 0x8000500d) {
            # Error code 0x8000500D just means this user account doesn't have
            # a TS Profile Path set, and we'll ignore that.  For any other
            # unexpected errors, go ahead and output the information to the
            # console.
 
            $_
        }
    }
 
    # Add a wildcard * to the end of the oldprofilepath to help -like match it to the users profile.
    $oldprofilepath = $oldprofilepath + "*"
 
    if ($ProfilePath -like $oldprofilepath) {
 
        echo "User $($user.sAMAccountName) has a TS profile located at: $ProfilePath" >> $outputfile
       
        $userDN = "$($user.DistinguishedName)"
        $ppValue = "$newprofilepath$($user.sAMAccountName)"
        echo "Changing TS Profile path for user $($user.sAMAccountName) to $ppValue" >> $outputfile
 
        # BE BLOODY CAREFUL! Leave the following line commented until you have trialed this script and are happy that it will make the
    # changes you want. Un-comment this line when you are ready to make bulk changes.
        #SetTSProperties
    }
}
