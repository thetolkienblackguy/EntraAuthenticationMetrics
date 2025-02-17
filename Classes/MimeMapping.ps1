class MimeMapping {
    # Created this class to map file extensions to MIME types as System.Web.MimeMapping does not work in PowerShell 7.x
    static [string] GetMimeType([string]$path) {
        $extension = [System.IO.Path]::GetExtension($path).ToLower()
        if ([string]::IsNullOrEmpty($extension)) {
            return "application/octet-stream"
        
        }

        try {
            $reg_key = [Microsoft.Win32.Registry]::ClassesRoot.OpenSubKey($extension)
            if ($reg_key -and $reg_key.GetValue("Content Type")) {
                return $reg_key.GetValue("Content Type").ToString()
            }
        }
        catch {
            Write-Verbose "Error getting MIME type for $($extension): $_"
        }

        return "application/octet-stream"
    }
}