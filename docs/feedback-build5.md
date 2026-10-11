# Feedback zu Build 4

Die beiden aktuellen Screenshot-Rückmeldungen in App Store Connect betrafen das uneinheitliche Button-Design und fehlende Mehrfachauswahl mit anschließender Entfernung bzw. Auswahl aller Aufräumfunde. Für OrbitDisk lag kein Crash-Feedback vor.

## Umsetzung

- Einheitliche breite Aktionszeilen mit abgerundeten Ecken und klarer Beschriftung; Filter/Sortierung als zusammengehörige Optionszeilen. Ein nicht löschbarer Analyseordner zeigt keine funktionslose Löschschaltfläche.
- Aufräumkandidaten: „Funde auswählen“, einzelne Checkboxen, „Alle Funde auswählen“, „Auswahl aufheben“ und eine feste untere Leiste mit Anzahl, Größe und „Auswahl löschen“.
- Dateiliste: gleicher Auswahlablauf, inklusive Auswahl aller sichtbaren Einträge bzw. aller aktuellen Such-/Filtertreffer.
- Entfernung ausschließlich nach expliziter gemeinsamer Bestätigung. Ausgewählte Ordner umfassen ihren Inhalt. Überlappende Eltern-/Kind-Auswahlen werden zusammengefasst; Pfad-/Wurzelschutz bleibt aktiv. Weitere Löschungen sind stoppbar, bereits entfernte Einträge bleiben entfernt.
- Verarbeitung und gemeinsame Aktualisierung der Dateistruktur im Hintergrund. Keine feste Dateigrenze.

Originale Feedback-Screenshots mit echten Dateinamen werden nicht im Code-Repository gespeichert. Die UI-Nachweise entstehen mit eigenen Simulator-Testdaten.

## Validierung und Auslieferung

30 Tests bestanden, einschließlich Auswahl-Normalisierung und tatsächlicher Entfernung ausschließlich ausgewählter temporärer Dateien. Im isolierten Simulator sind Aufräum-Auswahl, alle Funde, Auswahl aufheben, gefilterte Treffer und Abbrechen der Bestätigung geprüft. Helle/dunkle Darstellung und größte Bedienungshilfen-Schrift sind geprüft; Löschleiste und Suche überlappen nicht. Bei sehr großer Schrift beansprucht die Auswahlleiste mehr Platz, der Inhalt bleibt scrollbar. Synthetische Aufnahmen liegen unter `screenshots/feedback-build5-*.png`.

Version 1.0 (5) wurde am 11. Oktober 2026 hochgeladen und in App Store Connect für „Mark – Intern“ als „Im Test“ bestätigt. Die Prüfung mit echten Cloud-/USB-Dateianbietern auf einem physischen Gerät bleibt separat.
