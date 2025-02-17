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

        .PARAMETER ExcludeUsers
        If specified, will exclude users from the results.

        .EXAMPLE
        Get-EAMGroupMember -GroupId "00000000-0000-0000-0000-000000000000"

        .EXAMPLE
        Get-MgGroup -Filter "displayName eq 'My Group'" | Get-EAMGroupMember

        .EXAMPLE
        Get-MgGroup -Filter "displayName eq 'My Group'" | Get-EAMGroupMember -Recursive

        .EXAMPLE
        Get-MgGroup -Filter "displayName eq 'My Group'" | Get-EAMGroupMember -ExcludeGroups

        .INPUTS
        System.String
        System.Management.Automation.SwitchParameter

        .OUTPUTS
        System.Collections.Generic.List[psobject]

    #>
    [CmdletBinding(DefaultParameterSetName="Default")]
    [OutputType([PSObject])]
    Param (
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [Alias("Id")]
        [string]$GroupId,
        [Parameter(Mandatory=$false)]
        [switch]$Recursive,
        [Parameter(Mandatory=$false,ParameterSetName="ExcludeGroups")]
        [switch]$ExcludeGroups,
        [Parameter(Mandatory=$false,ParameterSetName="ExcludeUsers")]
        [switch]$ExcludeUsers
    
    )
    Begin {
        # Set the endpoint and oData type based on the parameters
        $end_point = If ($recursive) {
            "transitiveMembers"
        
        } Else {
            "members"
        
        }
        # Set the oData type based on the parameters
        $odata_type = If ($PSCmdlet.ParameterSetName -eq "ExcludeGroups") {
            "/microsoft.graph.user"
        
        } ElseIf ($PSCmdlet.ParameterSetName -eq "ExcludeUsers") {
            "/microsoft.graph.group"
        
        } 
    } Process {
        # Invoke-MgEAMRequest parameters
        $invoke_mg_params = @{}
        $invoke_mg_params["Method"] = "GET"
        $invoke_mg_params["Uri"] = "https://graph.microsoft.com/v1.0/groups/$($groupId)/$($end_point)$($odata_type)" 
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