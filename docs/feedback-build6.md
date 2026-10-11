# Feedback zu Build 5

Die neue Rückmeldung aus App Store Connect bemängelt „Ordneraktionen anzeigen“ als falsche Beschriftung und den Button als zu groß.

## Umsetzung

Die wiederholte breite Aktionszeile unter jedem Eintrag entfällt. Bei Ordnern öffnet „Details“ als kompakte Texttaste direkt neben der navigierbaren Zeile die Detailansicht mit Größe, Speicherort und verfügbaren Aktionen. Die Ordnerzeile öffnet weiterhin den Inhalt; Dateizeilen öffnen ihre Details direkt und benötigen keinen zweiten Button. Bei Bedienungshilfen-Schriftgrößen steht die kompakte Details-Taste unter der Ordnerzeile, damit lange Namen ausreichend Breite erhalten. Die Berührungsfläche der Details-Taste bleibt mindestens 44 Punkte hoch. VoiceOver benennt den betroffenen Ordner und erklärt die Funktion. Mehrfachauswahl bleibt erhalten.

Originale Feedback-Screenshots mit echten Dateinamen werden nicht im Repository gespeichert.

## Prüfung

Xcode-MCP-Build und signiertes Archiv erfolgreich. Die Simulatorprüfung bestätigt die richtige Detailansicht und kompakte Darstellung bei normalen und maximalen Bedienungshilfen-Schriftgrößen. Bei großer Schrift bleibt die Taste einzeilig unter dem Eintrag; die Liste bleibt scrollbar. Synthetische Nachweise unter `screenshots/feedback-build6-*.png`. Neue Crash-Rückmeldungen lagen nicht vor.
