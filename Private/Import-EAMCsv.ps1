Function Import-EAMCsv {
    <#
        .SYNOPSIS
        Imports a CSV file and returns a list of users.

        .DESCRIPTION
        Imports a CSV file and returns a list of users.

        .PARAMETER Path
        The path to the CSV file.

        .PARAMETER IdentityHeader
        The header of the identity column in the CSV file.

        .EXAMPLE
        Import-EAMCsv -Path "C:\Users\geekw\OneDrive\Documents\GitHub\EntraAuthanticationMetrics\Public\Users.csv" -IdentityHeader "id"

        .INPUTS
        System.String

        .OUTPUTS
        System.Object

    #>
    [CmdletBinding()]
    [OutputType([System.Object])]
    Param (
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [Parameter(Mandatory=$false)]
        [string]$IdentityHeader = "id"
    )
    Begin {
        $csv_data = Import-Csv -Path $path

    } Process {
        $users = ForEach ($row in $csv_data) {
            Get-EAMUser -UserId $row."$identityHeader" -ErrorAction Stop
        
        }
    } End {
        $users
    
    }
}