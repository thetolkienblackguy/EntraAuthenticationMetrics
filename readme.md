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

> **Version:** 0.3.0  
> **Author:** Gabriel Delaney ([thetolkienblackguy.com](https://thetolkienblackguy.com) | [GitHub](https://github.com/thetolkienblackguy) )  
> **Company:** Phoenix Horizons LLC  

## Table of Contents

1. [Features](#features)
2. [Prerequisites](#prerequisites)
3. [Installation](#installation)
4. [Authentication Setup](#authentication-setup)
5. [Usage Guide](#usage-guide)
6. [Dashboard Features](#dashboard-features)
7. [Known Limitations](#known-limitations)

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
  - Per-method **registered** and **last-used** dates (with relative age; stale methods highlighted)
  - Passkey detail (type + model), Windows Hello key strength, TAP usability, QR Code + PIN
  - Real-time filtering, search, and sorting
  - Dark/Light mode toggle and adoption statistics (incl. Passkeys by Model)
  - Method Inventory CSV export (one row per user/method)
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
Invoke-EAIQDashboardCreation -AllUsers

# Generate dashboard and open it in the browser
Invoke-EAIQDashboardCreation -AllUsers -OpenReport

# Generate dashboard and suppress certificate warning
Invoke-EAIQDashboardCreation -AllUsers -IgnoreCertificateWarning
```

#### Security Group Based Dashboard

```powershell
# Create dashboard for specific group
$group_id = "12345678-1234-1234-1234-123456789012"
Invoke-EAIQDashboardCreation -GroupId $group_id

```

#### Filter Based Dashboard

```powershell
# Filter examples

# Users with specific domain
$domain_filter = "endsWith(userPrincipalName,'@contoso.com')"
Invoke-EAIQDashboardCreation -Filter $domain_filter

# Users with specific display name pattern
$name_filter = "startsWith(displayName,'A')"
Invoke-EAIQDashboardCreation -Filter $name_filter
```

#### CSV Import Dashboard

```powershell
# CSV file should contain a column with user identifiers (UPN or Object ID)
# Example CSV content:
# UserPrincipalName
# user1@contoso.com
# user2@contoso.com

# Generate dashboard from CSV
Invoke-EAIQDashboardCreation -ImportCsv -Path ".\users.csv" -IdentityHeader "UserPrincipalName"
```

### Email Dashboard

```powershell
# Generate and email dashboard (Invoke-EAIQDashboardCreation returns the report path)
$dashboard_path = Invoke-EAIQDashboardCreation -AllUsers

Send-EAIQMailMessage -To "security-team@contoso.com" -From "reports@contoso.com" -Subject "Authentication Methods Dashboard" -Body "Please find attached the latest authentication methods dashboard." -Attachments $dashboard_path
```

### Report Data Export

You can also get the authentication report data (including registration status columns) in a format suitable for CSV export or use in other scripts:

```powershell
# Get authentication report data
# Note: New-EAMAuthenticationReport is deprecated in favor of Invoke-EAIQDashboardCreation; it remains for backward compatibility.
$auth_data = New-EAMAuthenticationReport -AllUsers

# Export to CSV
$auth_data | Export-Csv -Path "auth_report.csv" -NoTypeInformation

# Use in other scripts or create dashboard
Invoke-EAIQDashboardCreation -InputObject $auth_data
```

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
   - `lastUsedDateTime` is populated by Entra and may be `null` (shown as "Never") for methods that have not been used or where usage is not yet recorded
   - Beta Graph endpoints are subject to change

4. **Large Environment Considerations**
   - Progress bars displayed for large queries
   - Consider filtering for better performance

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
