Function Send-EAIQMailMessage {
    <#
        .DESCRIPTION
        This function sends an email message using the Microsoft Graph API.

        .SYNOPSIS
        This function sends an email message using the Microsoft Graph API.

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

        .EXAMPLE
        Send-EAIQMailMessage -To "john.doe@contoso.com" -From "jane.doe@contoso.com" -Subject "Test" -Body "This is a test"

        .EXAMPLE
        Send-EAIQMailMessage -To "john.doe@contoso.com" -From "jane.doe@contoso.com" -Subject "Test" -Body "This is a test" -Attachments "C:\Temp\test.txt"

            .INPUTS
        .INPUTS
        System.String
        System.String[]
        System.IO.FileInfo
        System.Boolean

        .OUTPUTS
    
    #>
    [CmdletBinding()]
    [OutputType()]
    param (      
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
        # Microsoft Graph request client (resolves the endpoint from the current context)
        $client = [EAIQGraphRequestClient]::new()

        # Creating parent message hash table
        $mail_message = @{}
        $mail_message["message"] = ""
        $mail_message["saveToSentItems"] = $saveToSentItems
           
        # Creating message hash table
        $message = @{}
        $message["subject"] = $subject
        $message["body"] = @{}
        $message["body"]["contentType"] = "HTML"
        $message["body"]["content"] = $body
        $message["importance"] = $importance

        # Creating recipient table
        $recipient_table = @{}
        $recipient_table["to"] = "toRecipients"
        $recipient_table["cc"] = "ccRecipients"
        $recipient_table["bcc"] = "bccRecipients"

        Try {
            # Setting recipients
            foreach ($recipient_type in $recipient_table.Keys) {
                If ($PSBoundParameters.ContainsKey($recipient_type)) {
                    # Setting recipients
                    $message[$recipient_table[$recipient_type]] = @(Set-EAIQRecipientArray -Recipients $PSBoundParameters[$recipient_type])
                
                }
            }

            # Setting attachments
            If ($PSBoundParameters.ContainsKey("Attachments")) {
                $message["attachments"] = @(Set-EAIQAttachmentArray -Attachments $attachments)

            }
        } Catch {
            Write-Error $_ -ErrorAction Stop
        
        }

        # Setting the message key
        $mail_message["message"] = $message

    } Process {
        Try {
            # Sending the message
            $client.InvokePostRequest("users", @($from, "sendMail"), $mail_message)

        } Catch {
            Write-Error $_

        }
    } End {

    }
}