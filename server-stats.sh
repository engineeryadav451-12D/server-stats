#!/bin/bash

# ─────────────────────────────────────────────
#  server-stats.sh — Git Bash Compatible
# ─────────────────────────────────────────────

print_section() {
  echo ""
  echo "========================================"
  echo "  $1"
  echo "========================================"
}

# ── Header ────────────────────────────────────
echo ""
echo "########################################"
echo "#       SERVER PERFORMANCE STATS       #"
echo "########################################"
echo "  Generated : $(date '+%Y-%m-%d %H:%M:%S')"

# ── System Info ───────────────────────────────
print_section "SYSTEM INFORMATION"
echo "Hostname   : $(hostname)"
echo "OS         : $(systeminfo 2>/dev/null | grep 'OS Name' | sed 's/OS Name://;s/^[ \t]*//' || echo 'Windows/Git Bash')"
echo "Kernel     : $(uname -r 2>/dev/null || uname -s)"

# ── CPU Usage ─────────────────────────────────
print_section "CPU USAGE"
CPU_USED=$(wmic cpu get loadpercentage 2>/dev/null | grep -E '^[0-9]+' | tr -d '[:space:]')
if [ -n "$CPU_USED" ]; then
  CPU_IDLE=$((100 - CPU_USED))
  echo "CPU Used   : ${CPU_USED}%"
  echo "CPU Idle   : ${CPU_IDLE}%"
else
  echo "CPU Used   : N/A"
fi

# ── Memory Usage ──────────────────────────────
print_section "MEMORY USAGE"
MEM_TOTAL_KB=$(wmic computersystem get TotalPhysicalMemory 2>/dev/null | grep -E '^[0-9]+' | tr -d '[:space:]')
MEM_FREE_KB=$(wmic OS get FreePhysicalMemory 2>/dev/null | grep -E '^[0-9]+' | tr -d '[:space:]')

if [ -n "$MEM_TOTAL_KB" ] && [ -n "$MEM_FREE_KB" ]; then
  MEM_TOTAL_MB=$((MEM_TOTAL_KB / 1024 / 1024))
  MEM_FREE_MB=$((MEM_FREE_KB / 1024))
  MEM_USED_MB=$((MEM_TOTAL_MB - MEM_FREE_MB))
  MEM_PCT=$(awk "BEGIN {printf \"%.1f\", ($MEM_USED_MB/$MEM_TOTAL_MB)*100}")
  echo "Total      : ${MEM_TOTAL_MB} MB"
  echo "Used       : ${MEM_USED_MB} MB  (${MEM_PCT}%)"
  echo "Free       : ${MEM_FREE_MB} MB"
else
  echo "Memory info unavailable"
fi

# ── Disk Usage ────────────────────────────────
print_section "DISK USAGE"
echo "[Drive Summary]"
printf "%-10s %-12s %-12s %-12s %-6s\n" "Drive" "Total" "Used" "Free" "Use%"
echo "------------------------------------------------------------"
wmic logicaldisk get Caption,Size,FreeSpace 2>/dev/null | grep -E '^[A-Z]:' | while read -r line; do
  DRIVE=$(echo "$line" | awk '{print $1}')
  FREE=$(echo "$line"  | awk '{print $2}')
  TOTAL=$(echo "$line" | awk '{print $3}')
  if [ -n "$TOTAL" ] && [ "$TOTAL" -gt 0 ] 2>/dev/null; then
    USED=$((TOTAL - FREE))
    TOTAL_GB=$(awk "BEGIN {printf \"%.1f\", $TOTAL/1073741824}")
    USED_GB=$(awk "BEGIN {printf \"%.1f\",  $USED/1073741824}")
    FREE_GB=$(awk "BEGIN {printf \"%.1f\",  $FREE/1073741824}")
    PCT=$(awk "BEGIN {printf \"%.1f\", ($USED/$TOTAL)*100}")
    printf "%-10s %-12s %-12s %-12s %-6s\n" \
      "$DRIVE" "${TOTAL_GB}GB" "${USED_GB}GB" "${FREE_GB}GB" "${PCT}%"
  fi
done

# ── Top 5 by CPU ──────────────────────────────
print_section "TOP 5 PROCESSES BY CPU"
printf "%-8s %-12s %s\n" "PID" "MEM(KB)" "COMMAND"
echo "-----------------------------"
tasklist 2>/dev/null | grep -v "^Image\|^===\|^$" | \
  awk '{mem=$5; gsub(/,/,"",mem); print mem, $2, $1}' | \
  sort -rn | head -5 | \
  awk '{printf "%-8s %-12s %s\n", $2, $1, $3}'

# ── Top 5 by Memory ───────────────────────────
print_section "TOP 5 PROCESSES BY MEMORY"
printf "%-8s %-12s %s\n" "PID" "MEM(KB)" "COMMAND"
echo "-----------------------------"
tasklist 2>/dev/null | grep -v "^Image\|^===\|^$" | \
  awk '{mem=$5; gsub(/,/,"",mem); print mem, $2, $1}' | \
  sort -rn | head -5 | \
  awk '{printf "%-8s %-12s %s\n", $2, $1, $3}'

# ── Logged-in Users ───────────────────────────
print_section "LOGGED IN USERS"
whoami

# ── Footer ────────────────────────────────────
echo ""
echo "########################################"
echo "#            END OF REPORT             #"
echo "########################################"
echo ""
