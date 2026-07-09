# Parentpeak Pedagogical AI Target Architecture

## 1. Zielbild

Eine sichere, alltagstaugliche Elternberatung, die:
- schnelle und hilfreiche Antworten liefert,
- bei Risiko-Themen klar begrenzt und an menschliche Hilfe verweist,
- datensparsam arbeitet,
- in Kosten und Qualität kontrollierbar bleibt.

Empfohlener Ansatz:
- Foundation-Model per API als Inference-Engine,
- eigene Parentpeak-Steuerung fuer Safety, Prompting, Inhalte und QA.

## 1.1 Verbindliche Fachprinzipien

Diese Prinzipien gelten fuer jede Antwort als verbindlich:
- Gewaltfreie Kommunikation (GFK) ist die Hauptmethode.
- kinderrechtsorientiert.
- gleichwuerdig.
- wissenschaftsbasiert.
- diskriminierungssensibel.
- bindungsorientiert.
- Das Kind ist eine eigenstaendige Person.
- Keine Gewalt, keine Beschaemung, keine Drohungen.
- Eltern werden nicht verurteilt.
- Antworten entlasten, aber bagatellisieren nicht.
- Bei Gefaehrdung wird klar an menschliche Hilfe verwiesen.

## 2. Architekturuebersicht (4 Schichten)

### A) Safety & Policy Layer (vor dem Modell)
Verantwortung:
- Krisen- und Gewalt-Intent frueh erkennen,
- medizinische/diagnostische Grenzen durchsetzen,
- Off-Topic sauber zurueckfuehren,
- Notfall-Hinweise ausgeben.

Bestand heute:
- `PedagogicalChatBackend` mit Keyword-Gates.

Ausbau:
- regelbasierte Gates + leichter Klassifikator (spater),
- versionierte Policies (z. B. policyVersion),
- definierte Escalation-Pfade je Risiko-Stufe.

### B) Prompt & Orchestration Layer
Verantwortung:
- konsistente Persona/Tonalitaet,
- strukturierte Antwortform (z. B. Kurzdiagnose vermeiden, 3 konkrete Schritte),
- Kontextaufbereitung (Kindesalter, Situation, Ziel).

Empfehlung:
- Prompt-Templates nach Thema:
  - Trotzphase,
  - Schlaf,
  - Konflikte,
  - Medien,
  - Schule/Kita.
- Guardrails auch nach Modellantwort (Post-Check).

### C) Knowledge Layer (RAG)
Verantwortung:
- kuratierte, paedagogisch validierte Inhalte einbinden,
- Halluzinationen reduzieren,
- nachvollziehbare Quellenhinweise liefern.

Empfehlung:
- kleine kuratierte Wissensbasis starten (FAQ, Leitfaden, Krisenplan),
- Embeddings + Retrieval pro Anfrage,
- Antwort mit "Was du jetzt tun kannst" + "Wann du Hilfe holen solltest".

### D) Observability & Cost Layer
Verantwortung:
- Qualitaet und Sicherheit messen,
- Kosten pro Nutzer/Tag steuern,
- Fehlerraten und Fallbacks sichtbar machen.

Kernmetriken:
- successRate,
- providerErrorRate,
- safetyInterventionRate,
- escalationRate,
- averageTokensPerTurn,
- costPerActiveUser.

## 3. Request-Flow (Soll)

1. Nutzer schreibt Nachricht.
2. Pre-Safety-Check (Crisis/Violence/Medical/Diagnosis/Off-Topic).
3. Falls kritisch: sofort sichere Antwort + Eskalationshinweis.
4. Sonst: Kontextaufbereitung + Prompt-Template + RAG-Snippets.
5. Modellaufruf via API.
6. Post-Safety-Check auf Modellantwort.
7. Antwort ausgeben, Events anonymisiert loggen.

## 4. Datenschutz und Compliance (MVP+)

- Keine Rohtexte dauerhaft speichern, wenn nicht zwingend noetig.
- Pseudonymisierte Event-Logs statt Klartext.
- PII-Minimierung in Prompt-Context.
- Retention-Regeln:
  - Operational Logs kurz,
  - Analytics aggregiert,
  - Nutzerexport/Loeschung unterstuetzen.
- Transparente Hinweise in UI:
  - KI ersetzt keine professionelle Beratung,
  - Notfallnummern bei Krise.

## 5. Betriebsmodell API vs. Eigenes Modell

Kurzfristig (empfohlen):
- API-Modell nutzen,
- Parentpeak-Layer kontrolliert Verhalten.

Mittelfristig:
- Modellvergleich (A/B) zwischen 2 API-Modellen,
- ggf. domain-spezifisches Fine-Tuning nur fuer Stil/Format.

Langfristig:
- eigenes Modell nur wenn:
  - sehr hoher Traffic,
  - stabile proprietaere Datengrundlage,
  - eigenes MLOps-Team fuer Safety, Eval, Red-Teaming vorhanden.

## 6. Konkreter 30-60-90 Plan

### 30 Tage
- Prompt-Templates je Kernthema einbauen.
- Safety-Policy versionieren.
- Basis-Metriken und Error-Codes instrumentieren.
- Krisenantworten lokalisiert und getestet.

### 60 Tage
- RAG-MVP mit kuratierter Wissensbasis live.
- Post-Response Safety-Check erweitern.
- Kostenbudget pro Nutzer und harte Limits aktivieren.

### 90 Tage
- Evaluation-Suite mit Gold-Set (paedagogische Testfaelle).
- Human-in-the-loop Review fuer kritische Kategorien.
- Modellvergleich mit qualitaets- und kostenbasiertem Routing.

## 7. Technische Schnittstellen (Parentpeak)

Empfohlene Bausteine:
- `lib/logic/pedagogical_chat_backend.dart`
  - Orchestration, Safety-Gates, Provider-Auswahl.
- `lib/logic/gemini_ai_service.dart`
  - Modell-Adapter.
- neues Backend-Endpoint (optional) fuer serverseitige AI-Orchestrierung:
  - zentrales Secret-Handling,
  - RAG-Retrieval,
  - Rate-Limits,
  - Audit-Events.

## 8. Akzeptanzkriterien fuer "Production Ready"

- Keine gewaltfoerdernden oder medizinisch-riskanten Antworten in Test-Suite.
- Krisenprompts liefern innerhalb von 1 Antwort den richtigen Eskalationspfad.
- Mindestens 95 Prozent erfolgreiche Antworten ohne Provider-Fehler.
- Kosten pro aktivem Nutzer innerhalb festgelegtem Budget.
- Klare UX fuer Nichtverfuegbarkeit ohne Fake-Antworten.

## 9. Entscheidungsempfehlung

Go mit:
- API-Key + eigene Parentpeak-Paedagogik-Architektur.

No-Go fuer jetzt:
- komplett eigenes Modelltraining als erster Schritt.

Damit erreicht ihr die beste Balance aus Time-to-Market, Sicherheit, Qualitaet und Kostenkontrolle.
