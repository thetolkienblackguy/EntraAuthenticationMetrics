Function Set-EAMRecipientArray {
    <#
        .SYNOPSIS
        This is a helper function that sets the recipient array for the Send-GraphMailMessage function.

        .DESCRIPTION
        This is a helper function that sets the recipient array for the Send-GraphMailMessage function.

        .INPUTS
        System.Array

        .OUTPUTS
        System.Object

    #>
    [CmdletBinding()]
    [OutputType([System.Object])]
    param (   
        [Parameter(Mandatory=$true)]
        [string[]]$Recipients

    )
    Begin {
        # Create the recipient array
        $recipient_array = [system.collections.generic.list[psobject]]::new()
        
    } Process {
        # Loop through each recipient and add it to the recipient array
        Foreach ($recipient in $recipients) {
            # Create the address table          
            $address = @{}
            $address["address"] = $recipient

            # Create the recipient table
            $recipient_table = @{}
            $recipient_table["emailAddress"] = $address

            # Add the recipient table to the recipient array
            $recipient_array.Add($recipient_table)

        }
    } End {
        # Return the recipient array
        $recipient_array

    }  
}