# Create a class to handle authentication method state
# This class is not currently used, but is a placeholder for future use
class GraphAuthenticationMethodState {
    [string]$UserPrincipalName
    [bool]$Certificate
    [bool]$PasswordAuthentication
    [string]$MFAStatus
    [System.Collections.Generic.Dictionary[string,bool]]$methods

    # Constructor
    GraphAuthenticationMethodState([string]$upn) {
        $this.User = $upn
        $this.Certificate = $false
        $this.PasswordAuthentication = $false
        $this.MFAStatus = "Disabled"
        $this.Methods = [System.Collections.Generic.Dictionary[string,bool]]::new()
    
    }

    # Add a method to the object
    [void] AddMethod([string]$method_name) {
        if ($method_name -ne "PasswordAuthentication") {
            $this.Methods[$method_name] = $true
            $this.MFAStatus = "Enabled"
        
        } else {
            $this.PasswordAuthentication = $true
        
        }
    }

    # Set the certificate state
    [void] SetCertificate([bool]$has_certificate) {
        if ($has_certificate) {
            $this.Certificate = $true
            $this.MFAStatus = "Enabled"
        
        }
    }
}