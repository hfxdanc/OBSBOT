#Requires -Version 2.0
[CmdletBinding()]
Param()

Begin {
    $installName = "OBSBOT TinyCam*"
    $processName = "OBSBOT_TinyCam"
    $programName = $processName + ".exe"
    $programs = @()

    $is64Bit = (Get-WmiObject Win32_OperatingSystem).OSArchitecture -eq "64-bit"

    if ($is64Bit) {
        $programs += Get-ChildItem HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall,HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall
    } else {
        $programs += Get-ChildItem HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall
    }

    $installed = ($programs) | Where-Object { $_.GetValue('DisplayName') -Like $installName }
}

Process {
    if ($installed) {
        $installDir = $installed.GetValue('InstallLocation') + "bin"
        $stdOutTempFile = "$env:TEMP\$((New-Guid).Guid)"
        $stdErrTempFile = "$env:TEMP\$((New-Guid).Guid)"

        while ($True) {
            if ($Null -eq (Get-Process $processName -ErrorAction SilentlyContinue)) {
                # Program is not running so make it so
                try {
                    $startArgs = @{
                        FilePath         = $installDir + "\" + $programName
                        RedirectStandardError  = $stdErrTempFile
                        RedirectStandardOutput = $stdOutTempFile
                        Wait             = $True
                        PassThru         = $True
                        WorkingDirectory = $installDir
                        WindowStyle      = "Minimized"
                    }
                    $process = Start-Process @startArgs

                    if ($process.ExitCode -NE 0) {
                        Write-Error -Message "Abnormal termination" -ErrorAction Stop
                    }

                    # Sleep for 3 seconds then restart program
                    Start-Sleep -Seconds 3
                }
                catch {
                    $PSCmdlet.ThrowTerminatingError($_)
                } finally {
                    Remove-Item -Path $stdOutTempFile, $stdErrTempFile -Force -ErrorAction Ignore
                }
            } else {
                # Sleep for a minute and re-check if the program is still running
                #  outside of this program's control
                Start-Sleep -Seconds 60
            }
        }
    }
}