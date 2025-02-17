Function New-EAMAuthenticationReport {
    <#
        .SYNOPSIS
        Gets the authentication report for Entra ID users.

        .DESCRIPTION
        This function retrieves authentication information for Entra ID users and generates a report. 
        It can get data for all users, users from a specific group, or users matching a filter.

        .PARAMETER AllUsers
        Get report for all users from Entra ID.

        .PARAMETER Filter
        Get report for users matching the specified filter.

        .PARAMETER GroupId
        The ID of the group to get users from.

        .PARAMETER ImportCsv
        Import users from a CSV file.

        .PARAMETER Path
        The path to the CSV file containing user data.

        .PARAMETER IdentityHeader
        The header in the CSV that contains the user identifier.

        .EXAMPLE
        New-EAMAuthenticationReport -AllUsers

        .EXAMPLE
        New-EAMAuthenticationReport -GroupId "12345678-1234-1234-1234-123456789012"

        .EXAMPLE
        New-EAMAuthenticationReport -Filter "startswith(displayName,'A')"

        .EXAMPLE
        New-EAMAuthenticationReport -ImportCsv -Path "users.csv" -IdentityHeader "UPN"

        .INPUTS
        System.String
        System.Automation.SwitchParameter

        .OUTPUTS
        System.Object
    #>
    [CmdletBinding(DefaultParameterSetName="AllUsers")]
    [OutputType([System.Object])]
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
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]$Path,
        [Parameter(Mandatory=$false,ParameterSetName="ImportCsv")]
        [string]$IdentityHeader = "id"
    
        )
    Begin {
        $ErrorActionPreference = "Stop"
        $report = [System.Collections.Generic.List[pscustomobject]]::new()
    
    } Process {
        Try {
            # Get users based on parameter set
            $parameter_set = $PSCmdlet.ParameterSetName
            switch ($parameter_set) {
                "ImportCsv" {
                    # Import-EAMCsv parameters
                    $import_csv_params = @{}
                    $import_csv_params["Path"] = $path
                    $import_csv_params["IdentityHeader"] = $identityHeader

                    # Import the CSV file and get the users from Entra ID
                    $users = Import-EAMCsv @import_csv_params
                    Break
                
                } Default {
                    # Get-EAMUsers parameters
                    $get_users_params = @{}
                    $get_users_params["ParameterSetName"] = $parameter_set
                    
                    # If the parameter set is Group, add the GroupId to the parameters for Get-EAMUsers
                    If ($parameter_set -eq "Group") {
                        $get_users_params["GroupId"] = $groupId

                    # If the parameter set is Filter, add the Filter to the parameters for Get-EAMUsers
                    } ElseIf ($parameter_set -eq "Filter") {
                        $get_users_params["Filter"] = $filter
                    }

                    # Get the users from Entra ID
                    $users = Get-EAMUsers @get_users_params
                    Break
                
                }
            }

            # Get the total number of users
            $total = @($users).Count

            # Initialize the iteration counter
            $i = 0
            # Process each user
            Foreach ($user in $users) {
                # Write-Progress parameters
                $write_progress_params = @{}
                $write_progress_params["Iteration"] = $i++
                $write_progress_params["Total"] = $total
                $write_progress_params["Item"] = $user.UserPrincipalName
                
                # Write the progress
                Invoke-EAMWriteProgress @write_progress_params
                
                # Get the authentication state of the user
                $auth_state = Get-EAMUserAuthenticationState -InputObject $user
                
                # Add the authentication state to the report
                $report.Add($auth_state)
            
            }
        } Catch {
            Write-Error "Error generating authentication report: $_"
            return
        
        }
    } End {
        If (!$report) {
            Write-Warning "No data found for authentication report"
            return
        
        }
        $report
    }
}