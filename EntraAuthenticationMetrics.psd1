@{
    # Module metadata
    ModuleVersion       = "0.2.0"
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
            ReleaseNotes = "Added downloads button to download data as csv from the dashboard. Added tenant name and id header to the dashboard. Changed status to method status. Improved TAP method status logic. Previously, if a TAP was associated with a user but was not usable due to expiration or one-time use it would still show up in the report as enabled. Added support for all graph environments."
        }
    }
}