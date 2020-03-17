## Adatok forrása

Sajnos egyelőre kézzel gépeltem be (a hírek alapján), hivatalos forrást, ahol gépi úton feldolgozható, napi bontású adatok lennének, nem találtam.

## Alapgondolat

Járványok során gyakran elhangzik a köznyelvben is, hogy "exponenciálisan nő a betegek száma". Ez nem csak köznyelvi szófordulat, hanem matematikailag is pontos megfogalmazás. Sokszor előfordul (például a járvány kezdeti fázisában, ha a betegség ellen nincs védőoltás, korábban nem estek át rajta sokan), hogy a betegek szinte csupa fogékony emberrel kerülnek kapcsolatba, így a betegség terjedését egyetlen egy dolog korlátozza: az, hogy hány beteg van. Amíg még kevés, addig a betegek száma is lassabban nő, de minél több beteg van, annál jobban nő a megbetegedések számának növekedési *üteme* is. Ez matematikailag az exponenciális függvény, melynek jellemzője épp ez: hogy minél nagyobb az értéke, annál gyorsabban nő.

Ebben a pontban két dolgot lehet megtenni. Az egyik, hogy a megbetegedések napi számának ábrázolásával képet lehet kapni a járvány helyzetéről; ezt szokás járványgörbének nevezni. (Bár a hivatalos adatközlések gyakran azt adják meg, hogy adott időpontig *összesen* hány beteg volt -- ennek a szép neve: kumulált esetszám -- az epidemiológiai vizsgálatokhoz általában a napi esetszámra kell áttérni. Szokás ezt incidenciának is nevezni, ami igazából az esetek száma osztva a háttérben lévő populáció nagyságával; tipikusan úgy szokták megadni, hogy hány beteg jut százezer lakosra. Amíg összességében nézzük a betegeket, ennek az osztásnak jellemzően nincs nagy jelentősége, mert a járvány lefutásának ideje alatt olyan nagyon nem változik meg az ország lélekszáma.)

A másik feladat ami ebben a komponensben végrehajtható, az a görbeillesztés az esetszámokra. Ha tudjuk, hogy exponenciális a növekedés, miért 

## Matematikai részletek

Jelölje a betegek számát $t$ időben $I\left(t\right)$, ekkor a "növekedési ütem" magyarul a derivált, tehát az, hogy a növekedési ütem a betegek számával arányos, így írható le:
\[
  \frac{\mathrm{d}I\left(t\right)}{\mathrm{d}t}=rI\left(t\right).
\]
Ez egy egyszerű differenciálegyenlet, melynek megoldása:
\[
  I\left(t\right)=I\left(0\right)e^{rt},
\]
ahol az $r$ paraméter a növekedési ráta.

### Exponenciális görbe illesztése

Az illesztés hagyományos legkisebbek négyzetek (OLS) elven történik, a logaritmált adatokon.

TODO

### LOESS nemparaméteres simítás

E módszer lényege, hogy nem tételezünk fel semmilyen függvényformát, hanem "követjük az adatokat"

TODO

## Számítástechnikai részletek

Az ábrázoláshoz a `ggplot2` csomagot használtam.