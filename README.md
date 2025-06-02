# System-Monitor
Linux System Monitoring Tool
A powerful bash script for monitoring Linux systems with security checks and resource monitoring.

## 📥 Installation

### Method 1: Direct Download
```bash
wget https://github.com/hacky20000/system-monitor/raw/main/system_monitor.sh
chmod +x system_monitor.sh
sudo ./system_monitor.sh
```

### Method 2: Clone Repository
```bash
git clone https://github.com/hacky20000/system-monitor.git
cd system-monitor
chmod +x system_monitor.sh
bash system_monitor.sh
```

## 🛠️ Requirements
- Bash 4.0+
- Linux system
- Basic tools: `top`, `free`, `df`

## 🚀 Quick Start
```bash
sudo ./system_monitor.sh
```
## ✨ Features
- CPU/RAM/Disk monitoring
- Service status checks
- Security scans
- Network analysis
- Hardware info
- User management

## 📷 Screenshot
![Main Menu Preview](screenshot.png)

## 📜 License
MIT

## 👨💻 Author
Jobran Qubaty
GitHub: [@hacky20000](https://github.com/hacky20000)
```

Key improvements:
1. Removed unnecessary sections
2. Simplified installation to 2 clear methods
3. Added emoji headers for better visual scanning
4. Kept only essential information
5. Made requirements more specific
6. Simplified feature list
7. Left placeholder for one screenshot
8. Clean author/license section


Here's a professional list of tools/dependencies for your System Monitor tool in English, formatted for your **README.md**:

---

### 🛠️ Tools & Dependencies

#### **Core Tools (Pre-installed on most Linux systems)**
| Tool | Purpose | Check Installation |
|------|---------|--------------------|
| `top` | CPU/Process monitoring | `command -v top` |
| `free` | RAM usage monitoring | `command -v free` |
| `df` | Disk space monitoring | `command -v df` |
| `ps` | Process management | `command -v ps` |
| `grep` | Output filtering | `command -v grep` |
| `awk` | Text processing | `command -v awk` |

#### **Recommended Additional Tools**
| Tool | Purpose | Install Command |
|------|---------|-----------------|
| `lm-sensors` | CPU temperature monitoring | `sudo apt install lm-sensors` |
| `iftop` | Real-time network monitoring | `sudo apt install iftop` |
| `figlet` | Fancy banner display | `sudo apt install figlet` |
| `dmidecode` | Hardware information (requires root) | `sudo apt install dmidecode` |

#### **Security Tools**
| Tool | Purpose |
|------|---------|
| `netstat`/`ss` | Open port checking |
| System log files | Failed login attempts |

---

### 🔧 Verification Command
Check if all core tools are installed:
```bash
for tool in top free df ps grep awk; do
    command -v $tool || echo "❌ $tool not found!"
done
```

### 📌 Notes:
1. **Pre-installed** on:
   - Ubuntu/Debian
   - CentOS/RHEL
   - Fedora

2. **Installation on other systems**:
   ```bash
   # Debian/Ubuntu
   sudo apt install lm-sensors iftop figlet dmidecode

   # RHEL/CentOS
   sudo yum install lm_sensors iftop figlet dmidecode

   # Fedora
   sudo dnf install lm_sensors iftop figlet dmidecode
   ```

3. **Minimum Requirements**:
   - Bash 4.0+
   - Linux kernel 3.2+
   - 100MB free disk space

4. **Recommended**:
   - Root access (for full functionality)
   - 512MB+ RAM
