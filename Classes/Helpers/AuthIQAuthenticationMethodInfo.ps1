class AuthIQAuthenticationMethodInfo {
    # Graph authentication method type -> friendly category and strength classification.
    # Strength drives the PRMFA (phishing-resistant) roll-up: "strong" methods count toward PRMFA.
    static [System.Collections.IDictionary] $method_table = @{
        "#microsoft.graph.microsoftAuthenticatorAuthenticationMethod" = @{ Name = "Microsoft Authenticator"; Strength = "standard" }
        "#microsoft.graph.passwordlessMicrosoftAuthenticatorAuthenticationMethod" = @{ Name = "Passwordless (Authenticator)"; Strength = "strong" }
        "#microsoft.graph.fido2AuthenticationMethod" = @{ Name = "Passkey (FIDO2)"; Strength = "strong" }
        "#microsoft.graph.windowsHelloForBusinessAuthenticationMethod" = @{ Name = "Windows Hello for Business"; Strength = "strong" }
        "#microsoft.graph.x509CertificateAuthenticationMethod" = @{ Name = "Certificate"; Strength = "strong" }
        "#microsoft.graph.platformCredentialAuthenticationMethod" = @{ Name = "Platform SSO Credential"; Strength = "strong" }
        "#microsoft.graph.softwareOathAuthenticationMethod" = @{ Name = "Software OATH"; Strength = "standard" }
        "#microsoft.graph.hardwareOathAuthenticationMethod" = @{ Name = "Hardware OATH"; Strength = "standard" }
        "#microsoft.graph.temporaryAccessPassAuthenticationMethod" = @{ Name = "Temporary Access Pass"; Strength = "standard" }
        "#microsoft.graph.qrCodePinAuthenticationMethod" = @{ Name = "QR Code + PIN"; Strength = "standard" }
        "#microsoft.graph.phoneAuthenticationMethod" = @{ Name = "Phone"; Strength = "weak" }
        "#microsoft.graph.emailAuthenticationMethod" = @{ Name = "Email"; Strength = "weak" }

    }

    # Microsoft Authenticator passkey AAGUIDs (confirmed against real tenant data and the
    # community passkey AAGUID registry: passkeydeveloper/passkey-authenticator-aaguids).
    static [string[]] $microsoft_authenticator_aaguids = @(
        "90a3ccdf-635c-4729-a248-9b709135078f",
        "257fa02a-18f3-4e34-8174-95d454c2e9ad",
        "de1e552d-db1d-4423-a619-566b625cdc84",
        "b6879edc-2a86-4bde-9c62-c1cac4a8f8e5"
    )

    # Windows Hello passkey AAGUIDs (software, hardware, and VBS variants).
    static [string[]] $windows_hello_aaguids = @(
        "9ddd1817-af5a-4672-a2b9-3e3dd95000a9",
        "08987058-cadc-4b81-b6e1-30de50dcbe96",
        "6028b017-b1d4-4c02-b4b3-afcdafc96bb2"
    )

    # Password is not an MFA method and is excluded from the report
    static [bool] IsPassword([string]$Type) {
        Return $Type -eq "#microsoft.graph.passwordAuthenticationMethod"

    }

    # Classify a FIDO2 passkey by type. passkeyType (deviceBound / synced) is a documented
    # enum on fido2AuthenticationMethod; maker identity comes from the AAGUID (authoritative),
    # falling back to the free-text model string. Non-FIDO2 methods are not passkeys.
    static [string] ClassifyPasskey([object]$Method) {
        If ($Method."@odata.type" -ne "#microsoft.graph.fido2AuthenticationMethod") {
            Return ""

        }

        If ($Method.passkeyType -eq "synced") {
            Return "Synced passkey"

        }

        $aaguid = "$($Method.aaGuid)".ToLower()

        If ($aaguid -in [AuthIQAuthenticationMethodInfo]::microsoft_authenticator_aaguids) {
            Return "Authenticator passkey"

        }

        If ($aaguid -in [AuthIQAuthenticationMethodInfo]::windows_hello_aaguids) {
            Return "Windows Hello passkey"

        }

        $model = "$($Method.model)"

        If ($model -like "Microsoft Authenticator*") {
            Return "Authenticator passkey"

        }

        If ($model -like "*Windows Hello*") {
            Return "Windows Hello passkey"

        }

        Return "Physical passkey"

    }

    # Return the friendly category and strength for a method type, deriving a label for unknown types
    static [pscustomobject] GetInfo([string]$Type) {
        If ([AuthIQAuthenticationMethodInfo]::method_table.Contains($Type)) {
            $entry = [AuthIQAuthenticationMethodInfo]::method_table[$Type]
            $info = [ordered]@{}
            $info["Name"] = $entry.Name
            $info["Strength"] = $entry.Strength
            Return [pscustomobject]$info

        }

        $derived = $Type -replace "#microsoft.graph.", "" -replace "AuthenticationMethod", ""
        $info = [ordered]@{}
        $info["Name"] = $derived
        $info["Strength"] = "standard"
        Return [pscustomobject]$info

    }

}
