Function Invoke-EAMWriteProgress {
    <#
        .SYNOPSIS
        Writes a progress bar to the console.

        .DESCRIPTION
        This function writes a progress bar to the console. This is a wrapper around the Write-Progress cmdlet.

        .PARAMETER Interation
        The current iteration of the process.

        .PARAMETER Total
        The total number of iterations of the process.

        .PARAMETER Item
        The item being processed.

        .INPUTS
        System.Int32
        System.String

        .OUTPUTS
        System.Void
        
    #>
    param (
        [Parameter(Mandatory=$true)]
        [int]$Iteration,
        [Parameter(Mandatory=$true)]
        [int]$Total,
        [Parameter(Mandatory=$true)]
        [string]$Item

    )
    # Calculate the percentage complete
    $percent_complete = ($iteration / $total) * 100
    
    # Write-Progress parameters
    $write_progress_params = @{}
    $write_progress_params["Activity"] = "Retrieving authentication methods for user $item"
    $write_progress_params["Status"] = "Processing $iteration of $total"
    $write_progress_params["PercentComplete"] = $percent_complete
    
    # Write the progress
    Write-Progress @write_progress_params

}