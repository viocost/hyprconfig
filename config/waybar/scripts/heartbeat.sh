#!/bin/bash

threshold_mid=150
threshold_hi=500

ping_result_ms=$(
  ping -w 1 -c 1 8.8.8.8 2>/dev/null |
    sed -nE 's/.*time=([0-9.]+) ms.*/\1/p'
)

if [ -n "$ping_result_ms" ]; then
  css_class="green"

  if awk "BEGIN {exit !($ping_result_ms > $threshold_hi)}"; then
    css_class="red"
  elif awk "BEGIN {exit !($ping_result_ms > $threshold_mid)}"; then
    css_class="yellow"
  fi

  text=" ${ping_result_ms} ms"
  tooltip="Heartbeat to 8.8.8.8: ${ping_result_ms} ms"
else
  css_class="timeout"
  text="󰋔 T/o"
  tooltip="Heartbeat to 8.8.8.8: timeout"
fi

printf '{"text":"%s", "tooltip":"%s","class":"%s"}\n' "$text" "$tooltip" "$css_class"
