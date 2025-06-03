#!/bin/bash

# Color definitions for output formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Define log file path
LOG_FILE="$HOME/system_monitor.log"

# Define reports directory path
REPORTS_DIR="$HOME/reports"

# Define thresholds for CPU, RAM, and Disk usage (in percentage)
CPU_THRESHOLD=80
RAM_THRESHOLD=80
DISK_THRESHOLD=80

# Function to log events
log_event() {
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $1" >> "$LOG_FILE"
    echo -e "${YELLOW}[$timestamp] $1${NC}"
}

# Function to create a text report
create_report() {
    local report_file="$REPORTS_DIR/system_report_$(date "+%Y%m%d_%H%M%S").txt"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    {
        echo "SYSTEM MONITOR - Full System Check Report"
        echo "Generated on: $timestamp"
        echo "=========================================="
        echo ""
        echo "=== System Monitor Log Entries ==="
        grep "$timestamp" "$LOG_FILE"
        echo ""
        echo "=== Detailed System Check Results ==="
        echo "$FULL_CHECK_OUTPUT"
        echo "=========================================="
        echo "End of Report"
    } > "$report_file" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Report saved to: $report_file${NC}"
        log_event "Full system check report saved to $report_file"
    else
        echo -e "${RED}Error: Failed to save report to $report_file. Check permissions.${NC}"
        log_event "ERROR: Failed to save report to $report_file."
    fi
}

# Function to check CPU usage
check_cpu_usage() {
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
    cpu_usage=$(echo "$cpu_usage" | awk '{printf "%.0f", $1}')
    echo -e "CPU Usage: ${GREEN}$cpu_usage%${NC}"
    if [ "$cpu_usage" -gt "$CPU_THRESHOLD" ]; then
        log_event "WARNING: CPU usage exceeded threshold - $cpu_usage% > $CPU_THRESHOLD%"
    fi
}

# Function to check RAM usage
check_ram_usage() {
    local ram_total=$(free | grep Mem | awk '{print $2}')
    local ram_used=$(free | grep Mem | awk '{print $3}')
    local ram_usage=$((ram_used * 100 / ram_total))
    echo -e "RAM Usage: ${GREEN}$ram_usage%${NC}"
    if [ "$ram_usage" -gt "$RAM_THRESHOLD" ]; then
        log_event "WARNING: RAM usage exceeded threshold - $ram_usage% > $RAM_THRESHOLD%"
    fi
}

# Function to check service status using pidof
check_service_status() {
    local service_name="$1"
    local process_name="$service_name"
    if [ "$service_name" = "ssh" ]; then
        process_name="sshd"
    elif [ "$service_name" = "apache2" ]; then
        process_name="apache2"
    fi

    if pidof "$process_name" >/dev/null 2>&1; then
        echo -e "Service $service_name: ${GREEN}Running${NC}"
        log_event "Service $service_name is running."
    else
        echo -e "Service $service_name: ${RED}Stopped${NC}"
        log_event "WARNING: Service $service_name is stopped."
    fi
}

# Function to show top processes
check_top_processes() {
    echo -e "${YELLOW}Top 5 CPU consuming processes:${NC}"
    ps -eo pid,ppid,cmd,%cpu --sort=-%cpu | head -n 6
    log_event "Checked top CPU consuming processes."
}

# Function to show system information
show_system_info() {
    echo -e "${YELLOW}System Information:${NC}"
    echo "Hostname: $(hostname)"
    echo "Uptime: $(uptime -p)"
    echo "Kernel Version: $(uname -r)"
    echo "Operating System: $(lsb_release -d 2>/dev/null | awk '{print $2,$3,$4,$5}' || cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2)"
    log_event "Displayed system information."
}

# Function to show hardware information
show_hardware_info() {
    echo -e "${YELLOW}Hardware Information:${NC}"
    echo "CPU Model: $(lscpu | grep 'Model name' | awk -F: '{print $2}' | xargs)"
    echo "Total CPU Cores: $(lscpu | grep '^CPU(s):' | awk '{print $2}')"
    echo "Total Memory: $(free -h | grep Mem | awk '{print $2}')"
    echo "Architecture: $(uname -m)"
    if command -v dmidecode >/dev/null 2>&1; then
        echo "Manufacturer: $(dmidecode -s system-manufacturer 2>/dev/null)"
        echo "Product Name: $(dmidecode -s system-product-name 2>/dev/null)"
    else
        echo "Manufacturer/Product: Information not available (dmidecode not installed or requires root)"
    fi
    log_event "Displayed hardware information."
}

# Function to check disk usage
check_disk_usage() {
    echo -e "${YELLOW}Disk Usage Information:${NC}"
    df -h | grep -E '^/dev/' | while read -r line; do
        local disk_usage=$(echo "$line" | awk '{print $5}' | tr -d '%')
        local mount_point=$(echo "$line" | awk '{print $6}')
        if [ "$disk_usage" -gt "$DISK_THRESHOLD" ]; then
            echo -e "Mount Point: $mount_point - Usage: ${RED}$disk_usage%${NC} (Exceeded threshold)"
            log_event "WARNING: Disk usage on $mount_point exceeded threshold - $disk_usage% > $DISK_THRESHOLD%"
        else
            echo -e "Mount Point: $mount_point - Usage: ${GREEN}$disk_usage%${NC}"
        fi
    done
    log_event "Checked disk usage."
}

# Function to check files and folders in home directory
check_files_folders() {
    echo -e "${YELLOW}Files and Folders in Home Directory:${NC}"
    local home_dir="$HOME"
    local folder_count=$(find "$home_dir" -type d | wc -l)
    local file_count=$(find "$home_dir" -type f | wc -l)
    local largest_files=$(find "$home_dir" -type f -exec du -h {} + 2>/dev/null | sort -rh | head -n 5)
    echo "Total Folders: $folder_count"
    echo "Total Files: $file_count"
    echo -e "${YELLOW}Top 5 Largest Files:${NC}"
    echo "$largest_files"
    log_event "Checked files and folders in home directory."
}

# Function to check network status
check_network_status() {
    echo -e "${YELLOW}Network Status:${NC}"
    if command -v ip >/dev/null 2>&1; then
        echo "Network Interfaces:"
        ip addr show | grep -E '^[0-9]+:' | awk '{print $2}' | tr -d ':'
        echo "IP Addresses:"
        ip addr show | grep inet | awk '{print $2}' | cut -d'/' -f1
    else
        echo "Network Interfaces (using ifconfig):"
        ifconfig 2>/dev/null | grep -E '^[a-zA-Z0-9]+:' | awk '{print $1}' | tr -d ':'
        echo "IP Addresses (using ifconfig):"
        ifconfig 2>/dev/null | grep inet | awk '{print $2}' | cut -d':' -f2
    fi
    echo "Network Connectivity (Ping Test):"
    if ping -c 4 8.8.8.8 >/dev/null 2>&1; then
        echo -e "Internet Connection: ${GREEN}Active${NC}"
        log_event "Internet connection is active."
    else
        echo -e "Internet Connection: ${RED}Inactive${NC}"
        log_event "WARNING: Internet connection is inactive."
    fi
    log_event "Checked network status."
}

# Function to check CPU temperature
check_cpu_temperature() {
    echo -e "${YELLOW}CPU Temperature:${NC}"
    if command -v sensors >/dev/null 2>&1; then
        sensors 2>/dev/null | grep -E 'temp|Core' | head -n 5
        log_event "Checked CPU temperature."
    else
        echo -e "${RED}Error: 'sensors' command not found. Install 'lm-sensors' to check temperature.${NC}"
        log_event "ERROR: Unable to check CPU temperature. 'sensors' not installed."
    fi
}

# Function to check connected users
check_connected_users() {
    echo -e "${YELLOW}Connected Users:${NC}"
    if command -v who >/dev/null 2>&1; then
        who | awk '{print "User: " $1 ", Terminal: " $2 ", Login Time: " $3 " " $4}'
        local user_count=$(who | wc -l)
        echo "Total Connected Users: $user_count"
        log_event "Checked connected users using 'who'. Total: $user_count"
    elif command -v w >/dev/null 2>&1; then
        w | grep -v LOAD | awk '{print "User: " $1 ", Terminal: " $2 ", Login Time: " $5}'
        local user_count=$(w | grep -v LOAD | wc -l)
        echo "Total Connected Users: $user_count"
        log_event "Checked connected users using 'w'. Total: $user_count"
    elif command -v users >/dev/null 2>&1; then
        echo "Connected Users (limited info):"
        users | tr ' ' '\n' | sort | uniq | awk '{print "User: " $1}'
        local user_count=$(users | tr ' ' '\n' | sort | uniq | wc -l)
        echo "Total Connected Users: $user_count"
        log_event "Checked connected users using 'users'. Total: $user_count"
    else
        echo -e "${RED}Error: No suitable command found ('who', 'w', or 'users') to check connected users.${NC}"
        echo "Alternative Check (using 'ps'):"
        ps aux | grep -E 'bash|sh|zsh' | grep -v 'grep' | awk '{print "User: " $1}' | sort | uniq
        local user_count=$(ps aux | grep -E 'bash|sh|zsh' | grep -v 'grep' | awk '{print $1}' | sort | uniq | wc -l)
        echo "Estimated Unique Users with Shells: $user_count"
        log_event "ERROR: Unable to check connected users. Fallback to 'ps' estimate. Total: $user_count"
    fi
}

# Function to check suspicious files (security)
check_suspicious_files() {
    echo -e "${YELLOW}Security Check: Suspicious Files:${NC}"
    local home_dir="$HOME"
    local temp_dirs="/tmp /var/tmp"
    
    echo -e "${YELLOW}1. Recently Modified Files in Home Directory (Last 24 Hours):${NC}"
    find "$home_dir" -type f -mtime -1 -ls 2>/dev/null | head -n 10
    local recent_count=$(find "$home_dir" -type f -mtime -1 2>/dev/null | wc -l)
    echo "Total Recently Modified Files: $recent_count"
    log_event "Checked recently modified files in home directory. Total: $recent_count"
    
    echo -e "${YELLOW}2. Hidden Files in Home Directory:${NC}"
    find "$home_dir" -type f -name ".*" -ls 2>/dev/null | head -n 10
    local hidden_count=$(find "$home_dir" -type f -name ".*" 2>/dev/null | wc -l)
    echo "Total Hidden Files: $hidden_count"
    log_event "Checked hidden files in home directory. Total: $hidden_count"
    
    echo -e "${YELLOW}3. Files with Suspicious Permissions (World-Writable, 777):${NC}"
    find "$home_dir" -type f -perm 0777 -ls 2>/dev/null | head -n 5
    local world_writable_count=$(find "$home_dir" -type f -perm 0777 2>/dev/null | wc -l)
    echo "Total World-Writable Files: $world_writable_count"
    if [ "$world_writable_count" -gt 0 ]; then
        log_event "WARNING: Found $world_writable_count world-writable files in home directory."
    else
        log_event "No world-writable files found in home directory."
    fi

    echo -e "${YELLOW}4. Executable Files in Temporary Directories:${NC}"
    for dir in $temp_dirs; do
        if [ -d "$dir" ] && [ -r "$dir" ]; then
            find "$dir" -type f -executable -ls 2>/dev/null | head -n 5
            local exec_count=$(find "$dir" -type f -executable 2>/dev/null | wc -l)
            echo "Total Executable Files in $dir: $exec_count"
            if [ "$exec_count" -gt 0 ]; then
                log_event "WARNING: Found $exec_count executable files in $dir."
            else
                log_event "No executable files found in $dir."
            fi
        else
            echo "Cannot access $dir (permission denied or directory does not exist)"
            log_event "WARNING: Cannot access $dir for executable file check."
        fi
    done
    log_event "Completed suspicious files check."
}

# Function to check suspicious processes (security)
check_suspicious_processes() {
    echo -e "${YELLOW}Security Check: Suspicious Processes:${NC}"
    echo -e "${YELLOW}1. Processes Running as 'root' (if accessible):${NC}"
    ps aux | grep -E '^root' | grep -v 'grep' | head -n 5
    local root_proc_count=$(ps aux | grep -E '^root' | grep -v 'grep' | wc -l)
    echo "Total Processes Running as root: $root_proc_count"
    log_event "Checked processes running as root. Total: $root_proc_count"

    echo -e "${YELLOW}2. Processes with Unusual Names or Paths:${NC}"
    ps aux | grep -E '^[a-z0-9]{8,}' | grep -v 'grep' | head -n 5
    local unusual_proc_count=$(ps aux | grep -E '^[a-z0-9]{8,}' | grep -v 'grep' | wc -l)
    echo "Total Processes with Unusual Names: $unusual_proc_count"
    if [ "$unusual_proc_count" -gt 0 ]; then
        log_event "WARNING: Found $unusual_proc_count processes with unusual names."
    else
        log_event "No processes with unusual names found."
    fi
    log_event "Completed suspicious processes check."
}

# Function to check failed login attempts (security)
check_failed_logins() {
    echo -e "${YELLOW}Security Check: Failed Login Attempts:${NC}"
    local log_files="/var/log/auth.log /var/log/secure"
    local found_log=0
    for log_file in $log_files; do
        if [ -f "$log_file" ] && [ -r "$log_file" ]; then
            found_log=1
            echo -e "${YELLOW}Checking $log_file for failed login attempts:${NC}"
            grep -i "failed" "$log_file" | grep -i "login" | tail -n 10
            local failed_count=$(grep -i "failed" "$log_file" | grep -i "login" | wc -l)
            echo "Total Failed Login Attempts in $log_file: $failed_count"
            if [ "$failed_count" -gt 0 ]; then
                log_event "WARNING: Found $failed_count failed login attempts in $log_file."
            else
                log_event "No failed login attempts found in $log_file."
            fi
        fi
    done
    if [ "$found_log" -eq 0 ]; then
        echo -e "${RED}Error: Cannot access log files (permission denied or files not found). Root privileges may be required.${NC}"
        log_event "ERROR: Cannot access log files for failed login check."
    fi
    log_event "Completed failed login attempts check."
}

# Function to check open ports (security)
check_open_ports() {
    echo -e "${YELLOW}Security Check: Open Ports:${NC}"
    if command -v netstat >/dev/null 2>&1; then
        echo "Using netstat to list open ports:"
        netstat -tulnp 2>/dev/null | grep -E 'LISTEN' | head -n 10
        local open_port_count=$(netstat -tulnp 2>/dev/null | grep -E 'LISTEN' | wc -l)
        echo "Total Open Ports: $open_port_count"
        log_event "Checked open ports using netstat. Total: $open_port_count"
    elif command -v ss >/dev/null 2>&1; then
        echo "Using ss to list open ports:"
        ss -tulnp 2>/dev/null | grep -E 'LISTEN' | head -n 10
        local open_port_count=$(ss -tulnp 2>/dev/null | grep -E 'LISTEN' | wc -l)
        echo "Total Open Ports: $open_port_count"
        log_event "Checked open ports using ss. Total: $open_port_count"
    else
        echo -e "${RED}Error: Neither 'netstat' nor 'ss' is available to check open ports.${NC}"
        log_event "ERROR: Unable to check open ports. Required tools not installed."
    fi
    echo -e "${YELLOW}Note: Check for unexpected services or unknown ports.${NC}"
    log_event "Completed open ports check."
}

# Function to monitor network traffic (security)
check_network_traffic() {
    echo -e "${YELLOW}Security Check: Network Traffic Monitoring:${NC}"
    if command -v iftop >/dev/null 2>&1; then
        echo -e "${GREEN}iftop is available. Launching real-time traffic monitor...${NC}"
        echo -e "${YELLOW}Press 'q' to quit iftop.${NC}"
        log_event "Launching iftop for real-time network traffic monitoring."
        iftop -t -s 10 2>/dev/null
        log_event "Exited iftop network traffic monitoring."
    elif command -v iptraf >/dev/null 2>&1; then
        echo -e "${GREEN}iptraf is available. Launching traffic monitor...${NC}"
        echo -e "${YELLOW}Follow on-screen instructions to navigate and exit iptraf.${NC}"
        log_event "Launching iptraf for network traffic monitoring."
        iptraf
        log_event "Exited iptraf network traffic monitoring."
    else
        echo -e "${RED}Error: Neither 'iftop' nor 'iptraf' is available for real-time traffic monitoring.${NC}"
        echo -e "${YELLOW}Falling back to basic network statistics:${NC}"
        if command -v ip >/dev/null 2>&1; then
            echo "Network Interface Statistics (using 'ip'):"
            ip -s link show | grep -E '^[0-9]+:' -A 2 | grep -E '^[0-9]+:|RX:|TX:'
        elif command -v ifconfig >/dev/null 2>&1; then
            echo "Network Interface Statistics (using 'ifconfig'):"
            ifconfig | grep -E '^[a-zA-Z0-9]+:|RX packets|TX packets'
        else
            echo -e "${RED}Error: No suitable tool found to display network statistics.${NC}"
        fi
        echo -e "${YELLOW}Active Connections (if available):${NC}"
        if command -v netstat >/dev/null 2>&1; then
            netstat -tunap 2>/dev/null | grep -E 'ESTABLISHED|CONNECTED' | head -n 10
            local connection_count=$(netstat -tunap 2>/dev/null | grep -E 'ESTABLISHED|CONNECTED' | wc -l)
            echo "Total Active Connections: $connection_count"
            log_event "Checked active connections using netstat. Total: $connection_count"
        elif command -v ss >/dev/null 2>&1; then
            ss -tunap 2>/dev/null | grep -E 'ESTAB' | head -n 10
            local connection_count=$(ss -tunap 2>/dev/null | grep -E 'ESTAB' | wc -l)
            echo "Total Active Connections: $connection_count"
            log_event "Checked active connections using ss. Total: $connection_count"
        else
            echo -e "${RED}Error: Neither 'netstat' nor 'ss' is available to check active connections.${NC}"
            log_event "ERROR: Unable to check active connections. Required tools not installed."
        fi
        echo -e "${YELLOW}Note: Install 'iftop' or 'iptraf' for real-time traffic monitoring.${NC}"
        log_event "Fallback to basic network statistics due to missing tools."
    fi
    log_event "Completed network traffic monitoring check."
}

# Function to display logo and developer info
show_logo() {
    clear
    if command -v figlet &> /dev/null; then
        echo -e "${CYAN}"
        figlet -f standard "SYSTEM MONITOR"
        echo -e "${NC}"
    else
        echo -e "${CYAN}================================="
        echo -e "      SYSTEM MONITOR"
        echo -e "=================================${NC}"
    fi
    echo -e "${GREEN}=== System Monitoring Tool ===${NC}"
    echo -e "${YELLOW}Developer: Jobran Qubaty${NC}"
    echo -e "${YELLOW}Email: aljabery2013@gmail.com${NC}"
    echo -e "${YELLOW}Organization: Yemen Cyber Security${NC}"
    echo -e "${CYAN}=================================${NC}"
    sleep 2
}

# Function to display the interactive menu
show_menu() {
    clear
    if command -v figlet &> /dev/null; then
        echo -e "${CYAN}"
        figlet -f standard "SYSTEM MONITOR"
        echo -e "${NC}"
    else
        echo -e "${CYAN}================================="
        echo -e "      SYSTEM MONITOR"
        echo -e "=================================${NC}"
    fi
    echo -e "${GREEN}=== System Monitoring Tool ===${NC}"
    echo -e "${YELLOW}Developer: Jobran Qubaty${NC}"
    echo -e "${CYAN}=================================${NC}"
    echo "1. Check CPU Usage"
    echo "2. Check RAM Usage"
    echo "3. Check Service Status (SSH)"
    echo "4. Check Service Status (Apache)"
    echo "5. Check Top Processes"
    echo "6. Show System Info"
    echo "7. Show Hardware Info"
    echo "8. Check Disk Usage"
    echo "9. Check Files and Folders in Home Directory"
    echo "10. Check Network Status"
    echo "11. Check CPU Temperature"
    echo "12. Check Connected Users"
    echo "13. Check Suspicious Files (Security)"
    echo "14. Check Suspicious Processes (Security)"
    echo "15. Check Failed Login Attempts (Security)"
    echo "16. Check Open Ports (Security)"
    echo "17. Check Network Traffic (Security)"
    echo "18. Run Full System Check"
    echo "19. Exit"
    echo "20. Update"
    echo -e "${YELLOW}Enter your choice (1-20):${NC}"
}

# Ensure the log file is created before any writing
if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE" 2>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Cannot create log file at $LOG_FILE. Trying alternative path...${NC}"
        LOG_FILE="/tmp/system_monitor_$(whoami).log"
        touch "$LOG_FILE" 2>/dev/null
        if [ $? -ne 0 ]; then
            echo -e "${RED}Error: Cannot create log file at $LOG_FILE either. Please check permissions or disk space.${NC}"
            exit 1
        fi
    fi
    chmod 640 "$LOG_FILE" 2>/dev/null
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] Log file created." >> "$LOG_FILE"
fi

# Ensure the reports directory is created
if [ ! -d "$REPORTS_DIR" ]; then
    mkdir -p "$REPORTS_DIR" 2>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Cannot create reports directory at $REPORTS_DIR. Check permissions.${NC}"
        REPORTS_DIR="/tmp/reports_$(whoami)"
        mkdir -p "$REPORTS_DIR" 2>/dev/null
        if [ $? -ne 0 ]; then
            echo -e "${RED}Error: Cannot create reports directory at $REPORTS_DIR either. Reports will not be saved.${NC}"
            log_event "ERROR: Cannot create reports directory."
        else
            log_event "Reports directory created at $REPORTS_DIR."
        fi
    else
        log_event "Reports directory created at $REPORTS_DIR."
    fi
fi

# Display the logo at startup
show_logo

# Function to update the script from GitHub
update_script() {
    echo -e "${YELLOW}Checking for updates from GitHub...${NC}"
    local script_url="https://raw.githubusercontent.com/hacky20000/system_monitor/main/system_monitor.sh"
    local temp_script="/tmp/system_monitor_update.sh"

    if ! curl -s "$script_url" -o "$temp_script"; then
        echo -e "${RED}Error: Failed to download the latest version from GitHub.${NC}"
        log_event "ERROR: Failed to update script from GitHub."
        return 1
    fi

    if [ ! -f "$temp_script" ]; then
        echo -e "${RED}Error: Update file not found. Check your internet connection.${NC}"
        log_event "ERROR: Update file not found."
        return 1
    fi

    echo -e "${GREEN}New version downloaded. Replacing current script...${NC}"
    if [ "$0" = "$temp_script" ]; then
        echo -e "${RED}Error: Cannot replace this script because it is being executed. Please run the update from a separate instance.${NC}"
        log_event "ERROR: Update failed - script is being executed."
        return 1
    fi

    if [ -f "$0" ]; then
        if ! mv "$temp_script" "$0"; then
            echo -e "${RED}Error: Failed to replace the script. Check permissions or try running with sudo.${NC}"
            log_event "ERROR: Failed to replace script file."
            return 1
        fi
        echo -e "${GREEN}Update successful! Please restart the script to apply changes.${NC}"
        log_event "Update completed successfully."
    else
        echo -e "${RED}Error: Current script file not found at $0. Update failed.${NC}"
        log_event "ERROR: Script file not found. Update failed."
        return 1
    fi
}

# Main interactive loop
FULL_CHECK_OUTPUT=""
while true; do
    show_menu
    read choice
    case $choice in
        1)
            check_cpu_usage
            ;;
        2)
            check_ram_usage
            ;;
        3)
            check_service_status "ssh"
            ;;
        4)
            check_service_status "apache2"
            ;;
        5)
            check_top_processes
            ;;
        6)
            show_system_info
            ;;
        7)
            show_hardware_info
            ;;
        8)
            check_disk_usage
            ;;
        9)
            check_files_folders
            ;;
        10)
            check_network_status
            ;;
        11)
            check_cpu_temperature
            ;;
        12)
            check_connected_users
            ;;
        13)
            check_suspicious_files
            ;;
        14)
            check_suspicious_processes
            ;;
        15)
            check_failed_logins
            ;;
        16)
            check_open_ports
            ;;
        17)
            check_network_traffic
            ;;
        18)
            echo -e "${YELLOW}Running Full System Check...${NC}"
            FULL_CHECK_OUTPUT=$( {
                echo "Full System Check Results"
                echo "========================="
                echo ""
                echo "1. CPU Usage Check"
                check_cpu_usage
                echo ""
                echo "2. RAM Usage Check"
                check_ram_usage
                echo ""
                echo "3. Service Status (SSH)"
                check_service_status "ssh"
                echo ""
                echo "4. Service Status (Apache)"
                check_service_status "apache2"
                echo ""
                echo "5. Top Processes"
                check_top_processes
                echo ""
                echo "6. System Information"
                show_system_info
                echo ""
                echo "7. Hardware Information"
                show_hardware_info
                echo ""
                echo "8. Disk Usage"
                check_disk_usage
                echo ""
                echo "9. Files and Folders"
                check_files_folders
                echo ""
                echo "10. Network Status"
                check_network_status
                echo ""
                echo "11. CPU Temperature"
                check_cpu_temperature
                echo ""
                echo "12. Connected Users"
                check_connected_users
                echo ""
                echo "13. Suspicious Files (Security)"
                check_suspicious_files
                echo ""
                echo "14. Suspicious Processes (Security)"
                check_suspicious_processes
                echo ""
                echo "15. Failed Login Attempts (Security)"
                check_failed_logins
                echo ""
                echo "16. Open Ports (Security)"
                check_open_ports
                echo ""
                echo "17. Network Traffic (Security)"
                check_network_traffic
                echo ""
                echo "========================="
                echo "End of Full System Check"
            } )
            echo "$FULL_CHECK_OUTPUT"
            if [ -d "$REPORTS_DIR" ]; then
                create_report
            else
                echo -e "${RED}Error: Reports directory not available. Report will not be saved.${NC}"
                log_event "ERROR: Reports directory not available. Report not saved."
            fi
            ;;
        19)
            echo -e "${GREEN}Exiting...${NC}"
            log_event "Script terminated by user."
            exit 0
            ;;
        20)
            update_script
            ;;
        *)
            echo -e "${RED}Invalid choice! Please select a number between 1 and 20.${NC}"
            ;;
    esac
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read
done
