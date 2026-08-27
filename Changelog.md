# Changelog

All notable changes to EntraAuthenticationMetrics will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0] - 2026-07-24

### Removed (Breaking)

- `New-EAMAuthenticationReport` and `New-EAMDashboard` are removed. They had different behavior and parameters from the `AuthIQ` cmdlets, so they are not provided as aliases. Use `Invoke-AuthIQDashboardCreation` to build the dashboard; for row-level data use the dashboard's Method Inventory CSV export.
- The deprecated cmdlets are no longer exported as functions. `Invoke-EAMDashboardCreation` and `Send-EAMMailMessage` are now **aliases** of `Invoke-AuthIQDashboardCreation` and `Send-AuthIQMailMessage` (identical parameters), so existing calls keep working, but the runtime deprecation warning is gone.
- `New-EntraAuthenticationMetricsDashboard` now aliases `Invoke-AuthIQDashboardCreation` (previously the removed `New-EAMDashboard`); its parameters are those of `Invoke-AuthIQDashboardCreation`.

### Changed

- Microsoft Authenticator registrations now surface the `clientAppName`, distinguishing the standalone Authenticator app from Authenticator Lite embedded in Outlook mobile. The aggregate `/authentication/methods` endpoint does not return this property, so for each user with an Authenticator method the tool makes one supplemental call to the type-specific `/authentication/microsoftAuthenticatorMethods` endpoint (non-fatal on error). It appears in the method detail ("Authenticator Lite (Outlook mobile)") and as a dedicated `ClientApp` column in the Method Inventory and All Users CSV exports.
- Disabled accounts (`accountEnabled = false`) are now excluded from all reporting (dashboard, counts, and CSV exports). They are not registration targets and Entra omits them from the `userRegistrationDetails` report, which previously showed them with an Unknown registration state.
- Per-user status is now tracked as two clearly-named fields, `MfaStatus` and `PrmfaStatus`, each `Registered` / `Not Registered`. This replaces the single `PRMFAStatus` field whose `Enabled` / `Disabled` values only described phishing-resistant coverage and were easily confused with the account state. Both statuses are computed once in the module (PRMFA is always a subset of MFA) and are included as columns in the Method Inventory CSV export.

### Added

- User email (the Graph `mail` attribute) is now collected and shown as a secondary line under the user in the list and detail header (only when it differs from the UPN), is included in user search, and is added as an `Email` column to the Method Inventory CSV export.
- User company and department (the Graph `companyName` and `department` attributes) are collected and shown as info chips in the user detail header (when present), are included in user search, and are added as `Company` and `Department` columns to the Method Inventory CSV export.
- "Users Without MFA" CSV export: a one-row-per-user list of everyone with no registered MFA method, including email, company, department, default MFA method, and whether registration-report data was available. Highest-priority registration targets.
- "Users Without PRMFA" CSV export: a one-row-per-user list of users who have MFA but no phishing-resistant method (disjoint from the no-MFA list; together they cover everyone lacking PRMFA), including email, company, department, default MFA method, and method count. The PRMFA upgrade targets.
- "All Users" CSV export: one row per enumerated auth method (with full method detail) plus a single method-blank row for users with no method, so every user in the run is present. Each row carries `MfaStatus`, `PrmfaStatus`, `MethodCount` (enumerated) and `IsMfaRegistered` / `MethodsRegistered` (from Entra's report). The other exports capture only the extremes (users with methods, or users flagged as having none); a user whom Entra flags as MFA-registered but for whom no method was enumerated previously appeared in neither. This export accounts for every user, keeps full method detail, and surfaces flag-vs-method gaps.

### Fixed

- `MfaStatus` and `PrmfaStatus` are now derived purely from the live enumerated methods: MFA is registered if the user holds any method, PRMFA if any is phishing-resistant (so PRMFA is always a subset of MFA). The `userRegistrationDetails` report's `isMfaRegistered` flag is no longer part of the calculation, because it lags the live data by up to ~36 hours and is unreliable in both directions (for example, `false` while a Windows Hello for Business method exists, or `true` for a user with no enumerable Entra method). The flag and `methodsRegistered` are still captured as separate columns for reference so the report-vs-live gap stays visible.
- Users absent from the `userRegistrationDetails` report (for example, disabled users, which Entra excludes) now show registration capability as `Unknown` instead of a misleading not-registered (`false`) state. "No data" is no longer collapsed into "not registered."
- Per-method registered dates now serialize as ISO 8601 strings. Windows PowerShell 5.1 serialized the underlying `[datetime]` values as `/Date(ms)/`, which the dashboard could not parse (blank dates) and which leaked into the CSV export.
- Temporary Access Passes that have been used or have expired (`isUsable = false`) are excluded entirely: they no longer count toward MFA registration or appear as a method. Only a currently usable TAP is counted and shown.
- Removed the per-method last-used column from the dashboard and CSV. Graph does not expose `lastUsedDateTime` for FIDO2 methods and usually leaves it `null` for others, so the value was unreliable and misleading. Only the registered date is shown.

## [0.3.0] - 2026-07-20

### Added

- Per-method-instance detail from the beta `/authentication/methods` endpoint: every registered method now carries its own `createdDateTime` (registered) and `lastUsedDateTime` (last used), plus type-specific detail - FIDO2 `passkeyType` and `model`, Windows Hello `keyStrength`, Temporary Access Pass usability, and Microsoft Authenticator device/app. QR Code + PIN, hardware OATH, platform-credential passkeys, and any future/unknown method type are captured (no method is dropped).
- New master-detail Methods view: pick a user and see each authentication method as a card with its registered date, last-used date (with relative age; stale methods highlighted), passkey type, and strength. User list can be filtered by registration recency (last 7 / 14 / 30 days or 6 months).
- Passkey type classification for FIDO2 credentials (Authenticator passkey / Physical passkey / Synced passkey / Windows containerized passkey) derived from `passkeyType` + model. Windows Hello for Business and Platform SSO are treated as their own credential types, not passkeys (they still count toward phishing-resistant MFA).
- Statistics view with donut-ring adoption KPIs, a method-adoption bar chart (with hover tooltips), and "Passkeys by Type" and "Passkeys by Model" breakdowns.
- Method Inventory CSV export (one row per user/method instance, including registered and last-used dates).
- Authentication method capability from the beta `reports/authenticationMethods/userRegistrationDetails` report (MFA / passwordless / SSPR capability, default MFA method, user type, admin), shown as chips in the user detail header. Requires the `AuditLog.Read.All` permission.
- "Registration data as of" timestamp in the dashboard header, sourced from the report's `lastUpdatedDateTime`.
- `Config/default.json` reference configuration.

### Changed

- Re-architected the module onto the IQ-family class model (`AuthIQ` prefix) to align with ConditionalAccessIQ (CAIQ) and EntraHealthIQ (EHIQ): a Graph request client, template manager, and log manager under `Classes/Helpers`, and user / registration-details / authentication-method / report-builder components under `Classes/Components`. The `Private/Get-EAM*` data functions were folded into these classes.
- Renamed the primary cmdlets to the `AuthIQ` prefix: `Invoke-AuthIQDashboardCreation` and `Send-AuthIQMailMessage`.
- Rebuilt the dashboard in the shared IQ interface (app header, tab navigation, clickable summary cards, master-detail split pane) on the common indigo/dark design tokens; the Font Awesome CDN dependency was removed so the report is fully self-contained and offline.
- Authentication methods are now read from beta (previously v1.0), which is what exposes the per-method registered/last-used timestamps and passkey metadata.
- `Invoke-AuthIQDashboardCreation` writes to an `EntraAuthenticationMetrics` output folder, logs to `Logs\`, and opens the report only when `-OpenReport` is supplied (previously opened by default).

### Deprecated

- `Invoke-EAMDashboardCreation`, `Send-EAMMailMessage`, `New-EAMAuthenticationReport`, and `New-EAMDashboard` are retained as thin, warning wrappers over the `AuthIQ` cmdlets and will be removed in a future release.

## [0.2.0] - 2025-03-09

### Added

- Downloads button to download data as csv from the dashboard
- Tenant name and id header to the dashboard

### Fixed

- Change Temporary Access Pass method status logic.  Previously, if a TAP was associated with a user but was not usable due to expiration or one-time use it would still show up in the report as enabled.

### Changed

- "Status" header in the report to "Method Status"

## [0.1.0] - 2025-03-07

### Added

- Support for all Graph environments (Global, US Gov, US Gov DoD, China, Germany)

### Changed

- Optimized reporting when using -GroupId as the parameter. Previously the tool would query the members endpoint for the group then pipe the results to the Get-EAMUser function. Now it selects the needed properties from the members endpoint. Which substantially improves performance.

## [0.0.2] - 2025-02-17

### Changed

- Started using changelog
