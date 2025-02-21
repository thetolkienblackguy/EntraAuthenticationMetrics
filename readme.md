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

> **Version:** 0.0.1  
> **Author:** Gabriel Delaney ([thetolkienblackguy.com](https://thetolkienblackguy.com) | [GitHub](https://github.com/thetolkienblackguy) )  
> **Company:** Phoenix Horizons LLC  

## Table of Contents

1. [Features](#features)
2. [Prerequisites](#prerequisites)
3. [Installation](#installation)
4. [Authentication Setup](#authentication-setup)
5. [Usage Guide](#usage-guide)
6. [Sample Output](#sample-output)
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
  - Real-time filtering and search
  - Dark/Light mode toggle
  - Method-specific views
  - Detailed statistics panel

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
    "UserAuthenticationMethod.Read.All"
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
# Generate dashboard for all users
Invoke-EAMDashboardCreation -AllUsers

# Generate dashboard and suppress certificate warning
Invoke-EAMDashboardCreation -AllUsers -IgnoreCertificateWarning

# Generate dashboard without opening in browser
Invoke-EAMDashboardCreation -AllUsers -InvokeDashboard:$false
```

#### Security Group Based Dashboard

```powershell
# Create dashboard for specific group
$group_id = "12345678-1234-1234-1234-123456789012"
Invoke-EAMDashboardCreation -GroupId $group_id

```

#### Filter Based Dashboard

```powershell
# Filter examples

# Users with specific domain
$domain_filter = "endsWith(userPrincipalName,'@contoso.com')"
Invoke-EAMDashboardCreation -Filter $domain_filter

# Users with specific display name pattern
$name_filter = "startsWith(displayName,'A')"
Invoke-EAMDashboardCreation -Filter $name_filter
```

#### CSV Import Dashboard

```powershell
# CSV file should contain a column with user identifiers (UPN or Object ID)
# Example CSV content:
# UserPrincipalName
# user1@contoso.com
# user2@contoso.com

# Generate dashboard from CSV
Invoke-EAMDashboardCreation -ImportCsv -Path ".\users.csv" -IdentityHeader "UserPrincipalName"
```

### Email Dashboard

```powershell
# Generate and email dashboard
$dashboard_path = "$($PWD)\Entra_Authentication_Metrics_Dashboard.html"
Invoke-EAMDashboardCreation -AllUsers -InvokeDashboard:$false

Send-EAMMailMessage -To "security-team@contoso.com" -From "reports@contoso.com" -Subject "Authentication Methods Dashboard" -Body "Please find attached the latest authentication methods dashboard." -Attachments $dashboard_path
```

### Report Data Export

You can also get the authentication report data in a format suitable for CSV export or use in other scripts:

```powershell
# Get authentication report data
$auth_data = New-EAMAuthenticationReport -AllUsers

# Export to CSV
$auth_data | Export-Csv -Path "auth_report.csv" -NoTypeInformation

# Use in other scripts or create dashboard
Invoke-EAMDashboardCreation -InputObject $auth_data
```

## Sample Output

### Dashboard Features

The interactive HTML dashboard provides:

- Real-time user filtering and search
- Method-specific views for detailed analysis
- Dark/Light mode toggle
- Comprehensive statistics panel
- Exportable data tables

## Known Limitations

1. **Certificate Authentication Detection**
   - Based on userCertificateIds property in Entra ID
   - May not reflect all certificate mapping configurations
   - Warning displayed unless suppressed with -IgnoreCertificateWarning

2. **Email Functionality**
   - Requires application (not delegated) permissions
   - Mail.Send permission must be granted at application level
   - From address must be authorized in tenant

3. **Large Environment Considerations**
   - Progress bars displayed for large queries
   - Consider filtering for better performance
   - Use CSV export for large data sets

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
