Function Send-EAMMailMessage {
    <#
        .SYNOPSIS
        [Deprecated] Sends an email message using the Microsoft Graph API.

        .DESCRIPTION
        Deprecated backward-compatibility wrapper. Use Send-EAIQMailMessage instead.
        This shim forwards all parameters to Send-EAIQMailMessage and will be removed
        in a future release.

        .PARAMETER To
        Specifies the recipient(s) of the email message.

        .PARAMETER Subject
        Specifies the subject of the email message.

        .PARAMETER Body
        Specifies the body of the email message.

        .PARAMETER From
        Specifies the sender of the email message.

        .PARAMETER Cc
        Specifies the carbon copy recipient(s) of the email message.

        .PARAMETER Bcc
        Specifies the blind carbon copy recipient(s) of the email message.

        .PARAMETER Attachments
        Specifies the attachment(s) of the email message.

        .PARAMETER Importance
        Specifies the importance of the email message.

        .PARAMETER SaveToSentItems
        Specifies whether to save the email message to the sent items folder.

        .INPUTS
        System.String
        System.String[]
        System.IO.FileInfo
        System.Boolean

        .OUTPUTS

        .EXAMPLE
        Send-EAMMailMessage -To "john.doe@contoso.com" -From "jane.doe@contoso.com" -Subject "Test" -Body "This is a test"

    #>
    [CmdletBinding()]
    [OutputType()]
    param(
        [Parameter(Mandatory=$true)]
        [Alias("Recipient")]
        [string[]]$To,
        [Parameter(Mandatory=$true)]
        [string]$Subject,
        [Parameter(Mandatory=$true)]
        [Alias("EmailBody")]
        [string]$Body,
        [Parameter(Mandatory=$true)]
        [Alias("Sender")]
        [string]$From,
        [Parameter(Mandatory=$false)]
        [string[]]$Cc,
        [Parameter(Mandatory=$false)]
        [string[]]$Bcc,
        [Parameter(Mandatory=$false)]
        [system.io.fileinfo[]]$Attachments,
        [Parameter(Mandatory=$false)]
        [ValidateSet("Low", "Normal", "High")]
        [string]$Importance = "Normal",
        [Parameter(Mandatory=$false)]
        [bool]$SaveToSentItems = $true

    )
    Begin {
        Write-Warning "Send-EAMMailMessage is deprecated. Use Send-EAIQMailMessage instead."

    } Process {
        Send-EAIQMailMessage @PSBoundParameters

    }

}
