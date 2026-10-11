# OrbitDisk

Native Speicheranalyse für iPhone und iPad, ausschließlich ab iOS 27.

## Funktionen

- Direkter Einstieg mit Auswahl eines über Dateien freigegebenen Ordners (Gerät, iCloud Drive, externe Laufwerke und unterstützte Dateianbieter).
- Sunburst mit drei Ebenen, animierter Hervorhebung und einem direkten Aktionspanel für den ausgewählten Bereich; Ordnernavigation, Suche und nach Größe sortierte Einträge.
- Quick Look für unterstützte Dateien; „In Dateien anzeigen“ öffnet den nativen Dateien-Browser mit dem aktuellen Ordner als Startort. Der Dateianbieter kann diesen Startort ignorieren. Eigene Dokumente sind in Dateien sichtbar; interne App-Verzeichnisse öffnen stattdessen den Dokumente-Bereich.
- Dateien und Ordner nach ausdrücklicher Sicherheitsabfrage löschen. Listen, Diagramm und übergeordnete Größen aktualisieren sich gemeinsam. Der Analyseordner selbst und interne App-Einstellungen sind geschützt; Löschaktionen bleiben innerhalb des freigegebenen Bereichs. Bei Cloud-Dateien kann Löschen andere Geräte betreffen.
- Zuletzt analysierte Ordner über lokal gespeicherte Bookmarks erneut öffnen; neuer Startpunkt über „Ordner oder Datenträger wählen“.
- Scan ohne feste Dateigrenze, mit animierter Ladeanzeige, Laufzeit, sichtbaren Lesefehlern und sofort bedienbarem Abbruch. Scan und Diagrammaufbereitung laufen außerhalb des UI-Threads; winzige Diagrammsegmente werden neutral dargestellt, während die Dateiliste alle lesbaren Einträge enthält.
- Abbrechbarer Scan mit monotonen Fortschrittszählern und ohne Verfolgung symbolischer Verzeichnislinks.
- Futuristische Oberfläche mit Lichtverläufen, leuchtenden Ringen und sanfter Auswahlanimation. Native SwiftUI-Navigation ohne Tab-Wechsel, adaptive Systemfarben, Dynamic Type, textuelle Alternative zum Diagramm, Rücksicht auf „Bewegung reduzieren“ und eigenes App-Icon.

Die Analyse überträgt keine Daten. iOS erlaubt keinen vollständigen Scan anderer Apps oder des Geräts. Systemkapazitäten sind Schätzungen und können von der Anzeige in Einstellungen abweichen. Cloud-Dateien können durch den Dateianbieter geladen werden. Ordnerzugriffe können ablaufen; dann erneut auswählen.

## Build

Xcode 27 mit iOS-27-SDK und XcodeGen:

```sh
xcodegen generate
open daisyiOS.xcodeproj
```

Scheme: `daisyiOS`. Mindestversion: `27.0`, Gerätefamilien: iPhone und iPad.

## Validierung

Am 11. Oktober 2026 mit Xcode 27 über Xcode-MCP gebaut. 17 Tests bestehen: Größenaggregation, 5.000 Dateien ohne Verlust, Fortschritt, Abbruch, Diagramm mit 10.000 Einträgen ohne 10.000 SwiftUI-Segmente sowie Lösch- und Pfadschutz. Die Testzahlen sind keine Dateigrenzen.

Version 1.0 (3) steht in TestFlight für die interne Gruppe „Mark – Intern“ auf „Im Test“. Build 3 enthält den direkten Einstieg ohne Tab-Leiste und App-Container-Auswahl sowie den überarbeiteten Scan. Die Upload- und Simulatornachweise werden in `release/status.json` lokal festgehalten. Eine Simulatorprüfung ersetzt keine Prüfung mit realen Cloud-/USB-Dateianbietern. App-Review ist wegen offener Pflichtangaben noch nicht eingereicht; Veröffentlichung bleibt manuell.

## Weiterentwicklung

- Inkrementelle Rescans und Cache
- Fotoanalyse
- Englische Übersetzung und vollständige Accessibility-Prüfung
- Geräteprüfung und App-Store-Vorbereitung

## Lizenz

Noch nicht festgelegt.
