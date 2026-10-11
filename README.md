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

## Navigation und Ordnerwerkzeuge

Ordnersegmente im Orb öffnen direkt ihre Unterordner; die Orb-Mitte führt zur vorherigen Ansicht zurück. Auch die ganze Ordnerzeile öffnet ihren Inhalt, während „Ordneraktionen anzeigen“ die Dateiaktionen einblendet. Die Liste gruppiert Ordner vor Dateien, mit Filtern für alle Einträge/Ordner/Dateien sowie Größe und Name als Sortierung.

„Ordner prüfen“ bietet rekursive Aufräumkandidaten und einen inhaltsbasierten Duplikatfinder mit auswählbarer Kopie zum Behalten und bestätigter Entfernung. Regeln und Prüfverhalten stehen in [docs/cleanup-and-duplicates.md](docs/cleanup-and-duplicates.md).

## Build

Xcode 27 mit iOS-27-SDK und XcodeGen:

```sh
xcodegen generate
open daisyiOS.xcodeproj
```

Scheme: `daisyiOS`. Mindestversion: `27.0`, Gerätefamilien: iPhone und iPad.

## Validierung

Am 11. Oktober 2026 mit Xcode 27 über Xcode-MCP gebaut. 27 Tests bestehen, einschließlich rekursiver Kandidaten, vollständiger Inhaltsduplikate, Hardlink-Schutz, Schutz bei geändertem Keeper, gebündelter Entfernung und Ordner-/Filtersortierung. Weitere Fälle: Größenaggregation, 5.000 Dateien ohne Verlust, Fortschritt, Abbruch, Diagramm mit 10.000 Einträgen ohne 10.000 SwiftUI-Segmente sowie Lösch- und Pfadschutz. Die Testzahlen sind keine Dateigrenzen.

Der neue Einstieg, die native Ordnerauswahl, ein vollständiger Scan mit 200.000 Dateien und 200 Unterordnern, die sichtbare Ladeanzeige während des Scans und ein tatsächlich bedienbarer Abbruch wurden auf einem isolierten iOS-27-Simulator geprüft. Screenshots liegen unter `screenshots/feedback-*.png`. Die 200.000 Dateien sind eine Testmenge, keine Grenze. Nicht lesbare Provider-Inhalte werden ausdrücklich gemeldet; reale Cloud-/USB-Anbieter brauchen weiterhin Geräteprüfung.

Version 1.0 (4) steht in TestFlight für die interne Gruppe „Mark – Intern“ auf „Im Test“. Build 3 enthält den direkten Einstieg ohne Tab-Leiste und App-Container-Auswahl sowie den überarbeiteten Scan. Die Upload- und Simulatornachweise werden in `release/status.json` lokal festgehalten. Eine Simulatorprüfung ersetzt keine Prüfung mit realen Cloud-/USB-Dateianbietern. App-Review ist wegen offener Pflichtangaben noch nicht eingereicht; Veröffentlichung bleibt manuell.

Für Build 4 sind Orb-Navigation und Zurück-Funktion, vollflächige Ordnerzeilen, Ordnergruppierung, Filter und Sortierung sowie Kandidaten- und Duplikat-Menüs im isolierten Simulator geprüft. Die Kopie zum Behalten und die Sicherheitsabfrage wurden bedient und abgebrochen; tatsächliche Entfernung samt Behalten und aktualisierter Dateistruktur ist durch Tests mit eigenen temporären Dateien abgesichert.

## Weiterentwicklung

- Inkrementelle Rescans und Cache
- Fotoanalyse
- Englische Übersetzung und vollständige Accessibility-Prüfung
- Geräteprüfung und App-Store-Vorbereitung

## Lizenz

Noch nicht festgelegt.
