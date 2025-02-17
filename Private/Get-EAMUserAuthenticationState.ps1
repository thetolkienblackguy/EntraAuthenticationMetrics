function Get-EAMUserAuthenticationState {
    <#
        .SYNOPSIS
        Get the authentication state of a user

        .DESCRIPTION
        Get the authentication state of a user and returns an object with boolean flags for each authentication method

        .PARAMETER InputObject
        The user object to get the authentication state of

        .EXAMPLE
        Get-EAMUserAuthenticationState -InputObject $user

        .INPUTS
        System.Object

        .OUTPUTS
        System.Object
    
    #>
    [CmdletBinding()]
    [OutputType([System.Object])]
    param (
        [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)]
        [object]$InputObject
    )
    Begin {
        $ErrorActionPreference = "Stop"
    
    } Process {
        Write-Debug "Input object properties:"
        Write-Debug ($inputObject | Format-List | Out-String)
        
        Write-Debug "UserPrincipalName value: $($inputObject.UserPrincipalName)"
        
        # Create the base object with all methods set to false
        $auth_state = New-EAMAuthenticationObject -User $inputObject.UserPrincipalName
        
        Write-Debug "Auth state after creation:"
        Write-Debug ($auth_state | Format-List | Out-String)
        
        # Process certificate
        if ($inputObject.authorizationinfo.certificateUserIds) {
            $auth_state.Certificate = $true
            $auth_state.PRMFAStatus = "Enabled"
        
        }

        # Process authentication methods
        $methods = $inputObject | Get-EAMUserAuthenticationMethods
        foreach ($method in $methods) {
            $method_name = $method.authenticationMethod
            if ($method_name) {
                $auth_state.$($method_name) = $true
                if ($method_name -in @("Fido2","WindowsHelloForBusiness")) {
                    $auth_state.PRMFAStatus = "Enabled"
                
                }
            }
        }
        Write-Debug "Final auth state:"
        Write-Debug ($auth_state | Format-List | Out-String)
        
        # Return the authentication state
        $auth_state
    
    } End {
    }
}