# Pedagogical AI Autopilot Setup (One-Time)

## Ziel

Nach dieser einmaligen Einrichtung laeuft der KI-Qualitaetscheck taeglich automatisch.
Kein taegliches manuelles Tun erforderlich.

## Bereits umgesetzt im Repo

1. Taegliches Pruefskript:
- scripts/pedagogical_ai_daily_check.sh

2. Geplanter GitHub Workflow:
- .github/workflows/pedagogical-ai-daily-check.yml
- Laeuft taeglich per Schedule + manuell per workflow_dispatch.

## Einmalige Einrichtung in GitHub

1. Repository Settings -> Secrets and variables -> Actions
2. Neues Secret anlegen:
- Name: GEMINI_API_KEY
- Value: dein echter API key

3. Optionales Secret (wenn gewuenscht):
- Name: GEMINI_MODEL
- Value: z. B. gemini-3.5-flash

Hinweis:
- Wenn GEMINI_MODEL fehlt, nutzt das Skript sinnvolle Fallback-Modelle.

## Betrieb danach

- Workflow laeuft taeglich automatisch.
- Bei Fehler wird der Workflow rot (FAIL).
- Bei Erfolg ist der Workflow gruen (PASS).

## Was du nicht mehr taeglich machen musst

- keine manuelle Prompt-Suite starten,
- keine manuelle Go/No-Go Bewertung,
- keine taegliche KI-Sichtpruefung.

## Optional (empfohlen)

- GitHub Notification fuer failed workflows aktivieren,
  damit du nur im Fehlerfall informiert wirst.
