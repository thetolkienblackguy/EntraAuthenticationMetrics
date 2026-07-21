@{
    # Module metadata
    ModuleVersion       = "0.3.0"
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
        "Invoke-EAIQDashboardCreation","Send-EAIQMailMessage",
        "Invoke-EAMDashboardCreation","Send-EAMMailMessage",
        "New-EAMAuthenticationReport","New-EAMDashboard"
    )
    CmdletsToExport     = @()
    VariablesToExport   = @()
    AliasesToExport     = @("New-EntraAuthenticationMetricsDashboard")

    # Private Data
    PrivateData = @{
        PSData = @{
            Tags         = @("AzureAD","EntraID","Authentication","Metrics")
            LicenseUri   = "https://github.com/thetolkienblackguy/EntraAuthenticationMetrics/blob/main/LICENSE"
            ProjectUri   = "https://github.com/thetolkienblackguy/EntraAuthenticationMetrics"
            ReleaseNotes = "Re-architected the module onto the IQ-family class model (EAIQ prefix) to align with ConditionalAccessIQ (CAIQ) and EntraHealthIQ (EHIQ). Primary cmdlets renamed to Invoke-EAIQDashboardCreation and Send-EAIQMailMessage. Authentication methods are now read from the beta /authentication/methods endpoint, capturing per-method registered (createdDateTime) and last-used (lastUsedDateTime) dates, passkey type/model, Windows Hello key strength, TAP usability, QR Code + PIN, and any unknown method type. New master-detail dashboard: pick a user and see each method as a card with its registered/last-used dates and strength, plus adoption statistics (incl. Passkeys by Model) and a Method Inventory CSV export. Registration capability (MFA/passwordless/SSPR, default method) comes from the beta userRegistrationDetails report (requires AuditLog.Read.All). Fully self-contained (no external CDN). Invoke-EAMDashboardCreation, Send-EAMMailMessage, New-EAMAuthenticationReport, and New-EAMDashboard remain as deprecated wrappers. Output goes to an EntraAuthenticationMetrics folder; the report opens only with -OpenReport."
        }
    }
}