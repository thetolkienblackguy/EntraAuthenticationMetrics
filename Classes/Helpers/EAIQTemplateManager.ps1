class EAIQTemplateManager {
    hidden [hashtable]$TemplateCache
    hidden [string]$TemplatePath

    EAIQTemplateManager([string]$TemplatePath) {
        $this.TemplatePath = $TemplatePath
        $this.TemplateCache = @{}

    }

    [string]GetTemplate([string]$TemplateName) {
        If ($this.TemplateCache.ContainsKey($TemplateName)) {
            Return $this.TemplateCache[$TemplateName]

        }

        $file_path = Join-Path -Path $this.TemplatePath -ChildPath $TemplateName

        If (!(Test-Path -Path $file_path)) {
            Throw "Template not found: $file_path"

        }

        $gc_params = @{}
        $gc_params["Path"] = $file_path
        $gc_params["Raw"] = $true
        $content = Get-Content @gc_params

        $this.TemplateCache[$TemplateName] = $content
        Return $content

    }

    [string]ReplaceTokens([string]$HtmlContent, [hashtable]$Tokens) {
        ForEach ($token in $Tokens.Keys) {
            $HtmlContent = $HtmlContent -replace [regex]::Escape("{{$token}}"), $Tokens[$token]

        }

        Return $HtmlContent

    }

    [void]ClearCache() {
        $this.TemplateCache = @{}

    }

    [int]GetCacheSize() {
        Return $this.TemplateCache.Count

    }

}
