# daisyiOS

Native Speicheranalyse für iPhone und iPad, ausschließlich ab iOS 27.

## Funktionen

- Gerätespeicher: Gesamtgröße, Belegung, aktuell freier Speicher und die vom System geschätzte verfügbare Kapazität für wichtige Daten.
- Analyse der eigenen App-Daten oder eines über Dateien freigegebenen Ordners (Gerät, iCloud Drive, externe Laufwerke und unterstützte Dateianbieter).
- Sunburst mit drei Ebenen und Auswahl des angetippten Bereichs; Ordnernavigation, Suche und nach Größe sortierte Einträge.
- Dateivorschau mit Quick Look; zuletzt analysierte Ordner über lokal gespeicherte Bookmarks erneut öffnen.
- Abbrechbarer Scan mit monotonen Fortschrittszählern und ohne Verfolgung symbolischer Verzeichnislinks.
- Native SwiftUI-Navigation und Tab-Leiste, Systemfarben, Dynamic Type, zugängliche textuelle Alternative zum Diagramm und eigenes App-Icon.

Die Analyse überträgt keine Daten. iOS erlaubt keinen vollständigen Scan anderer Apps oder des Geräts. Systemkapazitäten sind Schätzungen und können von der Anzeige in Einstellungen abweichen. Cloud-Dateien können durch den Dateianbieter geladen werden. Ordnerzugriffe können ablaufen; dann erneut auswählen.

## Build

Xcode 27 mit iOS-27-SDK und XcodeGen:

```sh
xcodegen generate
open daisyiOS.xcodeproj
```

Scheme: `daisyiOS`. Mindestversion: `27.0`, Gerätefamilien: iPhone und iPad.

## Validierung

Am 11. Oktober 2026 mit Xcode 27.0 über Xcode-MCP gebaut und im iOS-27-Simulator gestartet. Sieben Unit-Tests bestehen, einschließlich Größenaggregation, leerer und fehlender Ordner, monotoner Fortschritt bei tiefen Verzeichnisstrukturen und Diagrammanteile. Der Fortschritts-Regressionsfall wurde vor der Korrektur rot und danach grün ausgeführt.

Speicherübersicht, Analyse-Tab, Scan eigener Daten, Ergebnisnavigation und Auswahl eines Sunburst-Bereichs wurden im Simulator geprüft. Die Xcode-MCP-Geräteinteraktion meldete widersprüchlich „Session not found“ und ein belegtes Gerät; die Bedienprüfung erfolgte deshalb über Device Hub und Simulator-Screenshots. Dark Mode, große Schrift und externe Ordner sind noch nicht interaktiv geprüft.

Die Simulatorprüfung ersetzt keine Prüfung mit realen Cloud-/USB-Dateianbietern und keinem physischen Gerät. Signierung, TestFlight und App-Store-Veröffentlichung sind noch offen.

## Weiterentwicklung

- Inkrementelle Rescans und Cache
- Fotoanalyse und sichere Löschfunktionen
- Englische Übersetzung und vollständige Accessibility-Prüfung
- Geräteprüfung und App-Store-Vorbereitung

## Lizenz

Noch nicht festgelegt.
