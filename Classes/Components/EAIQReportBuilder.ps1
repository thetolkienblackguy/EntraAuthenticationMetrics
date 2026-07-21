class EAIQReportBuilder {
    [EAIQTemplateManager]$EAIQTemplateManager
    hidden [string]$OutputPath

    EAIQReportBuilder([string]$TemplatePath, [string]$OutputPath) {
        $this.EAIQTemplateManager = [EAIQTemplateManager]::new($TemplatePath)
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
        $tokens["FOOTER"] = $this.EAIQTemplateManager.GetTemplate("footer.html")

        $html = $this.EAIQTemplateManager.GetTemplate("auth_dashboard.html")
        Return $this.EAIQTemplateManager.ReplaceTokens($html, $tokens)

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
        $css = $this.EAIQTemplateManager.GetTemplate($FileName)
        Return "<style>`n$css`n</style>"

    }

    hidden [string]BuildScriptTag([string]$FileName) {
        $js = $this.EAIQTemplateManager.GetTemplate($FileName)
        Return "<script>`n$js`n</script>"

    }

    #endregion

}
