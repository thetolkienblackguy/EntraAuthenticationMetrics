class AuthIQGraphRequestClient {
    [string]$GraphEndpoint
    [ValidateSet("Beta", "v1.0")]
    [string]$ApiVersion = "v1.0"
    hidden [hashtable]$RequestParams = @{}

    #region Constructors

    AuthIQGraphRequestClient() {
        $this.RequestParams = @{}
        $this.SetGraphEndpoint()

    }

    #endregion

    #region Public HTTP Methods

    [object[]]InvokeGetRequest([string]$Endpoint, [string[]]$Segments, [string]$Filter, [hashtable]$QueryParams) {
        $query = $this.BuildGraphQuery($Filter, $QueryParams)
        $uri = $this.BuildUri($Endpoint, $Segments, $query)

        $options = @{}
        $options["Headers"] = @{}
        $options["Headers"]["ConsistencyLevel"] = "eventual"

        $this.SetRequestParams($uri, "GET", $options)
        $params = $this.ShowRequest()
        Return $this.Paginate($params)

    }

    [object]InvokePostRequest([string]$Endpoint, [string[]]$Segments, [hashtable]$Body) {
        $uri = $this.BuildUri($Endpoint, $Segments, $null)

        $ctj_params = @{}
        $ctj_params["InputObject"] = $Body
        $ctj_params["Depth"] = 10

        $options = @{}
        $options["Body"] = ConvertTo-Json @ctj_params
        $options["ContentType"] = "application/json"

        $this.SetRequestParams($uri, "POST", $options)
        $params = $this.ShowRequest()
        Return Invoke-MgGraphRequest @params

    }

    #endregion

    #region Pagination

    hidden [System.Collections.Generic.List[object]]Paginate([hashtable]$Params) {
        $results = [System.Collections.Generic.List[object]]::new()
        $next_link = $null
        $top_limit = $null

        If ($Params["Uri"] -match '\$top=(\d+)') {
            $top_limit = [int]$matches[1]

        }

        Do {
            If ($next_link) {
                $Params["Uri"] = $next_link

            }

            Try {
                $response = Invoke-MgGraphRequest @Params

                If ($response.value) {
                    ForEach ($item in $response.value) {
                        $results.Add($item)

                        If ($top_limit -and $results.Count -ge $top_limit) {
                            Return $results

                        }

                    }

                } ElseIf ($response -and !$response."@odata.context") {
                    $results.Add($response)
                    Return $results

                }

                $next_link = $response."@odata.nextLink"

            } Catch {
                $status_code = $null

                If ($_.Exception.Response) {
                    $status_code = $_.Exception.Response.StatusCode.value__

                }

                If ($status_code -eq 429) {
                    $retry_after = $this.GetRetryAfter($_.Exception)
                    Start-Sleep -Seconds $retry_after
                    Continue

                }

                Throw "Error during pagination: $($_.Exception.Message)"

            }

        } Until (!$next_link)

        Return $results

    }

    hidden [int]GetRetryAfter($Exception) {
        $retry_after = 60

        If ($Exception.Response -and $Exception.Response.Headers) {
            $header_value = $Exception.Response.Headers["Retry-After"]

            If ($header_value) {
                $retry_after = [int]$header_value

            }

        }

        Return $retry_after

    }

    #endregion

    #region URI Building

    [string]BuildUri([string]$Endpoint, [string[]]$Segments, [hashtable]$QueryParams) {
        $uri = [System.Text.StringBuilder]::new()
        [void]$uri.Append("$($this.GraphEndpoint)/$($this.ApiVersion)")

        If ($Endpoint) {
            $trimmed = $Endpoint.Trim("/")
            [void]$uri.Append("/$trimmed")

        }

        If ($Segments) {
            ForEach ($segment in $Segments) {
                $trimmed = $segment.Trim("/")
                If ($trimmed) {
                    [void]$uri.Append("/$trimmed")

                }

            }

        }

        If ($QueryParams) {
            If ($QueryParams.Count -gt 0) {
                $query_string = $this.BuildODataQueryString($QueryParams)
                [void]$uri.Append($query_string)

            }

        }

        Return $this.SanitizeUri($uri.ToString())

    }

    hidden [hashtable]BuildGraphQuery([string]$Filter, [hashtable]$QueryParams) {
        $query = @{}

        If ($Filter) {
            $query["Filter"] = $Filter

        }

        If ($QueryParams) {
            ForEach ($key in $QueryParams.Keys) {
                $query[$key] = $QueryParams[$key]

            }

        }

        Return $query

    }

    hidden [string]BuildODataQueryString([hashtable]$QueryParams) {
        If (!$QueryParams) {
            Return ""

        }

        If ($QueryParams.Count -eq 0) {
            Return ""

        }

        $pairs = [System.Collections.Generic.List[string]]::new()

        ForEach ($key in $QueryParams.Keys) {
            $value = $QueryParams[$key]
            $param_key = If ($key -match '^\$') {
                $key

            } Else {
                "`$$key"

            }

            $encoded_value = [uri]::EscapeDataString($value.ToString())
            $pairs.Add("$param_key=$encoded_value")

        }

        If ($pairs.Count -gt 0) {
            Return "?$($pairs -join '&')"

        }

        Return ""

    }

    hidden [string]SanitizeUri([string]$Uri) {
        $Uri = $Uri -replace "(?<!https:)/{2,}", "/"

        If ($Uri -ne "/" -and $Uri.EndsWith("/")) {
            $Uri = $Uri.TrimEnd("/")

        }

        Return $Uri

    }

    #endregion

    #region Request Management

    hidden [void]SetGraphEndpoint() {
        $context = Get-MgContext -ErrorAction Stop

        If ($context) {
            $env_params = @{}
            $env_params["Name"] = $context.Environment
            $env_params["ErrorAction"] = "Stop"
            $this.GraphEndpoint = (Get-MgEnvironment @env_params).GraphEndpoint

        } Else {
            Throw "Authentication needed. Please call Connect-MgGraph."

        }

    }

    hidden [void]SetRequestParams([string]$Uri, [string]$Method, [hashtable]$Options) {
        $this.RequestParams = @{}
        $this.RequestParams["Uri"] = $Uri
        $this.RequestParams["Method"] = $Method
        $this.RequestParams["OutputType"] = "PSObject"
        $this.RequestParams["ErrorAction"] = "Stop"

        ForEach ($key in $Options.Keys) {
            $this.RequestParams[$key] = $Options[$key]

        }

    }

    [hashtable]ShowRequest() {
        Return $this.RequestParams

    }

    #endregion

    #region Static Helpers

    static [bool]IsGuid([string]$Id) {
        $guid = [guid]::Empty
        Return [guid]::TryParse($Id, [ref]$guid)

    }

    #endregion

}
