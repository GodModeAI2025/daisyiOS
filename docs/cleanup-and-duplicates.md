# Aufräumkandidaten und Duplikate

Beide Aktionen stehen unter „Ordner prüfen“ in jeder Ordneransicht und beziehen sich auf diesen Ordner sowie seine Unterordner. Grundlage ist die zuletzt erfasste Dateistruktur; für neu hinzugefügte Dateien den Ordner erneut analysieren.

## Aufräumkandidaten

Nach dem Konzept des [Vorssaint-Cleaners](https://github.com/vorssaint/vorssaint-utils/tree/main/Sources/Vorssaint/Services/Cleaner) werden Namen und Speicherorte auf temporäre Daten, Logs, Diagnoseberichte, Caches, erzeugte Build-Daten und unvollständige Downloads geprüft. Jeder Vorschlag zeigt Kategorie, Grund, relativen Pfad und Größe. Es gibt keine Vorauswahl und kein automatisches Löschen. Backups, Fotomediatheken, Versionsverwaltung und erkannte System-/Authentifizierungsdaten werden ausgelassen; ein Elternordner mit geschützten Inhalten wird nicht als Ganzes angeboten. Kandidaten sind Hinweise, keine Garantie, dass ihre Inhalte entbehrlich sind. Vorhandene Vorschau, Speicherort und bestätigte Löschaktion stehen beim Prüfen zur Verfügung.

## Duplikate

Das Größenfilter-/Streaming-Hash-Konzept von [Swift Duplicate Finder](https://github.com/arraypress/swift-duplicate-finder) wurde als eigene iOS-Anpassung umgesetzt. Die App verwendet ausschließlich Foundation und Apples CryptoKit, ohne zusätzliche Paketabhängigkeit. Nach Größenvergleich wird jede mögliche Kopie vollständig mit SHA-256 gelesen. Unvollständige Lesevorgänge oder währenddessen veränderte Dateien werden gemeldet. Leere Dateien, Links und bewusst duplizierte Versions-/Paket-/Build-/Cache-Bereiche werden ausgelassen. Es gibt keine feste Dateigrenze.

Pro Gruppe wählt der Nutzer eine Kopie zum Behalten. Erst eine ausdrückliche Bestätigung startet die Entfernung der anderen Kopien. Unmittelbar vor jeder Entfernung werden unter Dateikoordination beide Inhalte und Dateimetadaten erneut geprüft. Die erhaltene Kopie lässt sich in dieser Ansicht nicht individuell löschen. Weitere Entfernungen können gestoppt werden; bereits entfernte Dateien bleiben entfernt. Die Dateistruktur wird nach der Aktion im Hintergrund gesammelt aktualisiert.
