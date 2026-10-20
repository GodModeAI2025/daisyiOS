# OrbitDisk macOS Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** Native OrbitDisk-Mac-App mit optimierter Bedienung als zusätzliche Plattform desselben Store-Produkts ausliefern.

**Architecture:** Ein macOS-Target nutzt die bestehenden Modelle und Analyse-/Löschdienste. Eine Mac-Fensteransicht verwaltet ihre eigene Analyse und Navigation; wiederverwendbare Anzeigeelemente erhalten nur notwendige Plattformanpassungen. AppKit übernimmt Dateiauswahl und Finder-Anzeige, SwiftUI das Layout und Quick Look.

**Tech Stack:** Swift 6, SwiftUI, Foundation, AppKit, QuickLook, CryptoKit, XcodeGen, Xcode MCP, XCTest.

**Spec:** `docs/superpowers/specs/2026-10-20-orbitdisk-macos-design.md`

## Global Constraints

- Native macOS-App ab macOS 27; iOS/iPadOS ab iOS 27 weiter unterstützen.
- Bestehender App-Store-Eintrag 6821645213 als Universal Purchase, Preisbasis 0,99 EUR Deutschland, weltweite Verfügbarkeit.
- App Sandbox, benutzerfreigegebener Lese-/Schreibzugriff und Security-Scoped Bookmarks; kein Full Disk Access.
- Keine feste Dateigrenze, keine automatische Löschung; vorhandene Löschschutz- und Inhaltsprüfungen behalten.
- Keine Drittanbieter-SDKs, Konten, Telemetrie, Cloud-Dienste oder GitHub-Workflows.
- Manuelle Veröffentlichung behalten; bestehenden iOS-Release nicht ersetzen.

## Review Focus

1. Widerrufener Ordnerzugriff nach Neustart: verständliche erneute Auswahl statt stiller leerer Analyse (Task 1).
2. Zwei Fenster analysieren unterschiedliche Ordner: Fortschritt und Navigation bleiben unabhängig (Task 2).
3. Lange Dateinamen und kleines Fenster: Größe und Aktionen bleiben erreichbar (Task 2).
4. Entfernte/synchronisierte Dateien während Vorschau oder Löschen: Fehler anzeigen, keine falschen Erfolgsmeldungen (Task 3).
5. Fehlgeschlagene Mac-Store-Zuordnung: kein zweiter Kauf und keine Änderung der iOS-Einreichung (Task 4).

## Dateiaufteilung

- `project.yml`: Mac-App- und Test-Target, gemeinsame Swift-Modulbezeichnung `daisyiOS` für vorhandene Tests, Plattformquellen und Schemes.
- `Sources/daisyiOS/Services/AccessStore.swift`: bedingte macOS-Bookmark-Optionen, bestehende öffentliche Schnittstellen bleiben.
- `Sources/daisyiOS/Views/ScanPickerView.swift`: `ScanModel` in eigene gemeinsame Datei `Views/ScanModel.swift` verschieben, iOS-Einstieg unverändert weiterverwenden.
- `Sources/daisyiOS/daisyiOSApp.swift`, `Views/RootView.swift`: Plattform-Einstieg, Fenstergröße und Cmd-O.
- Neu `Sources/daisyiOS/Views/MacRootView.swift`: Seitenleiste, laufende Analyse, pro Fenster gewähltes Ergebnis.
- Neu `Sources/daisyiOS/Views/MacFolderView.swift`: Ordnerpfad, Orb/Liste, Navigation, Suche und Inspektor.
- `Views/FolderDetailView.swift`: gemeinsam genutzte FileActionPanel/FolderContents plattformfähig halten; Navigation erhält optionalen Mac-Callback statt iOS-Zielansicht.
- `Views/LocationBrowser.swift`, `Views/CosmicStyle.swift`: UIKit-Grenzen bzw. native Farbwerte.
- Neu `Resources/OrbitDisk-macOS.entitlements`, Mac-Icon-Asset; bestehendes Privacy Manifest weiterverwenden.
- Neu `Sources/daisyiOSTests/AccessStoreTests.swift`, Mac-UI-Prüfprotokoll unter `docs/`; bestehende Dienste-Tests wiederverwenden.
- `release/store-submission.md`, `release/README.md`, `docs/privacy/de.md`, `docs/privacy/en.md`: tatsächlichen Mac-Stand und Unterschiede dokumentieren.

### Task 1: Native Mac-Build und persistenter Ordnerzugriff

**Interfaces:** Bestehend `AccessStore.add(name: String, url: URL) throws`, `url(for: Folder) throws -> URL`, `ScanModel.scanFolder(_ url: URL)`, `cancel()` bleiben identisch. Jeder MacRootView besitzt eine eigene ScanModel-Instanz.

- [ ] Xcode/SDK und Workspace per Xcode MCP neu ermitteln; Git-Worktree-Skill verwenden, isolierte Implementierungsbranch anlegen und Spec/Plan dorthin übernehmen.
- [ ] `AccessStoreTests.testSavedFolderReopens`, `testSameFolderIsNotDuplicated`, `testInvalidBookmarkThrows` mit isolierten UserDefaults schreiben: gespeicherte URL stimmt, derselbe Ordner steht einmal in folders, beschädigte Bookmark wirft Fehler. Auf iOS ausführen, anschließend Mac-Target-Testlauf als initial fehlende Plattform nachweisen.
- [ ] Mac-App-/Test-Target und Scheme `OrbitDiskMac` ergänzen, Deployment Target 27.0; bestehende Sources teilen und iOS-only Einstieg per Plattformbedingung ausschließen. ScanModel unverändert extrahieren. macOS-Bookmark-Erzeugung und Auflösung mit `.withSecurityScope`, Sandbox user-selected read/write und app-scoped bookmarks konfigurieren. Stale-Bookmark-Erneuerung muss dieselben Optionen verwenden.
- [ ] UI-Plattformblocker gezielt isolieren: UIKit-DocumentPicker nur iOS; Farben via native macOS-Systemfarben; iOS-Navigationsmodifikatoren nicht im Mac-Target kompilieren. Bestehende iOS-QuickLook-Abfrage für Mac durch native verfügbare Preview-Unterstützung ersetzen.
- [ ] `xcodegen generate`; `xcodebuild -scheme OrbitDiskMac -destination 'platform=macOS' build test` und iOS-Simulator-Build mit tatsächlich installiertem Simulator ausführen. PASS: Builds erfolgreich, Bookmark- und bestehende Dienstetests grün. Widerruf/Zugriff nach Neustart zusätzlich mit Sandbox-App manuell prüfen; Einschränkungen explizit dokumentieren.
- [ ] Geprüfte Plattform-/Zugriffsänderungen committen.

### Task 2: Anpassbares Mac-Fenster und Ordnernavigation

**Interfaces:** `MacRootView: View` besitzt `@State ScanModel`; `MacFolderView(result: ScanResult)` hält pro Fenster Pfad, ausgewählte Datei und BatchSelection. `FolderContents` bekommt optional `onOpenFolder: ((FileNode) -> Void)?`; ohne Callback bleibt bestehende iOS-Navigation bestehen.

- [ ] Vor UI-Code die Skills apple-hig, swiftui-specialist und app-resizability lesen. Native Ordnerauswahl als SwiftUI fileImporter mit folder content type; Cmd-O über fensterbezogene FocusedValues-Aktion an dieselbe Auswahl binden.
- [ ] UI-Abnahmeszenarien vor Implementierung festhalten: zwei Fenster mit verschiedenen Testordnern, Navigation via Orb/Zeile/Zurück, Dateiselektion, Suche+Filter+Sortierung; bei 900×650 und 1400×900 keine verdeckten Aktionen, sehr langer Name bleibt lesbar.
- [ ] MacRootView mit NavigationSplitView und zuletzt freigegebenen Ordnern implementieren. MacFolderView zeigt Pfad/Zurück, ViewThatFits für Orb/Liste und ausblendbaren Inspektor. Mindestfenster 900×650, Standard 1200×800. Für aktuellen Pfad immer `result.find(url)` verwenden; nach Löschung keine veralteten Knotenaktionen anbieten.
- [ ] Vorhandene SunburstChart, DirectoryListing, BatchSelectionBar und FileActionPanel nutzen; FileActionPanel für Mac-Ordnernavigation optionalen Callback geben. Root-Auswahl und Abbruch zeigen bestehende Fortschrittswerte und Fehlermeldungen.
- [ ] Mac-App starten und die vorab festgelegten Szenarien prüfen; hell/dunkel, Reduce Motion, Tastaturfokus und VoiceOver-Beschriftungen ergänzend prüfen. Geräte-/UI-Prüfungen gemäß device-interaction-Skill delegieren, falls dieser es verlangt. Screenshots und tatsächliche Ergebnisse sichern.
- [ ] iOS-Build und DirectoryListing-/Sunburst-Tests erneut prüfen; nur bei grünem Ergebnis committen.

### Task 3: Finder, Quick Look und sichere Dateiaktionen

**Interfaces:** FileActionPanel behält `node: FileNode`, `result: ScanResult`, `onDelete: () -> Void`. Mac-Reveal nutzt `NSWorkspace.shared.activateFileViewerSelecting([node.url])`; die bestehende `ScanResult.delete(_:)`-Schnittstelle und DuplicateEngine bleiben unverändert.

- [ ] Vor Änderung vorhandene FileDeletionTests/DuplicateEngineTests prüfen und nur fehlende Fälle ergänzen: bereits entfernte Datei meldet Fehlschlag; veränderte Duplikatkopie wird nicht gelöscht. Tests ausführen und fehlende Absicherung vor Fix reproduzieren.
- [ ] „Im Finder zeigen“, unterstützte Quick-Look-Vorschau und gleichlautende Kontextmenüaktionen ergänzen. Vorhandene Bestätigungen behalten; keinen Papierkorb oder Undo versprechen, solange vorhandene endgültige Löschung verwendet wird. Sichtbaren Dateipfad im Inspektor ergänzen.
- [ ] CleanupView und DuplicateView im Mac-Navigationskontext öffnen; gemeinsame Batch-Auswahl und Löschmeldungen weiterverwenden. Root-/Link-/Inhaltsprüfungen nicht lockern.
- [ ] Ausschließlich temporäre Testdaten verwenden: Finder zeigt richtige Datei, Preview öffnet und schließt, Abbrechen löscht nichts, bestätigte Löschung aktualisiert Liste/Orb, entfernte Datei verursacht verständlichen Fehler. Dateinamen mit Leerzeichen und Unicode mitprüfen.
- [ ] Beide Plattformen bauen, relevante Tests grün nachweisen und Dateiaktionen committen.

### Task 4: Gemeinsamer Store-Eintrag und Mac-Auslieferung

**Interfaces:** Bestehender ASC-Eintrag 6821645213 und Team SP73Z8JWXM. Keine zweite App anlegen; endgültige Mac-Bundle-ID anhand erlaubter Universal-Purchase-Konfiguration im Portal verifizieren, bevor signiert hochgeladen wird.

- [ ] Aktuellen iOS-Review-/Veröffentlichungsstand und verfügbare Mac-Plattform im bestehenden Portal lesen. Wenn Zuordnung nicht möglich ist, konkrete Apple-Blockade berichten; keine separate kostenpflichtige App als Ersatz anlegen.
- [ ] Mac-App-Icon, Signierung und Release-Konfiguration vervollständigen; Privacy Manifest und DE/EN-Datenschutztexte auf tatsächlichen Mac-Zugriff/Finder anpassen, keine Website-Aktualisierung behaupten. Info.plist enthält korrekte Exportangabe für CryptoKit-Hashing ohne eigene Verschlüsselung.
- [ ] Mac-Release archivieren und validieren: `xcodebuild -scheme OrbitDiskMac -destination 'generic/platform=macOS' -configuration Release archive -archivePath <isolierter Artefaktpfad>`; Export/Upload mit aktueller offizieller Xcode-Konfiguration, keine Credential-Extraktion.
- [ ] Verarbeitung und Buildnummer im Mac-Store-Eintrag nachweisen. Native Mac-Screenshots mit ausschließlich synthetischen Dateien aufnehmen, Metadaten und Review-Anleitung für Finder/Ordnerfreigaben ergänzen. Preisbasis und weltweite Verfügbarkeit unverändert prüfen.
- [ ] Mac zur Prüfung übermitteln, soweit keine neue rechtlich bindende Bestätigung nötig ist. Tatsächlichen Status und Submission-ID zurücklesen; iOS-Status und manuelle Veröffentlichung erneut prüfen. Keine öffentliche Verfügbarkeit aus Upload oder Review ableiten.
- [ ] Release-Dokumentation mit überprüften Ergebnissen aktualisieren. Vollständigen Diff auf Sicherheits-/iOS-Regressionsrisiken prüfen, abschließende Review gemäß gewähltem Ausführungsweg durchführen, dann committen/pushen und nach Branch-Finishing-Skill integrieren.
