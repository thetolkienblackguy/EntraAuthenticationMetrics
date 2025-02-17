Function Invoke-EAMDashboardCreation {
    <#
        .SYNOPSIS
        Generates an Entra ID Authentication Metrics dashboard.

        .DESCRIPTION
        This function creates a dashboard visualizing authentication metrics from Entra ID.
        It can process data from various sources and generate an HTML dashboard.

        .PARAMETER AllUsers
        Get all users from Entra ID.

        .PARAMETER Filter
        Get users matching the specified filter.

        .PARAMETER GroupId
        The ID of the group to get users from.

        .PARAMETER ImportCsv
        Import users from a CSV file.

        .PARAMETER Path
        The path to the CSV file containing user data.

        .PARAMETER IdentityHeader
        The header in the CSV that contains the user identifier.

        .PARAMETER InputObject
        Existing authentication report data to use. Can be passed via pipeline.

        .PARAMETER InvokeDashboard
        Open the dashboard in the default browser.

        .PARAMETER IgnoreCertificateWarning
        Suppress the certificate-based authentication warning.

        .EXAMPLE
        Invoke-EAMDashboardCreation -AllUsers

        .EXAMPLE
        Invoke-EAMDashboardCreation -GroupId "12345678-1234-1234-1234-123456789012"

        .EXAMPLE
        $report = New-EAMAuthenticationReport -AllUsers
        Invoke-EAMDashboardCreation -InputObject $report

        .INPUTS
        System.Object[]
        System.String
        System.Automation.SwitchParameter
        System.Boolean

        .OUTPUTS
        System.String
    
    #>
    [CmdletBinding(DefaultParameterSetName="AllUsers")]
    [OutputType([System.String])]
    Param(
        [Parameter(Mandatory=$false,ParameterSetName="AllUsers")]
        [switch]$AllUsers,
        [Parameter(Mandatory=$true,ParameterSetName="Filter")]
        [string]$Filter,
        [Parameter(Mandatory=$true,ParameterSetName="Group")]
        [ValidateScript({
            $_ -match "^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$"
        
        })]
        [string]$GroupId,
        [Parameter(Mandatory=$false,ParameterSetName="ImportCsv")]
        [switch]$ImportCsv,
        [Parameter(Mandatory=$true,ParameterSetName="ImportCsv")]
        [ValidateScript({
            Test-Path $_ -PathType Leaf
        
        })]
        [string]$Path,
        [Parameter(Mandatory=$false,ParameterSetName="ImportCsv")]
        [string]$IdentityHeader = "id",
        [Parameter(Mandatory=$true,ParameterSetName="InputObject")]
        [object[]]$InputObject,
        [Parameter(Mandatory=$false)]
        [bool]$InvokeDashboard = $true,
        [Parameter(Mandatory=$false)]
        [switch]$IgnoreCertificateWarning
    
    )
    Begin {
        $ErrorActionPreference = "Stop"
        $report = [System.Collections.Generic.List[pscustomobject]]::new()
    
    } Process {
        Try {
            # Handle pipeline input or generate report
            Switch ($PSCmdlet.ParameterSetName) {
                "InputObject" {
                    $report = $inputObject
                
                } Default {
                    # Create a new report with the specified parameters
                    $new_report_params = @{}
                    Foreach ($param in $PSBoundParameters.GetEnumerator()) {
                        # Add the parameter to the new report if it is not the invoke dashboard or ignore certificate warning because they are not New-EAMAuthenticationReport parameters
                        If ($param.Key -notin @("InvokeDashboard","IgnoreCertificateWarning")) {
                            $new_report_params[$param.Key] = $param.Value

                        }
                    }
                    $report = New-EAMAuthenticationReport @new_report_params
                
                }
            }
        } Catch {
            Write-Error "Error processing data: $_" -ErrorAction Stop
        
        }
    } End {
        Try {
            # Create and display the dashboard
            If ($report) {
                New-EAMDashboard -DataSet $report -InvokeDashboard:$invokeDashboard
                If (!$ignoreCertificateWarning) {
                    Write-EAMCertificateWarning
                
                }
            } Else {
                Write-Error "No data was found to create the dashboard" -ErrorAction Stop
            
            }
        } Catch {
            Write-Error "Error creating dashboard: $_" -ErrorAction Stop
        
        }
    }
}