class AuthIQEmailReportRenderer {
    <#
        .SYNOPSIS
        Renders email-safe HTML (inline styles, table layout) for EntraAuthenticationMetrics
        reports from a normalized data shape.

        .DESCRIPTION
        Centralizes the email shell, summary cards, sections, tables, and pill markup so the
        report builder only shapes data and never re-implements email markup. The interactive
        dashboard relies on stripped-in-email constructs (head styles, script-driven master
        detail, grid), so this produces a body that renders in mail clients while the full
        dashboard is attached.

        Report shape passed to Render:
            title    [string]
            tenant   [string]   optional tenant line under the header
            intro    [string]   optional lead paragraph
            cards    [object[]] each @{ count; label; color }
            sections [object[]] each @{ heading; columns; rows; empty }
                column = @{ label; align; nowrap }         align/nowrap optional
                row    = @{ cells = [object[]]; style }     cells are pre-rendered inner HTML
                empty  = [string]                           message shown when rows is empty
            footer   [string]   optional footnote

    #>
    hidden $TemplateManager

    hidden static [string]$ThStyle = "background-color:#1e293b;color:#ffffff;padding:10px 12px;font-size:11px;font-weight:600;text-transform:uppercase;letter-spacing:0.5px;white-space:nowrap;"
    hidden static [string]$TdStyle = "padding:8px 12px;border-bottom:1px solid #e5e7eb;font-size:12px;vertical-align:top;"

    #region Constructor

    AuthIQEmailReportRenderer($TemplateManager) {
        $this.TemplateManager = $TemplateManager

    }

    #endregion

    #region Public API

    [string]Render([hashtable]$Report) {
        $sections_sb = [System.Text.StringBuilder]::new()

        ForEach ($section in @($Report.sections)) {
            [void]$sections_sb.AppendLine($this.BuildSection($section))

        }

        $shell = $this.TemplateManager.GetTemplate("email_report.html")

        $tokens = @{}
        $tokens["TITLE"] = $Report.title
        $tokens["TIMESTAMP"] = Get-Date -Format "MMMM d, yyyy 'at' h:mm tt"
        $tokens["TENANT_HTML"] = $this.BuildTenant([string]$Report.tenant)
        $tokens["INTRO_HTML"] = $this.BuildIntro([string]$Report.intro)
        $tokens["SUMMARY_HTML"] = $this.BuildCards(@($Report.cards))
        $tokens["SECTIONS_HTML"] = $sections_sb.ToString()
        $tokens["FOOTER_HTML"] = $this.BuildFooter([string]$Report.footer)

        Return $this.TemplateManager.ReplaceTokens($shell, $tokens)

    }

    # Pill span used for both status badges and chips
    [string]Pill([string]$Text, [string]$Background, [string]$Foreground) {
        $style = "display:inline-block;padding:3px 8px;border-radius:999px;font-size:10px;font-weight:700;text-transform:uppercase;letter-spacing:0.3px;background-color:$Background;color:$Foreground;"

        Return "<span style=""$style"">$Text</span>"

    }

    # HtmlEncode helper so builders never touch raw values
    [string]Encode([string]$Value) {
        Return [System.Net.WebUtility]::HtmlEncode([string]$Value)

    }

    #endregion

    #region Fragments

    hidden [string]BuildTenant([string]$Tenant) {
        If (!$Tenant) {
            Return ""

        }

        Return "<p style=""margin:2px 0 0 0;font-size:12px;color:#94a3b8;"">Tenant: $($this.Encode($Tenant))</p>"

    }

    hidden [string]BuildIntro([string]$Intro) {
        If (!$Intro) {
            Return ""

        }

        $sb = [System.Text.StringBuilder]::new()
        [void]$sb.AppendLine("<tr><td style=""background-color:#ffffff;border-radius:8px;padding:16px 24px;font-size:13px;color:#334155;"">$Intro</td></tr>")
        [void]$sb.AppendLine('<tr><td style="height:24px;"></td></tr>')

        Return $sb.ToString()

    }

    hidden [string]BuildFooter([string]$Footer) {
        If (!$Footer) {
            Return ""

        }

        Return "<tr><td style=""padding:4px 8px;font-size:11px;color:#94a3b8;"">$Footer</td></tr>"

    }

    hidden [string]BuildCards([object[]]$Cards) {
        If (!$Cards -or $Cards.Count -eq 0) {
            Return ""

        }

        $sb = [System.Text.StringBuilder]::new()
        $width = [int][math]::Floor(96 / $Cards.Count)
        $card_base = "width:$($width)%;text-align:center;padding:16px 8px;background-color:#ffffff;border-radius:8px;"

        ForEach ($card in $Cards) {
            [void]$sb.AppendLine("<td style=""$($card_base)border-top:4px solid $($card.color);"">")
            [void]$sb.AppendLine("<div style=""font-size:28px;font-weight:700;color:$($card.color);line-height:1.2;"">$($card.count)</div>")
            [void]$sb.AppendLine("<div style=""font-size:11px;font-weight:600;text-transform:uppercase;letter-spacing:0.5px;color:#6b7280;margin-top:4px;"">$($card.label)</div>")
            [void]$sb.AppendLine('</td>')
            [void]$sb.AppendLine('<td style="width:2%;"></td>')

        }

        Return $sb.ToString()

    }

    hidden [string]BuildSection([object]$Section) {
        $sb = [System.Text.StringBuilder]::new()

        [void]$sb.AppendLine('<tr><td style="background-color:#ffffff;border-radius:8px;overflow:hidden;">')
        [void]$sb.AppendLine('<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0">')
        [void]$sb.AppendLine('<tr><td style="padding:16px 24px;border-bottom:1px solid #e5e7eb;">')
        [void]$sb.AppendLine("<h2 style=""margin:0;font-size:16px;font-weight:600;color:#1a1a2e;"">$($Section.heading)</h2>")
        [void]$sb.AppendLine('</td></tr>')
        [void]$sb.AppendLine('<tr><td style="padding:0;">')
        [void]$sb.AppendLine($this.BuildTable(@($Section.columns), @($Section.rows), [string]$Section.empty))
        [void]$sb.AppendLine('</td></tr>')
        [void]$sb.AppendLine('</table>')
        [void]$sb.AppendLine('</td></tr>')
        [void]$sb.AppendLine('<tr><td style="height:24px;"></td></tr>')

        Return $sb.ToString()

    }

    hidden [string]BuildTable([object[]]$Columns, [object[]]$Rows, [string]$EmptyMessage) {
        If (!$Rows -or $Rows.Count -eq 0) {
            $message = If ($EmptyMessage) {
                $EmptyMessage

            } Else {
                "Nothing to report."

            }

            Return "<p style=""padding:16px 24px;margin:0;font-size:13px;color:#166534;"">$message</p>"

        }

        $sb = [System.Text.StringBuilder]::new()

        [void]$sb.AppendLine('<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="border-collapse:collapse;font-family:Segoe UI,Arial,sans-serif;">')
        [void]$sb.AppendLine('<tr>')

        ForEach ($column in $Columns) {
            $align = If ($column.align) { $column.align } Else { "left" }
            [void]$sb.AppendLine("<th style=""$([AuthIQEmailReportRenderer]::ThStyle)text-align:$align;"">$($column.label)</th>")

        }

        [void]$sb.AppendLine('</tr>')

        ForEach ($row in $Rows) {
            [void]$sb.AppendLine("<tr style=""$($row.style)"">")

            $col_index = 0
            ForEach ($cell in @($row.cells)) {
                $column = $Columns[$col_index]
                $align = If ($column.align) { $column.align } Else { "left" }
                $nowrap = If ($column.nowrap) { "white-space:nowrap;" } Else { "" }
                [void]$sb.AppendLine("<td style=""$([AuthIQEmailReportRenderer]::TdStyle)text-align:$align;$nowrap"">$cell</td>")
                $col_index++

            }

            [void]$sb.AppendLine('</tr>')

        }

        [void]$sb.AppendLine('</table>')

        Return $sb.ToString()

    }

    #endregion

}
