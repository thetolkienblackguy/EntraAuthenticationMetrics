class EAIQLogManager {
    [string]$LogFile
    [bool]$WriteOutput
    [bool]$Verbose
    hidden [bool]$IsInteractive = $true

    EAIQLogManager([string]$LogFile, [bool]$WriteOutput, [bool]$Verbose, [bool]$IsInteractive) {
        $this.LogFile = $LogFile
        $this.WriteOutput = $WriteOutput
        $this.Verbose = $Verbose
        $this.IsInteractive = $IsInteractive
        $this.InitializeLogFile()

    }

    hidden [void]InitializeLogFile() {
        If (!$this.LogFile) {
            Return

        }

        $log_directory = [System.IO.Path]::GetDirectoryName($this.LogFile)

        If (!(Test-Path -Path $log_directory)) {
            $ni_params = @{}
            $ni_params["Path"] = $log_directory
            $ni_params["ItemType"] = "Directory"
            $ni_params["Force"] = $true
            New-Item @ni_params | Out-Null

        }

        If (!(Test-Path -Path $this.LogFile)) {
            New-Item -Path $this.LogFile -ItemType File -Force | Out-Null

        }

    }

    hidden [string]FormatMessage([string]$Message) {
        $timestamp = Get-Date -Format "MM/dd/yy HH:mm:ss"
        Return "[$timestamp] $Message"

    }

    hidden [void]WriteLog([string]$Message, [string]$Color, [bool]$RespectVerbose) {
        If ($RespectVerbose -and !$this.Verbose) {
            Return

        }

        $formatted = $this.FormatMessage($Message)

        If ($this.WriteOutput) {
            If ($this.IsInteractive) {
                $wh_params = @{}
                $wh_params["Object"] = $formatted
                $wh_params["ForegroundColor"] = $Color
                $wh_params["BackgroundColor"] = "Black"
                Write-Host @wh_params

            } Else {
                Write-Output $formatted

            }

        }

        If ($this.LogFile) {
            $of_params = @{}
            $of_params["FilePath"] = $this.LogFile
            $of_params["Append"] = $true
            $of_params["InputObject"] = $formatted
            Out-File @of_params

        }

    }

    [void]Initialize([string]$Message) {
        $this.WriteLog($Message, "Yellow", $false)

    }

    [void]Information([string]$Message) {
        $this.WriteLog($Message, "Yellow", $true)

    }

    [void]Success([string]$Message) {
        $this.WriteLog($Message, "Green", $true)

    }

    [void]Warning([string]$Message) {
        $this.WriteLog($Message, "Yellow", $false)

    }

    [void]Error([string]$Message) {
        $this.WriteLog($Message, "Red", $false)

    }

    [void]Finalize([string]$Message) {
        $this.WriteLog($Message, "Cyan", $false)

    }

}
