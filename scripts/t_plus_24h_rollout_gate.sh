#!/usr/bin/env bash

set -euo pipefail

read -r -p "Crash-Free Sessions in % (z.B. 99.7): " crash_free
read -r -p "API 5xx in % (z.B. 0.3): " api_5xx
read -r -p "Payment Success in % (z.B. 96.2): " payment_success
read -r -p "Offene Sev-1/Sev-2 Incidents? (yes/no): " open_incidents
read -r -p "Support-Erstantwortzeit in Stunden (z.B. 4): " first_response_hours
read -r -p "Kritischer Security/Datenschutzvorfall offen? (yes/no): " critical_security

go_count=0

echo ""
echo "--- Rollout Gate Ergebnis ---"

# Hard stop rules
hard_stop=0
if awk "BEGIN {exit !($crash_free < 99.0)}"; then
  echo "[STOP] Crash-Free < 99.0%"
  hard_stop=1
fi
if awk "BEGIN {exit !($api_5xx > 2.0)}"; then
  echo "[STOP] API 5xx > 2.0%"
  hard_stop=1
fi
if awk "BEGIN {exit !($payment_success < 90.0)}"; then
  echo "[STOP] Payment Success < 90%"
  hard_stop=1
fi
if [[ "${critical_security,,}" == "yes" ]]; then
  echo "[STOP] Kritischer Security/Datenschutzvorfall offen"
  hard_stop=1
fi

if [[ "$hard_stop" -eq 1 ]]; then
  echo ""
  echo "ENTSCHEIDUNG: STOP"
  echo "Aktion: Rollout pausieren, Ursache fixen, danach Re-Smoke."
  exit 0
fi

# 5-question scorecard
if awk "BEGIN {exit !($crash_free >= 99.5)}"; then ((go_count+=1)); fi
if awk "BEGIN {exit !($api_5xx < 0.5)}"; then ((go_count+=1)); fi
if awk "BEGIN {exit !($payment_success >= 95.0)}"; then ((go_count+=1)); fi
if [[ "${open_incidents,,}" == "no" ]]; then ((go_count+=1)); fi
if awk "BEGIN {exit !($first_response_hours < 12.0)}"; then ((go_count+=1)); fi

echo "Ja-Antworten: $go_count/5"

if [[ "$go_count" -eq 5 ]]; then
  echo "ENTSCHEIDUNG: GO auf 25%"
elif [[ "$go_count" -eq 4 ]]; then
  echo "ENTSCHEIDUNG: HOLD bei 10% (in 12h neu pruefen)"
else
  echo "ENTSCHEIDUNG: STOP (Hotfix priorisieren)"
fi
