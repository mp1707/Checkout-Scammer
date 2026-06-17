# Checkout Scammer – Design Dokument

## Meta

- Plattform: Steam
- Engine: Godot 4.6

## Core Player Craving und Juice-Source

- Mit dem Handscanner ein Produkt anvisieren und scannen
- Das satisfying „Beep“-Geräusch hören
- Coin-Animation beim Kassenbon-Abschluss sehen
- Den aktuellen Verkaufsbetrag im Kassendisplay sehen
- Geld beim Kassenbon-Abschluss direkt hochzählen sehen
- Der Scanner-Moment ist der wichtigste Kern des Spiels

## Perspektive und Art-Style

- 2D Pixel-Art
- Minimalistisch wie Scritchy Scratch
- 1-Screen-Gameplay
- Abstrakt, ohne sichtbaren Player-Sprite
- Kein vollständig sichtbarer Kunde
- Der Kunde wird nur durch einen kundenspezifischen Signalträger im rechten Tischbereich angedeutet
- UI-Stil angelehnt an Scritchy Scratch / Balatro
- Alle Spiel- und UI-Farben nutzen die Endesga-64-Palette: <https://lospec.com/palette-list/endesga-64>
- Menüs, Schriften, Buttons, Tooltips, Scannerfeedback, Schatten und Popups verwenden nur Farben aus dieser Palette.
- Neue UI-Farben werden als Theme-Tokens gepflegt, nicht frei pro Szene gemischt.
- Transparenz darf genutzt werden, aber die zugrunde liegende RGB-Farbe bleibt aus Endesga 64.
- Top-Down-Ansicht
- Der Kassentisch ist das zentrale Spielfeld
- Links und rechts davon befinden sich Menüleisten für Status, Geld und Upgrades

## Layout

- Der Screen ist in drei Hauptbereiche aufgeteilt:
  - Linke Menüleiste: ca. 15% Breite
  - Mittlerer Viewport / Kassentisch: ca. 70% Breite
  - Rechte Menüleiste: ca. 15% Breite

### Linke Menüleiste

- Zeigt:
  - Tag
  - Kunde, z.B. `1/3`
  - Mietziel / „Rent due tonight“
  - Aktuelles Geld / „Cash in Drawer“

### Mittlerer Viewport / Kassentisch

- Der mittlere Bereich ist der Kassentisch.
- Das Spielfeld soll wie ein abstrakter Kassentisch wirken, nicht wie ein realistischer Supermarkt.
- Der Tisch darf klare, simple Shapes haben.
- Reale Objekte werden nur sparsam angedeutet.

### Scanner

- Der Scanner ist dauerhaft der Maus-Cursor.
- Der OS-Cursor ist im Spielbereich versteckt und wird beim Verlassen des Spiels wieder sichtbar.
- Der Hotspot des animierten Laser-Cursors sitzt exakt am Mauspunkt.
- Das Scanner-Sprite bleibt sichtbar und sitzt unterhalb des Laser-Hotspots.
- Der Laser-Cursor nutzt vier animierte Zustände aus `assets/textures/environment/laser.png`.
- Scanner-Sprite und Laser-Cursor liegen immer über Produkt-Sprites, Waagentexten und Popups; das Scanner-Sprite wird über dem Laser gezeichnet.
- Rechtsklick auf ein Festpreis-Produkt startet einen 2-Sekunden-Scan.
- Während des Scans muss der Spieler Rechtsklick halten und den Laser-Hotspot auf dem Produkt-Sprite halten.
- Lässt der Spieler Rechtsklick los, bewegt den Hotspot vom Sprite oder unterbricht den Laser durch ein anderes Top-Target, bricht der Scan ab.
- Während des Scans zeigt das Produkt oben links am Sprite den Ladekreis aus `assets/textures/ui/loading_circle.png` in 0.5x-Größe.
- Hält man Rechtsklick gedrückt, kann jedes neu berührte Festpreis-Produkt nach seiner eigenen 2-Sekunden-Dauer einmal gescannt werden.
- Bleibt Rechtsklick gedrückt, kann dasselbe Festpreis-Produkt erneut gescannt werden, wenn der Cursor-Hotspot dessen Hitbox aktiv verlässt und wieder berührt.
- Der rote Cross-with-Laser-Zustand ist nur sichtbar, während Rechtsklick gedrückt ist.
- Beim erfolgreichen Scan pulst der Laser-Cursor kräftiger.
- Mehrfachscans entstehen durch wiederholte Rechtsklicks oder durch Verlassen und erneutes Berühren desselben Produkts bei gehaltenem Rechtsklick.
- Hält man den Laser-Cursor über Obst, wird die blaue Chevron-Animation angezeigt, solange die Scantaste nicht gedrückt ist.
- Wird die Scantaste gehalten, bleibt der rote Cross-with-Laser-Zustand als kontinuierlicher Scanvorgang aktiv, auch über Obst.
- Obst ist nicht scannerverkaufbar. Linksklick-Drag bewegt Obst normal; während Drag verschwindet nur der Laser-Cursor, das Scanner-Sprite bleibt sichtbar.
- Coupons werden per 2-Sekunden-Rechtsklick-Hold mit dem Handscanner ehrlich aktiviert und zeigen dabei denselben Ladekreis.

### Waage

- Obst muss über die Waage gebucht werden.
- Die Waage steht im Tischbereich oberhalb des Scanners.
- Die Waage ist eine eigene Drop-Zone und akzeptiert immer nur ein wiegbares Produkt gleichzeitig.
- Wenn Obst auf die Waage gelegt wird, spielt die Waage die Press-Animation aus `waage_sheet.png`.
- Solange Obst auf der Waage liegt, bleibt die Waage visuell belastet.
- Das Ablegen auf der Waage startet eine 2-Sekunden-Wiegung.
- Während der Wiegung zeigt das Obst oben links am Sprite den Ladekreis aus `assets/textures/ui/loading_circle.png` in 0.5x-Größe.
- Wird das Obst vor Ablauf der 2 Sekunden von der Waage genommen, bricht die Wiegung ab und es wird kein Betrag berechnet.
- Nach vollständigen 2 Sekunden berechnet die Waage den Betrag aus Gewicht, Kilopreis, Coupons und Stickern.
- Der berechnete Betrag erscheint im Kassendisplay und wird zum offenen Verkaufsbetrag des Obstes addiert.
- Obst kann mehrfach gewogen werden.
- Zum mehrfachen Buchen kann Obst mit der Maus von der Waage hochgehoben und erneut abgelegt werden.
- Während das Obst hochgehoben wird, verschwindet der Betrag aus dem Kassendisplay; der offene Betrag bleibt am Obst gespeichert.
- Wird dasselbe Obst später erneut vollständig gewogen, erhöht sich sein aktueller offener Verkaufsbetrag erneut.
- Wird ein Sticker auf Obst geklebt, das gerade auf der Waage liegt, aktualisiert sich der offene Verkaufsbetrag im Kassendisplay sofort.
- Die erste Wiegung ist sicher.
- Ab der zweiten Wiegung desselben Obstes läuft derselbe Suspicion-/Caught-Pfad wie bei Mehrfachscans.
- Bei Caught verschwindet das Obst, der offene Betrag wird gelöscht und kein Geld wird gebucht.

### Produktfläche

- Im rechten Tischbereich liegen die Produkte verstreut auf dem Kassentisch.
- Es gibt kein sichtbares Fließband mehr.
- Ein Kunde hat weiterhin 10 Produkte.
- Zu Beginn eines Kunden liegen alle 10 Produkte direkt auf der Matte.
- Wenn ein Coupon für diesen Kunden aktiv ist, liegt der Coupon zusätzlich als erstes Objekt auf der Matte.
- Neue Produkte rutschen während eines Kunden nicht nach.
- Gescannte oder gewogene Produkte bleiben sichtbar und erhalten ab der ersten Buchung eine kleine Zahl rechts unten am Sprite.
- Die Zahl zeigt, wie oft das Produkt gebucht wurde. Bei `0` wird keine Zahl angezeigt.

### Kassenbon

- Ein Scan oder eine Wiegung bucht noch kein Geld in den Total-Wert.
- Nach einem erfolgreichen Scan oder einer erfolgreichen Wiegung zeigt das Display der Kasse den offenen Verkaufsbetrag des aktuell gebuchten Produktes.
- Der aktuelle Verkaufsbetrag nutzt grüne, displaytypische Schrift direkt im Kassendisplay.
- Ist der Einkauf fertig, hält der Spieler den Scanner über die Kasse.
- Über der Kasse wird die grüne Checkmark-Animation angezeigt.
- Rechtsklick auf die Kasse öffnet ein Popup: Bon erzeugen? Ja/Nein.
- Nein schließt nur das Popup.
- Ja erzeugt den Kassenbon als Popup.
- Der Kassenbon listet nur gebuchte Artikel.
- Mehrfach gescannte oder mehrfach gewogene Produkte erscheinen mehrfach auf dem Bon; doppelte Einträge werden leicht hervorgehoben.
- Unten steht die Summe.
- Erst beim Erzeugen des Kassenbons wird die Summe zum Geldbestand gebucht.
- Der Bon wird mit Continue beendet; danach kommt der nächste Kunde.

### Müll-Loch

- Rechts unten im Eck des Kassentisches befindet sich das Müll-Loch.
- Es liegt unter der Produktfläche.
- Es ist ein rundes Loch im Tisch mit Label `Trash`.
- Produkte oder Coupons können dort hineingeworfen werden.
- Wird ein Coupon in den Müll geworfen, wird er nicht gescannt.
- Das ist eine versteckte Scam-Mechanik.
- Wird ein Produkt mit offenem Verkaufsbetrag in den Müll geworfen, verschwindet es und der offene Betrag wird nicht gebucht.

### Kundensignal

- Rechts oben über der Produktfläche ist der Signalträger des aktuellen Kundentyps sichtbar.
- Der Signalträger deutet den Kunden an, ohne einen vollständigen Kunden zu zeigen.
- Es gibt vier optisch unterscheidbare Kundentypen: Jimmy, Margaret, Chad und Doris.
- Der Signalträger zeigt die aktuelle Suspicion über drei gezeichnete Sprite-Stufen:
  - Grün: bis inklusive `30%` Suspicion.
  - Gelb: ab `31%` bis inklusive `60%` Suspicion.
  - Rot: ab `61%` Suspicion.
- Es gibt keine plumpe Suspicion-Progressbar mit Zahl.
- Der Signalträger ist die kreative, diegetische Anzeige des Suspicion-Meters.
- Mouseover über den Kunden-/Signalträgerbereich zeigt Name und Beschreibung des Kundentyps.

### Rechte Menüleiste

- Zeigt Upgrades.
- Enthält:
  - Coupon-Button
  - Sortiment-Level-Up-Button
  - Sticker-Button

## Game Setting

- Der Spieler ist Convenience-Store-/Kiosk-Besitzer und Kassierer.
- Ziel: Jeden Tag die Miete zahlen können und so viel Geld wie möglich einnehmen, um Upgrades zu kaufen.
- Twist: Man merkt bereits am ersten Tag, dass man durch normales Scannen und Abkassieren die Miete nicht zahlen kann.
- Die Summe des normalen Produktwerts reicht knapp nicht aus, um die Miete zu zahlen.
- Man muss also kreativ werden und Kunden betrügen, indem man Produkte mehrfach scannt.

## Kundentypen

Jeder Kunde hat einen Typ. Der Typ bestimmt, aus welchem Preisbereich des aktuellen Sortiments Produkte gezogen werden, wie schnell Suspicion steigt, welche Zusatzstrafe bei Caught passiert und welche Kundendialoge gezeigt werden.

- Jimmy (Kid)
  - Tooltip: `Doesn't pay attention at all and pays with the credit card of his mom.`
  - Kaufverhalten: billigste `30%` des aktuell freigeschalteten Sortiments.
  - Suspicion: `0 -> 20 -> 45 -> 70`.
  - Caught-Strafe: nur das aktuelle Produkt geht verloren.
  - Caught-Text: `Jimmy: Hey, that beep happened twice. I'm putting this one back.`
  - Abschied: `Jimmy: Bye! Mom's card worked, right?`
- Margaret (Fatlady)
  - Tooltip: `A wealthy regular who trusts you completely — unless the mood ring turns red.`
  - Kaufverhalten: gesamtes aktuell freigeschaltetes Sortiment.
  - Suspicion: `10 -> 50 -> 75 -> 90`.
  - Caught-Strafe: nur das aktuelle Produkt geht verloren.
  - Caught-Text: `Margaret: That was an extra scan, dear. Remove this item from my bill.`
  - Abschied: `Margaret: Thank you, dear. See you next time.`
- Chad (Businessman)
  - Tooltip: `Always in a hurry, yet paranoid enough to watch your every move.`
  - Kaufverhalten: teuerste `30%` des aktuell freigeschalteten Sortiments.
  - Suspicion: `30 -> 65 -> 85 -> 95`.
  - Caught-Strafe: aktuelles Produkt geht verloren und zusätzlich wird einmal dessen Produktwert vom aktuellen Geldbestand abgezogen. Der Geldbestand kann dadurch nicht unter `0$` fallen.
  - Caught-Text: `Chad: I saw the double charge. Refund me this item's price from the drawer. Now.`
  - Abschied: `Chad: Receipt. I'm already late.`
- Doris (Oldlady)
  - Tooltip: `The sweetest, slowest customer — but get caught and she'll tell the whole neighborhood.`
  - Kaufverhalten: billigste `60%` des aktuell freigeschalteten Sortiments.
  - Suspicion: `5 -> 30 -> 55 -> 75`.
  - Caught-Strafe: aktuelles Produkt geht verloren und die Start-Suspicion des nächsten Kunden steigt um `+20%`. Mehrfaches Erwischtwerden bei Doris stapelt diesen Aufschlag.
  - Caught-Text: `Doris: Oh dear, an extra charge. Put this back, and I'll warn the next person in line.`
  - Abschied: `Doris: Thank you, sweetheart. I'll shuffle along now.`

### Kaufverhalten über Preis-Perzentile

- Kundentypen kaufen nicht aus festen Produktlisten, sondern aus Preisbereichen des aktuellen Sortiments.
- Das Sortiment wird dafür nach Produktwert sortiert.
- Festpreis-Produkte nutzen `price_cents`.
- Wiegbare Produkte nutzen den erwarteten Stückpreis aus durchschnittlichem generierten Gewicht mal Kilopreis.
- Die Perzentilgrenzen werden immer neu aus dem aktuell freigeschalteten Sortiment berechnet.
- Sortiment-Level-Ups verschieben die Perzentilgrenzen automatisch.
- Die Prozentwerte sind Balancing-Werte und zentral anpassbar.

## Grundstruktur / Runs

- Ein Run besteht aus 8 Geschäftstagen.
- Ein Geschäftstag besteht aus 3 Kunden.
- Ein Kunde hat 10 zufällige Produkte.
- Für den Prototyp ist die Produktanzahl auf 10 gesetzt, aber zentral im Balancing pflegbar.
- Der erste Kunde eines Runs ist immer Jimmy.
- Alle weiteren Kunden werden zufällig aus den vier Kundentypen gezogen.
- Nie zweimal derselbe Kundentyp direkt hintereinander.
- Es gibt aktuell keine vordefinierten Kundenfolgen. Falls sie später wieder gebraucht werden, werden sie als separates Content-System ergänzt.
- Die ersten Kunden bringen bei ehrlichem Spiel knapp nicht genug Geld ein.
- Dadurch lernt der Spieler die Scam-Mechanik.
- Runs und zufällige Kunden werden deterministisch über einen Seed erzeugt.
- Normale neue Runs erzeugen einen frischen Seed, damit ein Spielneustart eine andere Kunden- und Produktfolge liefert.
- Der gleiche Seed soll die gleiche Kundentyp-, Produkt- und Gewichtsfolge erzeugen.
- Der gleiche Seed soll auch die gleiche Gewichtsfolge für Obst erzeugen.

## Balancing-Defaults

- Startgeld: `10$`
- Tagesmiete im Prototyp: `40$`
- Produktpreise im Startsortiment liegen grob zwischen `0,50$` und `1,80$`.
- Diese Werte sind erste Platzhalter und dürfen später beim Balancing angepasst werden.
- Wichtig: Balancing muss zentralisiert und im Godot-Editor einfach editierbar sein.
- Zentral pflegbar sein sollen mindestens:
  - Startgeld
  - Tagesmiete / Mietkurve
  - Tage pro Run
  - Kunden pro Tag
  - Produkte pro Kunde
  - sichtbare Objekt-Slots
  - Produktpreise
  - Kilopreise für Obst
  - Obst-Gewichtsranges, Rundung, Verteilung und Sprite-Skalierung
  - Produktgewichte für die Kundengenerierung
  - Kundentypen, Kundentyp-Tooltips und Kundentyp-Texturen
  - Kundentyp-Caught- und Abschiedsdialoge
  - Preis-Perzentile je Kundentyp
  - Coupon-Kosten
  - Coupon-Rabatte
  - Coupon-Gewichtungsboni
  - Sticker-Multiplikatoren und tägliche Sticker-Refills
  - Sortiment-Level-Up-Kosten
  - Suspicion-Stufen je Kundentyp
  - Chad-Geldstrafe und Doris-Start-Suspicion-Bonus

### Aktuelle Produkt-Werte

- Startsortiment:
  - Apfel: `150-500g`, aktuell `3,00$ / kg`
  - Orange: `150-500g`, aktuell `3,20$ / kg`
  - Banane: `120-500g`, aktuell `2,60$ / kg`
  - Kaugummi: `0,95$`
  - Bonbonrolle: `0,80$`
  - Taschentuecher: `1,40$`
- Sortiment-Level 2:
  - Brown Snackbar: `1,30$`
- Alle Werte sind Balancing-Platzhalter in den Produkt-Resources.

## Kunden-Produktfluss

- Ein Kunde hat 10 Produkte.
- Der Kundentyp bestimmt, aus welchem Preisbereich des aktuellen Sortiments diese Produkte gezogen werden.
- Coupons können die Gewichtung innerhalb dieses Kundentyp-Produktpools verändern.
- Zu Beginn eines Kunden liegen alle 10 Produkte direkt sichtbar auf der Produktfläche.
- Wenn ein Coupon für diesen Kunden aktiv ist, liegt er zusätzlich als erstes Objekt auf der Produktfläche.
- Es gibt keine versteckte Nachzieh-Queue mehr.
- Der Spieler kann die Produkte in freier Reihenfolge scannen, wiegen oder wegwerfen.
- Die Reihenfolge innerhalb der sichtbaren Produkt-Slots ist frei wählbar.
- Festpreis-Produkte können:
  - gescannt werden
  - mehrfach gescannt werden
  - in den Müll geworfen werden, falls das Produkt oder Objekt dafür gedacht ist
- Obst kann:
  - auf die Waage gelegt werden
  - nach 2 Sekunden auf der Waage abgerechnet werden
  - mehrfach gewogen werden
  - in den Müll geworfen werden
- Obst bekommt beim Erstellen der Produktinstanz ein deterministisches zufälliges Gewicht.
- Leichte und realistische Gewichte sind häufig, sehr schwere Früchte selten.
- Die Gewichtsrundung liegt aktuell bei `10g`.
- Die Obst-Spritegröße wird anhand des jeweiligen Gewichts von ca. `1.0x` bis maximal `2.0x` skaliert.
- Jeder erfolgreiche Scan oder jede erfolgreiche Wiegung erhöht den offenen Verkaufsbetrag und die sichtbare Buchungszahl des betroffenen Produkts.
- Der offene Verkaufsbetrag wird erst beim Erzeugen des Kassenbons zum Total-Wert gebucht.

## Suspicion-System

- Jeder Kunde hat ein internes Suspicion-Meter.
- Das Suspicion-Meter ist die Wahrscheinlichkeit, beim Betrügen erwischt zu werden.
- Die Start-Suspicion und alle Steigerungsstufen kommen aus dem aktuellen Kundentyp.
- Ein Caught-Roll passiert bei jedem Produkt-Scan ab dem zweiten Scan desselben Produkts und bei jeder Wiegung ab der zweiten Wiegung desselben Obstes.
- Der erste Scan oder die erste Wiegung eines Produkts ist immer sicher.
- Coupon-Scam löst keinen Caught-Roll aus.
- Jeder Mehrfachscan- oder Wiege-Scam-Versuch erhöht die Suspicion nach dem Caught-Roll, auch wenn der Spieler erwischt wird.
- Jimmy steigt über `0 -> 20 -> 45 -> 70`.
- Margaret steigt über `10 -> 50 -> 75 -> 90`.
- Chad steigt über `30 -> 65 -> 85 -> 95`.
- Doris steigt über `5 -> 30 -> 55 -> 75`.
- Nach der letzten Stufe bleibt die Suspicion beim letzten Wert des Kundentyps.
- Mehrfachscans sind unbegrenzt möglich, bis der Spieler erwischt wird oder den Kassenbon abschließt.
- Neuer Kunde = neues Suspicion-Meter mit Startwert des Kundentyps.
- Doris kann durch Caught einen `+20%` Start-Suspicion-Bonus für den nächsten Kunden stapeln.
- Dieser Bonus wird beim nächsten Kunden auf dessen Kundentyp-Startwert addiert und bei `100%` gecappt.
- Die aktuelle Suspicion wird ausschließlich über den grün/gelb/roten Sprite-Zustand des Kundensignals angezeigt.
- Die sichtbaren Signal-Farben sind für alle Kundentypen gleich: bis inklusive `30%` grün, bis inklusive `60%` gelb, darüber rot.
- Es gibt keine zusätzliche Suspicion-Zahl und keine Progressbar.

## Erwischen / Strafe

- Wird man erwischt, erscheint eine kundentyp-spezifische Textbox aus `CustomerTypeResource.caught_dialog_text`.
- Der Text nennt die konkrete Konsequenz, damit der Spieler versteht, ob nur das Produkt verloren geht oder eine Zusatzstrafe ausgelöst wurde.

- Die Textbox muss mit Enter weggeklickt werden.
- Die Wirkung:
  - Das aktuelle Produkt verschwindet visuell.
  - Der offene Verkaufsbetrag im Kassendisplay wird gelöscht.
  - Es wird kein Geld vom offenen Produktbetrag gebucht.
  - Jeder Kundentyp verliert immer mindestens das aktuelle Produkt.
  - Jimmy und Margaret haben keine weitere Strafe.
  - Chad zieht zusätzlich einmal den Produktwert vom aktuellen Geldbestand ab. Der Geldbestand ist bei `0$` gecappt.
  - Doris erhöht zusätzlich die Start-Suspicion des nächsten Kunden um `+20%`. Dieser Aufschlag stapelt, wenn Doris mehrfach erwischt.
- Danach geht der Kunde weiter normal.

## Tagesende

- Zwischen Geschäftstagen, also immer nach 3 Kunden, wird die Miete bezahlt.
- Kann man die Miete nicht zahlen, verliert man sofort.
- Eine spätere Schuldenmechanik ist möglich, aber out of scope für den Prototyp.
- Aktive Tages-Coupons laufen am Tagesende aus.
- Bio-Sticker werden zu Beginn jedes neuen Tages wieder auf `3` aufgefüllt.

## Upgrades

- In der rechten Menüleiste gibt es temporäre und permanente Upgrades:
  - Coupons
  - Sortiment-Level-Up
  - Sticker

## Coupons

- Der Coupon-Button öffnet ein Popup-Menü.
- Dort erscheinen Coupons nur für Produkte, die bereits im Sortiment sind.
- Beispiel:

`Coupon: Apfel -20%`

- Mouseover-Tooltip:

`Kunden kaufen mehr Äpfel.`

- Coupons erhöhen die Chance, dass Kunden bestimmte Produkte kaufen.
- Dadurch kann man die Chance auf wertvollere Produkte erhöhen.
- Ein gekaufter Coupon gilt für den Geschäftstag, in dem er aktiviert wird.
- Wird ein Coupon während eines aktiven Kunden gekauft, wird er beim nächsten Kunden aktiviert.
- Wird ein Coupon beim letzten Kunden eines Geschäftstags gekauft, aktiviert er sich beim ersten Kunden des nächsten Geschäftstags.
- Der Mouseover-Tooltip des Coupon-Buttons erklärt diese Verzögerung.
- Beispiel:
  - Am Anfang gibt es viele 0,50$ Produkte.
  - Es gibt wenige 1$ Produkte.
  - Ein Coupon sorgt dafür, dass Kunden mehr 1$ Produkte kaufen.
  - Dadurch verdient man insgesamt mehr Geld.

### Coupon-Scam

- Wenn ein Kunde Produkte kauft, die durch einen Coupon beeinflusst wurden, kommt der passende Coupon mit auf die Produktfläche.
- Der Coupon ist ein Extra-Objekt und zählt nicht zu den 10 Produkten des Kunden.
- Der Coupon wird immer als erstes sichtbares Objekt auf die Produktfläche gelegt.
- Er belegt einen sichtbaren Objekt-Slot, reduziert aber nicht die interne Produktanzahl des Kunden.
- Der Spieler kann den Coupon ehrlich scannen.
- Dann wird der Rabatt für alle danach gescannten oder gewogenen passenden Produkte dieses Kunden angewendet.
- Der Spieler kann den Coupon aber auch in das Müll-Loch werfen.
- Dadurch erhält der Spieler den Vorteil des Coupons:
  - Kunden kaufen wertvollere Produkte
- Aber der Nachteil wird negiert:
  - Der Rabatt wird nicht angewendet
- Coupon-Scam erhöht keine Suspicion und löst keinen Caught-Roll aus.
- Diese Mechanik soll nicht stark erklärt werden.
- Der Spieler soll sie selbst herausfinden.

## Sortiment-Level-Up

- Der Sortiment-Level-Up-Button zeigt immer den Preis der nächsten Stufe an.
- Ähnlich wie die Münzverbesserung bei Scritchy Scratch.
- Der Button ist ausgegraut, wenn man nicht genug Geld hat.
- Wenn man genug Geld hat, kann man das Sortiment mit einem Klick hochleveln.
- Dadurch wird der Produktpool erweitert.
- Sortiment-Level-Ups können auch während eines aktiven Kunden gekauft werden.
- Sie wirken erst ab dem nächsten Kunden.
- Der Mouseover-Tooltip erklärt diese Verzögerung.
- Mouseover zeigt:
  - Welche Produkte im nächsten Level enthalten sind
  - Was diese Produkte wert sind
- Am Anfang hat man nur Billigprodukte.
- Durch Sortiment-Level-Ups arbeitet man sich langsam zu wertvolleren Produkten hoch.

## Sticker

- Der Sticker-Button im rechten Menüpanel öffnet ein kleines Popup am rechten UI-Bereich.
- Das Popup blockiert den mittleren Spielbereich nicht.
- Der Spieler hat pro Tag `3x Bio-Sticker`.
- Die Sticker werden als einzelne physische Sticker im Popup angezeigt.
- Jeder Bio-Sticker kann aus dem Popup heraus per Drag-&-Drop auf Obst gezogen werden.
- Bio-Sticker können nicht auf Festpreis-Produkte, Coupons, Müll, Scanner, Kasse oder leere Fläche geklebt werden.
- Nach dem Aufkleben ist der Sticker verbraucht und kann nicht entfernt werden.
- Der Sticker ist sichtbar auf dem Obst und bewegt sich mit dem Produkt.
- Tooltip: `Verdreifacht den Preis von Obst`
- Der Bio-Sticker multipliziert Obst-Abrechnungen mit `x3`.
- Liegt das beklebte Obst beim Aufkleben auf der Waage, wird der offene Betrag auf der Kasse sofort mit dem Stickerwert aktualisiert.
- Bei Obst außerhalb der Waage wirkt der Sticker auf spätere Wiegungen.
- Verbrauchte Sticker bleiben bis zum Tagesende verbraucht.

## Win / Lose

- Win:
  - Am Ende von Tag 8 die Miete zahlen können
- Lose:
  - Tagesmiete nicht bezahlen können
- Kein Zeitdruck
- Später kann das Spiel endlos skalieren, aber das ist out of scope für den Prototyp.

## Sortiment einfach gedacht

- Kein detailliertes Sortiment-Management.
- Keine Stückzahlen.
- Kein Lagerbestand.
- Keine Einkaufspreise.
- Produkte werden nicht einzeln verwaltet.
- Stattdessen gibt es:
  - Startsortiment
  - Sortimentserweiterungen über den Level-Up-Button

## Start-Sortiment

- Für den aktuellen Asset-Stand gibt es im Startsortiment:
  - Apfel
  - Orange
  - Banane
  - Kaugummi
  - Bonbonrolle
  - Taschentuecher
- Das Sortiment kann vorerst genau einmal erweitert werden.
- Die erste Erweiterung fügt hinzu:
  - Brown Snackbar

## Mögliche spätere Produktlinien

Out of scope für den Prototyp:

- Bürobedarf
- Hygieneartikel
- Kühlware
- Luxusartikel

## Core-Gameplay-Loop

- Kunde startet.
- Der Kundentyp wird rechts oben über der Produktfläche sichtbar.
- Beim ersten Kunden eines Runs ist der Kundentyp immer Jimmy.
- Alle 10 Produkte liegen direkt in der verstreuten Produktfläche.
- Falls für diesen Kunden ein Coupon aktiv ist, liegt er zusätzlich zuerst in der Produktfläche.
- Der Spieler nimmt ein Produkt von der Produktfläche.
- Der Handscanner ist permanent der Cursor.
- Festpreis-Produkte werden per 2-Sekunden-Rechtsklick-Hold mit dem Laser-Cursor gescannt.
- Ein gültiger Scan löst aus:
  - Beep
  - Verkaufsbetrag im Kassendisplay erhöht sich
  - Laser-Cursor-Feedback
- Obst wird mit dem Scanner-Cursor gedraggt und auf die Waage gelegt.
- Danach kann der Spieler das Festpreis-Produkt nochmal scannen oder Obst erneut vollständig wiegen.
- Ab der ersten Buchung zeigt das Produkt rechts unten seine Buchungszahl.
- Wenn der Einkauf fertig ist, hält der Spieler den Scanner über die Kasse und klickt.
- Bei Ja im Confirm-Popup wird der Kassenbon erzeugt, die Bon-Summe gebucht und der Bon angezeigt.
- Continue auf dem Bon startet den nächsten Kunden.
- Festpreis-Produkte können mehrfach gescannt werden.
- Obst kann mehrfach gewogen werden.
- Mehrfaches Scannen oder mehrfaches Wiegen erhöht die Suspicion.
- Die Suspicion wird über den Sprite-Zustand des Kundensignals angezeigt.
- Danach kommt der nächste Kunde.
- Nach 3 Kunden endet der Geschäftstag.
- Am Tagesende wird die Miete bezahlt.
- Upgrades können jederzeit gekauft werden und wirken ab dem nächsten Kunden.

## Scan-Regeln

- Ein Scan zählt nur, wenn:
  - der Spieler Rechtsklick 2 Sekunden lang gedrückt hält
  - der Laser-Hotspot währenddessen auf dem Sprite des scanbaren Objekts bleibt
  - das getroffene Objekt ein Festpreis-Produkt oder Coupon ist
- Kein Scan zählt, wenn:
  - der Spieler Rechtsklick vor Ablauf der 2 Sekunden loslässt
  - der Laser-Hotspot das Sprite verlässt
  - ein anderes Objekt das Top-Target unter dem Laser wird
  - der Spieler das Produkt nur zieht
  - das Produkt Obst bzw. ein wiegbares Produkt ist
- Dadurch wird der Scan-Moment klarer und absichtlicher.
- Der erste erfolgreiche Scan eines Produkts zeigt den offenen Verkaufsbetrag im Kassendisplay.
- Ab dem ersten erfolgreichen Scan zeigt das Produkt seine Buchungszahl.
- Jeder weitere erfolgreiche Scan desselben Produkts erhöht diesen offenen Verkaufsbetrag erneut um den Produktwert.
- Bei Mehrfachscans wird vor dem erfolgreichen Hinzufügen ein Caught-Roll gegen die aktuelle Suspicion ausgeführt. Danach steigt die Suspicion auch dann, wenn der Spieler erwischt wurde.

## Drag-&-Drop-Regeln

- Produkt wird mit Linksklick gedrückt gehalten.
- Dadurch haftet es am Cursor.
- Danach kann es abgelegt werden:
  - im Müll-Loch
  - auf der Waage, wenn es Obst ist
  - optional zurück auf dem Tisch, falls nötig
- Rechtsklick-Hold auf Festpreis-Produkte scannt nach 2 Sekunden.
- Linksklick-Drag bewegt Produkte und Coupons.
- Obst kann mit dem Scanner-Cursor per Linksklick normal gedraggt werden; während des Drags verschwindet nur der Laser-Cursor, das Scanner-Sprite bleibt sichtbar.
- Der offene Verkaufsbetrag wird erst beim Erzeugen des Kassenbons zum Total-Wert gebucht.
- Beim Ablegen im Müll-Loch verschwindet das Produkt oder der Coupon.
- Sticker werden aus dem Sticker-Popup gezogen und können nur auf Obst gedroppt werden.

## Juice-Fokus

- Das Scannen der Produkte ist der wichtigste Kern des Spiels.
- Scannen muss sich extrem satisfying anfühlen.
- Der Spieler soll auch nach 200 Produkten noch Lust auf den nächsten Scan haben.

### Scan-Juice

- Angenehmer Beep-SFX
- Pitch-Eskalation bei Double-, Triple- und Multi-Scans
- Offener Verkaufsbetrag sitzt gut lesbar im Kassendisplay
- Geld zählt links in der Menüleiste animiert hoch, wenn der Kassenbon erzeugt wird
- Kurzer Screen Shake bei Double Scans
- Visuelles Feedback am Scanner
- Roter Laser-Cursor, der beim Scannen kräftiger wird
- Sichtbarer Cross-with-Laser-Zustand beim Rechtsklick-Scan
- Produkt wobbelt oder squasht kurz beim erfolgreichen Scan

### Produktflächen-Juice

- Neue Produkte fahren weich von rechts rein.
- Die Produkte liegen leicht verstreut statt in einer perfekten Reihe.
- Wenn ein aktives Objekt verarbeitet wurde, rückt das nächste Produkt nach.
- Die Bewegung soll weich und satisfying wirken.
- Nicht zu realistisch, eher abstrakt und toy-like.

### Suspicion-Juice

- Das Kundensignal wechselt zwischen grünem, gelbem und rotem Sprite des aktiven Kundentyps nach den globalen Signal-Farben: bis inklusive `30%` grün, bis inklusive `60%` gelb, darüber rot.
- Bei steigender Suspicion kann das Kundensignal kurz pulsieren.
- Bei hoher Suspicion kann das Kundensignal minimal unruhig wirken.
- Kein komplexes Animationssystem nötig.
- Kleine visuelle Andeutungen reichen.

## Prototyp-Fokus

Für den ersten spielbaren Prototyp ist wichtig:

- 1 Screen
- Linke Statusleiste
- Mittlerer Kassentisch
- Rechte Upgrade-Leiste
- Verstreute Produktfläche im rechten Tischbereich
- 10 Produkte pro Kunde
- Alle Kundenprodukte direkt sichtbar auf der Matte
- Handscanner als permanenter Cursor mit sichtbarem Scanner-Sprite und rotem Laser-Default-Zustand
- Scannen per 2-Sekunden-Rechtsklick-Hold auf Festpreis-Produkte und Coupons
- Obst ist wiegbar und nicht scanbar
- Waage im Tischbereich mit 2-Sekunden-Wiegung
- Ladekreis oben links am Sprite für laufende Scans und Wiegungen
- Kassenbon-Abschluss über Register-Hitbox
- Müll-Loch rechts unten
- Kundensignal rechts oben mit vier Kundentypen und je drei Suspicion-Sprites
- Offener Verkaufsbetrag im Kassendisplay
- Buchungszahl am Produkt ab der ersten erfolgreichen Buchung
- Geld zählt beim Erzeugen des Kassenbons direkt hoch
- Double-Scan erhöht Suspicion
- Mehrfaches Wiegen erhöht Suspicion wie Mehrfachscans
- Erster Kunde eines Runs ist Jimmy, danach random Kundentypen ohne direkte Wiederholung
- Kundentypen steuern Produkt-Preisbereich, Suspicion-Kurve und Caught-Strafe
- Sticker-Button mit `3x` Bio-Stickern pro Tag
- Miete am Tagesende
- Lose bei nicht bezahlbarer Miete
- Coupon-, Sticker- und Sortiment-Upgrade als einfache Buttons
