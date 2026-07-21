Function Get-EAIQAuthenticationReportData {
    <#
        .SYNOPSIS
        Gathers the authentication report dataset for Entra ID users.

        .DESCRIPTION
        Internal orchestrator that resolves the target user set, retrieves the
        authentication method registration report (Graph beta), and builds a flat
        per-user authentication state object for each user. Returns the report
        rows along with the report "data as of" timestamp and the tenant name.

        .PARAMETER AllUsers
        Gather data for all users in the tenant.

        .PARAMETER Filter
        Gather data for users matching the specified Graph filter.

        .PARAMETER GroupId
        Gather data for the transitive members of the specified group.

        .PARAMETER ImportCsv
        Gather data for the users listed in a CSV file.

        .PARAMETER Path
        Path to the CSV file containing user identifiers.

        .PARAMETER IdentityHeader
        Header in the CSV that contains the user identifier.

        .INPUTS
        None

        .OUTPUTS
        System.Management.Automation.PSCustomObject

        .EXAMPLE
        Get-EAIQAuthenticationReportData -AllUsers
        Gathers the authentication dataset for every user in the tenant.

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
        $ErrorActionPreference = "Stop"
        Write-Debug "Initializing authentication report components"

        $client = [EAIQGraphRequestClient]::new()
        $beta_client = [EAIQGraphRequestClient]::new()
        $beta_client.ApiVersion = "Beta"

        $user_client = [EAIQUserClient]::new($client)
        $registration_client = [EAIQRegistrationDetailsClient]::new($beta_client)
        # Methods are read from beta so each instance carries createdDateTime, lastUsedDateTime, passkeyType, etc.
        $method_client = [EAIQAuthenticationMethodClient]::new($beta_client)

    } Process {
        Write-Debug "Gathering users with parameter set: $($PSCmdlet.ParameterSetName)"

        Switch ($PSCmdlet.ParameterSetName) {
            "Filter" {
                $user_client.GetUsersByFilter($filter)

            } "Group" {
                $user_client.GetGroupMembers($groupId)

            } "ImportCsv" {
                $user_client.ImportFromCsv($path, $identityHeader)

            } Default {
                $user_client.GetAllUsers()

            }

        }

        $users = $user_client.ShowUsers()

        # userRegistrationDetails is a tenant-wide report; pull once and look up per user
        $registration_client.GetRegistrationDetails()
        $registration_lookup = $registration_client.ShowLookup()

        $total = @($users).Count
        $i = 0

        ForEach ($user in $users) {
            $i++

            $percent = 0

            If ($total -gt 0) {
                $percent = ($i / $total) * 100

            }

            $wp_params = @{}
            $wp_params["Activity"] = "Retrieving authentication methods"
            $wp_params["Status"] = "Processing $i of $total - $($user.userPrincipalName)"
            $wp_params["PercentComplete"] = $percent
            Write-Progress @wp_params

            $method_client.AddAuthenticationState($user, $registration_lookup)

        }

        Write-Progress -Activity "Retrieving authentication methods" -Completed

    } End {
        $tenant_info = $user_client.GetTenantInfo()
        $tenant_name = If ($tenant_info.displayName) {
            "$($tenant_info.displayName) ($($tenant_info.id))"

        } Else {
            "Unknown Tenant"

        }

        $result = [ordered]@{}
        $result["Report"] = $method_client.ShowReport()
        $result["DataAsOf"] = $registration_client.ShowDataAsOf()
        $result["TenantName"] = $tenant_name
        [pscustomobject]$result

    }

}
