# Roadmap

**Letzte Aktualisierung:** 13. August 2026
**Status-Legende:** -- geplant | -- in Arbeit | -- erledigt | -- verschoben

---

## Phase 1: Fundament (MVP)

**Ziel:** Erster lauffaehiger End-to-End-Flow: Event anlegen, Teilnehmer registrieren, Armband scannen, Punkte buchen, Praemie einloesen.

### Backend
- [x] Node.js/Express Projektstruktur + TypeORM + PostgreSQL
- [x] Docker Compose Setup (PostgreSQL, Redis, MinIO, App)
- [x] Auth-System: PIN + Geraetebindung + JWT-Tokens
- [x] Event CRUD API (erstellen, konfigurieren, archivieren)
- [x] Teilnehmer-Verwaltung API (registrieren, zuweisen, suchen)
- [x] Punkte-Buchung API (Einzel + Batch, Gruende, Schnellwahl)
- [x] Praemien-Katalog API (CRUD, Einloesung, Limits)
- [x] Transaktions-Logging (append-only, signiert)
- [x] Socket.IO Grundstruktur (Live-Punktestand)
- [x] Redis Caching (Sessions, haeufige Abfragen)
- [x] BullMQ Setup (E-Mail-Queue, Cleanup-Jobs)
- [x] Winston Logging + Fehlerbehandlung
- [x] Health-Check Endpoints (/health, /ready)
- [x] Seed-Daten fuer Demo-Event

### Flutter App (Android + iOS)
- [x] Projektstruktur + State-Management
- [x] NFC-Scan: Tag lesen, ID + Token validieren
- [x] NFC-Schreiben: Server-Token + Notfalldaten auf Tag
- [ ] QR-Code Scanner als Alternative
- [x] Login-Screen (PIN + Geraetebindung)
- [x] Scan-Screen: Band antippen, Profil anzeigen
- [x] Punkte-Buchung: Schnellwahl + manuell + Grund
- [x] Praemien-Ansicht + Einloesung
- [x] Offline-Queue: Buchungen zwischenspeichern + Retry
- [ ] Push-Benachrichtigungen (Firebase)

### Web-Dashboard (Next.js)
- [x] Projektstruktur + Auth-Integration
- [x] Admin-Login
- [x] Event-Erstellung (Wizard, Grundeinstellungen)
- [x] Teilnehmer-Liste + Registrierung
- [x] Punkte-Uebersicht + manuelle Buchung
- [x] Praemien-Verwaltung

### DevOps
- [x] GitHub Actions CI Pipeline (Lint, Test, Build)
- [ ] Docker Build + Push to Registry
- [ ] Deployment auf eigenem Server
- [ ] Prometheus + Grafana Monitoring
- [ ] Uptime Kuma Health-Monitoring
- [ ] pg_dump Backup-Cronjob

---

## Phase 2: Gamification & Engagement

**Ziel:** Das Punktesammeln wird zum Erlebnis. Teilnehmer oeffnen die App freiwillig.

### Gamification-Kern
- [ ] Level-/Rang-System (Admin-konfigurierbar)
- [ ] Badge-System (System + Admin-erstellte, dynamische Seltenheit)
- [ ] Badge-Showcase + Sammlung + Titel auf Profil
- [ ] Leaderboard: Einzel + Team (konfigurierbare Updates/Zeitraeume)
- [ ] Team-Score Berechnung (Summe/Durchschnitt, konfigurierbar)
- [ ] Animierter Scan-Splash (Avatar, Level, Effekte)
- [ ] Evolving Avatar System (entwickelt sich mit Level)
- [ ] Sound-/Vibrations-Feedback (abschaltbar)

### Punkte-Erweiterung
- [ ] Konfigurierbare Punkt-Typen/Waehrungen
- [ ] Punkte-Multiplikatoren (Admin-definiert: Zeit, Aktivitaet, Level)
- [ ] P2P-Transfer ueber die App (konfigurierbare Limits)
- [ ] Separates Strafsystem (Karten + Strafpunkte + Ampel, kombinierbar)
- [ ] Straf-Schwellen mit konfigurierbaren Konsequenzen
- [ ] Straf-Abbau (manuell, zeitbasiert, Aufgaben)
- [ ] Punkte-Verfall (konfigurierbar pro Event)

### Teilnehmer-Erlebnis
- [ ] Teilnehmer-App: Self-Service (Punktestand, Verlauf, Badges)
- [ ] Praemien-Shop (konfigurierbar pro Event)
- [ ] QR-Code am Band fuer Punktestand-Webseite
- [ ] Push-Benachrichtigungen (Punkte erhalten, Level-Up, neue Praemien)

---

## Phase 3: Event-Management & Kommunikation

**Ziel:** Aus der Punkte-App wird eine vollstaendige Event-Plattform.

### Event-Verwaltung
- [ ] Event-Templates (vorgefertigt + Community)
- [ ] Event-Wizard (Schritt-fuer-Schritt Erstellung)
- [ ] Event-Klon + als Vorlage speichern
- [ ] Event Import/Export (Konfiguration als Datei)
- [ ] Mehrtaegige Events (Tagesabschluss, Unterkunftsverwaltung, Nachtruhe)
- [ ] Wiederkehrende Events / Saison-System
- [ ] Schnell-Event Modus (2-Minuten Setup + Quick-Join)
- [ ] Check-in/Check-out (konfigurierbar pro Event)

### Zeitplan & Programm
- [ ] Frei gestaltbarer Zeitplan
- [ ] Aktivitaets-Anmeldung (FCFS / Losverfahren pro Aktivitaet)
- [ ] Erinnerungen (konfigurierbar)
- [ ] Kalender-Sync (iCal + Live-Sync + Eltern-Kalender)

### Karte & Standort
- [ ] Interaktive Karte (Custom-Bild + OpenStreetMap)
- [ ] Live-Status (offen/geschlossen, Wartezeit, Teilnehmer-Dichte)
- [ ] Geofencing (Check-in, Punkte-Validierung, Sicherheitszonen)
- [ ] Offline-Karte (Bild gecached, Live-Daten online)

### Chat & Kommunikation
- [ ] Chat-System (Gruppen, Event-weit, DM, Betreuer-intern)
- [ ] Chat-Moderation (konfigurierbar: Filter, Freigabe, Melden)
- [ ] Medien im Chat (konfigurierbar)
- [ ] Broadcasts (Push + Chat + Prioritaeten + Zielgruppen)

### Fotos & Feedback
- [ ] Fotogalerie (Alben, Tags, konfigurierbare Uploads)
- [ ] Feedback-System (Admin-konfigurierbarer Fragebogen)

### Terminal/Kiosk
- [ ] Terminal-Modus: Auto-Punkte / Betreuer-Bestaetigung / Quiz
- [ ] Station-Konfiguration (Wiederholung, Cooldown, Schwierigkeit)
- [ ] Versteckte + zeitbegrenzte Stationen
- [ ] Idle-Screen (konfigurierbar)

---

## Phase 4: Eltern, Sicherheit & Analytics

**Ziel:** Vertrauen schaffen. Eltern einbinden, Sicherheit gewaehrleisten, Daten nutzen.

### Eltern-Portal
- [ ] Eltern-Auth (Magic Link, Code, eigener Account)
- [ ] Live-Einblick (konfigurierbare Inhalte pro Event)
- [ ] Eltern-Kommunikation (DM an Betreuer, Kontaktformular)
- [ ] Eltern-Benachrichtigungen (waehlbar aus Admin-Vorgaben)

### Notfall & Sicherheit
- [ ] Notfallmodul (Alarm + Anwesenheit + Treffpunkte + Protokoll)
- [ ] Konfigurierbare Alarm-Stufen
- [ ] Notfalldaten-Zugriff (Scan + PIN + offline vom Tag)
- [ ] Medikamenten-Tracking (Erinnerung + Dokumentation + Eltern-Info)

### DSGVO & Datenschutz
- [ ] Einwilligungs-Management (digital, Checkbox, PDF)
- [ ] Loeschantrags-System (30-Tage-Frist)
- [ ] Automatische DSE-Generierung (basierend auf genutzten Features)
- [ ] EU-Serverstandort Dokumentation

### Analytics & Dashboards
- [ ] Drag-and-Drop Admin-Dashboard (Widgets)
- [ ] Rollen-spezifische Dashboard-Ansichten (konfigurierbar)
- [ ] Vorschau-Modus (Admin sieht App aus jeder Rolle + Testdaten)
- [ ] Auto-Berichte (Tages-, Event-, benutzerdefiniert)
- [ ] Event-Vergleich + Plattform-Benchmark
- [ ] Live-Feed (Admin-Detail + Teilnehmer-Highlights)
- [ ] Export: CSV, PDF, Excel, API, Event-Config

---

## Phase 5: Plattform & Erweiterung

**Ziel:** Oekosystem aufbauen. Dritte koennen anbinden und erweitern.

### Plugin-System
- [ ] Plugin-Architektur (Hooks ueberall: UI, Backend, Spiele, Berichte)
- [ ] Plugin-Marketplace mit Bewertungen
- [ ] Gestufte Sicherheit (offiziell = voll, Community = sandboxed)
- [ ] Plugin-Dokumentation + SDK

### Automatisierung
- [ ] Automation-Engine (Trigger -> Bedingung -> Aktion + Zeitsteuerung)
- [ ] Authentifizierte API fuer Dritte (API-Key/Token)

### Integrationen
- [ ] Messenger: Slack, Discord, WhatsApp (Benachrichtigungen + Kommandos)
- [ ] Payment: Stripe + PayPal + Rechnung
- [ ] Kalender: Google Calendar + Outlook
- [ ] Anmelde-Systeme: API-Schnittstelle
- [ ] Wetter: Daten + Empfehlungen + Unwetter-Warnung + Plananpassung
- [ ] Social Media: Teilen + Feed

### Display
- [ ] Live-Display TV-Modus (konfigurierbare Slide-Rotation)
- [ ] Passiv-Display + interaktives Touch-Terminal Modi
- [ ] Feier-Effekte (App + Display + Sound bei Level-Up)
- [ ] Notfall-Kanal auf Display

---

## Phase 6: Gamification Deluxe

**Ziel:** Aus dem Punktesystem wird ein vollstaendiges Spiel-Universum.

### Minispiele
- [ ] Quiz-Builder (Admin erstellt frei, alle Fragetypen)
- [ ] Schnitzeljagd (QR + NFC + GPS kombinierbar)
- [ ] AR-Features (Schnitzeljagd + Info-Overlay + Kreaturen sammeln)
- [ ] Multiplayer (Live-Duell, Team, asynchroner Highscore)
- [ ] Game-Builder (Vorlagen + visueller Editor)

### Erweiterte Mechaniken
- [ ] Sammelkarten + Stickeralbum + Album-Bonus
- [ ] Boss-Challenges (Camp + Team + Tagesboss)
- [ ] Mini-Wirtschaft (Marktplatz, dynamische Preise, Auktionen)
- [ ] Gilden mit Gilden-Quests
- [ ] Turnier-System (Bracket + Liga)
- [ ] Spezial-Events (Happy Hour, Countdown, Ueberraschung)
- [ ] UGC (Teilnehmer schlagen Challenges, Quiz, Geschichten vor)

### Praemien Deluxe
- [ ] Bundle-Praemien + Mystery-Boxen (konfigurierbar)
- [ ] Praemien-Reservierung + Warteliste
- [ ] Digitale Praemien (Privilegien + In-App-Items)
- [ ] Praemien-Kategorien (Admin-erstellbar)

---

## Phase 7: Enterprise & Skalierung

**Ziel:** Bereit fuer grosse Organisationen und internationale Nutzung.

### Organisation
- [ ] Multi-Org mit konfigurierbarer Hierarchie
- [ ] Cross-Org Profil (optional, eigene Punkte pro Event)
- [ ] Org-Dashboard + Trends + Benchmark
- [ ] Template-Sharing (intern + oeffentliche Bibliothek)
- [ ] Teilnehmer-Historie + Treue-Programm

### Event-Vielfalt
- [ ] Virtuelle/Hybride Events
- [ ] Event-Templates (maximal breit + Community)
- [ ] Schnell-Event + Quick-Join

### Betreuer-Features
- [ ] Betreuer-Gamification (Punkte, Badges, Leaderboard)
- [ ] Automatische Schichtplanung
- [ ] Teilnehmer-Notizen + Uebergabe-Funktion
- [ ] Schulung: Tutorial + Videos + Pruefung

### Urkunden & Rueckblick
- [ ] Urkunden-Generator (Editor + Druck + Digital + QR)
- [ ] Jahresrueckblick (Spotify-Wrapped-Stil)
- [ ] Migrations-Assistent (Feld-Mapping, Vorschau)

---

## Phase 8: Vollausbau

**Ziel:** Das komplette Oekosystem steht.

### Technologie
- [ ] KI: Analyse + Empfehlungen + Content-Generierung
- [ ] IoT-Anbindung (Wetter, Tuerschloesser, Sensoren)
- [ ] Smartwatch-App (Betreuer) + Fitness-Tracker (Teilnehmer)
- [ ] Raspberry Pi Komplett-Kit (Anleitung + Image + 3D-Gehaeuse)

### Spezial-Module
- [ ] Verpflegungsmodul (Menuplan + Allergiefilter + Voting)
- [ ] Packliste (Admin-erstellbar + Erinnerungen)
- [ ] Transport-Management (Fahrgemeinschaften + Live-Bus-Tracking)
- [ ] Inventar + Ausleihe-System

### Geschaeft & Community
- [ ] Feature-basiertes Abrechnungssystem
- [ ] In-App-Payments (konfigurierbar)
- [ ] White-Label Modus
- [ ] Internationalisierung (i18n)
- [ ] Source-Available Lizenzierung
- [ ] Onboarding: Demo-Event + Wizard + Docs/FAQ
- [ ] Altersgruppen-Anpassung + Inklusions-Features
- [ ] Einfache Sprache (konfigurierbar)
- [ ] Barrierefreiheit (WCAG nachruesten)
- [ ] CSS/Theme-Editor + Event-Themes
- [ ] Branding pro Event (frei gestaltbar)

---

## Meilenstein-Uebersicht

| Phase | Kernlieferung | Abhaengigkeiten |
|---|---|---|
| **1 - MVP** | Event -> Scan -> Punkte -> Praemie | - |
| **2 - Gamification** | Levels, Badges, Leaderboard, Avatare | Phase 1 |
| **3 - Event-Mgmt** | Karte, Chat, Zeitplan, Terminals | Phase 1 |
| **4 - Eltern/Sicherheit** | Eltern-Portal, Notfall, Analytics | Phase 2+3 |
| **5 - Plattform** | Plugins, API, Integrationen, Display | Phase 3+4 |
| **6 - Deluxe Games** | AR, Bosse, Wirtschaft, Gilden, Turniere | Phase 2+5 |
| **7 - Enterprise** | Multi-Org, Historie, Betreuer-Tools | Phase 4+5 |
| **8 - Vollausbau** | KI, IoT, Wearables, Module, White-Label | Phase 5+6+7 |

Phase 2 und 3 koennen parallel entwickelt werden. Ab Phase 4 baut alles aufeinander auf.
