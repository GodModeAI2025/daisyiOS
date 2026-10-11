# daisyiOS

Native Speicheranalyse für iPhone und iPad, ausschließlich ab iOS 27.

## Funktionen

- Gerätespeicher: Gesamtgröße, Belegung, aktuell freier Speicher und die vom System geschätzte verfügbare Kapazität für wichtige Daten.
- Analyse der eigenen App-Daten oder eines über Dateien freigegebenen Ordners (Gerät, iCloud Drive, externe Laufwerke und unterstützte Dateianbieter).
- Sunburst mit drei Ebenen, animierter Hervorhebung und einem direkten Aktionspanel für den ausgewählten Bereich; Ordnernavigation, Suche und nach Größe sortierte Einträge.
- Quick Look für unterstützte Dateien; „In Dateien anzeigen“ öffnet den nativen Dateien-Browser mit dem aktuellen Ordner als Startort. Der Dateianbieter kann diesen Startort ignorieren. Eigene Dokumente sind in Dateien sichtbar; interne App-Verzeichnisse öffnen stattdessen den Dokumente-Bereich.
- Dateien und Ordner nach ausdrücklicher Sicherheitsabfrage löschen. Listen, Diagramm und übergeordnete Größen aktualisieren sich gemeinsam. Der Analyseordner selbst und interne App-Einstellungen sind geschützt; Löschaktionen bleiben innerhalb des freigegebenen Bereichs. Bei Cloud-Dateien kann Löschen andere Geräte betreffen.
- Zuletzt analysierte Ordner über lokal gespeicherte Bookmarks erneut öffnen; neuer Startpunkt über „Ordner oder Datenträger wählen“.
- Abbrechbarer Scan mit monotonen Fortschrittszählern und ohne Verfolgung symbolischer Verzeichnislinks.
- Futuristische Oberfläche mit Lichtverläufen, leuchtenden Ringen und sanfter Auswahlanimation. Native SwiftUI-Navigation und Tab-Leiste, adaptive Systemfarben, Dynamic Type, textuelle Alternative zum Diagramm, Rücksicht auf „Bewegung reduzieren“ und eigenes App-Icon.

Die Analyse überträgt keine Daten. iOS erlaubt keinen vollständigen Scan anderer Apps oder des Geräts. Systemkapazitäten sind Schätzungen und können von der Anzeige in Einstellungen abweichen. Cloud-Dateien können durch den Dateianbieter geladen werden. Ordnerzugriffe können ablaufen; dann erneut auswählen.

## Build

Xcode 27 mit iOS-27-SDK und XcodeGen:

```sh
xcodegen generate
open daisyiOS.xcodeproj
```

Scheme: `daisyiOS`. Mindestversion: `27.0`, Gerätefamilien: iPhone und iPad.

## Validierung

Am 11. Oktober 2026 mit Xcode 27.0 über Xcode-MCP gebaut und im iOS-27-Simulator gestartet. Vierzehn Unit-Tests bestehen, einschließlich Größenaggregation, leerer und fehlender Ordner, monotoner Fortschritt bei tiefen Verzeichnisstrukturen, Diagrammanteile, tatsächliches Löschen, Schutz vor Pfadausbrüchen und Symlinks sowie die Aktualisierung der Größen und Dateizähler. Der Fortschritts-Regressionsfall wurde vor der Korrektur rot und danach grün ausgeführt.

Speicherübersicht, Analyse-Tab, Scan eigener Daten, Ergebnisnavigation und Auswahl eines Sunburst-Bereichs wurden im Simulator geprüft. Die Xcode-MCP-Geräteinteraktion meldete widersprüchlich „Session not found“ und ein belegtes Gerät; die Bedienprüfung erfolgte deshalb über Device Hub und Simulator-Screenshots. Quick Look, Dateien-Browser, animierte Auswahl sowie Abbrechen und Bestätigen der Löschabfrage sind mit eigenen Testdateien geprüft. Tatsächliches Löschen und die Aktualisierung der übergeordneten Größen wurden zusätzlich per Dateisystem-Rückprüfung bestätigt.

Dark Mode und die größte Accessibility-Schrift wurden visuell geprüft; das Aktionspanel bleibt scrollbar. Die Simulatorprüfung ersetzt keine Prüfung auf einem physischen Gerät mit realen Cloud-/USB-Dateianbietern. Signierung, TestFlight und App-Store-Veröffentlichung sind noch offen.

## Weiterentwicklung

- Inkrementelle Rescans und Cache
- Fotoanalyse
- Englische Übersetzung und vollständige Accessibility-Prüfung
- Geräteprüfung und App-Store-Vorbereitung

## Lizenz

Noch nicht festgelegt.
