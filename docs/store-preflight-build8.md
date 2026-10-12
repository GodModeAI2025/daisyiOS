# App-Store-Freigabe-Check: OrbitDisk

Geprüft am 12. Oktober 2026. Swift/SwiftUI, iOS und iPadOS 27. Grundlage: [Appstore-Review](https://github.com/GodModeAI2025/Appstore-Review), Guideline-Fassung 8. Juni 2026. Prüfumfang: fokussierter Quell-/Konfigurationsscan, Privacy Manifest, aktuelle Store-Metadaten, Simulator-Linkprüfung und native Store-Aufnahmen. Keine vollständige physische Cloud-/USB-Geräteprüfung oder rechtliche Begutachtung.

## 1. Freigabe-Ampel

Einreichbar nach Behebung der offenen Erklärungen. Noch keine Einreichungsfreigabe bestätigt: Datenschutzveröffentlichung, Inhaltsrechte und der vom Eigentümer angekündigte Datenschutzseiten-Inhalt sind offen.

## 2. Kritische und hohe Befunde

### Datenschutz in der App — behoben in Build 8, Guideline 5.1.1(i)

Der Prüfer braucht einen dauerhaft erreichbaren Datenschutzlink. `Sources/daisyiOS/Views/ScanPickerView.swift` zeigt jetzt die vom Eigentümer vorgegebene Datenschutzerklärung und einen Supportkontakt im Einstieg. Helle/dunkle Ansicht und AX5 sind geprüft. Safari öffnet die richtige Domain; der vollständige URL-Pfad war im Simulator nicht live lesbar. Aufwand: erledigt. Die Veröffentlichung des OrbitDisk-Inhalts der Webseite liegt beim Eigentümer.

### Datei-Zeitstempel im Privacy Manifest — behoben in Build 8, Required-Reason-API

Die Duplikatprüfung liest Änderungen an ausgewählten Dateien (`Sources/daisyiOS/Services/DuplicateEngine.swift:65`). `Sources/daisyiOS/Resources/PrivacyInfo.xcprivacy` deklariert jetzt FileTimestamp mit 3B52.1 für nutzergewählte Verzeichnisse. Der Code verarbeitet diese Daten lokal. [Apple-Dokumentation](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype). Der erneute Rohscan meldet keine undeklarierte API-Kategorie. Build und signiertes Archiv erfolgreich.

## 3. Mittlere Befunde und Hinweise

| Punkt | Guideline | Stand |
|---|---|---|
| Alte Store-Bilder zeigen entfernte Tabs | 2.3.3 | Durch vier aktuelle native iPhone-/iPad-Aufnahmen ersetzt; Portal je zwei Bilder bestätigt |
| „Segment“ im Rohscan | 5.1.2 | Fehlalarm: RingSegment/Diagrammcode, kein Analytics-SDK; keine Tracking-Abfrage nötig |
| Inhaltsrechte und Privacy-Veröffentlichung | 5.1, 5.2 | Konkrete Eigentümerbestätigung angefragt; automatische Freigabeprüfung blockiert die Einreichung bis dahin |
| Physische Dateianbieter | 2.1 | Reale Cloud-/USB-Anbieter weiterhin separat prüfen; lokale Dateien sind für Review ausreichend |

## 4. Was bereits gut gelöst ist

- Native Ordnerauswahl und ausdrückliche Verzeichnisfreigabe (2.5.15).
- Keine Konten, Werbe-/Analytics-SDKs, In-App-Käufe oder eigene Inhaltsübertragung gefunden (4.8, 5.1, 3.1).
- Kostenpflichtiger Download über App Store Connect mit 0,99 EUR Basispreis; keine zusätzliche Paywall.
- Bestätigtes Löschen mit Pfadschutz, Abbruch und Hintergrundverarbeitung.
- Aktuelle Review-Notizen erklären Ordnerauswahl, Navigation, Aufräumfunde und Duplikate.

## 5. Offene Fragen an den Eigentümer

- Welche konkrete Inhaltsrechte-Erklärung soll gespeichert werden? Der automatische Prüfer verlangt eine spezifische Einordnung der möglichen Dateien fremder Herkunft (5.2).
- Darf „Keine Daten erfasst“ mit Apples Richtigkeits-, Gesetzeskonformitäts- und Aktualisierungsbestätigung veröffentlicht werden (5.1)?
- Ist der angekündigte OrbitDisk-Inhalt auf der Datenschutzseite fertig (5.1.1(i))?

## 6. Einreichungs-Checkliste

- Erfüllt: aktueller Build 8 im Portal gespeichert, intern „Im Test“; Xcode-MCP-Build/Archiv/Upload erfolgreich.
- Erfüllt: Dienstprogramme, aktuelle Beschreibung, Review-Anleitung, Kontakt, kein Demo-Login erforderlich.
- Erfüllt: Altersfragebogen, 4+ mit regionalen Entsprechungen; weltweite Verfügbarkeit für 175 Länder/Regionen.
- Erfüllt: Preisbasis Deutschland 0,99 EUR; entsprechende lokale Preise durch Apple.
- Erfüllt: aktuelle native Store-Bilder für iPhone und iPad, fiktive Dateien, RGB ohne Alpha.
- Erfüllt: Datenschutz-URL im Portal und in der App; Privacy Manifest, lokaler Rohscan ohne reale Tracking-SDKs.
- Offen: Inhaltsrechte und Veröffentlichung der Privacy-Antwort; Website-Inhalt durch Eigentümer.
- Nicht bestätigt: App-Review-Einreichung, Apple-Genehmigung, öffentliche Veröffentlichung.

## 7. Review-Notizen

Aktuelle englische Anleitung ist in `release/app-store/de-DE/review_notes.txt` und App Store Connect gespeichert. Keine Demo-Zugangsdaten nötig. Veröffentlichung bleibt manuell.
