#!/usr/bin/env bash

CPU=$(top -l 1 | grep -E '^CPU' | awk '{print $3}')

MEMORY_TOTAL=$(sysctl -a | grep memsize | awk '{print $2}')
PAGE_SIZE=$(sysctl -a | grep 'hw.pagesize:' | awk '{print $2}')
WIRED=$(memory_pressure | grep wired | awk '{print $4}')
FREE_PAGES=$(vm_stat | grep free | awk '{ print $3 }' | sed 's/\.//')
INACTIVE_PAGES=$(vm_stat | grep inactive | awk '{ print $3 }' | sed 's/\.//')
SPECULATIVE_PAGES=$(vm_stat | grep speculative | awk '{ print $3 }' | sed 's/\.//')
FREE=$((($FREE_PAGES+SPECULATIVE_PAGES) * $PAGE_SIZE))
INACTIVE=$(($INACTIVE_PAGES * $PAGE_SIZE))
TOTAL_FREE=$((($FREE+$INACTIVE)))
MEMORY=$((($MEMORY_TOTAL - $TOTAL_FREE) * 100 / $MEMORY_TOTAL))
MEMORY=🐏$(printf "%2d" $MEMORY)

BATTERY=$(system_profiler SPPowerDataType | rg 'State of Charge' | awk '{print $5}' | sed 's/%//')
BATTERY=⚡$(printf "%2d" $BATTERY)

DATE=$(date '+%H:%M')

echo "$CPU - #[fg=blue]$MEMORY% - #[fg=red]️$BATTERY%#[default] - $DATE"
