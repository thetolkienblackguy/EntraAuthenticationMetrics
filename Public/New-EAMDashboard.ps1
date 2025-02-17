
<#
    .SYNOPSIS
    Create a authentication dashboard from a dataset

    .DESCRIPTION
    This function creates a authentication dashboard from a dataset. The dataset should be an array of objects with the 
    following properties:
    User [string]
    PRMFAStatus [string]
    EmailAuthentication [bool]
    Fido2 [bool]
    AuthenticatorApp [bool]
    PhoneAuthentication [bool]
    Passwordless [bool]
    SoftwareOath [bool]
    TemporaryAccessPass [bool]
    WindowsHelloForBusiness [bool]

    .PARAMETER DataSet
    The dataset to create the dashboard from

    .PARAMETER ScriptPath
    The path to the script. Default is the current working directory

    .PARAMETER Outfile
    The path to the output file. Default is the current working directory

    .PARAMETER Css
    The path to the css file. Default is the template folder in the current working directory

    .PARAMETER HtmlTemplate
    The path to the html template file. Default is the template folder in the current working directory

    .PARAMETER Js
    The path to the javascript file. Default is the template folder in the current working directory

    .PARAMETER InvokeDashboard
    If present, the dashboard will be opened in the default browser

    .EXAMPLE
    New-EAMDashboard -DataSet $data

    .EXAMPLE
    New-EAMDashboard -DataSet $data -ScriptPath "C:\Scripts" -Outfile "C:\Scripts\Entra_Authentication_Dashboard.html" -Css "C:\Scripts\templates\styles.css" -HtmlTemplate "C:\Scripts\templates\template.html" -Js "C:\Scripts\templates\script.js" -InvokeDashboard

    .INPUTS
    System.Object[]
    System.String

    .OUTPUTS
    System.String

#>
function New-EAMDashboard {
    [Alias("New-EntraAuthenticationMetricsDashboard")]
    [cmdletbinding()]
    [outputtype([string])]
    param (
        [Parameter(Mandatory=$true,Position=0)]
        [object[]]$DataSet,
        [Parameter(Mandatory=$false,Position=1)]
        [string]$ScriptPath = $PSScriptRoot,
        [Parameter(Mandatory=$false,Position=2)]
        [string]$Outfile = "$($PWD)\Entra_Authentication_Metrics_Dashboard.html",
        [Parameter(Mandatory=$false)]
        [ValidateScript({Test-Path $_})]
        [string]$Css = "$($script:template_path)\styles.css",
        [Parameter(Mandatory=$false)]
        [ValidateScript({Test-Path $_})] 
        [string]$HtmlTemplate = "$($script:template_path)\template.html",
        [Parameter(Mandatory=$false)]
        [ValidateScript({Test-Path $_})]
        [string]$Js = "$($script:template_path)\script.js",
        [Parameter(Mandatory=$false)]
        [switch]$InvokeDashboard
    
    )
    Begin {
        #region Preresiquites
        $ErrorActionPreference = "Stop"
        $PSDefaultParameterValues = @{}
        $PSDefaultParameterValues["Get-Content:Raw"] = $true

        #endregion

        #region splatting
        # Out-file parameters
        $out_file_params = @{}
        $out_file_params["FilePath"] = $outfile
        $out_file_params["Encoding"] = "UTF8"

        #endregion
    } Process {
        #region import data
        Try {
            $styles = Get-Content -Path $css
            $html = Get-Content -Path $htmlTemplate
            $script = Get-Content -Path $js

        } Catch {
            Write-Error "Error reading template files: $_"
        
        }

        #endregion

        #region Main
        Try {
            # Insert css
            $html = $html.Replace('<!-- STYLES -->', $styles)

            # Insert javascript
            $html = $html.Replace('<!-- SCRIPT -->', $script)

            # Convert data to json and insert into html
            $json = $dataSet | ConvertTo-Json
            $html = $html.Replace('const users = USERDATA;', "const users = $json;")

            # Write to file
            $html | Out-File @out_file_params
        
        } Catch {
            Write-Error "Error creating dashboard: $_"
        
        }

        #endregion
    
    } End {
        #region Invoke Dashboard
        if ($invokeDashboard) {
            Invoke-Item -Path $outfile
        
        }

        #endregion
    }
}