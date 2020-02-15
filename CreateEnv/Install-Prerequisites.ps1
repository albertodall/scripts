param(
    [Parameter(Mandatory=$true)] 
    [string] $VMName,
 
    [Parameter(Mandatory=$true)] 
    [string] $ISOStoragePath,

    [Parameter(Mandatory=$true)] 
    [string] $AdditionalComponentsFolder
)

#$VMName = 'Test-ISBets01'
$DismLogFileName = 'dism.log'
#$AdditionalComponentsFolder = 'D:\Install'
#$ISOStoragePath = '\\ISARCHIVE-NAS2\SCVMM-Library\ISO'
#$SQLServerISOFileName = 'en_sql_server_2016_developer_x64_dvd_8777069.iso'

$VM = Get-VM | Where-Object { $_.Name -eq $VMName }
if (($VM -ne $null) -and ($VM.State -eq 'Off')) {
    $vmFirmware = $VM | Get-VMFirmware    
    $bootDrive = $vmFirmware.BootOrder `
        | Where-Object { $_.BootType -eq 'Drive' } `
        | Select-Object -First 1
    $VMStoragePath = Split-Path $bootDrive.Device.Path -Parent

    New-Item "$VMStoragePath\OSImage" -Type Directory | Out-Null
    Mount-WindowsImage -ImagePath $bootDrive.Device.Path `
        -Path "$VMStoragePath\OSImage" `
        -LogPath "$VMStoragePath\$DismLogFileName" -Index 1 -Verbose | Out-Null

    # # Install Powershell 5.1
    # Add-WindowsPackage -PackagePath "$AdditionalComponentsFolder\Win8.1AndW2K12R2-KB3191564-x64.msu" `
    #     -Path "$VMStoragePath\OSImage" `
    #     -LogPath "$VMStoragePath\$DismLogFileName" -Verbose | Out-Null

    # Disable SMB1
    Disable-WindowsOptionalFeature -FeatureName smb1protocol `
        -Path "$VMStoragePath\OSImage" `
        -LogPath "$VMStoragePath\$VMName\$DismLogFileName" -Verbose | Out-Null
    
    # Copy ISO images required by the environment
    # New-Item -Path "$VMStoragePath\OSImage\ISO" -Type Directory -ErrorAction Ignore -Verbose | Out-Null
    # if ((Test-Path "$VMStoragePath\OSImage\ISO\$SQLServerISOFileName") -eq $false) {
    #     Copy-Item -Path "$ISOStoragePath\$SQLServerISOFileName" -Destination "$VMStoragePath\OSImage\ISO" -Verbose | Out-Null
    # }

    # # Copy required Powershell modules
    # # Find-Module <module name> | Save-Module -Path <destination path>
    # Get-ChildItem -Path "$AdditionalComponentsFolder\PSModules" -Directory -Verbose | `
    #     ForEach-Object { 
    #         Copy-Item $_.FullName -Destination "$VMStoragePath\OSImage\Program Files\WindowsPowerShell\Modules\" -Force -Recurse
    #     }

    Dismount-WindowsImage -Path "$VMStoragePath\OSImage" -Save -LogPath "$VMStoragePath\$DismLogFileName" -Verbose | Out-Null
    Remove-Item -Path "$VMStoragePath\OSImage" -Force | Out-Null
} else {
    if ($VM -eq $null) {
        Write-Error "Virtual Machine $VMName does not exist on this Hyper-V server. Cannot install prerequisites."
    } elseif ($VM.State -ine 'Off') {
        Write-Warning "Virtual Machine $VMName is not turned off. Skipping prerequisites setup."
    }  
}