## Alapgondolat

Abban a szakaszban, amikor a járványgörbe felfutása exponenciális, az azon a szakaszon kimért növekedési ráta felhasználható a reprodukciós szám becslésére. Ez intuitíve is logikus: minél gyorsabban fut fel egy járvány, annál nagyobb az $R$. A valóságban az összefüggés ennél kicsit bonyolultabb, számít az is, hogy egy fertőzött milyen gyorsan adja át a betegséget, de Wallinga és Lipitsch [2007-es cikkükben](https://royalsocietypublishing.org/doi/abs/10.1098/rspb.2006.3754) részletesen kidolgozták ennek a matematikáját. Nagyon leegyszerűsítve az alapgondolat: ha az illesztett görbe alapján a duplázódási idő 5 nap, és a betegség serial interval-a szintén 5 nap, akkor $R=2$. Hiszen 5 nap alatt jönnek létre a másodlagos fertőzések, és az kétszer annyi beteget jelent, akkor mindenki átlagosan két embernek adta át a fertőzést. Ha a duplázódási idő 5 nap, de a serial interval csak 3, akkor az $R$ kisebb mint kettő, hiszen 5 nap alatt egy átadási generációnál több is történik, *mégis* csak kétszer annyi beteg van -- egy beteg tehát 2-nél kevesebb betegnek adta át a kórt. Fordítva, ha a serial interval hosszabb mint a duplázódási idő, akkor az $R$ nagyobb mint 2, mert még az első generáció sem jöhetett létre teljesen, mégis már kétszer annyi beteg van -- egy beteg tehát 2-nél többnek adta át a kórt átlagban.

Ez a pont ezt a gondolatot használja fel az $R$ becslésére. Ne feledjük: a kulcskérdés, hogy az $R$ értéke hogyan viszonyul az 1-hez.

Kiválasztható a teljes görbére illesztett exponenciális, vagy ez ablakozható is. Az ablakozás szerepe itt is ugyanaz: kikereshetjük a releváns időtartományt, ahol tényleg exponenciálisan viselkedik a járványgörbe. Fontos, hogy az ablakozás helyességét, értelmességét itt nem láthatjuk, azt minden esetben a Járványgörbe pont alapján ellenőrizzük!

Amennyiben időben változik az $R$ (és így a növekedési ráta is), egy kézenfekvő megoldás a folyamatosan változó dinamika követésére a csúszóablak: a 7. naptól kezdve minden egyes napra kiszámoljuk a megelőző 7 nap adataiból számolt növekedési rátát, és abból az $R$-et. (Innen kapta a módszer a nevét: mintha egy hét nap szélességű ablakot végigtolnánk a görbén, és mindig az ablakban látott adatokból számolnánk.) Így mindig az aktuális helyzetről kapunk képet, annak árán, hogy bizonytalanabb lesz a becslésünk, hiszen mindig csak 7 napnyi adatot használunk fel, bármilyen hosszú is a járványgörbe. Természetesen az ablak szélessége állítható: a hosszabb ablak stabilabb becslést eredményez, de összemoshat különböző dolgokat, a szűkebb ablakban gyorsabban tudja követni az $R$ változásait, de a kevesebb adat miatt bizonytalanabb becslés a dolog ára.

Mindenesetre ezzel a módszerrel az időben változó $R$-et (például: járványügyi intézkedések hatása) is nyomon tudjuk követni.

## Matematikai részletek

Elsőként az Euler--Lotka-egyenletet vezetjük le.

TODO

A csúszóablak szélességének a megválasztása, illetve annak dilemmája a statisztikában jól ismert bias-variance trade-off egy példája.

TODO

A konfidenciaintervallum számításához a regressziós modellből vettünk újra és újra mintákat, felhasználva a növekedési ráta standard hibáját (lényegében poszterior szimulációt végeztünk).

TODO

## Számítástechnikai részletek

A növekedési ráta átszámítására Wallinga és Lipitsch cikkének gondolatát közvetlenül felírtam gamma eloszlásra (`r2R0gamma` és `lm2R0gamma_sample` függvények). A cikk melléklete a szükséges formulát közvetlenül is tartalmazza. A csúszóablakot a `zoo::rollapply` valósítja meg.