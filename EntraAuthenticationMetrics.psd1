@{
    # Module metadata
    ModuleVersion       = "0.1.0"
    GUID                = "49bc84ab-afe2-4659-9ff4-ca536efb6006"
    Author              = "Gabriel Delaney - gdelaney@phzconsulting.com | https://github.com/thetolkienblackguy"
    CompanyName         = "Phoenix Horizons LLC"
    Copyright           = "(c) Phoenix Horizons LLC. All rights reserved."
    Description         = "PowerShell module for gathering authentication metrics from Entra ID."

    # Supported PowerShell editions
    PowerShellVersion   = "5.1"
    CompatiblePSEditions = @("Desktop", "Core")

    # Dependencies
    RequiredModules     = @("Microsoft.Graph.Authentication")

    # Module file paths
    RootModule          = "EntraAuthenticationMetrics.psm1"
    
    FunctionsToExport   = @(
        "Invoke-EAMDashboardCreation","Send-EAMMailMessage",
        "New-EAMAuthenticationReport","New-EAMDashboard"
    )
    CmdletsToExport     = @()
    VariablesToExport   = "*"
    AliasesToExport     = "*"
    
    # Private Data
    PrivateData = @{
        PSData = @{
            Tags         = @("AzureAD","EntraID","Authentication","Metrics")
            LicenseUri   = "https://github.com/thetolkienblackguy/EntraAuthenticationMetrics/blob/main/LICENSE"
            ProjectUri   = "https://github.com/thetolkienblackguy/EntraAuthenticationMetrics"
            ReleaseNotes = "Optimized reporting when using -GroupId as the parameter. Previously the tool would query the members endpoint for the group then pipe the results to the Get-EAMUser function. Now it selects the needed properties from the members endpoint. Which substantially improves performance. Added support for all graph environments."
        }
    }
}