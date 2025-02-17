Function New-EAMAuthenticationObject {
    <#
        .SYNOPSIS
        Creates a new object for the EAM Authentication Report

        .DESCRIPTION
        This function creates a new object for the EAM Authentication Report.

        .PARAMETER User
        The user object to add to the report.

        .PARAMETER ReportHeaders
        The headers to add to the report.

        .EXAMPLE
        New-EAMAuthenticationObject -User $user -ReportHeaders $reportHeaders
    
        .INPUTS
        System.String 
        System.String[]

        .OUTPUTS
        System.Object
    
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    Param (
        [Parameter(Mandatory=$true)]
        [string]$User,
        [Parameter(Mandatory=$false)]
        [string[]]$ReportHeaders = @(
            "User", "PRMFAStatus", "EmailAuthentication", "Fido2", "Certificate", "AuthenticatorApp", #"PasswordAuthentication", 
            "PhoneAuthentication", "Passwordless", "SoftwareOath", "TemporaryAccessPass", "WindowsHelloForBusiness"
        
        )
    )
    Begin {
        Write-Debug "Creating new auth object for user: $User"
        # Create a new object
        $obj = [ordered] @{}
    
    } Process {
        # Add the user to the object
        $obj["User"] = $user

        # Set the PRMFAStatus to Disabled
        $obj["PRMFAStatus"] = "Disabled"

        Write-Debug "Object after setting User:"
        Write-Debug "$($obj | Format-List | Out-String)"

        # Add the report headers to the object
        Foreach ($header in $reportHeaders) {
            if ($header -notin @("User","PRMFAStatus")) {  
                $obj[$header] = $false # Set the value to false as the default, it will be updated in the Get-EAMUserAuthenticationState function
            
            }
        }
    } End {
        Write-Debug "Final object:"
        Write-Debug "$($obj | Format-List | Out-String)"

        # Return the object
        [pscustomobject]$obj
    
    }
}