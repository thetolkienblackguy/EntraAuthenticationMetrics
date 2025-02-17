Function Get-EAMUsers {
    <#
        .SYNOPSIS
        Get the users from Entra

        .DESCRIPTION
        Get the users from Entra

        .PARAMETER ParameterSetName
        The parameter set to use.

        .PARAMETER GroupId
        The group ID to use.

        .EXAMPLE    
        Get-EAMUsers -ParameterSetName "All"

        .EXAMPLE
        Get-EAMUsers -ParameterSetName "Group" -GroupId "12345678-1234-1234-1234-123456789012"

        .INPUTS
        System.String   

        .OUTPUTS
        System.Object
    
    #>
    [CmdletBinding(DefaultParameterSetName="AllUsers")]
    [OutputType([System.Object])]
    param (
        [Parameter(Mandatory=$true,ParameterSetName="AllUsers")]
        [Parameter(Mandatory=$true,ParameterSetName="Group")]
        [Parameter(Mandatory=$true,ParameterSetName="Filter")]
        [string]$ParameterSetName,
        [Parameter(Mandatory=$false,ParameterSetName="Group")]
        [string]$GroupId,
        [Parameter(Mandatory=$false,ParameterSetName="Filter")]
        [string]$Filter
    
    )
    If ($parameterSetName -eq "Group" -and !$groupId) {
        throw "GroupId is required when using the Group parameter set"
    
    }
    switch ($parameterSetName) {
        "AllUsers" { 
            return Get-EAMUser -All 
        
        } "Group" { 
            return Get-EAMGroupMember -GroupId $groupId | Get-EAMUser 
        
        } "Filter" { 
            return Get-EAMUser -Filter $filter
        
        } default {
            throw "Invalid parameter set name: $parameterSetName"
        
        }
    }
}