Function New-EAMDashboard {
    <#
        .SYNOPSIS
        [Deprecated] Creates an authentication dashboard from a dataset.

        .DESCRIPTION
        Deprecated. Use Invoke-EAIQDashboardCreation instead. This function is
        retained as a thin wrapper for backward compatibility and will be removed in
        a future release. It renders the supplied dataset to a self-contained HTML
        dashboard using the current template set.

        .PARAMETER DataSet
        The dataset to create the dashboard from.

        .PARAMETER Outfile
        The path to the output HTML file.

        .PARAMETER Title
        Title displayed in the report header.

        .PARAMETER InvokeDashboard
        Open the dashboard in the default browser once created.

        .INPUTS
        System.Object[]

        .OUTPUTS
        System.String

        .EXAMPLE
        New-EAMDashboard -DataSet $data -InvokeDashboard

    #>
    [Alias("New-EntraAuthenticationMetricsDashboard")]
    [CmdletBinding()]
    [OutputType([System.String])]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [object[]]$DataSet,
        [Parameter(Mandatory=$false, Position=1)]
        [string]$Outfile = "$($PWD)\Entra_Authentication_Metrics_Dashboard.html",
        [Parameter(Mandatory=$false)]
        [string]$Title = "Entra Authentication Metrics",
        [Parameter(Mandatory=$false)]
        [switch]$InvokeDashboard

    )
    Begin {
        Write-Warning "New-EAMDashboard is deprecated. Use Invoke-EAIQDashboardCreation instead."

        $template_path = Join-Path -Path $PSScriptRoot -ChildPath "..\Templates"
        $output_directory = Split-Path -Path $outfile -Parent

        If (!$output_directory) {
            $output_directory = "$($PWD)"

        }

        $file_name = Split-Path -Path $outfile -Leaf
        $report_builder = [EAIQReportBuilder]::new($template_path, $output_directory)

    } Process {
        $report_html = $report_builder.BuildAuthenticationReport($dataSet, $title, "Unknown Tenant", "Not available")
        $report_path = $report_builder.ExportReport($report_html, $null, $file_name)

        If ($invokeDashboard) {
            $ii_params = @{}
            $ii_params["Path"] = $report_path
            Invoke-Item @ii_params

        }

        $report_path

    }

}
