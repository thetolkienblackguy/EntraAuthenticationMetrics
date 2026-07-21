Function New-EAMAuthenticationReport {
    <#
        .SYNOPSIS
        [Deprecated] Gets the authentication report dataset for Entra ID users.

        .DESCRIPTION
        Deprecated. Use Invoke-EAIQDashboardCreation to generate the dashboard, or
        Get-EAIQAuthenticationReportData to obtain the raw dataset. This function is
        retained as a thin wrapper for backward compatibility and will be removed in
        a future release. It returns the per-user authentication report rows.

        .PARAMETER AllUsers
        Get report for all users from Entra ID.

        .PARAMETER Filter
        Get report for users matching the specified Graph filter.

        .PARAMETER GroupId
        The ID of the group whose transitive members are reported on.

        .PARAMETER ImportCsv
        Import users from a CSV file.

        .PARAMETER Path
        The path to the CSV file containing user identifiers.

        .PARAMETER IdentityHeader
        The header in the CSV that contains the user identifier.

        .INPUTS
        None

        .OUTPUTS
        System.Object

        .EXAMPLE
        New-EAMAuthenticationReport -AllUsers

    #>
    [CmdletBinding(DefaultParameterSetName="AllUsers")]
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
        [string]$IdentityHeader = "id"

    )
    Begin {
        Write-Warning "New-EAMAuthenticationReport is deprecated. Use Invoke-EAIQDashboardCreation, or Get-EAIQAuthenticationReportData for the raw dataset."

    } Process {
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

        $data = Get-EAIQAuthenticationReportData @data_params
        $data.Report

    }

}
