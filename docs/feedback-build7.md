# Präzisierung zur Ordnerliste

Die Rückmeldung zum Screenshot aus Build 6 fordert Filter und Sortierung nebeneinander, das Entfernen der Details-Taste sowie rechts eine erkennbare Navigation zur tieferen Analyseebene.

## Umsetzung

- Zwei Optionsfelder stehen in einer gemeinsamen horizontalen Zeile. Symbol und Titel bilden einen kompakten Kopf, der aktuelle Wert steht darunter. Nur bei großen Bedienungshilfen-Schriftgrößen stehen beide Felder auf voller Breite untereinander, um extreme Wortumbrüche zu vermeiden.
- Die zusätzliche Details-Taste entfällt vollständig.
- Der Ordnername und die Größe erhalten die volle Zeilenbreite. Rechts darunter zeigt „Tiefer analysieren“ mit Vorwärtspfeil die Navigation. Die gesamte Ordnerzeile öffnet die Analyse dieses Ordners; Zurück führt zur vorherigen Ebene.
- Dateizeilen öffnen weiterhin die Dateivorschau und Aktionen. Mehrfachauswahl und die Aktionen des aktuell analysierten Ordners bleiben verfügbar.

Die reale Screenshot-Datei mit privaten Dateinamen wird nicht im Repository gespeichert.

## Prüfung

Xcode-MCP-Build und signiertes Archiv bestanden. Im isolierten Simulator stehen beide Optionsfelder bei normaler Schrift nebeneinander; lange Ordnernamen bleiben lesbar. Die Ordnerzeile öffnet die richtige Analyseebene, Zurück führt zum Ausgangsordner. Bei maximaler Bedienungshilfen-Schrift bleiben die Optionswerte auf voller Breite lesbar. Synthetische Nachweise unter `screenshots/feedback-build7-*.png`.
