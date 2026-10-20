# macOS 1.0 (9): bisherige Nachweise

Stand: 20. Oktober 2026. Native macOS-Erweiterung im gemeinsamen OrbitDisk-Projekt, Branch codex/orbitdisk-macos.

- Xcode 27.1, macOS SDK 27.0; Mac-Laufzeittests auf macOS 27.2.
- Xcode MCP verbunden, eigener Workspace workspace-4CB5rLtDIa. Mac BuildProject einschließlich Test-Target erfolgreich; letzter Build nach Fortschrittskorrektur erfolgreich (10.311 s).
- macOS: 32/32 Tests erfolgreich vor der abschließenden Fortschrittskorrektur, Ergebnis /private/tmp/orbitdisk-mac9/Logs/Test/Test-OrbitDiskMac-2026.10.20_19-15-52-+0200.xcresult.
- iOS: 32/32 Tests erfolgreich nach expliziter onDelete-Zuordnung, Ergebnis /private/tmp/orbitdisk-macos-baseline/Logs/Test/Test-daisyiOS-2026.10.20_19-21-43-+0200.xcresult.
- Signierter Debug-Build startet; tatsächliche Signatur enthält App Sandbox, benutzergewählten Lese-/Schreibzugriff und app-scoped bookmarks.
- Native UI: separates zweites Fenster, Ordnerauswahl und synthetisches Analyseergebnis (57 KB, 4 Dateien, 3 Ordner), Orb, Filter/Sortierung nebeneinander und Finder-Aktion sichtbar. Analyseabbruch beobachtet.
- Nutzer bestätigt laufende App und verlangt Abbruch der Tests. UI-Prüfung gestoppt, keine Fenster beendet oder neu gestartet.
- Nicht ausgeführt: abschließender Layout-Regressionstest, weitere UI-Prüfung für Drag/drop, Finder-/Quick-Look-Aufruf, Größenänderung, Bookmark-Neustart und Löschbestätigung. Kein Erfolg für diese Punkte behauptet.
- Fortschrittskorrektur: stabile Mac-Breite, reservierte Status-/Pfadzeilen, permanente Zählerzeile für nicht lesbare Einträge. Ursache aus Nutzer-Screenshot und Layoutcode nachvollzogen; neue Laufzeitverifikation auf Nutzerwunsch ausgesetzt.
- Apple bestätigt Zugriffserweiterung durch Drag/drop und persistente Security-Scoped Bookmarks: https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/EnablingAppSandbox.html
- Xcode AddEntitlement meldete den dokumentierten app-scope-Schlüssel als nicht existent. Kanonische XcodeGen-Entitlements anhand Apple-Referenz erstellt und im signierten Produkt überprüft.

Release-Archiv, Upload, Verarbeitung und Testerfreigabe werden separat dokumentiert. Ein erfolgreicher Debug-Build belegt keine TestFlight-Verfügbarkeit.

## Release bestätigt

- Finales Release-Archiv erfolgreich: /private/tmp/OrbitDisk-1.0-9.xcarchive. Version 1.0 (9), Bundle com.godmodeai.daisyiOS, Minimum macOS27, AppName OrbitDisk, AppIcon und Exportangabe vorhanden. Release-Signatur enthält genau Sandbox, user-selected read/write und app-scoped bookmarks, ohne Debug-Recht.
- Abschließender iOS-Kompilierlauf erfolgreich: /private/tmp/orbitdisk-ios-final-build.log; keine Tests neu gestartet.
- Upload per Xcode erfolgreich am20Oktober2026 um19:34Europe/Berlin (EXPORT SUCCEEDED).
- Build verarbeitet: UUID11c5eff7-aa1a-4954-9470-7df220f483f4. TestFlight-Gruppe Mark – Intern zeigt1.0(9), macOS, **Im Test**, 90Tage. Gruppe enthält bestehenden Tester mark_zimmermann@mac.com, keine neuen externen Tester.
- Mac-Beschreibung und Mac-Review-Hinweise im ASC-Entwurf gespeichert; manuelle Veröffentlichung aktiv. Keine Mac-App-Review-Einreichung oder öffentliche Mac-Verfügbarkeit behauptet. Mac-Store-Screenshots fehlen noch.
- Read-only-Codeprüfung: fehlende Ordnernavigation bei Aufräumfunden, enge Quick-Look-Typenliste und synchrone Drop-Metadatenabfrage korrigiert. Korrekturen im finalen Release-Archiv enthalten.
