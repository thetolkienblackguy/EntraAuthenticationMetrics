Function Write-EAMCertificateWarning {
    <#
        .SYNOPSIS
        Writes a warning about the certificate based authentication.

        .DESCRIPTION
        This function writes a warning about the certificate based authentication.
        
    #>
    $warning = [System.Text.StringBuilder]::new()
    [void]$warning.AppendLine("`n***********************************************************************************************************************************`n")
    [void]$warning.AppendLine("Currently certificate-based authentication is calculated based on whether the userCertificateIds property is populated in Entra Id")
    [void]$warning.AppendLine("Depending on the way your tenant does name mapping for certificate-based authentication, this may not be reported accurately`n")
    [void]$warning.AppendLine("***********************************************************************************************************************************`n")
    Write-Warning $warning.ToString()
}