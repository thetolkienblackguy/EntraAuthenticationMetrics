# EntraAuthenticationMetrics

[![GitHub Release](https://img.shields.io/github/v/release/thetolkienblackguy/EntraAuthenticationMetrics.svg)](https://github.com/thetolkienblackguy/EntraAuthenticationMetrics/releases)
[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/EntraAuthenticationMetrics)](https://www.powershellgallery.com/packages/EntraAuthenticationMetrics)
[![PSGallery Platform](https://img.shields.io/powershellgallery/p/EntraAuthenticationMetrics)](https://www.powershellgallery.com/packages/EntraAuthenticationMetrics)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/EntraAuthenticationMetrics)](https://www.powershellgallery.com/packages/EntraAuthenticationMetrics)
[![License](https://img.shields.io/github/license/thetolkienblackguy/EntraAuthenticationMetrics)](https://github.com/thetolkienblackguy/EntraAuthenticationMetrics/blob/main/LICENSE)

Track and visualize authentication methods in Entra ID (formerly Azure AD) with a focus on Phishing-Resistant authentication.

## Dashboard Previews

The EntraAuthenticationMetrics module provides comprehensive, interactive dashboards to help you understand and manage authentication methods in your organization:

### Comprehensive Authentication Metrics
A user-friendly interface that allows:
- Filtering and searching users
- Detailed view of Phishing-Resistant MFA status
- Method-specific insights

![Entra Authentication Metrics Dashboard](imgs/entra_authentication_metrics.png)

### Authentication Statistics Dashboard
This dashboard offers a detailed breakdown of authentication methods, highlighting:
- Phishing-Resistant MFA adoption
- Strong authentication method coverage
- Standard and legacy authentication method usage

![Authentication Statistics Dashboard](imgs/authentication_statistics.png)

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
  - CSV export for analysis
  - Email delivery via Graph API
  - Custom filtering capabilities

## Prerequisites

### Required Components

- PowerShell 5.1 or PowerShell 7.x
- Microsoft.Graph.Authentication module (automatically installed)

### Microsoft Graph Permissions

1. **For Dashboard Generation**:
   - User.Read.All
   - Group.Read.All
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
    "Group.Read.All",
    "UserAuthenticationMethod.Read.All"
)
```

### App Registration (Required for Email)

1. Navigate to [Entra Portal](https://entra.microsoft.com) > App Registrations
2. Create New Registration:
   - Name: "EntraAuthenticationMetrics"
   - Supported account type: Single tenant
   - Click Register

3. Add Required Permissions:
   - Click "API Permissions"
   - Add Microsoft Graph permissions:
     - User.Read.All (Application)
     - Group.Read.All (Application)
     - UserAuthenticationMethod.Read.All (Application)
     - Mail.Send (Application)
   - Grant admin consent

4. Create Secret or Certificate:
   - Under "Certificates & secrets"
   - Create new client secret or upload certificate
   - Save credentials securely

5. Connect Using App Credentials:

```powershell
# Using client secret
$client_id = "your-client-id"
$client_secret = "your-client-secret" | ConvertTo-SecureString -AsPlainText -Force
$tenant_id = "your-tenant-id"

Connect-MgGraph -ClientId $client_id -ClientSecret $client_secret -TenantId $tenant_id

# Or using certificate
Connect-MgGraph -ClientId $client_id -CertificateThumbprint "cert-thumbprint" -TenantId $tenant_id
```

## Usage Guide

### Report Generation Methods

#### All Users Report

```powershell
# Basic all users report
$all_users_report = New-EAMAuthenticationReport -AllUsers

# Generate dashboard for all users
Invoke-EAMDashboardCreation -AllUsers

# Export all users report
$all_users_report = New-EAMAuthenticationReport -AllUsers
$allUsersReport | Export-Csv -Path "all_users_report.csv" -NoTypeInformation
```

#### Security Group Based Report

```powershell
# Get report for specific group
$group_id = "12345678-1234-1234-1234-123456789012"
$group_report = New-EAMAuthenticationReport -GroupId $group_id

# Create dashboard for group
Invoke-EAMDashboardCreation -GroupId $group_id

# Export group report
$group_report | Export-Csv -Path "group_report.csv" -NoTypeInformation
```

#### Filter Based Report

```powershell
# Filter examples

# Users with specific domain
$domain_filter = "endsWith(userPrincipalName,'@contoso.com')"
$domain_report = New-EAMAuthenticationReport -Filter $domain_filter

# Users with specific display name pattern
$name_filter = "startsWith(displayName,'A')"
$name_report = New-EAMAuthenticationReport -Filter $name_filter

```

#### CSV Import Report

```powershell
# CSV file should contain a column with user identifiers (UPN or Object ID)
# Example CSV content:
# UserPrincipalName
# user1@contoso.com
# user2@contoso.com

# Generate report from CSV
$csv_report = New-EAMAuthenticationReport -ImportCsv -Path ".\users.csv" -IdentityHeader "UserPrincipalName"

# Create dashboard from CSV import
Invoke-EAMDashboardCreation -ImportCsv -Path ".\users.csv" -IdentityHeader "UserPrincipalName"

# Export processed report
$csv_report | Export-Csv -Path "processed_report.csv" -NoTypeInformation
```

### Email Reports

```powershell
# Generate and email dashboard
$report = New-EAMAuthenticationReport -AllUsers
$dashboard_path = Join-Path $env:TEMP "auth_report.html"
New-EAMDashboard -DataSet $report -Outfile $dashboard_path -InvokeDashboard:$false

Send-EAMMailMessage -To "security-team@contoso.com" `
                    -From "reports@contoso.com" `
                    -Subject "Authentication Methods Report" `
                    -Body "Please find attached the latest authentication methods dashboard." `
                    -Attachments $dashboard_path
```

## Sample Output

### CSV Export Format

```csv
User,PRMFAStatus,Fido2,WindowsHelloForBusiness,Certificate,AuthenticatorApp,PhoneAuthentication,EmailAuthentication
user1@contoso.com,Enabled,True,False,False,True,False,False
user2@contoso.com,Disabled,False,False,False,True,True,False
user3@contoso.com,Enabled,False,True,False,True,False,False
```

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
