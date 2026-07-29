class EAIQAuthenticationMethodClient {
    [EAIQGraphRequestClient]$Client
    [System.Collections.Generic.List[pscustomobject]]$Report

    EAIQAuthenticationMethodClient([EAIQGraphRequestClient]$Client) {
        $this.Client = $Client
        $this.Report = [System.Collections.Generic.List[pscustomobject]]::new()

    }

    #region Read Operations

    [void]AddAuthenticationState([object]$User, [hashtable]$RegistrationLookup) {
        $method_instances = [System.Collections.Generic.List[pscustomobject]]::new()
        $has_x509 = $false
        $prmfa = $false

        $raw_methods = $this.GetUserMethods($User.id)

        ForEach ($method in $raw_methods) {
            $type = $method."@odata.type"

            If ([EAIQAuthenticationMethodInfo]::IsPassword($type)) {
                Continue

            }

            # A Temporary Access Pass that has been used up or expired is reported by
            # Graph with isUsable = false. It is not a currently valid MFA method, so it
            # is excluded entirely (not counted, not shown).
            If ($type -eq "#microsoft.graph.temporaryAccessPassAuthenticationMethod" -and $method.isUsable -eq $false) {
                Continue

            }

            $info = [EAIQAuthenticationMethodInfo]::GetInfo($type)
            $instance = $this.BuildInstance($method, $info)
            $method_instances.Add($instance)

            If ($info.Strength -eq "strong") {
                $prmfa = $true

            }

            If ($type -eq "#microsoft.graph.x509CertificateAuthenticationMethod") {
                $has_x509 = $true

            }

        }

        # Certificate-based authentication is inferred from certificateUserIds when no x509 method is present
        If (!$has_x509 -and $User.authorizationInfo.certificateUserIds) {
            $method_instances.Add($this.BuildCertificateInstance())
            $prmfa = $true

        }

        $record = [ordered]@{}
        $record["User"] = $User.userPrincipalName
        $record["Email"] = If ($User.mail) {
            $User.mail

        } Else {
            ""

        }

        $record["Company"] = If ($User.companyName) {
            $User.companyName

        } Else {
            ""

        }

        $record["Department"] = If ($User.department) {
            $User.department

        } Else {
            ""

        }

        $record["Id"] = $User.id
        $record["MethodCount"] = $method_instances.Count
        $this.AddRegistrationDetails($record, $User.id, $RegistrationLookup)

        # Two tracked statuses. MFA is registered if the user holds any method or
        # the registration report says so; PRMFA requires a phishing-resistant
        # method. PRMFA is always a subset of MFA.
        $mfa_registered = ($method_instances.Count -gt 0) -or ($record["IsMfaRegistered"] -eq $true)
        $record["MfaStatus"] = If ($mfa_registered) {
            "Registered"

        } Else {
            "Not Registered"

        }

        $record["PrmfaStatus"] = If ($prmfa) {
            "Registered"

        } Else {
            "Not Registered"

        }

        $record["Methods"] = $method_instances

        $this.Report.Add([pscustomobject]$record)

    }

    [object[]]ShowReport() {
        Return $this.Report

    }

    #endregion

    #region Internal Methods

    hidden [object[]]GetUserMethods([string]$UserId) {
        $segments = @($UserId, "authentication", "methods")
        Return $this.Client.InvokeGetRequest("users", $segments, $null, $null)

    }

    hidden [pscustomobject]BuildInstance([object]$Method, [pscustomobject]$Info) {
        $name = $Method.displayName

        If (!$name) {
            $name = $Method.model

        }

        If (!$name) {
            $name = $Info.Name

        }

        $created = $Method.createdDateTime

        If (!$created) {
            $created = $Method.creationDateTime

        }

        $instance = [ordered]@{}
        $instance["Category"] = $Info.Name
        $instance["Strength"] = $Info.Strength
        $instance["Name"] = $name
        $instance["Model"] = If ($Method.model) {
            $Method.model

        } Else {
            ""

        }

        $instance["Detail"] = $this.BuildDetail($Method)
        $instance["Registered"] = $this.NormalizeDate($created)
        $instance["LastUsed"] = $this.NormalizeDate($Method.lastUsedDateTime)
        $instance["PasskeyClass"] = $this.BuildPasskeyClass($Method)

        Return [pscustomobject]$instance

    }

    # Graph date values can arrive as [datetime] (Invoke-RestMethod auto-parses them),
    # which Windows PowerShell 5.1 serializes to "/Date(ms)/" via ConvertTo-Json. Emit a
    # plain ISO 8601 UTC string instead so the value is portable and the dashboard can parse it.
    hidden [string]NormalizeDate([object]$Value) {
        If (!$Value) {
            Return ""

        }

        $dt = $Value -as [datetime]
        If ($dt) {
            Return $dt.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

        }

        Return "$Value"

    }

    # Classify a passkey by type. Only FIDO2 credentials are passkeys; Windows Hello for
    # Business and Platform SSO are distinct credential types and are not passkeys.
    hidden [string]BuildPasskeyClass([object]$Method) {
        Return [EAIQAuthenticationMethodInfo]::ClassifyPasskey($Method)

    }

    hidden [string]BuildDetail([object]$Method) {
        $type = $Method."@odata.type"

        Switch ($type) {
            "#microsoft.graph.fido2AuthenticationMethod" {
                Return $this.FormatPasskeyType($Method.passkeyType)

            } "#microsoft.graph.platformCredentialAuthenticationMethod" {
                Return $this.FormatPasskeyType($Method.passkeyType)

            } "#microsoft.graph.windowsHelloForBusinessAuthenticationMethod" {
                If ($Method.keyStrength) {
                    Return "Key strength: $($Method.keyStrength)"

                }

                Return ""

            } "#microsoft.graph.temporaryAccessPassAuthenticationMethod" {
                If ($Method.isUsable) {
                    Return "Usable"

                }

                Return "Not usable ($($Method.methodUsabilityReason))"

            } "#microsoft.graph.microsoftAuthenticatorAuthenticationMethod" {
                $parts = [System.Collections.Generic.List[string]]::new()

                If ($Method.deviceTag) {
                    $parts.Add($Method.deviceTag)

                }

                If ($Method.phoneAppVersion) {
                    $parts.Add("app $($Method.phoneAppVersion)")

                }

                Return ($parts -join " - ")

            } "#microsoft.graph.phoneAuthenticationMethod" {
                If ($Method.phoneType) {
                    Return "$($Method.phoneType) phone"

                }

                Return ""

            } Default {
                Return ""

            }

        }

        Return ""

    }

    hidden [string]FormatPasskeyType([string]$PasskeyType) {
        If (!$PasskeyType) {
            Return "Passkey"

        }

        Switch ($PasskeyType) {
            "deviceBound" {
                Return "Device-bound passkey"

            } "synced" {
                Return "Synced passkey"

            } Default {
                Return "$PasskeyType passkey"

            }

        }

        Return "Passkey"

    }

    hidden [pscustomobject]BuildCertificateInstance() {
        $instance = [ordered]@{}
        $instance["Category"] = "Certificate"
        $instance["Strength"] = "strong"
        $instance["Name"] = "Certificate-based"
        $instance["Model"] = ""
        $instance["Detail"] = "From certificateUserIds"
        $instance["Registered"] = $null
        $instance["LastUsed"] = $null
        $instance["PasskeyClass"] = ""

        Return [pscustomobject]$instance

    }

    hidden [void]AddRegistrationDetails([System.Collections.Specialized.OrderedDictionary]$Record, [string]$UserId, [hashtable]$RegistrationLookup) {
        $detail = $null

        If ($RegistrationLookup -and $RegistrationLookup.ContainsKey($UserId)) {
            $detail = $RegistrationLookup[$UserId]

        }

        # When a user is absent from the userRegistrationDetails report (for
        # example, disabled users, which Entra excludes) the report fields are
        # left null so "no data" is not mistaken for "not registered".
        $has_data = [bool]$detail
        $Record["HasRegistrationData"] = $has_data

        If ($has_data) {
            $Record["IsMfaRegistered"] = [bool]$detail.isMfaRegistered
            $Record["IsMfaCapable"] = [bool]$detail.isMfaCapable
            $Record["IsPasswordlessCapable"] = [bool]$detail.isPasswordlessCapable
            $Record["IsSsprRegistered"] = [bool]$detail.isSsprRegistered
            $Record["IsSsprCapable"] = [bool]$detail.isSsprCapable
            $Record["IsAdmin"] = [bool]$detail.isAdmin
            $Record["UserType"] = If ($detail.userType) {
                $detail.userType

            } Else {
                ""

            }

            $Record["DefaultMfaMethod"] = If ($detail.defaultMfaMethod) {
                $detail.defaultMfaMethod

            } Else {
                "none"

            }

            $Record["MethodsRegistered"] = If ($detail.methodsRegistered) {
                $detail.methodsRegistered -join ", "

            } Else {
                ""

            }

        } Else {
            $Record["IsMfaRegistered"] = $null
            $Record["IsMfaCapable"] = $null
            $Record["IsPasswordlessCapable"] = $null
            $Record["IsSsprRegistered"] = $null
            $Record["IsSsprCapable"] = $null
            $Record["IsAdmin"] = $null
            $Record["UserType"] = ""
            $Record["DefaultMfaMethod"] = "unknown"
            $Record["MethodsRegistered"] = ""

        }

    }

    #endregion

}
