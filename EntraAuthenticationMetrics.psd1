@{
    # Module metadata
    ModuleVersion       = "0.4.0"
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
        "Invoke-AuthIQDashboardCreation","Send-AuthIQMailMessage"
    )
    CmdletsToExport     = @()
    VariablesToExport   = @()
    AliasesToExport     = @(
        "Invoke-EAIQDashboardCreation","Send-EAIQMailMessage",
        "Invoke-EAMDashboardCreation","Send-EAMMailMessage",
        "New-EntraAuthenticationMetricsDashboard"
    )

    # Private Data
    PrivateData = @{
        PSData = @{
            Tags         = @("AzureAD","EntraID","Authentication","Metrics")
            LicenseUri   = "https://github.com/thetolkienblackguy/EntraAuthenticationMetrics/blob/main/LICENSE"
            ProjectUri   = "https://github.com/thetolkienblackguy/EntraAuthenticationMetrics"
            ReleaseNotes = "BREAKING: the deprecated EAM-prefixed cmdlets are removed as functions. Invoke-EAMDashboardCreation and Send-EAMMailMessage are now aliases of Invoke-AuthIQDashboardCreation and Send-AuthIQMailMessage. New-EAMAuthenticationReport and New-EAMDashboard are removed with no alias (different behavior): use Invoke-AuthIQDashboardCreation, and the dashboard Method Inventory CSV export for row data. Added: user email (mail) as a column in the dashboard, search, and CSV export. Fixed: MFA Registered is now derived so PRMFA is always a subset (a user counts as MFA registered if they hold any registered method or the report says so), correcting cases where PRMFA exceeded MFA Registered; users absent from the userRegistrationDetails report (for example disabled users) now show registration fields as Unknown instead of a misleading not-registered state. Prior IQ-family re-architecture retained: methods read from the beta /authentication/methods endpoint (per-method registered/last-used dates, passkey type/model, Windows Hello key strength, TAP usability), master-detail dashboard, adoption statistics, and registration capability from the beta userRegistrationDetails report (requires AuditLog.Read.All). Fully self-contained (no external CDN); output goes to an EntraAuthenticationMetrics folder and opens only with -OpenReport."
        }
    }
}