# Changelog

All notable changes to EntraAuthenticationMetrics will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-02-26

### Added

- Support for all Graph environments (Global, US Gov, US Gov DoD, China, Germany)

### Changed

- Optimized reporting when using -GroupId as the parameter. Previously the tool would query the members endpoint for the group then pipe the results to the Get-EAMUser function. Now it selects the needed properties from the members endpoint. Which substantially improves performance.

## [0.0.2] - 2025-02-17

### Changed

- Started using changelog
