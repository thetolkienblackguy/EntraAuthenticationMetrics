Function Invoke-EAIQDashboardCreation {
    <#
        .SYNOPSIS
        Generates an interactive Entra ID authentication metrics dashboard.

        .DESCRIPTION
        Collects per-user authentication method state and the authentication
        method registration report from Microsoft Graph, then renders a
        self-contained HTML dashboard. Data can be gathered for all users, a
        Graph filter, a group's transitive members, or a CSV import - or an
        existing dataset can be supplied via InputObject.

        Registration status (isMfaRegistered, isMfaCapable, isPasswordlessCapable,
        methodsRegistered, defaultMfaMethod, and related fields) is read from the
        beta reports/authenticationMethods/userRegistrationDetails endpoint, which
        requires the AuditLog.Read.All permission.

        .PARAMETER AllUsers
        Gather data for all users from Entra ID.

        .PARAMETER Filter
        Gather data for users matching the specified Graph filter.

        .PARAMETER GroupId
        The ID of the group whose transitive members are reported on.

        .PARAMETER ImportCsv
        Import users from a CSV file.

        .PARAMETER Path
        The path to the CSV file containing user identifiers.

        .PARAMETER IdentityHeader
        The header in the CSV that contains the user identifier.

        .PARAMETER InputObject
        Existing authentication report data to render instead of gathering it.

        .PARAMETER OutputPath
        Directory to save the report. Defaults to .\EntraAuthenticationMetrics under the current location.

        .PARAMETER FileName
        Name of the HTML report file.

        .PARAMETER Title
        Title displayed in the report header.

        .PARAMETER OpenReport
        Opens the generated report in the default browser.

        .PARAMETER IgnoreCertificateWarning
        Suppress the certificate-based authentication warning.

        .INPUTS
        System.Object[]

        .OUTPUTS
        System.String

        .EXAMPLE
        Invoke-EAIQDashboardCreation -AllUsers -OpenReport
        Generates the dashboard for every user and opens it.

        .EXAMPLE
        Invoke-EAIQDashboardCreation -GroupId "12345678-1234-1234-1234-123456789012"
        Generates the dashboard for the transitive members of a group.

        .EXAMPLE
        $report = Get-EAIQAuthenticationReportData -AllUsers
        Invoke-EAIQDashboardCreation -InputObject $report.Report

    #>
    [CmdletBinding(DefaultParameterSetName="AllUsers")]
    [OutputType([System.String])]
    param(
        [Parameter(Mandatory=$false, ParameterSetName="AllUsers")]
        [switch]$AllUsers,
        [Parameter(Mandatory=$true, ParameterSetName="Filter")]
        [string]$Filter,
        [Parameter(Mandatory=$true, ParameterSetName="Group")]
        [ValidateScript({
            $_ -match "^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$"

        })]
        [string]$GroupId,
        [Parameter(Mandatory=$false, ParameterSetName="ImportCsv")]
        [switch]$ImportCsv,
        [Parameter(Mandatory=$true, ParameterSetName="ImportCsv")]
        [ValidateScript({
            Test-Path -Path $_ -PathType Leaf

        })]
        [string]$Path,
        [Parameter(Mandatory=$false, ParameterSetName="ImportCsv")]
        [string]$IdentityHeader = "id",
        [Parameter(Mandatory=$true, ParameterSetName="InputObject")]
        [object[]]$InputObject,
        [Parameter(Mandatory=$false)]
        [string]$OutputPath = "$($PWD)\EntraAuthenticationMetrics",
        [Parameter(Mandatory=$false)]
        [string]$FileName = "Entra_Authentication_Metrics_Dashboard.html",
        [Parameter(Mandatory=$false)]
        [string]$Title = "Entra Authentication Metrics",
        [Parameter(Mandatory=$false)]
        [switch]$OpenReport,
        [Parameter(Mandatory=$false)]
        [switch]$IgnoreCertificateWarning

    )
    Begin {
        $ErrorActionPreference = "Stop"
        Write-Debug "Initializing dashboard creation"

        $template_path = Join-Path -Path $PSScriptRoot -ChildPath "..\Templates"
        $report_builder = [EAIQReportBuilder]::new($template_path, $outputPath)

        $log_path = Join-Path -Path $outputPath -ChildPath "Logs\Invoke-EAIQDashboardCreation_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').log"
        $is_interactive = ($host.Name -ne "Default Host")
        $log_manager = [EAIQLogManager]::new($log_path, $true, $true, $is_interactive)

        $report_rows = $null
        $data_as_of = "Not available"
        $tenant_name = "Unknown Tenant"

    } Process {
        $log_manager.Initialize("Starting authentication dashboard creation")

        Try {
            If ($PSCmdlet.ParameterSetName -eq "InputObject") {
                $log_manager.Information("Using supplied dataset")
                $report_rows = $inputObject

            } Else {
                $data_params = @{}

                Switch ($PSCmdlet.ParameterSetName) {
                    "Filter" {
                        $data_params["Filter"] = $filter

                    } "Group" {
                        $data_params["GroupId"] = $groupId

                    } "ImportCsv" {
                        $data_params["Path"] = $path
                        $data_params["IdentityHeader"] = $identityHeader

                    } Default {
                        $data_params["AllUsers"] = $true

                    }

                }

                $log_manager.Information("Gathering authentication data ($($PSCmdlet.ParameterSetName))")
                $data = Get-EAIQAuthenticationReportData @data_params
                $report_rows = $data.Report
                $data_as_of = $data.DataAsOf
                $tenant_name = $data.TenantName

            }

        } Catch {
            $log_manager.Error("Failed to gather authentication data: $($_.Exception.Message)")
            Write-Error "Failed to gather authentication data: $($_.Exception.Message)" -ErrorAction Stop

        }

    } End {
        If (!$report_rows) {
            $log_manager.Warning("No data was found to create the dashboard")
            Write-Warning "No data was found to create the dashboard"
            Return

        }

        Try {
            $log_manager.Information("Rendering dashboard for $(@($report_rows).Count) user(s)")
            $report_html = $report_builder.BuildAuthenticationReport($report_rows, $title, $tenant_name, $data_as_of)
            $report_path = $report_builder.ExportReport($report_html, $null, $fileName)
            $log_manager.Success("Report created at: $report_path")

            If ($openReport) {
                $ii_params = @{}
                $ii_params["Path"] = $report_path
                Invoke-Item @ii_params

            }

            If (!$ignoreCertificateWarning) {
                Write-EAIQCertificateWarning

            }

            $log_manager.Finalize("Authentication dashboard creation complete")
            $report_path

        } Catch {
            $log_manager.Error("Failed to create dashboard: $($_.Exception.Message)")
            Write-Error "Failed to create dashboard: $($_.Exception.Message)" -ErrorAction Stop

        }

    }

}
