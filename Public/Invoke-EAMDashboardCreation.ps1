Function Invoke-EAMDashboardCreation {
    <#
        .SYNOPSIS
        [Deprecated] Generates an Entra ID authentication metrics dashboard.

        .DESCRIPTION
        Deprecated backward-compatibility wrapper. Use Invoke-EAIQDashboardCreation
        instead. This shim forwards all parameters to Invoke-EAIQDashboardCreation and
        will be removed in a future release.

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
        Directory to save the report.

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
        Invoke-EAMDashboardCreation -AllUsers

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
        Write-Warning "Invoke-EAMDashboardCreation is deprecated. Use Invoke-EAIQDashboardCreation instead."

    } Process {
        Invoke-EAIQDashboardCreation @PSBoundParameters

    }

}
