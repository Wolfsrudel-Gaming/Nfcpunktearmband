# Konzept-Review: NFC-Punktesystem 2.0

**Datum:** 13. August 2026
**Basis:** Ursprungskonzept "NFCPunkteApp" (August 2026, Prototyp-Stand)
**Methode:** 240-Fragen-Review zur Neuausrichtung (80 Grundsatz + 160 Vertiefung)

---

## Zusammenfassung: Vom Offline-Prototyp zur Event-Gamification-Plattform

Das urspruengliche Konzept war ein reines Offline-System: alle Daten auf dem NFC-Tag, kein Server, kein Internet. Die Review zeigt eine fundamentale Neuausrichtung hin zu einer **universellen Event-Gamification-Plattform** mit Server-Backend, Multi-Plattform-Support, umfangreicher Gamification, KI-Features und einem Plugin-Oekosystem.

**Kernphilosophie aus 240 Antworten:** Maximale Konfigurierbarkeit. Fast jedes Feature ist pro Event an-/abschaltbar. Der Admin hat volle Kontrolle ueber das Erlebnis.

---

## 1. Architektur & Infrastruktur

| Entscheidung | Antwort |
|---|---|
| Datenhaltung | **Hybrid**: Server ist die Wahrheit, NFC-Tag traegt Offline-Cache fuer Notfaelle |
| Backend | **Node.js / Express** |
| Datenbank | **PostgreSQL** |
| ORM | **TypeORM** |
| Kommunikation | **WebSockets (Socket.IO)** |
| Hosting | **Docker auf eigenem Server** |
| Cache | **Redis** (Caching, Sessions, Pub/Sub) |
| Job-Queue | **BullMQ** (Redis-basiert, fuer E-Mails, Reports, Cleanup) |
| File-Storage | **S3-kompatibler Storage** (MinIO self-hosted) |
| Logging | **Winston** |
| Offline-Strategie | **Queue + Retry** (Buchungen lokal zwischenspeichern, bei Netz hochladen) |
| Multi-Event | **Ja, von Anfang an** |
| Architekturstil | **Monolith** |
| CI/CD | **GitHub Actions + Docker** |
| API-Versionierung | **Keine** (backward-kompatible Aenderungen) |
| Monitoring | **Prometheus + Grafana + Uptime Kuma** |
| Environments | **Docker Compose Profile** (dev/staging/prod) |
| Secrets | **Docker Secrets** |
| DB-Backups | **pg_dump per Cron** auf externen Storage |
| Testing | **Jest + Testcontainers** (echte DB in Tests) |

### Architektur-Skizze

```
                        +------------------+
                        |   PostgreSQL     |
                        +--------+---------+
                                 |
              +------------------+------------------+
              |                                     |
        +-----+------+                      +-------+------+
        |   Redis    |                      |    MinIO     |
        | Cache/Queue|                      |  (S3-Fotos)  |
        +-----+------+                      +--------------+
              |
        +-----+--------------------------+
        |  Node.js/Express (Monolith)    |
        |  - REST API + Socket.IO       |
        |  - Auth (PIN + Geraetebindung)|
        |  - BullMQ Workers             |
        |  - Plugin-System              |
        |  - Automation-Engine          |
        +----+--------+--------+--------+
             |        |        |        |
    +--------+--+ +---+------+ +-------+------+ +--------+
    | Flutter   | | Next.js  | | Terminal/    | | Wearable|
    | App       | | Web      | | Kiosk       | | Watch   |
    | Android   | | Dashboard| | Tablet      | |         |
    | iOS       | | Admin    | | Raspberry Pi| |         |
    | NFC/QR    | | Eltern   | | Web         | |         |
    | Chat      | | TN-Portal| |             | |         |
    | AR/Spiele | | Analytics| |             | |         |
    +-----------+ +----------+ +-------------+ +---------+
```

---

## 2. Plattform & Client

| Entscheidung | Antwort |
|---|---|
| Zielplattformen | **Android + iOS + Web** |
| Mobile Technologie | **Flutter** (Cross-Platform) |
| Web-Framework | **React + Next.js** |
| UI-Design | **Gamification-Look** (verspielt, farbenfroh, Animationen) |
| Push-Benachrichtigungen | **Ja, fuer Teilnehmer UND Betreuer** |
| App-Store | **Google Play + Apple App Store** |
| Sprache | **Deutsch zuerst, i18n-ready** |
| Updates | **Klassische Store-Updates** |
| Dark Mode | **Ja, mit Auto-Wechsel** |
| Wearable | **Smartwatch-App** (Betreuer) + **Fitness-Tracker** (Teilnehmer-Punkte) |

---

## 3. NFC & Hardware

| Entscheidung | Antwort |
|---|---|
| Rolle des NFC-Tags | **ID + Server-signiertes Token + Notfalldaten** |
| Identifikationswege | **NFC + QR-Code + App-Login** |
| Tag-Typ | **NTAG215 (min.) / NTAG216 (empfohlen)** wegen umfangreicher Notfalldaten |
| Wiederverwendung | **Komplett wiederverwendbar** |
| Notfalldaten auf Tag | **Umfangreich**: Name, Blutgruppe, Allergien, Kontaktperson, besondere Beduerfnisse |
| Krypto-Signatur | **Server-signiertes Token** |
| Schreibschutz | **NTAG-Passwort** (nur im Admin-Modus beschreibbar) |
| Armband-Design | **Farben nach Gruppe + Event-Branding** |
| Armband-Zuweisung | **Alle Varianten**: Einzel-Scan vor Ort, Vorab-Versand, Batch |
| Band verloren | **Automatisch neues Band + altes gesperrt + Eltern-Benachrichtigung** |
| Multi-Band | **Konfigurierbar** pro Event |

---

## 4. Benutzer & Rollen

| Entscheidung | Antwort |
|---|---|
| Authentifizierung | **PIN + Geraete-Bindung** |
| Rollen | **4 Rollen**: Admin, Betreuer, Teilnehmer, Eltern |
| Teilnehmer-Accounts | **Optionaler Self-Service** |
| Eltern-Zugang | **Live-Einblick**, Inhalte konfigurierbar pro Event |
| Eltern-Auth | **Mehrere Optionen**: Magic Link, Code, eigener Account |
| Eltern-Kommunikation | **Konfigurierbar**: DM an Betreuer und/oder Kontaktformular |
| Eltern-Benachrichtigungen | **Eltern waehlen aus Admin-Vorgaben** |
| Registrierung | **Online-Voranmeldung ODER Vor-Ort** |
| Anmeldefelder | **Vom Admin pro Event konfigurierbar** |
| Betreuer-Einladung | **Event-Code** (6-stellig) |
| Betreuer-Berechtigungen | **Frei konfigurierbar** pro Betreuer |
| Stationen | **Optionales Feature** |

### Betreuer-Features
| Feature | Details |
|---|---|
| Betreuer-Gamification | **Punkte + Badges + Leaderboard** unter Betreuern |
| Schichtplanung | **Automatische Planung** basierend auf Verfuegbarkeiten |
| Teilnehmer-Notizen | **Strukturiert + Uebergabe-Funktion** bei Schichtwechsel |
| Schulung/Onboarding | **Tutorial + Videos + Pruefung** |

---

## 5. Punktesystem & Gamification

### Punkte-Grundsystem
| Entscheidung | Antwort |
|---|---|
| Punkt-Typen | **Vom Admin frei konfigurierbar** |
| Punktevergabe | **Dreifach**: Betreuer + Terminal-Stationen + P2P |
| Vergabe-Flow | **Schnellwahl + manueller Modus** |
| Batch-Buchung | **Gruppen-Buchung + Multi-Scan** |
| Vergabe-Gruende | **Vordefiniert + Freitext** |
| Multiplikatoren | **Vom Admin definiert** (Zeit, Aktivitaet, Level) |
| Punkte-Verfall | **Konfigurierbar pro Event** |
| P2P-Transfer | **Ueber die App**, Admin-konfigurierbare Limits |

### Strafsystem (separat)
| Entscheidung | Antwort |
|---|---|
| Straftypen | **Alles kombinierbar**: Karten, Strafpunkte-Konto, Ampelsystem |
| Konsequenzen | **Konfigurierbar pro Schwelle** |
| Straf-Abbau | **Alle Optionen konfigurierbar**: manuell, zeitbasiert, Aufgaben |
| Sichtbarkeit fuer Eltern | **Konfigurierbar pro Event** |

### Scan-Erlebnis
| Entscheidung | Antwort |
|---|---|
| Scan-Ansicht | **Animierter Splash** mit Avatar/Level, dann Profilkarte |
| Avatar | **Evolving Avatar**: entwickelt sich mit Level/Badges weiter |
| Feedback | **Sound + Vibration**, abschaltbar |
| Punktestand ohne App | **QR-Code (eigenes Handy) + NFC-Terminal vor Ort** |

### Gamification-Details
| Entscheidung | Antwort |
|---|---|
| Level-System | **Admin-konfigurierbar** |
| Achievement-Typen | **Alle**: Meilensteine + Verhalten + Sammler + Admin-definierte |
| Badge-Seltenheit | **Dynamisch** nach Anzahl der Besitzer |
| Badge-Handel | **Konfigurierbar** |
| Badge-Display | **Showcase + Sammlung + Titel-System** |
| Leaderboard-Update | **Konfigurierbar** (Echtzeit, Intervall, feste Zeiten) |
| Leaderboard-Zeitraeume | **Frei konfigurierbar** |
| Team-Score-Berechnung | **Konfigurierbar** (Summe, Durchschnitt, beides) |
| Turniere | **Bracket + Liga**, Admin waehlt |

### Challenges & Quests
| Entscheidung | Antwort |
|---|---|
| Challenge-Builder | **Einfach + Regelbasiert + mehrstufige Quests** |
| Challenge-Typen | **Einzel + Team + kooperativ** (alle vs. Ziel) |
| Story/Narrativ | **Optional**: Event KANN ein Narrativ haben |
| Auto-Challenges | **Alle Varianten**: aktivitaetsbasiert + taeglich + personalisiert |

### Sammel- & Kampf-Mechaniken
| Entscheidung | Antwort |
|---|---|
| Sammel-System | **Stickeralbum + Sammelkarten + Album-Bonus** |
| Boss-Challenges | **Camp-Boss + Team-Bosse + Tagesboss** |
| UGC | **Alles**: Challenges + Quiz + Fotos + Geschichten vorschlagen |
| Mini-Wirtschaft | **Marktplatz + dynamische Preise + Auktionen** |
| Gilden | **Selbstorganisiert mit eigenen Gilden-Quests** |
| Spezial-Events | **Happy Hour + Ueberraschung + Countdown-Events** |

---

## 6. Praemien-System

| Entscheidung | Antwort |
|---|---|
| Verwaltung | **App + Dashboard synchronisiert** |
| Kategorien | **Vom Admin erstellbar** |
| Bundles | **Konfigurierbar pro Event** (Rabatt-Pakete, Mystery-Boxen) |
| Reservierung | **Reservierung + Warteliste** |
| Digitale Praemien | **Privilegien + In-App-Items + physische Praemien** |
| Limits | **Konfigurierbar** (Stueckzahl, Zeitfenster) |
| Einloesungs-Modus | **Konfigurierbar** |
| Shop | **Konfigurierbar pro Event** |
| In-App-Payments | **Konfigurierbar** (echtes Geld optional) |

---

## 7. Terminal-Stationen

| Entscheidung | Antwort |
|---|---|
| Station-Modi | **Alle konfigurierbar**: Auto-Punkte, Betreuer-Bestaetigung, Quiz-Aufgabe |
| Wiederholungsregeln | **Konfigurierbar pro Station**: unbegrenzt, Cooldown, taeglich, einmalig |
| Versteckte Stationen | **Ja**: unsichtbar auf Karte + zeitlich begrenzt aktiv |
| Schwierigkeitsgrade | **Admin entscheidet pro Station** |

### Terminal/Kiosk Hardware
| Entscheidung | Antwort |
|---|---|
| Funktionsumfang | **Alles was die App kann** |
| Identifikation | **NFC + QR + PIN**, je nach Terminal |
| Idle-Screen | **Konfigurierbar** |
| Raspberry Pi | **Komplettpaket**: Bauanleitung + SD-Image + 3D-Gehaeuse + Stueckliste |

---

## 8. Event-Features

### Event-Management
| Entscheidung | Antwort |
|---|---|
| Event-Erstellung | **Wizard + Templates** |
| Event-Klon | **Klonen + Templates + Import/Export** |
| Event-Archiv | **Dauerhaft** |
| Event-Typen | **Maximal breit + Community-Templates** |
| Mehrtaegig | **Tagesabschluss + Unterkunftsverwaltung + Nachtruhe-Regeln** |
| Wiederkehrend | **Fortlaufend ODER Saison-basiert**, Admin entscheidet |
| Schnell-Event | **Quick-Setup + Quick-Join** (2-Minuten Mini-Event) |
| Virtuell/Hybrid | **Beides**: rein virtuell oder hybrid |
| Branding | **CSS/Theme-Editor** mit Live-Preview |
| Event-Themes | **Frei gestaltbar** (eigene Designs) |

### Zeitplan & Programm
| Entscheidung | Antwort |
|---|---|
| Zeitplan-Gestaltung | **Frei gestaltbar** |
| Aktivitaets-Anmeldung | **FCFS oder Losverfahren**, pro Aktivitaet waehlbar |
| Erinnerungen | **Konfigurierbar** (Admin und Teilnehmer stellen ein) |
| Kalender-Sync | **iCal + Live-Sync + Eltern-Kalender** |
| Wetter-Reaktion | **Alternativen + Plananpassung + Sicherheitswarnungen** |

### Chat & Kommunikation
| Entscheidung | Antwort |
|---|---|
| Chat-Typen | **Gruppen + Event-weit + Direktnachrichten + Betreuer-intern** |
| Moderation | **Konfigurierbar**: Wortfilter, Freigabe, Melde-Funktion |
| Chat-Medien | **Konfigurierbar** |
| Broadcasts | **Push + Chat + Prioritaetsstufen + Zielgruppen** |

### Karte & Standort
| Entscheidung | Antwort |
|---|---|
| Kartentyp | **Custom-Bild + OpenStreetMap** (je nach Event) |
| Live-Status | **Alles**: Stations-Status + Wartezeit + Teilnehmer-Dichte + naechste Aktivitaet |
| Geofencing | **Alle Anwendungsfaelle**: Check-in + Punkte-Validierung + Sicherheitszonen |
| Offline-Karte | **Bild offline, Live-Daten online** |

### Fotos & Feedback
| Entscheidung | Antwort |
|---|---|
| Foto-Upload | **Konfigurierbar** (wer darf, mit/ohne Moderation) |
| Fotogalerie | **Alben + Tags**, keine Gesichtserkennung |
| Feedback-System | **Admin-konfigurierbarer Fragebogen** pro Aktivitaet |
| Feedback-Anonymitaet | **Teilnehmer waehlt** ob anonym oder namentlich |

### Minispiele
| Entscheidung | Antwort |
|---|---|
| Quiz-Typen | **Admin-erstellter Quiz-Builder** (freie Fragetypen) |
| Schnitzeljagd | **QR + NFC + GPS**, je nach Jagd kombinierbar |
| Multiplayer | **Alle Modi**: Live-Duell + Team + asynchroner Highscore |
| Custom Games | **Vorlagen + Builder** fuer eigene Spiele |
| AR-Features | **Alle**: Schnitzeljagd + Info-Overlay + Kreaturen sammeln |

---

## 9. Daten, Analytics & Display

### Dashboard & Berichte
| Entscheidung | Antwort |
|---|---|
| Admin-Dashboard | **Drag-and-Drop Widgets** |
| Rollen-Dashboards | **Komplett konfigurierbar** pro Rolle |
| Vorschau-Modus | **Alle Rollen + Testdaten** (Admin schlupft in jede Rolle) |
| Auto-Berichte | **Tages + Event + benutzerdefiniert** |
| Event-Vergleich | **Eigene Events + Plattform-Benchmark** |
| Live-Feed | **Getrennte Feeds**: Admin (detailliert) + Teilnehmer (Highlights) |
| Export | **Alles + Berichte + Event-Konfiguration** zum Reimportieren |

### Live-Display
| Entscheidung | Antwort |
|---|---|
| Display-Inhalte | **Voll konfigurierbar** (welche Slides, wie lange, Reihenfolge) |
| Interaktivitaet | **Beides**: passives Display ODER interaktives Touch-Terminal |
| Feier-Effekte | **Alles**: App + Display + Sound bei Level-Up etc. |
| Notfall-Kanal | **Sofort-Meldung + Sound + Sammelplatz-Karte + Push an alle** |

### Spezielle Exports
| Entscheidung | Antwort |
|---|---|
| Urkunden | **Editor + Druck + Digital + QR-Verifikation** |
| Jahresrueckblick | **Fuer Teilnehmer + Organisation** (Spotify-Wrapped-Stil) |
| Datenmigration | **Migrations-Assistent** mit Feld-Mapping und Vorschau |

---

## 10. Sicherheit, Datenschutz & Notfall

### Datenschutz (DSGVO)
| Entscheidung | Antwort |
|---|---|
| Privacy-by-Design | **Ja**: Verschluesselung, Pseudonymisierung, Einwilligungsmanagement |
| Verschluesselung | **TLS + E2E fuer sensible Daten** |
| Audit-Log | **Vollstaendig** |
| Anti-Cheat | **Signierte Transaktionen + Anomalie-Erkennung** |
| Einwilligung | **Alle Methoden**: digital, Checkbox, PDF |
| Datenloeschung | **Loeschantrag + 30-Tage-Frist** |
| Serverstandort | **EU** |
| DSE-Generator | **Automatisch basierend auf genutzten Features** |

### Notfallmodul
| Entscheidung | Antwort |
|---|---|
| Notfallmodul | **Vollstaendig**: Alarm + Anwesenheitscheck + Treffpunkte + Notfalldaten + Protokoll |
| Alarm-Stufen | **Konfigurierbar** (Admin definiert eigene Stufen) |
| Notfalldaten-Zugriff | **Scan + PIN-Bestaetigung + offline vom Tag lesbar** |
| Medikamenten-Tracking | **Erinnerung + Dokumentation + Eltern-Info** |

---

## 11. Integration & Erweiterbarkeit

### Messenger & Externe Dienste
| Entscheidung | Antwort |
|---|---|
| Messenger-Integration | **Volle Integration**: Benachrichtigungen + Kommandos + Buchung + Leaderboard |
| Anmelde-Systeme | **API-Schnittstelle** fuer gaengige Tools |
| Wetter | **Alle Features**: Daten + Empfehlungen + Unwetter-Warnung |
| Social Media | **Teilen nach aussen + Feed nach innen** |
| Kalender | **Google Calendar + Outlook** |
| Payment | **PayPal + Stripe + Rechnung** |
| IoT | **Offene Schnittstelle** fuer beliebige Geraete |

### Plugin-System
| Entscheidung | Antwort |
|---|---|
| Entwickler-Zugang | **Stufenweise oeffnen**: intern → Partner → offen |
| Marketplace | **Ja, mit Bewertungen** |
| Plugin-Hooks | **Ueberall**: UI, Backend, Spiele, Integrationen, Berichte, Widgets |
| Sicherheit | **Gestuft**: offizielle = voller Zugriff, Community = sandboxed |

### Automationen
| Entscheidung | Antwort |
|---|---|
| Regel-Engine | **Vollstaendige Automation-Engine**: Trigger → Bedingung → Aktion + Zeitsteuerung |
| KI-Features | **Analyse + Empfehlungen + Content-Generierung** (kein Chat-Bot) |

---

## 12. Geschaeftsmodell & Entwicklung

### Monetarisierung
| Entscheidung | Antwort |
|---|---|
| Lizenz | **Source Available** |
| Preismodell | **Feature-basiert** (Basis guenstig, Premium-Features extra) |
| Free Tier | **Test-Event kostenlos** |
| Zahlung | **PayPal + Stripe + Rechnung** |
| In-App-Payments | **Konfigurierbar** (echtes Geld optional) |

### Organisation & Skalierung
| Entscheidung | Antwort |
|---|---|
| Org-Hierarchie | **Konfigurierbar** |
| Cross-Org Profil | **Optional**, jedes Event hat eigene Punkte |
| Org-Statistiken | **Dashboard + Trends + Benchmark** |
| Teilnehmer-Historie | **Ueber Events hinweg + Treue-Programm** |
| Template-Sharing | **Organisationsintern + oeffentliche Bibliothek** |

### Produkt
| Entscheidung | Antwort |
|---|---|
| Produktname | **Noch offen** (kreativ/spielerisch, z.B. QuestBand, ScanQuest) |
| White-Label | **Spaeter** (Architektur vorbereiten) |
| Barrierefreiheit | **Spaeter nachruestbar** |
| Altersgruppen | **UI + Schwierigkeit + Inhalte** nach Alter angepasst |
| Inklusion | **Umfassend**: Beduerfnisse + angepasste Aufgaben + Buddy + Hilfsmittel |
| Einfache Sprache | **Konfigurierbar pro Event** |
| Onboarding | **Demo-Event mit Dummy-Daten** |
| Support | **Self-Service** (Docs + FAQ) |

### Spezial-Module
| Entscheidung | Antwort |
|---|---|
| Verpflegung | **Menuplan + Allergiefilter + Teilnehmer-Voting** vor dem Event |
| Packliste | **Vom Admin erstellbar + Erinnerungen** |
| An-/Abreise | **Abfahrtszeiten + Fahrgemeinschaften + Live-Bus-Tracking** |
| Inventar | **Stations-Inventar + Ausleihe-System** |

### Vision
| Entscheidung | Antwort |
|---|---|
| Virtuelle Events | **Rein virtuell + hybrid** moeglich |
| 3-Jahres-Vision | **DACH-Start → international → Oekosystem** |
| Erfolgsfaktor | **Alle drei gleichwertig**: Einfachheit + Spass + Zuverlaessigkeit |
| Entwicklung | **Solo + KI-Unterstuetzung** |
| Timeline | **Kein fester Zeitdruck** |

---

## 13. Delta zum Ursprungskonzept

| Aspekt | Alt (Prototyp) | Neu (Review 2026) |
|---|---|---|
| Datenhaltung | Alles auf dem Tag | Server-first, Tag als Cache + Notfalldaten |
| Backend | Keins | Node.js/Express + PostgreSQL + Redis |
| Plattform | Nur Android (Kotlin) | Flutter (Android+iOS) + Next.js Web + Terminals + Watch |
| Offline | Komplett offline | Queue+Retry, Online-first |
| Rollen | Admin + Betreuer | Admin + Betreuer + Teilnehmer + Eltern |
| Punkte | Eine Waehrung, fest | Konfigurierbare Typen, P2P, Terminals, Multiplikatoren |
| Praemien | Hardcoded Liste | Konfigurierbarer Shop + Bundles + Auktionen + digitale Items |
| Sicherheit | hashCode() | Server-Token, E2E, Privacy-by-Design, Notfallmodul |
| Gamification | Keine | Levels, Badges, Challenges, Quests, Bosse, AR, Sammelkarten, Gilden |
| Skalierung | Ein Handy | 10.000+ Teilnehmer, Multi-Event, Multi-Org |
| Geschaeftsmodell | Keins | Feature-basiertes Pay-per-Event, Source Available |
| Features | Punkte buchen | Event-Mgmt, Chat, Karte, Wetter, Verpflegung, Transport, Inventar, IoT |

---

## 14. Empfohlene Entwicklungsphasen

### Phase 1: Fundament (MVP)
- Node.js/Express Server mit PostgreSQL + Redis + BullMQ
- Socket.IO Echtzeit-Infrastruktur
- Auth-System (PIN + Geraetebindung)
- Event CRUD (erstellen, konfigurieren)
- Teilnehmer-Verwaltung (Online-Anmeldung + Vor-Ort-Registrierung)
- NFC-Scan (Flutter): Tag lesen/schreiben, Server-Token, Notfalldaten
- Basale Punktebuchung (Schnellwahl + manuell, Einzel + Batch)
- Einfacher Praemienkatalog + Einloesung
- Web-Dashboard: Admin-Grundfunktionen
- Docker + GitHub Actions CI/CD
- Prometheus + Grafana Monitoring

### Phase 2: Gamification & Engagement
- Level-/Rang-System (Admin-konfigurierbar)
- Achievements/Badges (System + Admin, dynamische Seltenheit)
- Leaderboard (Einzel + Team, konfigurierbare Updates)
- Challenges (Admin-erstellt + automatisch + Quests)
- Animierter Scan-Splash + evolving Avatars
- Separates Strafsystem (Karten, Punkte, Ampel)
- P2P-Transfer mit konfigurierbaren Limits
- Teilnehmer-App (Self-Service, Punktestand, Shop)
- Push-Benachrichtigungen
- QR-Code als Alternativ-Identifikation
- Sound-/Vibrations-Feedback

### Phase 3: Event-Management & Kommunikation
- Event-Templates + Wizard + Klon + Import/Export
- Zeitplan/Programm (frei gestaltbar, Kalender-Sync)
- Interaktive Karte (Custom + OSM, Live-Status, Geofencing)
- Check-in/Check-out (konfigurierbar)
- Chat-System (Gruppen, Event, DM, Betreuer-intern, Moderation)
- Broadcasts mit Prioritaeten + Zielgruppen
- Fotogalerie (Alben, Tags, konfigurierbare Uploads)
- Feedback-System (konfigurierbarer Fragebogen)
- Terminal/Kiosk-Modus

### Phase 4: Eltern, Sicherheit & Analytics
- Eltern-Portal (Live-Einblick, konfigurierbare Inhalte)
- Eltern-Auth (Magic Link, Code, Account)
- Notfallmodul (Alarm, Anwesenheit, Treffpunkte, Notfalldaten)
- Medikamenten-Tracking + Erinnerungen
- Drag-and-Drop Dashboard (Admin)
- Auto-Berichte (Tages-, Event-, benutzerdefiniert)
- Live-Feed (getrennt fuer Admin/Teilnehmer)
- Urkunden-Generator + QR-Verifikation

### Phase 5: Plattform & Erweiterung
- Plugin-System + Marketplace
- Authentifizierte API fuer Dritte
- Automation-Engine (If-This-Then-That)
- Messenger-Integrationen (Slack, Discord, WhatsApp)
- Payment-Integration (Stripe, PayPal, Rechnung)
- Live-Display (TV-Modus, konfigurierbare Rotation, Notfall)
- Export (CSV, PDF, Excel, API, Event-Config)
- Wetter-Integration + Reaktionssystem

### Phase 6: Gamification Deluxe
- Minispiele: Quiz-Builder, Schnitzeljagd (QR+NFC+GPS), AR
- Sammelkarten + Stickeralbum + Album-Bonus
- Boss-Challenges (Camp + Team + Tagesboss)
- Mini-Wirtschaft (Marktplatz, Auktionen, dynamische Preise)
- Gilden mit eigenen Quests
- Turnier-System (Bracket + Liga)
- Spezial-Events (Happy Hour, Countdown, Ueberraschung)
- UGC (Teilnehmer schlagen Challenges, Quiz, Geschichten vor)

### Phase 7: Enterprise & Skalierung
- Multi-Org mit konfigurierbarer Hierarchie
- Teilnehmer-Historie + Treue-Programm
- Org-Dashboard + Benchmark
- Template-Sharing (intern + oeffentlich)
- Mehrtaegige Events (Unterkunft, Nachtruhe, Tagesabschluss)
- Wiederkehrende Events + Saison-System
- Schnell-Event Modus
- Virtuelle/Hybride Events

### Phase 8: Vollausbau
- White-Label
- KI: Analyse + Empfehlungen + Content-Generierung
- IoT-Anbindung (Wetter, Tuerschloesser, Sensoren)
- Smartwatch-App + Fitness-Tracker-Integration
- Raspberry Pi Komplett-Kit (Anleitung + Image + 3D-Gehaeuse)
- Verpflegungsmodul + Teilnehmer-Voting
- Transport-Management + Live-Bus-Tracking
- Inventar + Ausleihe-System
- Jahresrueckblick (Spotify-Wrapped-Stil)
- Altersgruppen-Anpassung + Inklusions-Features
- Barrierefreiheit (WCAG nachruestbar)
- Feature-basiertes Abrechnungssystem
- Internationalisierung
- Source-Available Lizenzierung
