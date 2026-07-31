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

    # Inline-styled email body: adoption stat cards plus the MFA gap users. Posture per user is the
    # dashboard's method-strength classification (auth_dashboard_script.js / method Strength field):
    #   Prmfa    -> holds a phishing-resistant (strong) method (PRMFA enabled)
    #   Standard -> best method is standard strength (Microsoft Authenticator, OATH, TAP)
    #   Weak     -> only weak-strength methods (Phone / Email - the dashboard's "Legacy" group)
    #   NoMfa    -> no registered MFA
    # RiskScope selects which gap the table lists: "NoMfa", "Weak", or "Both". Standard and Prmfa
    # users are never listed. The cards always show the full breakdown regardless of scope.
    [string]BuildAuthenticationEmailReport([object[]]$ReportData, [string]$Title, [string]$TenantName, [string]$DataAsOf, [string]$RiskScope) {
        $renderer = [AuthIQEmailReportRenderer]::new($this.AuthIQTemplateManager)

        $rows = @($ReportData)
        $total = $rows.Count

        $include_no = ($RiskScope -eq "NoMfa") -or ($RiskScope -eq "Both")
        $include_weak = ($RiskScope -eq "Weak") -or ($RiskScope -eq "Both")

        $prmfa_count = 0
        $standard_count = 0
        $weak_count = 0
        $nomfa_count = 0
        $gap = [System.Collections.Generic.List[object]]::new()

        ForEach ($row in $rows) {
            $posture = $this.MfaPosture($row)

            If ($posture -eq "NoMfa") {
                $nomfa_count++

            } ElseIf ($posture -eq "Weak") {
                $weak_count++

            } ElseIf ($posture -eq "Standard") {
                $standard_count++

            } Else {
                $prmfa_count++

            }

            $in_scope = (($posture -eq "NoMfa") -and $include_no) -or (($posture -eq "Weak") -and $include_weak)

            If ($in_scope) {
                $gap.Add([pscustomobject]@{ Row = $row; Posture = $posture })

            }

        }

        $cards = @(
            @{ count = $total; label = "Users"; color = "#6366f1" },
            @{ count = $prmfa_count; label = "PRMFA Enabled"; color = "#059669" },
            @{ count = $standard_count; label = "Standard"; color = "#4f46e5" },
            @{ count = $weak_count; label = "Weak (Legacy)"; color = "#dc2626" },
            @{ count = $nomfa_count; label = "No MFA"; color = "#7f1d1d" }

        )

        $columns = @(
            @{ label = "Status"; nowrap = $true },
            @{ label = "User" },
            @{ label = "Email" },
            @{ label = "Department" },
            @{ label = "Default MFA Method"; nowrap = $true }

        )

        $gap_rows = [System.Collections.Generic.List[object]]::new()

        ForEach ($item in ($gap | Sort-Object -Property @{Expression={$_.Posture}}, @{Expression={$_.Row.User}})) {
            $row = $item.Row
            $cells = @(
                $this.MfaPosturePill($item.Posture, $renderer),
                $renderer.Encode($row.User),
                $renderer.Encode($row.Email),
                $renderer.Encode($row.Department),
                $renderer.Encode($row.DefaultMfaMethod)
            )

            $gap_rows.Add(@{ cells = $cells; style = "" })

        }

        $sections = @(
            @{ heading = $this.GapHeading($RiskScope, $gap_rows.Count); columns = $columns; rows = $gap_rows.ToArray(); empty = $this.GapEmptyMessage($RiskScope) }

        )

        $report = @{}
        $report["title"] = $Title
        $report["tenant"] = $TenantName
        $report["intro"] = "Authentication method adoption across $total user(s): $prmfa_count phishing-resistant (PRMFA), $standard_count standard (Authenticator or OATH), $weak_count weak (phone or email only), $nomfa_count with no registered MFA. The gap users below are the action list. The full interactive dashboard is attached."
        $report["cards"] = $cards
        $report["sections"] = $sections
        $report["footer"] = "Registration data as of $DataAsOf. Open the attached dashboard for per-user detail, search, and CSV export."

        Return $renderer.Render($report)

    }

    # Posture from the dashboard's per-method Strength (strong / standard / weak). Strong maps to
    # PRMFA. A "standard" method (Authenticator, OATH, TAP) means the user is not weak. Weak is only
    # when every registered method is weak strength (Phone / Email - the dashboard's Legacy group).
    hidden [string]MfaPosture([object]$Row) {
        If ($Row.MfaStatus -ne "Registered") {
            Return "NoMfa"

        }

        If ($Row.PrmfaStatus -eq "Registered") {
            Return "Prmfa"

        }

        $strengths = @($Row.Methods | ForEach-Object { $_.Strength })

        If ($strengths -contains "standard") {
            Return "Standard"

        }

        # Registered per the report but with no enumerable methods to classify - do not assume weak.
        If (@($Row.Methods).Count -eq 0) {
            Return "Standard"

        }

        Return "Weak"

    }

    # Status pill using the dashboard's strength colors: Weak (Legacy) red, No MFA deeper red. Only
    # Weak and NoMfa reach the gap table; Standard and Prmfa are included for completeness.
    hidden [string]MfaPosturePill([string]$Posture, [object]$Renderer) {
        If ($Posture -eq "NoMfa") {
            Return $Renderer.Pill("No MFA", "#fecaca", "#7f1d1d")

        }

        If ($Posture -eq "Standard") {
            Return $Renderer.Pill("Standard", "#e0e7ff", "#4f46e5")

        }

        If ($Posture -eq "Prmfa") {
            Return $Renderer.Pill("PRMFA", "#d1fae5", "#059669")

        }

        Return $Renderer.Pill("Weak", "#fee2e2", "#dc2626")

    }

    hidden [string]GapHeading([string]$RiskScope, [int]$Count) {
        If ($RiskScope -eq "NoMfa") {
            Return "Users Without Registered MFA ($Count)"

        }

        If ($RiskScope -eq "Weak") {
            Return "Users With Weak (Legacy) MFA Only ($Count)"

        }

        Return "MFA Gap Users ($Count)"

    }

    hidden [string]GapEmptyMessage([string]$RiskScope) {
        If ($RiskScope -eq "NoMfa") {
            Return "Every user in this dataset has a registered MFA method."

        }

        If ($RiskScope -eq "Weak") {
            Return "No users are limited to weak (Legacy) methods."

        }

        Return "No gaps: every user has at least standard MFA."

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
