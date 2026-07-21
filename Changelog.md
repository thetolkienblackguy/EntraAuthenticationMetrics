# Changelog

All notable changes to EntraAuthenticationMetrics will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

- Re-architected the module onto the IQ-family class model (`EAIQ` prefix) to align with ConditionalAccessIQ (CAIQ) and EntraHealthIQ (EHIQ): a Graph request client, template manager, and log manager under `Classes/Helpers`, and user / registration-details / authentication-method / report-builder components under `Classes/Components`. The `Private/Get-EAM*` data functions were folded into these classes.
- Renamed the primary cmdlets to the `EAIQ` prefix: `Invoke-EAIQDashboardCreation` and `Send-EAIQMailMessage`.
- Rebuilt the dashboard in the shared IQ interface (app header, tab navigation, clickable summary cards, master-detail split pane) on the common indigo/dark design tokens; the Font Awesome CDN dependency was removed so the report is fully self-contained and offline.
- Authentication methods are now read from beta (previously v1.0), which is what exposes the per-method registered/last-used timestamps and passkey metadata.
- `Invoke-EAIQDashboardCreation` writes to an `EntraAuthenticationMetrics` output folder, logs to `Logs\`, and opens the report only when `-OpenReport` is supplied (previously opened by default).

### Deprecated

- `Invoke-EAMDashboardCreation`, `Send-EAMMailMessage`, `New-EAMAuthenticationReport`, and `New-EAMDashboard` are retained as thin, warning wrappers over the `EAIQ` cmdlets and will be removed in a future release.

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
