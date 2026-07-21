class EAIQRegistrationDetailsClient {
    [EAIQGraphRequestClient]$Client
    [System.Collections.Generic.List[object]]$RegistrationDetails
    [string]$DataAsOf

    EAIQRegistrationDetailsClient([EAIQGraphRequestClient]$Client) {
        $this.Client = $Client
        $this.RegistrationDetails = [System.Collections.Generic.List[object]]::new()

    }

    #region Read Operations

    [void]GetRegistrationDetails() {
        $endpoint = "reports/authenticationMethods/userRegistrationDetails"
        $results = $this.Client.InvokeGetRequest($endpoint, $null, $null, $null)

        ForEach ($item in $results) {
            $this.RegistrationDetails.Add($item)

            If ($item.lastUpdatedDateTime) {
                If (!$this.DataAsOf -or ($item.lastUpdatedDateTime -gt $this.DataAsOf)) {
                    $this.DataAsOf = $item.lastUpdatedDateTime

                }

            }

        }

    }

    [hashtable]ShowLookup() {
        $lookup = @{}

        ForEach ($detail in $this.RegistrationDetails) {
            If ($detail.id) {
                $lookup[$detail.id] = $detail

            }

        }

        Return $lookup

    }

    [string]ShowDataAsOf() {
        Return $this.DataAsOf

    }

    #endregion

}
