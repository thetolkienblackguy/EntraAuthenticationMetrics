class GraphAuthenticationMethodInfo {
    # Graph Authentication Method Table
    static [System.Collections.IDictionary] $method_table = @{
        "#microsoft.graph.microsoftAuthenticatorAuthenticationMethod" = "AuthenticatorApp"
        "#microsoft.graph.phoneAuthenticationMethod" = "PhoneAuthentication"
        "#microsoft.graph.passwordAuthenticationMethod" = "PasswordAuthentication"
        "#microsoft.graph.fido2AuthenticationMethod" = "Fido2"
        "#microsoft.graph.windowsHelloForBusinessAuthenticationMethod" = "WindowsHelloForBusiness"
        "#microsoft.graph.emailAuthenticationMethod" = "EmailAuthentication"
        "#microsoft.graph.temporaryAccessPassAuthenticationMethod" = "TemporaryAccessPass"
        "#microsoft.graph.passwordlessMicrosoftAuthenticatorAuthenticationMethod" = "Passwordless"
        "#microsoft.graph.softwareOathAuthenticationMethod" = "SoftwareOath"
    
    }

    # Method to get friendly name
    static [string] GetFriendlyName([string]$graph_method) {
        return [GraphAuthenticationMethodInfo]::method_table[$graph_method]
    
    }

    # Method to check if method is valid
    static [bool] IsValidMethod([string]$graph_method) {
        return [GraphAuthenticationMethodInfo]::method_table.ContainsKey($graph_method)
    
    }

    # Method to get all friendly names
    static [string[]] GetAllFriendlyNames() {
        return [GraphAuthenticationMethodInfo]::method_table.Values
    
    }

    # Method to get all graph methods
    static [string[]] GetAllMethods() {
        return [GraphAuthenticationMethodInfo]::method_table.Keys
    
    }
}