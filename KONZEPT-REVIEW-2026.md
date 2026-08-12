# Konzept-Review: NFC-Punktesystem 2.0

**Datum:** 12. August 2026
**Basis:** Ursprungskonzept "NFCPunkteApp" (August 2026, Prototyp-Stand)
**Methode:** 80-Fragen-Review zur Neuausrichtung

---

## Zusammenfassung: Vom Offline-Prototyp zur Event-Plattform

Das urspruengliche Konzept war ein reines Offline-System: alle Daten auf dem NFC-Tag, kein Server, kein Internet. Die Review zeigt eine fundamentale Neuausrichtung hin zu einer **universellen Event-Gamification-Plattform** mit Server-Backend, Multi-Plattform-Support und umfangreichen Features.

---

## 1. Architektur & Infrastruktur

| Entscheidung | Antwort |
|---|---|
| Datenhaltung | **Hybrid**: Server ist die Wahrheit, NFC-Tag traegt Offline-Cache fuer Notfaelle |
| Backend | **Node.js / Express** |
| Datenbank | **PostgreSQL** |
| Kommunikation | **WebSockets** (Echtzeit-Updates unbedingt) |
| Hosting | **Docker auf eigenem Server** |
| Offline-Strategie | **Queue + Retry** (Buchungen lokal zwischenspeichern, bei Netz hochladen) |
| Multi-Event | **Ja, von Anfang an** |
| Architekturstil | **Monolith** (ein Prozess, alles drin) |
| CI/CD | **GitHub Actions + Docker** (Push to main = Auto-Deploy) |

### Architektur-Skizze

```
                        +------------------+
                        |   PostgreSQL     |
                        +--------+---------+
                                 |
                        +--------+---------+
                        |  Node.js/Express |
                        |  (Monolith)      |
                        |  - REST API      |
                        |  - WebSocket     |
                        |  - Auth          |
                        |  - Plugin-System |
                        +----+----+----+---+
                             |    |    |
              +--------------+    |    +---------------+
              |                   |                    |
     +--------+-------+  +-------+--------+  +--------+-------+
     |  Flutter App   |  |  Next.js Web   |  |  Terminal/     |
     |  (Android/iOS) |  |  Dashboard     |  |  Kiosk         |
     |  - NFC Scan    |  |  - Admin       |  |  - Tablet      |
     |  - QR Scan     |  |  - Eltern      |  |  - Raspberry Pi|
     |  - Punkte      |  |  - Teilnehmer  |  |  - Web         |
     |  - Chat        |  |  - Analytics   |  |                |
     +----------------+  +----------------+  +----------------+
```

---

## 2. Plattform & Client

| Entscheidung | Antwort |
|---|---|
| Zielplattformen | **Android + iOS + Web** |
| Mobile Technologie | **Flutter** (Cross-Platform) |
| Web-Framework | **React + Next.js** (Admin-Dashboard, Teilnehmer-Portal, Eltern-Ansicht) |
| UI-Design | **Gamification-Look** (verspielt, farbenfroh, Animationen, passend fuer Kinder/Jugendliche) |
| Push-Benachrichtigungen | **Ja, fuer Teilnehmer UND Betreuer** |
| App-Store | **Google Play + Apple App Store** |
| Sprache | **Deutsch zuerst, i18n-ready** (Architektur vorbereitet fuer spaetere Sprachen) |
| Updates | **Klassische Store-Updates** |
| Dark Mode | **Ja, mit Auto-Wechsel** (folgt Systemeinstellung) |

---

## 3. NFC & Hardware

| Entscheidung | Antwort |
|---|---|
| Rolle des NFC-Tags | **ID + kryptografische Signatur + Notfalldaten** |
| Identifikationswege | **NFC + QR-Code + App-Login** (maximale Flexibilitaet) |
| Tag-Typ | **Guenstigster der reicht** (NTAG215/216 wegen Notfalldaten) |
| Wiederverwendung | **Komplett wiederverwendbar** |
| Notfalldaten auf Tag | **Umfangreich**: Name, Blutgruppe, Allergien, Kontaktperson, besondere Beduerfnisse |
| Krypto-Signatur | **Server-signiertes Token** (Server erzeugt Token bei Registrierung) |
| Schreibschutz | **NTAG-Passwort** (nur im Admin-Modus beschreibbar) |
| Armband-Design | **Farben nach Gruppe + Event-Branding** |

### Hinweis Tag-Speicher
Durch die umfangreichen Notfalldaten (Name, Blutgruppe, Allergien, Kontakt, besondere Beduerfnisse) + Server-Token + ID wird NTAG213 (144 Byte) zu klein. Empfehlung: **NTAG215 (504 Byte)** als Minimum, **NTAG216 (888 Byte)** fuer Komfort.

---

## 4. Benutzer & Rollen

| Entscheidung | Antwort |
|---|---|
| Authentifizierung | **PIN + Geraete-Bindung** (Geraet einmalig autorisiert, danach PIN) |
| Rollen | **4 Rollen**: Admin, Betreuer, Teilnehmer, Eltern |
| Teilnehmer-Accounts | **Optionaler Self-Service** (koennen sich einloggen, muessen aber nicht) |
| Eltern-Zugang | **Live-Einblick** (Punktestand und Aktivitaeten jederzeit einsehbar) |
| Registrierung | **Online-Voranmeldung ODER Vor-Ort** |
| Betreuer-Einladung | **Event-Code** (6-stelliger Code) |
| Betreuer-Berechtigungen | **Frei konfigurierbar** (Admin legt pro Betreuer fest) |
| Stationen | **Optionales Feature** (kann aktiviert werden, muss nicht) |

---

## 5. Punktesystem & Gamification

| Entscheidung | Antwort |
|---|---|
| Punkt-Typen | **Vom Admin frei konfigurierbar** (beliebige Waehrungen/Kategorien) |
| Punktevergabe | **Dreifach**: Betreuer manuell + automatische Terminal-Stationen + P2P zwischen Teilnehmern |
| Strafpunkte | **Separates Straf-System** (getrennt von normalen Punkten) |
| Punkte-Verfall | **Konfigurierbar pro Event** |
| Level-System | **Admin-konfigurierbar** (ob und welche Stufen) |
| Achievements/Badges | **System-Achievements + Admin-erstellte** |
| Leaderboard | **Oeffentlich sichtbar + Team-Leaderboard** |
| Challenges | **Admin-erstellt + automatisch generiert** |

### Praemien-System

| Entscheidung | Antwort |
|---|---|
| Verwaltung | **App + Dashboard synchronisiert** |
| Verfuegbarkeit/Limits | **Konfigurierbar** (Stueckzahl, Zeitfenster, Admin entscheidet) |
| Einloesungs-Modus | **Konfigurierbar** (Sofort-Scan, Bestaetigung, Voucher, Warenkorb) |
| Teilnehmer-Shop | **Konfigurierbar pro Event** (kann aktiviert werden) |
| P2P-Transfer | **Ueber die App** |
| P2P-Limits | **Admin-konfigurierbar** |

---

## 6. Event-Features

| Entscheidung | Antwort |
|---|---|
| Event-Erstellung | **Wizard + Templates** (von Vorlage starten oder komplett neu) |
| Event-Archiv | **Dauerhaft** (alle Events bleiben gespeichert) |
| Check-in/Check-out | **Konfigurierbar pro Event** |
| Zeitplan/Programm | **Vollstaendiger Tagesplan** mit Uhrzeiten, Aktivitaeten, Orten |
| Teams/Gruppen | **Optionales Feature** |
| Nachrichten | **Chat-System** (gruppenbasierter Chat) |
| Karte | **Interaktive Karte** (Stationen, Zelte, Einrichtungen mit Markern) |
| Fotos/Medien | **Profilbilder + Aktivitaets-Fotos** (Fotos an Buchungen anhaengbar) |
| Feedback | **Aktivitaeten-Bewertung + Event-Gesamtfeedback** |
| Minispiele | **Alle Varianten**: Quiz, Schnitzeljagd, AR-Features |

---

## 7. Daten, Analytics & Display

| Entscheidung | Antwort |
|---|---|
| Statistiken | **Live-Dashboard + historische Trends** |
| Export-Formate | **Alle**: CSV, PDF-Berichte, Excel, API-Zugang |
| Live-Display | **Rotierendes Display**: Leaderboard + Programm + Nachrichten |
| Daten-Retention | **Admin entscheidet** pro Event |

---

## 8. Sicherheit & Datenschutz

| Entscheidung | Antwort |
|---|---|
| DSGVO | **Privacy-by-Design**: Verschluesselung, Pseudonymisierung, Einwilligungsmanagement, Loeschkonzept |
| Verschluesselung | **TLS + E2E fuer sensible Daten** (selektiv) |
| Audit-Log | **Vollstaendig** (jede Aktion geloggt) |
| Anti-Cheat | **Signierte Transaktionen + Anomalie-Erkennung** |

---

## 9. Integration & Erweiterbarkeit

| Entscheidung | Antwort |
|---|---|
| API | **Authentifiziert** (API-Key/Token) |
| Plugin-System | **Von Anfang an** (modulare Architektur) |
| Messenger-Integration | **Slack, Discord, WhatsApp** |
| Kalender | **Google Calendar, Outlook** |
| Payment | **PayPal, Stripe** |
| Zielgruppe | **Universell** (Festivals, Firmen-Events, Schulen, Vereine, ...) |

---

## 10. Geschaeftsmodell & Entwicklung

| Entscheidung | Antwort |
|---|---|
| Lizenz | **Source Available** (Code einsehbar, kommerzielle Nutzung eingeschraenkt) |
| Geschaeftsmodell | **Pay-per-Event** |
| Terminal/Kiosk | **Alle Varianten**: Tablet, Web, Raspberry Pi |
| Onboarding | **Self-Service + Wizard + Demo-Event** |
| MVP-Fokus | **Voller Flow End-to-End** (Event anlegen bis Praemie einloesen) |
| Skalierung | **Gross** (100+ Events, 10.000+ Teilnehmer) |
| Timeline | **Kein fester Zeitdruck** |
| Entwicklung | **Solo + KI-Unterstuetzung** |

---

## 11. Delta zum Ursprungskonzept

| Aspekt | Alt (Prototyp) | Neu (Review 2026) |
|---|---|---|
| Datenhaltung | Alles auf dem Tag | Server-first, Tag als Cache |
| Backend | Keins | Node.js/Express + PostgreSQL |
| Plattform | Nur Android (Kotlin) | Flutter (Android+iOS) + Next.js Web |
| Offline | Komplett offline | Queue+Retry, Online-first |
| Rollen | Admin + Betreuer | Admin + Betreuer + Teilnehmer + Eltern |
| Punkte | Eine Waehrung, fest | Konfigurierbare Typen, P2P, Terminals |
| Praemien | Hardcoded Liste | Konfigurierbarer Shop |
| Sicherheit | hashCode() | Server-Token, E2E, Privacy-by-Design |
| Gamification | Keine | Levels, Badges, Challenges, Leaderboard, Minispiele |
| Skalierung | Ein Handy | 10.000+ Teilnehmer, Multi-Event |
| Geschaeftsmodell | Keins | Pay-per-Event, Source Available |

---

## 12. Empfohlene Entwicklungsphasen

### Phase 1: Fundament (MVP)
- Node.js/Express Server mit PostgreSQL
- WebSocket-Infrastruktur
- Auth-System (PIN + Geraetebindung)
- Event CRUD (erstellen, konfigurieren)
- Teilnehmer-Verwaltung (Registrierung, Armband-Zuweisung)
- NFC-Scan (Flutter): Tag lesen/schreiben, Server-Token
- Basale Punktebuchung (Betreuer scannt, bucht Punkte)
- Einfacher Praemienkatalog + Einloesung
- Web-Dashboard: Admin-Grundfunktionen
- Docker + GitHub Actions CI/CD

### Phase 2: Gamification & Engagement
- Level-/Rang-System
- Achievements/Badges
- Leaderboard (Einzel + Team)
- Challenges (Admin-erstellt + automatisch)
- Teilnehmer-App (Self-Service, Punktestand, Shop)
- Eltern-Portal (Live-Einblick)
- Push-Benachrichtigungen
- QR-Code als Alternativ-Identifikation

### Phase 3: Event-Management
- Event-Templates + Wizard
- Zeitplan/Programm-Verwaltung
- Interaktive Gelaendekarte
- Check-in/Check-out
- Chat-/Nachrichtensystem
- Foto-/Medien-Upload
- Feedback-System
- Terminal/Kiosk-Modus

### Phase 4: Plattform & Skalierung
- Plugin-System
- API fuer Dritte (authentifiziert)
- Messenger-Integrationen (Slack, Discord, WhatsApp)
- Kalender-Sync
- Payment-Integration (Stripe, PayPal)
- Live-Display (TV-Modus)
- CSV/PDF/Excel-Export
- Minispiele + AR

### Phase 5: Enterprise & Community
- Multi-Mandanten-Faehigkeit
- White-Label-Optionen
- Anomalie-Erkennung / Anti-Cheat
- Raspberry Pi Terminal
- Onboarding-Wizard + Demo-Event
- Dokumentation + Source-Available Lizenz
- Pay-per-Event Abrechnungssystem
