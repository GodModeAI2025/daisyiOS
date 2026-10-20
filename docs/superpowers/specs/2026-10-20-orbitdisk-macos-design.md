# OrbitDisk für macOS

Stand: 20. Oktober 2026. Entwurfsumfang vom Eigentümer im Chat bestätigt; diese schriftliche Spezifikation ist vor der Implementierungsplanung zu prüfen.

## Ziel und Plattform

OrbitDisk erhält eine native macOS-App im bestehenden App-Store-Eintrag (Apple-ID 6821645213) als Universal Purchase. Sie übernimmt Speicheranalyse, interaktiven Orb, Aufräumkandidaten, Duplikatsuche und bestätigte Dateiaktionen. Die bestehende iPhone-/iPad-App bleibt ab iOS 27 unterstützt. Die Mac-App zielt auf macOS 27; SDK und Signierungsfähigkeit werden vor Umsetzung live in Xcode geprüft.

Ein eigener nativer macOS-Target im bestehenden XcodeGen-Projekt verwendet die gemeinsamen Modelle und Dienste. Das vermeidet eine zweite Analyseimplementierung und erlaubt AppKit-Dateiaktionen. Mac Catalyst wäre ein kleinerer Port, erfüllt den gewünschten nativen Fenster- und Bedienungsaufbau aber schlechter. Eine getrennte Anwendung mit eigenem Kauf und eigener Logik würde unnötige Produkt- und Wartungsduplikate schaffen.

## Fenster und Bedienung

Ein anpassbares Fenster mit linker Seitenleiste für zuletzt freigegebene Ordner und Ordner-/Datenträgerauswahl, mittlerem Analysebereich und rechtem Dateiinspektor. Im Analysebereich stehen Orb und Dateiliste bei ausreichender Breite nebeneinander; bei schmalerem Fenster ordnen sie sich untereinander an. Der Inspektor ist ausblendbar. Ein sinnvolles Mindestmaß hält Bedienelemente erreichbar. Fensterzustände und laufende Analysen sind pro Fenster getrennt; gemeinsame gespeicherte Ordnerzugriffe dürfen wiederverwendet werden.

Ordnersegmente und Ordnerzeilen öffnen die nächste Ebene; die Orb-Mitte führt zurück. Ein sichtbarer Pfad und Zurück-Steuerung erklären den aktuellen Ort. Ordner stehen immer vor Dateien. Filter und Sortierung stehen nebeneinander. Dateiauswahl zeigt Größe, Pfad und verfügbare Aktionen im Inspektor. Lange Namen dürfen Aktionen und Größen nicht verdrängen.

Die vorhandene indigo-violette, futuristische Gestaltung bleibt erhalten, ergänzt durch native macOS-Seitenleisten, Werkzeugleiste, Menüs und Fokusdarstellung. Systemdarstellung, Kontrast, VoiceOver und reduzierte Bewegung werden berücksichtigt. Animationen dürfen Navigation und Scanfortschritt nicht blockieren.

## Mac-Dateiaktionen und Zugriff

Die native Ordnerauswahl erlaubt vom Benutzer ausgewählte Verzeichnisse und eingebundene Datenträger. Ein Menüpunkt mit Cmd-O öffnet die Auswahl. Finder-Anzeige verwendet die native Reveal-Funktion; Quick Look erscheint nur bei unterstützten Dateien. Kontextmenüs und Tastaturbefehle ergänzen sichtbare Aktionen. Destruktive Aktionen erhalten keine ungeschützten globalen Tastenkürzel.

App Sandbox und ausschließlich benutzerfreigegebener Lese-/Schreibzugriff bleiben aktiv. Dauerhafte Zugriffe verwenden auf macOS Security-Scoped Bookmarks; abgelaufene oder widerrufene Zugriffe führen zu verständlicher erneuter Auswahl. Keine Vollzugriffsberechtigung oder automatische Analyse fremder Verzeichnisse. Cloud-Provider können Inhalte laden und Löschungen synchronisieren.

## Gemeinsame Logik und Sicherheit

ScanEngine, ScanResult, CleanupCandidates, DuplicateEngine, DirectoryListing und DeletionSelection werden wiederverwendet. Plattformanpassungen betreffen Einstieg, Fensterlayout, Dateiauswahl, Finder/Quick Look, Bookmark-Optionen sowie UIKit-spezifische View-Modifikatoren. Bestehende iOS-Ansichten und Tests behalten ihre Schnittstellen, soweit technisch möglich.

Fortschritt, Laufzeit, Abbruch, Fehlermeldungen und Hinweise auf unlesbare Einträge bleiben sichtbar. Keine feste Dateigrenze. Auswahl von Aufräumfunden und Duplikaten bleibt ausdrücklich; keine automatische Löschung. Schutz des Analysewurzelverzeichnisses, Pfad-/Linkprüfungen und erneute Inhaltsprüfung vor Duplikatlöschungen bleiben erhalten. Die Löschbestätigung benennt Einträge, Umfang und mögliche Synchronisation. Native Wiederherstellbarkeit darf nur zugesagt werden, wenn die tatsächliche Mac-Löschimplementierung sie gewährleistet.

## Betroffene Projektteile

- project.yml, macOS-App-Target und Tests, Sandbox-Entitlements, App-Icon und Signierung.
- App-Einstieg/RootView und Mac-Fensteransichten; gemeinsame Anzeigeelemente gezielt weiterverwenden.
- AccessStore, LocationBrowser, FolderDetailView und plattformabhängige Dateiaktionen.
- Gemeinsame Tests sowie Mac-Zugriffs- und UI-Prüfungen.
- Release-Dokumentation, Datenschutztexte bei tatsächlichen Plattformunterschieden und Mac-Store-Metadaten/Bilder.

Keine neuen Analysealgorithmen, Drittanbieter-SDKs, Konten, Telemetrie, Cloud-Dienste oder GitHub-Workflows.

## Prüfung und Auslieferung

Xcode MCP für Projekt-/Build-Prüfung verwenden; tatsächliche Tools und Workspace-IDs neu ermitteln. iOS und macOS bauen, gemeinsame relevante Tests auf beiden Plattformen ausführen. Mac-UI mit schmalem und breitem Fenster, heller/dunkler Darstellung, Tastaturfokus und VoiceOver-Beschriftungen prüfen. Mit isolierten Testdateien Ordnerwahl, erneuten Zugriff nach App-Neustart, Orb-Navigation, Filter/Sortierung, Quick Look, Finder, Scanabbruch, Aufräum- und Duplikatbestätigung prüfen. Keine privaten Benutzerdateien für Löschtests.

Signiertes Mac-Archiv erstellen und zum vorhandenen App-Store-Eintrag hochladen. Plattformzuordnung, Bundle-ID-Konfiguration und Universal-Purchase-Verknüpfung vor Upload prüfen. Bestehenden iOS-Review-/Veröffentlichungsstand live lesen und nicht durch den Mac-Upload ersetzen. Preisbasis 0,99 EUR Deutschland und weltweite Verfügbarkeit beibehalten; keine zweite kostenpflichtige Produktanlage.

Mac-Screenshots und plattformspezifische Review-Hinweise ergänzen, Datenschutz-/Exportangaben anhand tatsächlichen Verhaltens überprüfen und Mac-Version zur Prüfung einreichen, soweit keine neuen verbindlichen Eigentümererklärungen erforderlich sind. Manuelle Veröffentlichung beibehalten. Build, Upload, Verarbeitung, Review und öffentliche Verfügbarkeit getrennt belegen; Apple-Freigabe ist keine lokale Implementierungsprüfung.

## Abnahme

Die Mac-App lässt sich nativ bauen und starten, zeigt das beschriebene anpassbare Layout und bietet alle bestehenden Kernfunktionen mit Mac-Dateiaktionen. Zugriff und Löschung bleiben auf freigegebene Ordner beschränkt. iOS baut weiterhin. Store-Erfolg wird nur mit dem tatsächlich verifizierten Portalstatus berichtet.
