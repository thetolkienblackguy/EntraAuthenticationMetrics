Function Get-EAMGroupMember {
    <#
        .DESCRIPTION
        Gets the members of a group, unlike Get-MgGroupMember, this has a recursive option to get the members of nested groups.
        
        .SYNOPSIS
        Gets the members of a group, unlike Get-MgGroupMember, this has a recursive option to get the members of nested groups.
        
        .PARAMETER GroupId
        The Id of the group to get the members of.

        .PARAMETER Recursive
        If specified, will recursively get the members of nested groups. 

        .PARAMETER ExcludeGroups
        If specified, will exclude groups from the results.

        .PARAMETER ApiVersion
        The version of the API to use.

        .PARAMETER Select
        The properties to select from the results.

        .EXAMPLE
        Get-EAMGroupMember -GroupId "00000000-0000-0000-0000-000000000000"

        .EXAMPLE
        Get-MgGroup -Filter "displayName eq 'My Group'" | Get-EAMGroupMember

        .EXAMPLE
        Get-MgGroup -Filter "displayName eq 'My Group'" | Get-EAMGroupMember -Recursive

        .EXAMPLE
        Get-MgGroup -Filter "displayName eq 'My Group'" | Get-EAMGroupMember -ExcludeGroups -Select "Id","UserPrincipalName"

        .INPUTS
        System.String
        System.Management.Automation.SwitchParameter

        .OUTPUTS
        System.Object

    #>
    [CmdletBinding()]
    [OutputType([system.object])]
    Param (
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [Alias("Id")]
        [string]$GroupId,
        [Parameter(Mandatory=$false)]
        [switch]$Recursive,
        [Parameter(Mandatory=$false)]
        [switch]$ExcludeGroups,
        [ValidateSet("Beta","v1.0")]
        [string]$ApiVersion = "v1.0",
        [Parameter(Mandatory=$false)]
        [string[]]$Select = @(
            "Id","UserPrincipalName","Authorizationinfo"
            
        )
    )
    Begin {
        # Get the Microsoft Graph endpoint, if not already set
        If (!$script:graph_endpoint) {
            $script:graph_endpoint = Get-EAMGraphEndpoint
        
        }

        # Set the endpoint and oData type based on the parameters
        $end_point = If ($recursive) {
            "transitiveMembers"
        
        } Else {
            "members"
        
        }
        # Set the oData type based on the parameters
        $odata_type = If ($ExcludeGroups) {
            "/microsoft.graph.user"
        
        } 
    } Process {
        # Invoke-MgEAMRequest parameters
        $invoke_mg_params = @{}
        $invoke_mg_params["Method"] = "GET"
        $invoke_mg_params["Uri"] = "$($script:graph_endpoint)/$($apiVersion)/groups/$($groupId)/$($end_point)$($odata_type)?`$select=$($($select -join ","))" 
        $invoke_mg_params["OutputType"] = "PSObject"
        
        Try {
            # Loop through the pages of results
            Do {
                # Invoke-MgEAMRequest
                $r = Invoke-MgGraphRequest @invoke_mg_params
                
                # Output the results
                $r.Value
                
                # Set the next link
                $invoke_mg_params["Uri"] = $r."@odata.nextLink"
        
            # Loop until there are no more pages
            } Until (!$r."@odata.nextLink")

        } Catch {
            Write-Error -Message $_

        }
    } End {
    }
}