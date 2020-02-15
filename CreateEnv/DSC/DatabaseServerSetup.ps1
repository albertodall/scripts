Configuration DatabaseServerSetup {
    Import-DscResource -ModuleName PSDesiredStateConfiguration 
    Import-DscResource -ModuleName StorageDsc
    Import-DscResource -ModuleName SqlServerDsc

    Node $AllNodes.NodeName
    {
        WaitforDisk WaitForDisk1 {
             DiskId = 1
             RetryIntervalSec = 60
             RetryCount = 60
        }

        Disk VolumeD {
             DiskId = 1
             DriveLetter = 'D'
             FSFormat = 'NTFS'
             DependsOn = '[WaitForDisk]WaitForDisk1'
        }

        File UserDBFolder {
            DestinationPath = 'D:\Dbs'
            Type            = 'Directory'
            DependsOn       = '[Disk]VolumeD'
        }

        File TempDBFolder {
            DestinationPath = 'D:\Dbs\TempDb'
            Type            = 'Directory' 
            DependsOn       = '[File]UserDBFolder'
        }

        File BackupDBFolder {
            DestinationPath = 'D:\Dbs\Backup'
            Type            = 'Directory' 
            DependsOn       = '[File]UserDBFolder'
        }
       
        MountImage SQLServerIso {
            ImagePath   = 'C:\ISO\en_sql_server_2016_developer_x64_dvd_8777069.iso'
            DriveLetter = 'Y'
            StorageType = 'ISO'
        }

        WaitForVolume WaitForSQLServerIso {
            DriveLetter      = 'Y'
            RetryIntervalSec = 5
            RetryCount       = 10
        }

        WindowsFeature NetFramework45 {
            Name   = 'NET-Framework-45-Core'
            Ensure = 'Present'
        }

        #region Install SQL Server
        SqlSetup InstallDefaultInstance {
            InstanceName         = 'MSSQLSERVER'
            Features             = 'SQLENGINE'
            SQLCollation         = 'SQL_Latin1_General_CP1_CI_AS'
            SQLSysAdminAccounts  = 'BUILTIN\Administrators'
            InstallSharedDir     = 'C:\Program Files\Microsoft SQL Server'
            InstallSharedWOWDir  = 'C:\Program Files (x86)\Microsoft SQL Server'
            InstanceDir          = 'C:\Program Files\Microsoft SQL Server'
            InstallSQLDataDir    = 'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Data'
            SQLUserDBDir         = 'D:\Dbs'
            SQLUserDBLogDir      = 'D:\Dbs'
            SQLTempDBDir         = 'D:\Dbs\TempDB'
            SQLTempDBLogDir      = 'D:\Dbs\TempDB'
            SQLBackupDir         = 'D:\Dbs\Backup'
            SecurityMode         = 'SQL'
            SAPwd                = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList ('sa', (ConvertTo-SecureString -String 'P@ssw0rd' -AsPlainText -Force))
            SourcePath           = 'Y:'
            UpdateEnabled        = 'True'
            ForceReboot          = $false
            DependsOn            = '[WindowsFeature]NetFramework45', '[WaitForVolume]WaitForSQLServerIso', '[File]TempDBFolder', '[File]BackupDBFolder'
        }
        
        SqlWindowsFirewall SQLServerFirewallException {
            InstanceName = 'MSSQLSERVER'
            Features     = 'SQLENGINE'
            SourcePath   = 'Y:'
            DependsOn    = '[SqlSetup]InstallDefaultInstance'
        }

        SqlServerMemory SetSQLServerMinAndMaxMemory {
            InstanceName = 'MSSQLSERVER'          
            MinMemory    = 1024
            MaxMemory    = 2048
            DependsOn    = '[SqlSetup]InstallDefaultInstance'
        }

        SqlServerMaxDop SetSQLServerMaxDop {
            InstanceName = 'MSSQLSERVER'
            MaxDop       = 1
            DynamicAlloc = $false
            DependsOn    = '[SqlSetup]InstallDefaultInstance'
        }

        SqlServerNetwork SQLServerEnableTcpProtocol
        {
            InstanceName   = 'MSSQLSERVER'
            ProtocolName   = 'Tcp'
            IsEnabled      = $true
            TCPDynamicPort = $false
            TCPPort        = 1433
            RestartService = $true
            DependsOn      = '[SqlSetup]InstallDefaultInstance'
        }
    }
}