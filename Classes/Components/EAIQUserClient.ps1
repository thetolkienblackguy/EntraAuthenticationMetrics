class EAIQUserClient {
    [EAIQGraphRequestClient]$Client
    [System.Collections.Generic.List[object]]$Users
    hidden [string]$UserSelect = "id,userPrincipalName,mail,authorizationInfo"

    EAIQUserClient([EAIQGraphRequestClient]$Client) {
        $this.Client = $Client
        $this.Users = [System.Collections.Generic.List[object]]::new()

    }

    #region Read Operations

    [void]GetAllUsers() {
        $query_params = @{}
        $query_params["select"] = $this.UserSelect
        $query_params["count"] = "true"

        $results = $this.Client.InvokeGetRequest("users", $null, $null, $query_params)
        $this.UpdateUsers($results)

    }

    [void]GetUsersByFilter([string]$Filter) {
        $query_params = @{}
        $query_params["select"] = $this.UserSelect
        $query_params["count"] = "true"

        $results = $this.Client.InvokeGetRequest("users", $null, $Filter, $query_params)
        $this.UpdateUsers($results)

    }

    [void]GetGroupMembers([string]$GroupId) {
        $segments = @($GroupId, "transitiveMembers", "microsoft.graph.user")
        $query_params = @{}
        $query_params["select"] = $this.UserSelect

        $results = $this.Client.InvokeGetRequest("groups", $segments, $null, $query_params)
        $this.UpdateUsers($results)

    }

    [void]ImportFromCsv([string]$Path, [string]$IdentityHeader) {
        $csv_data = Import-Csv -Path $Path

        ForEach ($row in $csv_data) {
            $identity = $row.$IdentityHeader

            If (!$identity) {
                Continue

            }

            $this.GetUserById($identity)

        }

    }

    [object]GetTenantInfo() {
        $results = $this.Client.InvokeGetRequest("organization", $null, $null, $null)

        If ($results) {
            Return $results[0]

        }

        Return $null

    }

    [object[]]ShowUsers() {
        Return $this.Users

    }

    #endregion

    #region Internal Methods

    hidden [void]GetUserById([string]$UserId) {
        $filter = If ([EAIQGraphRequestClient]::IsGuid($UserId)) {
            "id eq '$UserId'"

        } Else {
            $escaped = $UserId.Replace("'", "''")
            "userPrincipalName eq '$escaped'"

        }

        $query_params = @{}
        $query_params["select"] = $this.UserSelect

        $results = $this.Client.InvokeGetRequest("users", $null, $filter, $query_params)
        $this.UpdateUsers($results)

    }

    hidden [void]UpdateUsers([object[]]$Results) {
        ForEach ($item in $Results) {
            $this.Users.Add($item)

        }

    }

    #endregion

}
