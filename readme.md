# EntraAuthenticationMetrics

[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/EntraAuthenticationMetrics)](https://www.powershellgallery.com/packages/EntraAuthenticationMetrics)
[![PSGallery Platform](https://img.shields.io/powershellgallery/p/EntraAuthenticationMetrics)](https://www.powershellgallery.com/packages/EntraAuthenticationMetrics)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/EntraAuthenticationMetrics)](https://www.powershellgallery.com/packages/EntraAuthenticationMetrics)

Track and visualize authentication methods in Entra ID (formerly Azure AD) with a focus on Phishing-Resistant authentication.

## Dashboard Previews

The EntraAuthenticationMetrics module provides comprehensive, interactive dashboards to help you understand and manage authentication methods in your organization:

### Comprehensive Authentication Metrics

A user-friendly interface that allows:

- Filtering and searching users
- Detailed view of Phishing-Resistant MFA status
- Method-specific insights

![Entra Authentication Metrics Dashboard](https://github.com/thetolkienblackguy/EntraAuthenticationMetrics/blob/main/Imgs/dashboard.png)

### Authentication Statistics Dashboard

This dashboard offers a detailed breakdown of authentication methods, highlighting:

- Phishing-Resistant MFA adoption
- Strong authentication method coverage
- Standard and legacy authentication method usage

![Authentication Statistics Dashboard](https://github.com/thetolkienblackguy/EntraAuthenticationMetrics/blob/main/Imgs/auth_stats.png)

> **Version:** 0.4.0  
> **Author:** Gabriel Delaney ([thetolkienblackguy.com](https://thetolkienblackguy.com) | [GitHub](https://github.com/thetolkienblackguy) )  
> **Company:** Phoenix Horizons LLC  

## Table of Contents

1. [Breaking Changes (0.4.0)](#breaking-changes-040)
2. [Features](#features)
3. [Prerequisites](#prerequisites)
4. [Installation](#installation)
5. [Authentication Setup](#authentication-setup)
6. [Usage Guide](#usage-guide)
7. [Dashboard Features](#dashboard-features)
8. [Known Limitations](#known-limitations)

## Breaking Changes (0.4.0)

The deprecated `EAM`-prefixed cmdlets are no longer exported as functions. Two are now aliases; two are removed outright.

| Old cmdlet | Status in 0.4.0 | Use instead |
| --- | --- | --- |
| `Invoke-EAMDashboardCreation` | **Alias** of `Invoke-AuthIQDashboardCreation` (identical parameters) | `Invoke-AuthIQDashboardCreation` |
| `Send-EAMMailMessage` | **Alias** of `Send-AuthIQMailMessage` (identical parameters) | `Send-AuthIQMailMessage` |
| `New-EAMAuthenticationReport` | **Removed** (different behavior, not alias-able) | `Invoke-AuthIQDashboardCreation`; Method Inventory CSV export for row data |
| `New-EAMDashboard` | **Removed** (different parameters, not alias-able) | `Invoke-AuthIQDashboardCreation -InputObject $data` |
| `New-EntraAuthenticationMetricsDashboard` | Alias **repointed** to `Invoke-AuthIQDashboardCreation` | `Invoke-AuthIQDashboardCreation` |

Notes:

- The two aliases keep existing scripts working, but the previous runtime deprecation warning is gone. Move to the `AuthIQ` names.
- `New-EAMDashboard` accepted `-DataSet` / `-Outfile` / `-InvokeDashboard`. The equivalent is `Invoke-AuthIQDashboardCreation -InputObject <rows> -FileName <name> -OpenReport`.

### Other changes in 0.4.0

- **User email column.** The Graph `mail` attribute is collected and shown under the user (list and detail) when it differs from the UPN, is searchable, and is added to the Method Inventory CSV export.
- **PRMFA/MFA count fix.** `MFA Registered` is now derived so `PRMFA Enabled` is always a subset; it no longer reports fewer MFA-registered users than PRMFA users.
- **Unknown registration state.** Users absent from the `userRegistrationDetails` report (for example, disabled users) show registration capability as `Unknown` rather than a misleading not-registered state.

## Features

- 🔐 **Phishing-Resistant MFA Tracking**
  - FIDO2 Security Keys
  - Windows Hello for Business
  - Certificate-Based Authentication

- 📱 **Standard Authentication Methods**
  - Microsoft Authenticator App
  - Software OATH Tokens
  - Temporary Access Pass

- 📊 **Interactive Dashboard**
  - Master-detail view: per-user cards for every registered method
  - Per-method **registered** date (with relative age; stale methods highlighted)
  - Passkey detail (type + model), Windows Hello key strength, TAP usability, QR Code + PIN
  - User email shown alongside the UPN (when it differs), plus company and department in the detail; all searchable
  - Real-time filtering, search, and sorting
  - Dark/Light mode toggle and adoption statistics (incl. Passkeys by Model)
  - Per-user `MfaStatus` and `PrmfaStatus` (Registered / Not Registered), tracked separately
  - Method Inventory CSV export (one row per user/method, includes email, company, department, both statuses)
  - Users Without MFA CSV export (no registered MFA at all: highest-priority targets)
  - Users Without PRMFA CSV export (have MFA but no phishing-resistant method: upgrade targets)
  - Registration capability (MFA / passwordless / SSPR, default method) from the Entra userRegistrationDetails report

- 📋 **Reporting Options**
  - Interactive HTML dashboard
  - Email delivery via Graph API
  - Custom filtering capabilities

## Prerequisites

### Required Components

- PowerShell 5.1 or PowerShell 7.x
- Microsoft.Graph.Authentication module (automatically installed)

### Microsoft Graph Permissions

1. **For Dashboard Generation**:
   - User.Read.All
   - GroupMember.Read.All
   - UserAuthenticationMethod.Read.All
   - AuditLog.Read.All (for the userRegistrationDetails registration report)

2. **For Email Functionality** (Additional):
   - Mail.Send (Application permission only)

## Installation

```powershell
# Install from PowerShell Gallery
Install-Module -Name EntraAuthenticationMetrics -Scope CurrentUser

# Import the module
Import-Module EntraAuthenticationMetrics
```

## Authentication Setup

### Interactive Authentication (Dashboard Only)

```powershell
# Connect with required scopes
Connect-MgGraph -Scopes @(
    "User.Read.All",
    "GroupMember.Read.All",
    "UserAuthenticationMethod.Read.All",
    "AuditLog.Read.All"
)
```

### App Registration (Required for Email)

1. Navigate to [Entra Portal](https://entra.microsoft.com) > App Registrations
2. Create New Registration:
   - Name: "EntraAuthenticationMetrics"
   - Supported account type: Single tenant
   - Click Register
   ![App Registration](https://github.com/thetolkienblackguy/EntraAuthenticationMetrics/blob/main/Imgs/app_registration.png)

3. Add Required Permissions:
   - Click "API Permissions"
   - Add Microsoft Graph permissions:
     - User.Read.All (Application)
     - GroupMember.Read.All (Application)
     - UserAuthenticationMethod.Read.All (Application)
     - AuditLog.Read.All (Application)
     - Mail.Send (Application)
   - Grant admin consent
   ![Graph API Permissions](https://github.com/thetolkienblackguy/EntraAuthenticationMetrics/blob/main/Imgs/graph_api_permissions.png)

4. Create Secret or Certificate:
   - Under "Certificates & secrets"
   - Create new client secret or upload certificate
   - Save credentials securely

5. Connect Using App Credentials:

```powershell
# Using client secret
$client_id = "your-client-id"
$client_secret = "your-client-secret" | ConvertTo-SecureString -AsPlainText -Force
$client_secret_credential = New-Object System.Management.Automation.PSCredential($client_id, $client_secret)
$tenant_id = "your-tenant-id"

Connect-MgGraph -ClientSecretCredential $client_secret_credential -TenantId $tenant_id

# Or using certificate
Connect-MgGraph -ClientId $client_id -CertificateThumbprint "cert-thumbprint" -TenantId $tenant_id
```

## Usage Guide

### Dashboard Generation Methods

#### All Users Dashboard

```powershell
# Generate dashboard for all users (saved under .\EntraAuthenticationMetrics)
Invoke-AuthIQDashboardCreation -AllUsers

# Generate dashboard and open it in the browser
Invoke-AuthIQDashboardCreation -AllUsers -OpenReport

# Generate dashboard and suppress certificate warning
Invoke-AuthIQDashboardCreation -AllUsers -IgnoreCertificateWarning
```

#### Security Group Based Dashboard

```powershell
# Create dashboard for specific group
$group_id = "12345678-1234-1234-1234-123456789012"
Invoke-AuthIQDashboardCreation -GroupId $group_id

```

#### Filter Based Dashboard

```powershell
# Filter examples

# Users with specific domain
$domain_filter = "endsWith(userPrincipalName,'@contoso.com')"
Invoke-AuthIQDashboardCreation -Filter $domain_filter

# Users with specific display name pattern
$name_filter = "startsWith(displayName,'A')"
Invoke-AuthIQDashboardCreation -Filter $name_filter
```

#### CSV Import Dashboard

```powershell
# CSV file should contain a column with user identifiers (UPN or Object ID)
# Example CSV content:
# UserPrincipalName
# user1@contoso.com
# user2@contoso.com

# Generate dashboard from CSV
Invoke-AuthIQDashboardCreation -ImportCsv -Path ".\users.csv" -IdentityHeader "UserPrincipalName"
```

### Email Dashboard

```powershell
# Generate and email dashboard (Invoke-AuthIQDashboardCreation returns the report path)
$dashboard_path = Invoke-AuthIQDashboardCreation -AllUsers

Send-AuthIQMailMessage -To "security-team@contoso.com" -From "reports@contoso.com" -Subject "Authentication Methods Dashboard" -Body "Please find attached the latest authentication methods dashboard." -Attachments $dashboard_path
```

### Report Data Export

Three CSV exports are available from the dashboard header:

- **Export Method Inventory CSV** - one row per user / method instance, including user email, company, department, `MfaStatus`, `PrmfaStatus`, method category, strength, and registered date.
- **Export Users Without MFA** - one row per user with no registered MFA method at all, with email, company, department, default MFA method, and whether registration-report data was available. Highest-priority registration targets.
- **Export Users Without PRMFA** - one row per user who has MFA but no phishing-resistant method, with email, company, department, default MFA method, and method count. The PRMFA upgrade targets. Together with the no-MFA list this covers everyone lacking phishing-resistant MFA.

> The standalone `New-EAMAuthenticationReport` cmdlet was removed in 0.4.0. If you need the report rows in a variable for scripting, capture the report path from `Invoke-AuthIQDashboardCreation` and use the dashboard CSV export, or open an issue if a dedicated data cmdlet would help your workflow.

## Dashboard Features

The interactive HTML dashboard provides:

- Real-time user filtering and search
- Method-specific views for detailed analysis
- Dark/Light mode toggle
- Comprehensive statistics panel

## Known Limitations

1. **Certificate Authentication Detection**
   - Based on userCertificateIds property in Entra ID
   - May not reflect all certificate mapping configurations
   - Warning displayed unless suppressed with -IgnoreCertificateWarning

2. **Email Functionality**
   - Requires application (not delegated) permissions
   - Mail.Send permission must be granted at application level

3. **Beta Graph Endpoints**
   - Per-method registered/last-used dates and passkey metadata come from the beta `/authentication/methods` endpoint (requires `UserAuthenticationMethod.Read.All`)
   - Registration capability chips come from the beta `reports/authenticationMethods/userRegistrationDetails` report (requires `AuditLog.Read.All`); its "Registration data as of" timestamp reflects when Entra last refreshed the report
   - Per-method **last-used** is not shown: the `fido2AuthenticationMethod` resource has no `lastUsedDateTime` property, and for types that do (for example Windows Hello for Business) Entra usually leaves it `null`, so the value was unreliable and was removed. Registered (`createdDateTime`) is reliable and is shown
   - Beta Graph endpoints are subject to change

4. **Disabled Users and Registration Report Coverage**
   - Disabled accounts (`accountEnabled = false`) are excluded from all reporting, since they are not registration targets and Entra omits them from `userRegistrationDetails`
   - The report still refreshes periodically, so a recently changed enabled user may briefly be missing from it; such users show registration capability (MFA / passwordless / SSPR, default method) as `Unknown` rather than `false`, while their live method data (including PRMFA and MFA Registered) is still shown

5. **Large Environment Considerations**
   - Progress bars displayed for large queries
   - Consider filtering for better performance

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
