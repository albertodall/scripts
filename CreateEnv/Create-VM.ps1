param(
    [Parameter(Mandatory=$true)] 
    [string] $VMName,

    [Parameter(Mandatory=$true)] 
    [string] $AdministratorPassword,

    [Parameter(Mandatory=$true)] 
    [string] $GoldenImagePath,

    [Parameter(Mandatory=$true)] 
    [string] $VMStorePath
)

# VM Configuration parameters
#$GoldenImagePath = 'D:\VM\Hyper-V\GoldenImages'
#$VMStorePath = 'D:\VM\Hyper-V'
#$VMName = 'Test-ISBets01'
#$AdministratorPassword = 'P@ssw0rd'
$AnswerFileTemplate = 'unattend-template.xml'
$AnswerFileName = 'unattend.xml'
$DismLogFileName = 'dism.log'

$VM = Get-VM | Where-Object { $_.Name -eq $VMName }
if ($VM -eq $null) {
    
    # Create VM if does not exist
    $VMCreationParam = @{
        Name = $VMName
        MemoryStartupBytes = 2GB
        Path = "$VMStorePath\$VMName"
        Generation = 2
        ErrorAction = 'Stop'
        Verbose = $true
    }
    $VM = New-VM @VMCreationParam

    # Create Disk C (SYSTEM) starting from a Sysprepped Image
    Copy-Item -Path "$GoldenImagePath\WIN2012R2.vhdx" -Destination "$VMStorePath\$VMName\$VMName-DiskC.vhdx" -Force -Verbose
    $VHD_DiskC = Get-VHD -Path "$VMStorePath\$VMName\$VMName-DiskC.vhdx" -Verbose

    # Prepare Windows answer file for unattended OS setup
    New-Item "$VMStorePath\$VMName\OSImage" -Type Directory | Out-Null
    Mount-WindowsImage -ImagePath $VHD_DiskC.Path `
        -Path "$VMStorePath\$VMName\OSImage" -Index 1 `
        -LogPath "$VMStorePath\$VMName\$DismLogFileName" -Verbose | Out-Null
    New-Item -Path "$VMStorePath\$VMName\OSImage\Windows\Panther\Unattend" -Type Directory | Out-Null
    (Get-Content ".\$AnswerFileTemplate") `
            -replace '{SERVER-HOSTNAME}', $VMName.ToUpper() `
            -replace '{ADMINISTRATOR-PASSWORD}', $AdministratorPassword `
        | Out-File "$VMStorePath\$VMName\OSImage\Windows\Panther\Unattend\$AnswerFileName" -Force -Encoding utf8 -Verbose
    Dismount-WindowsImage -Path "$VMStorePath\$VMName\OSImage" -Save -LogPath "$VMStorePath\$VMName\$DismLogFileName" -Verbose | Out-Null
    Remove-Item -Path "$VMStorePath\$VMName\OSImage" -Force | Out-Null

    # Create Disk D (DATA) 
    $VHDParam_DiskD = @{
        Path = "$VMStorePath\$VMName\$VMName-DiskD.vhdx"
        Dynamic = $True
        SizeBytes = 100GB
        ErrorAction = 'Stop'
        Verbose = $true
    }   
    $VHD_DiskD = New-VHD @VHDParam_DiskD

    $VM | Add-VMHardDiskDrive -Path $VHD_DiskC.Path -ControllerType 'SCSI' -ControllerLocation 1 -Verbose
    $VM | Add-VMHardDiskDrive -Path $VHD_DiskD.Path -ControllerType 'SCSI' -ControllerLocation 2 -Verbose
    $BootDevice = Get-VMHardDiskDrive -VM $VM -ControllerType 'SCSI' -ControllerLocation 1 -Verbose
    $VM | Set-VMFirmware -FirstBootDevice $BootDevice -Verbose   

    $VM | Get-VMNetworkAdapter | Remove-VMNetworkAdapter -Verbose
    $VM | Add-VMNetworkAdapter -Name 'LAN' -SwitchName 'Default Switch' -Verbose
} else {
    Write-Warning "Virtual Machine $VMName already exists on this Hyper-V server."
}

$VMConfigParams = @{
    ProcessorCount = 1
    DynamicMemory = $True
    MemoryMinimumBytes = 1GB
    MemoryMaximumBytes = 2GB
    CheckpointType = 'Disabled'
    ErrorAction = 'Stop'
    Verbose = $true
}   
$VM | Set-VM @VMConfigParams