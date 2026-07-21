class MimeMapping {
    # Maps file extensions to MIME types as System.Web.MimeMapping is not available in PowerShell 7.x
    static [string] GetMimeType([string]$Path) {
        $extension = [System.IO.Path]::GetExtension($Path).ToLower()

        If ([string]::IsNullOrEmpty($extension)) {
            Return "application/octet-stream"

        }

        Try {
            $reg_key = [Microsoft.Win32.Registry]::ClassesRoot.OpenSubKey($extension)

            If ($reg_key -and $reg_key.GetValue("Content Type")) {
                Return $reg_key.GetValue("Content Type").ToString()

            }

        } Catch {
            Write-Verbose "Error getting MIME type for $($extension): $($_.Exception.Message)"

        }

        Return "application/octet-stream"

    }

}
