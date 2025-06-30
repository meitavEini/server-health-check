#!/bin/bash

if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Running on macOS"
else
    echo "Running on Linux"
fi

# פונקציה לצבעים
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
reset=$(tput sgr0)

echo "----------------------------------------"
echo "        🖥️ SERVER HEALTH REPORT        "
echo "----------------------------------------"

# CPU usage
idle=$(top -l 1 | grep "CPU usage" | awk -F'idle' '{print $1}' | awk -F',' '{print $NF}' | tr -d ' %')
cpu_usage=$(echo "scale=2; 100 - $idle" | bc)

# Memory usage
mem_line=$(top -l 1 | grep PhysMem)
used=$(echo $mem_line | awk '{print $2}' | sed 's/G//')
unused=$(echo $mem_line | awk '{print $6}' | sed 's/G//')
total=$(echo "$used + $unused" | bc)
mem_usage=$(echo "scale=2; $used / $total * 100" | bc)

# Disk usage
disk_usage=$(df / | tail -1 | awk '{print $5}' | tr -d '%')

# Top CPU process
top_cpu_process=$(ps -A -o %cpu,comm | sort -nr | awk 'NR==2 {print $2 " (" $1 "%)"}')

# Top memory process
top_mem_process=$(ps -A -o %mem,comm | sort -nr | awk 'NR==2 {print $2 " (" $1 "%)"}')

# CPU status
if (( $(echo "$cpu_usage > 85" | bc -l) )); then
  cpu_status="${red}⚠️ HIGH${reset}"
else
  cpu_status="${green}✅ OK${reset}"
fi

# Memory status
if (( $(echo "$mem_usage > 85" | bc -l) )); then
  mem_status="${red}⚠️ HIGH${reset}"
else
  mem_status="${green}✅ OK${reset}"
fi

# Disk status
if [ "$disk_usage" -gt 85 ]; then
  disk_status="${red}⚠️ HIGH${reset}"
else
  disk_status="${green}✅ OK${reset}"
fi

echo "CPU Usage:    $cpu_usage% $cpu_status"
echo "Memory Usage: $mem_usage% $mem_status"
echo "Disk Usage:   $disk_usage% $disk_status"
echo "Top CPU Process: $top_cpu_process"
echo "Top Mem Process: $top_mem_process"
echo "----------------------------------------"

# Recommendation
echo "Recommendation:"

# מחשבים תנאים מראש
cpu_ok=$(echo "$cpu_usage <= 85" | bc)
mem_ok=$(echo "$mem_usage <= 85" | bc)
if [ "$disk_usage" -le 85 ]; then
  disk_ok=1
else
  disk_ok=0
fi

if (( $(echo "$cpu_usage > 85" | bc -l) )); then
  echo "- Consider stopping heavy CPU processes or checking background jobs."
fi

if (( $(echo "$mem_usage > 85" | bc -l) )); then
  echo "- Consider closing apps or upgrading RAM."
fi

if [ "$disk_usage" -gt 85 ]; then
  echo "- Consider cleaning logs or freeing up disk space."
fi

if [ "$cpu_ok" -eq 1 ] && [ "$mem_ok" -eq 1 ] && [ "$disk_ok" -eq 1 ]; then
  echo "- System status looks good! ✅"
fi

echo "----------------------------------------"
