$PSDefaultParameterValues["Get-ChildItem:File"] = $true
$PSDefaultParameterValues["Join-Path:Path"] = $PSScriptRoot

$imports = @("Classes\Helpers", "Classes\Components", "Private", "Public")

ForEach ($import in $imports) {
    $import_path = Join-Path -ChildPath $import
    $get_child_params = @{}
    $get_child_params["Path"] = $import_path
    $get_child_params["Recurse"] = $true
    $get_child_params["Include"] = "*.ps1"

    $files = Get-ChildItem @get_child_params

    ForEach ($file in $files) {
        . $file.FullName

        If ($import -eq "Public") {
            Export-ModuleMember -Function $file.BaseName

        }

    }

}

# Backward-compatibility aliases. The canonical cmdlets are now AuthIQ-prefixed;
# the former EAIQ- and EAM-prefixed names resolve to them. New-EAMAuthenticationReport
# and New-EAMDashboard had different behavior and were removed (see CHANGELOG).
Set-Alias -Name "Invoke-EAIQDashboardCreation" -Value "Invoke-AuthIQDashboardCreation"
Set-Alias -Name "Send-EAIQMailMessage" -Value "Send-AuthIQMailMessage"
Set-Alias -Name "Invoke-EAMDashboardCreation" -Value "Invoke-AuthIQDashboardCreation"
Set-Alias -Name "Send-EAMMailMessage" -Value "Send-AuthIQMailMessage"
Set-Alias -Name "New-EntraAuthenticationMetricsDashboard" -Value "Invoke-AuthIQDashboardCreation"
Export-ModuleMember -Alias @(
    "Invoke-EAIQDashboardCreation",
    "Send-EAIQMailMessage",
    "Invoke-EAMDashboardCreation",
    "Send-EAMMailMessage",
    "New-EntraAuthenticationMetricsDashboard"
)

# Register type accelerators for all classes
$type_accelerators = [psobject].Assembly.GetType("System.Management.Automation.TypeAccelerators")
$class_folders = @("Classes\Helpers", "Classes\Components")

ForEach ($folder in $class_folders) {
    $folder_path = Join-Path -ChildPath $folder
    $class_files = Get-ChildItem -Path $folder_path -Recurse -Include "*.ps1"

    ForEach ($class_file in $class_files) {
        $class_name = $class_file.BaseName
        Try {
            $type = Invoke-Expression "[type]'$class_name'"
            $type_accelerators::Add($class_name, $type)

        } Catch {
            Write-Verbose "Could not register type accelerator for: $class_name"

        }

    }

}
