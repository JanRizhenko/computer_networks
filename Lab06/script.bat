@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set server1=127.0.0.1
set server2=127.0.0.1

set server1_username=Admin
set server2_username=Admin

set server1_password=password123
set server2_password=password123

set server1_is_available=false
set server2_is_available=false

set disk_letter=Z
set folder_name=SharedFolder

set shared_folder_remark=Jan's shared folder
set shared_folder_path=C:\Users\Admin\Desktop
set shared_folder_name=JanShare
set shared_name=JanSharedFolder

echo ========================================
echo SCRIPT START
echo ========================================
echo.

echo [INFO] ====== SYSTEM INFORMATION ======
echo [INFO] Username: %username%
echo [INFO] Computer name: %computername%
echo [INFO] Domain/Workgroup: WORKGROUP
echo [INFO] Network adapter: Realtek PCIe GbE Family Controller
echo [INFO] MAC address: CC-28-AA-08-3E-5C
echo.

echo [INFO] ====== OS VERSION ======
ver
echo.

echo [INFO] ====== NETWORK CONFIGURATION ======
ipconfig | findstr /C:"IPv4" /C:"Subnet" /C:"Gateway" /C:"DNS"
echo [INFO] IP address: 192.168.0.100
echo [INFO] Subnet mask: 255.255.255.0
echo [INFO] Gateway: 192.168.0.1
echo [INFO] DNS server: 192.168.0.1
echo.

echo [INFO] ====== ADDITIONAL INFORMATION ======
systeminfo | findstr /C:"OS Name" /C:"OS Version" /C:"System Boot Time" /C:"System Manufacturer" /C:"BIOS Version"
echo.

echo ========================================
echo SERVER AVAILABILITY CHECK
echo ========================================
echo.

set server1_ip=%server1%
set server2_ip=%server2%

echo [INFO] Checking Server 1 availability: %server1_ip%
ping %server1% -n 2 -w 1000 | find "TTL=" >nul
set check_result=%errorlevel%
if "%check_result%"=="0" (
    echo [SUCCESS] Server 1 is ONLINE - %server1_ip%
    set server1_is_available=true
) else (
    echo [ERROR] Server 1 is OFFLINE - %server1_ip%
    set server1_is_available=false
)
echo.

echo [INFO] Checking Server 2 availability: %server2_ip%
ping %server2% -n 2 -w 1000 | find "TTL=" >nul
set check_result=%errorlevel%
if "%check_result%"=="0" (
    echo [SUCCESS] Server 2 is ONLINE - %server2_ip%
    set server2_is_available=true
) else (
    echo [ERROR] Server 2 is OFFLINE - %server2_ip%
    set server2_is_available=false
)
echo.

echo [INFO] ====== AVAILABILITY SUMMARY ======
echo [INFO] Server 1 %server1_ip%: !server1_is_available!
echo [INFO] Server 2 %server2_ip%: !server2_is_available!
echo.

echo ========================================
echo ARP TABLE CONFIGURATION
echo ========================================
echo.

if "!server1_is_available!"=="true" (
    echo [INFO] Adding static ARP entry for Server 1
    
    for /f "tokens=2" %%i in ('arp -a %server1% 2^>nul ^| findstr "%server1%"') do (
        echo [INFO] Found MAC address for Server 1: %%i
        
        arp -s %server1% %%i >nul 2>&1
        set arp_result=!errorlevel!
        
        if "!arp_result!"=="0" (
            echo [SUCCESS] Static ARP entry added for Server 1
        ) else (
            echo [ERROR] Failed to add ARP entry for Server 1
        )
    )
    echo.
) else (
    echo [INFO] Server 1 is offline, skipping ARP configuration
    echo.
)

if "!server2_is_available!"=="true" (
    echo [INFO] Adding static ARP entry for Server 2
    
    for /f "tokens=2" %%i in ('arp -a %server2% 2^>nul ^| findstr "%server2%"') do (
        echo [INFO] Found MAC address for Server 2: %%i
        
        arp -s %server2% %%i >nul 2>&1
        set arp_result=!errorlevel!
        
        if "!arp_result!"=="0" (
            echo [SUCCESS] Static ARP entry added for Server 2
        ) else (
            echo [ERROR] Failed to add ARP entry for Server 2
        )
    )
    echo.
) else (
    echo [INFO] Server 2 is offline, skipping ARP configuration
    echo.
)

echo [INFO] Current ARP table entries for servers:
arp -a | findstr "%server1% %server2%" 2>nul
set arp_check=%errorlevel%
if "%arp_check%"=="0" (
    echo [INFO] ARP entries found
) else (
    echo [INFO] No ARP entries found for these servers
)
echo.

echo ========================================
echo CLEAR NETWORK CONNECTIONS
echo ========================================
echo.

echo [INFO] Deleting existing network connections...
net use * /delete /y >nul 2>&1
set net_clear=%errorlevel%

if "%net_clear%"=="0" (
    echo [SUCCESS] All network resources deleted
) else (
    echo [INFO] No network resources to delete
)
echo.

if "!server1_is_available!"=="true" (
    echo ========================================
    echo CONNECTING TO SERVER 1
    echo ========================================
    echo.
    
    echo [INFO] Attempting connection to Server 1: %server1_ip%
    echo [INFO] Testing connection to localhost
    echo.
    
    net use \\%server1% /user:%server1_username% %server1_password% >nul 2>&1
    set conn_result=%errorlevel%
    
    if "%conn_result%"=="0" (
        echo [SUCCESS] Connection to Server 1 established
        echo.
        
        echo [INFO] Synchronizing time with Server 1...
        net time \\%server1% /set /yes >nul 2>&1
        set time_result=%errorlevel%
        
        if "%time_result%"=="0" (
            echo [SUCCESS] Time synchronized with Server 1
            echo [INFO] Current time: 
            time /t
        ) else (
            echo [INFO] Time synchronization not available for this server
        )
        echo.
        
        echo [INFO] Attempting to map network drive %disk_letter%:
        net use %disk_letter%: \\%server1%\%folder_name% /user:%server1_username% %server1_password% /persistent:yes >nul 2>&1
        set drive_result=%errorlevel%
        
        if "%drive_result%"=="0" (
            echo [SUCCESS] Network drive %disk_letter%: mapped successfully
            echo [INFO] Path: \\%server1%\%folder_name%
            echo.
            
            echo [INFO] Network drive contents:
            dir %disk_letter%:\ /b 2>nul
        ) else (
            echo [INFO] Network drive mapping not available - ensure SharedFolder exists
        )
        echo.
    ) else (
        echo [INFO] Connection not available - ensure file sharing is enabled
        echo.
    )
) else (
    echo [INFO] Server 1 is offline, skipping connection
    echo.
)

if "!server2_is_available!"=="true" (
    echo ========================================
    echo CONNECTING TO SERVER 2
    echo ========================================
    echo.
    
    echo [INFO] Attempting connection to Server 2: %server2_ip%
    echo [INFO] Testing connection to localhost
    echo.
    
    net use \\%server2% /user:%server2_username% %server2_password% >nul 2>&1
    set conn2_result=%errorlevel%
    
    if "%conn2_result%"=="0" (
        echo [SUCCESS] Connection to Server 2 established
        echo [INFO] Available resources on Server 2:
        net view \\%server2% 2>nul
    ) else (
        echo [INFO] Connection not available - ensure file sharing is enabled
    )
    echo.
) else (
    echo [INFO] Server 2 is offline, skipping connection
    echo.
)

echo ========================================
echo CREATE SHARED FOLDER
echo ========================================
echo.

echo [INFO] Creating directory: %shared_folder_path%\%shared_folder_name%
if not exist "%shared_folder_path%\%shared_folder_name%" (
    mkdir "%shared_folder_path%\%shared_folder_name%" 2>nul
    set mkdir_result=%errorlevel%
    
    if "%mkdir_result%"=="0" (
        echo [SUCCESS] Directory created
    ) else (
        echo [ERROR] Failed to create directory
    )
) else (
    echo [INFO] Directory already exists
)
echo.

echo [INFO] Creating test file...
(
    echo Network Admin - %date% %time%
    echo MAC: CC-28-AA-08-3E-5C
    echo IP: 192.168.0.100
    echo Server 1: %server1% - !server1_is_available!
    echo Server 2: %server2% - !server2_is_available!
) > "%shared_folder_path%\%shared_folder_name%\info.txt"

if exist "%shared_folder_path%\%shared_folder_name%\info.txt" (
    echo [SUCCESS] Test file created
    echo [INFO] File location: %shared_folder_path%\%shared_folder_name%\info.txt
) else (
    echo [ERROR] Failed to create file
)
echo.

echo [INFO] Setting up shared access...
net share %shared_name%="%shared_folder_path%\%shared_folder_name%" /remark:"%shared_folder_remark%" >nul 2>&1
set share_result=%errorlevel%

if "%share_result%"=="0" (
    echo [SUCCESS] Shared access configured
    echo [INFO] Network path: \\%computername%\%shared_name%
    echo [INFO] Local path: %shared_folder_path%\%shared_folder_name%
    echo.
    
    echo [INFO] Shared resource information:
    net share %shared_name% 2>nul
) else (
    echo [INFO] Shared access may already exist or insufficient permissions
    echo [INFO] Attempting to view existing share...
    net share %shared_name% 2>nul
)
echo.

if "!server1_is_available!"=="true" (
    echo ========================================
    echo COPY FILES FROM SERVER 1
    echo ========================================
    echo.
    
    echo [INFO] Attempting to copy files from Server 1
    
    if exist "\\%server1%\%folder_name%\*.*" (
        copy "\\%server1%\%folder_name%\*.*" "%shared_folder_path%\%shared_folder_name%\" /Y >nul 2>&1
        set copy_result=%errorlevel%
        
        if "%copy_result%"=="0" (
            echo [SUCCESS] Files copied from Server 1
        ) else (
            echo [ERROR] Failed to copy files
        )
    ) else (
        echo [INFO] No files found on Server 1 - ensure SharedFolder exists
    )
    echo.
) else (
    echo [INFO] Server 1 is offline, skipping file copy
    echo.
)

if "!server2_is_available!"=="true" (
    echo ========================================
    echo COPY FILES FROM SERVER 2
    echo ========================================
    echo.
    
    echo [INFO] Attempting to copy files from Server 2
    
    if exist "\\%server2%\%folder_name%\*.*" (
        copy "\\%server2%\%folder_name%\*.*" "%shared_folder_path%\%shared_folder_name%\" /Y >nul 2>&1
        set copy2_result=%errorlevel%
        
        if "%copy2_result%"=="0" (
            echo [SUCCESS] Files copied from Server 2
        ) else (
            echo [ERROR] Failed to copy files
        )
    ) else (
        echo [INFO] No files found on Server 2 - DNS server has no file sharing
    )
    echo.
) else (
    echo [INFO] Server 2 is offline, skipping file copy
    echo.
)

REM ========================================
REM BLOCK 9: Final Report
REM ========================================

echo ========================================
echo FINAL REPORT
echo ========================================
echo.

echo [INFO] Current network connections:
net use 2>nul
set netuse_check=%errorlevel%
if "%netuse_check%"=="0" (
    echo [INFO] Network connections listed above
) else (
    echo [INFO] No active network connections
)
echo.

echo [INFO] Active shared resources:
net share 2>nul
echo.

echo [INFO] Shared folder contents:
if exist "%shared_folder_path%\%shared_folder_name%" (
    echo [INFO] Files in shared folder:
    dir "%shared_folder_path%\%shared_folder_name%" /b
    echo.
    echo [INFO] Total files:
    dir "%shared_folder_path%\%shared_folder_name%" | find "File"
) else (
    echo [ERROR] Shared folder not found
)
echo.

echo [INFO] Server status summary:
echo [INFO] - Server 1 %server1%: !server1_is_available!
echo [INFO] - Server 2 %server2%: !server2_is_available!
echo.

echo ========================================
echo SCRIPT COMPLETED SUCCESSFULLY
echo Date and time: %date% %time%
echo ========================================
echo.

pause
endlocal