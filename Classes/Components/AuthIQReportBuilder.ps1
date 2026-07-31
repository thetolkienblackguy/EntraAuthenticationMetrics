class AuthIQReportBuilder {
    [AuthIQTemplateManager]$AuthIQTemplateManager
    hidden [string]$OutputPath

    AuthIQReportBuilder([string]$TemplatePath, [string]$OutputPath) {
        $this.AuthIQTemplateManager = [AuthIQTemplateManager]::new($TemplatePath)
        $this.OutputPath = $OutputPath

    }

    #region Authentication Report

    [string]BuildAuthenticationReport([object[]]$ReportData, [string]$Title, [string]$TenantName, [string]$DataAsOf) {
        $rows = @($ReportData)

        $ctj_params = @{}
        $ctj_params["InputObject"] = $rows
        $ctj_params["Depth"] = 8
        $json_data = ConvertTo-Json @ctj_params

        # ConvertTo-Json may collapse a single-item collection to a bare object; the dashboard
        # expects an array. Wrap only when the output is not already a JSON array.
        If (!"$json_data".TrimStart().StartsWith("[")) {
            $json_data = "[$json_data]"

        }

        $tokens = $this.BuildBaseTokens($Title, $TenantName)
        $tokens["DATA_AS_OF"] = If ($DataAsOf) {
            $DataAsOf

        } Else {
            "Not available"

        }

        $tokens["STYLES"] = $this.BuildStyleTag("auth_dashboard_styles.css")
        $tokens["SCRIPTS"] = $this.BuildScriptTag("auth_dashboard_script.js")
        $tokens["DATA"] = "const reportData = $json_data;"
        $tokens["FOOTER"] = $this.AuthIQTemplateManager.GetTemplate("footer.html")

        $html = $this.AuthIQTemplateManager.GetTemplate("auth_dashboard.html")
        Return $this.AuthIQTemplateManager.ReplaceTokens($html, $tokens)

    }

    # Inline-styled email body: adoption stat cards plus the at-risk users. RiskScope selects which
    # at-risk users to list - "NoMfa" (no registered MFA), "Weak" (registered but not phishing
    # resistant), or "Both". The cards always show the full breakdown regardless of scope.
    [string]BuildAuthenticationEmailReport([object[]]$ReportData, [string]$Title, [string]$TenantName, [string]$DataAsOf, [string]$RiskScope) {
        $renderer = [AuthIQEmailReportRenderer]::new($this.AuthIQTemplateManager)

        $rows = @($ReportData)
        $total = $rows.Count

        $include_no = ($RiskScope -eq "NoMfa") -or ($RiskScope -eq "Both")
        $include_weak = ($RiskScope -eq "Weak") -or ($RiskScope -eq "Both")

        $strong_count = 0
        $weak_count = 0
        $no_count = 0
        $at_risk = [System.Collections.Generic.List[object]]::new()

        ForEach ($row in $rows) {
            $category = $this.MfaRiskCategory($row)

            If ($category -eq "NoMfa") {
                $no_count++

            } ElseIf ($category -eq "Weak") {
                $weak_count++

            } Else {
                $strong_count++

            }

            $in_scope = (($category -eq "NoMfa") -and $include_no) -or (($category -eq "Weak") -and $include_weak)

            If ($in_scope) {
                $at_risk.Add([pscustomobject]@{ Row = $row; Category = $category })

            }

        }

        $cards = @(
            @{ count = $total; label = "Users"; color = "#6366f1" },
            @{ count = ($strong_count + $weak_count); label = "MFA Registered"; color = "#22c55e" },
            @{ count = $strong_count; label = "Phishing-Resistant"; color = "#312e81" },
            @{ count = $weak_count; label = "Weak MFA"; color = "#f59e0b" },
            @{ count = $no_count; label = "No MFA"; color = "#dc2626" }

        )

        $columns = @(
            @{ label = "Status"; nowrap = $true },
            @{ label = "User" },
            @{ label = "Email" },
            @{ label = "Department" },
            @{ label = "Default MFA Method"; nowrap = $true }

        )

        $risk_rows = [System.Collections.Generic.List[object]]::new()

        ForEach ($item in ($at_risk | Sort-Object -Property @{Expression={$_.Category}}, @{Expression={$_.Row.User}})) {
            $row = $item.Row
            $cells = @(
                $this.MfaRiskPill($item.Category, $renderer),
                $renderer.Encode($row.User),
                $renderer.Encode($row.Email),
                $renderer.Encode($row.Department),
                $renderer.Encode($row.DefaultMfaMethod)
            )

            $risk_rows.Add(@{ cells = $cells; style = $this.MfaRiskRowStyle($item.Category) })

        }

        $sections = @(
            @{ heading = $this.RiskHeading($RiskScope, $risk_rows.Count); columns = $columns; rows = $risk_rows.ToArray(); empty = $this.RiskEmptyMessage($RiskScope) }

        )

        $report = @{}
        $report["title"] = $Title
        $report["tenant"] = $TenantName
        $report["intro"] = "Authentication method adoption across $total user(s): $strong_count phishing-resistant, $weak_count weak MFA only, $no_count with no registered MFA. The at-risk users below are the immediate gap. The full interactive dashboard is attached."
        $report["cards"] = $cards
        $report["sections"] = $sections
        $report["footer"] = "Registration data as of $DataAsOf. Open the attached dashboard for per-user detail, search, and CSV export."

        Return $renderer.Render($report)

    }

    hidden [string]MfaRiskCategory([object]$Row) {
        If ($Row.MfaStatus -ne "Registered") {
            Return "NoMfa"

        }

        If ($Row.PrmfaStatus -ne "Registered") {
            Return "Weak"

        }

        Return "Strong"

    }

    hidden [string]MfaRiskPill([string]$Category, [object]$Renderer) {
        If ($Category -eq "NoMfa") {
            Return $Renderer.Pill("No MFA", "#fee2e2", "#991b1b")

        }

        Return $Renderer.Pill("Weak", "#fef3c7", "#92400e")

    }

    hidden [string]MfaRiskRowStyle([string]$Category) {
        If ($Category -eq "NoMfa") {
            Return "background-color:#fef2f2;color:#991b1b;"

        }

        Return "background-color:#fffbeb;color:#92400e;"

    }

    hidden [string]RiskHeading([string]$RiskScope, [int]$Count) {
        If ($RiskScope -eq "NoMfa") {
            Return "Users Without Registered MFA ($Count)"

        }

        If ($RiskScope -eq "Weak") {
            Return "Users With Weak MFA Only ($Count)"

        }

        Return "At-Risk Users ($Count)"

    }

    hidden [string]RiskEmptyMessage([string]$RiskScope) {
        If ($RiskScope -eq "NoMfa") {
            Return "Every user in this dataset has a registered MFA method."

        }

        If ($RiskScope -eq "Weak") {
            Return "No users are limited to weak MFA methods."

        }

        Return "No at-risk users: every user has a phishing-resistant MFA method."

    }

    #endregion

    #region Export

    [string]ExportReport([string]$HtmlContent, [string]$SubPath, [string]$FileName) {
        $export_path = If ($SubPath) {
            Join-Path -Path $this.OutputPath -ChildPath $SubPath

        } Else {
            $this.OutputPath

        }

        If (!(Test-Path -Path $export_path)) {
            $ni_params = @{}
            $ni_params["Path"] = $export_path
            $ni_params["ItemType"] = "Directory"
            $ni_params["Force"] = $true
            [void](New-Item @ni_params)

        }

        $full_path = Join-Path -Path $export_path -ChildPath $FileName

        $of_params = @{}
        $of_params["FilePath"] = $full_path
        $of_params["Encoding"] = "UTF8"
        $of_params["InputObject"] = $HtmlContent
        Out-File @of_params

        Return $full_path

    }

    #endregion

    #region Internal Methods

    hidden [hashtable]BuildBaseTokens([string]$Title, [string]$TenantName) {
        $tokens = @{}
        $tokens["TITLE"] = $Title
        $tokens["TENANT_NAME"] = $TenantName

        $gd_params = @{}
        $gd_params["Format"] = "MMMM d, yyyy 'at' h:mm tt"
        $tokens["TIMESTAMP"] = Get-Date @gd_params

        Return $tokens

    }

    hidden [string]BuildStyleTag([string]$FileName) {
        $css = $this.AuthIQTemplateManager.GetTemplate($FileName)
        Return "<style>`n$css`n</style>"

    }

    hidden [string]BuildScriptTag([string]$FileName) {
        $js = $this.AuthIQTemplateManager.GetTemplate($FileName)
        Return "<script>`n$js`n</script>"

    }

    #endregion

}
