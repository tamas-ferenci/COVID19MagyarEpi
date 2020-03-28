## Alapgondolat

Járványok során gyakran elhangzik a köznyelvben is, hogy "exponenciálisan nő a betegek száma". Ez nem csak köznyelvi szófordulat, hanem matematikailag is lehet pontos megfogalmazás. Sokszor előfordul ugyanis, különösen egy járvány kezdeti szakaszában, ha a betegség ellen nincs védőoltás és korábban nem estek át rajta sokan, hogy a betegek szinte csupa fogékony emberrel kerülnek kapcsolatba, így a betegség terjedését egyetlen egy dolog korlátozza: az, hogy hány beteg van. Amíg még kevés, addig a betegek száma is lassabban nő, de minél több beteg van, annál jobban nő a megbetegedések számának növekedési *üteme* is. Ez matematikailag az exponenciális függvény, melynek jellemzője épp ez: hogy minél nagyobb az értéke, annál gyorsabban nő.

Ebben a pontban két dolgot lehet megtenni. Az egyik, hogy a megbetegedések napi számának ábrázolásával képet lehet kapni a járvány helyzetéről; ezt szokás járványgörbének nevezni. (Bár a hivatalos adatközlések gyakran azt adják meg, hogy adott időpontig *összesen* hány beteg volt -- ennek a szép neve: kumulált esetszám -- az epidemiológiai vizsgálatokhoz általában a napi esetszámra kell áttérni. Szokás ezt incidenciának is nevezni, ami igazából az esetek száma osztva a háttérben lévő populáció nagyságával; tipikusan úgy szokták megadni, hogy hány beteg jut százezer lakosra. Amíg egy országon belül nézzük a betegeket, ennek az osztásnak egy gyors járványnál nincs nagy jelentősége, mert a járvány lefutásának ideje alatt olyan nagyon nem változik meg az ország lélekszáma.)

A másik feladat ami ebben a komponensben végrehajtható, az a görbeillesztés az esetszámokra. Ha tudjuk, hogy exponenciális a növekedés, miért nem illesztjük rá a -- matematikailag ismert -- exponenciális görbét? Ez azért fontos, mert ha rápasszítunk egy ilyet (tehát megkeressük a legjobban illeszkedő exponenciálisat), akkor annak paraméterei bizonyos értelemben tisztán, az esetszámok lévő ingadozás jelentette zajtól megtisztítva mutatják, hogy mi a betegszám növekedési üteme. Márpedig ez a szám sok további számításhoz fontos input-adat.

Ami nagyon fontos lehet, hogy pontosan mely pontokra illesztjük a görbét: elképzelhető, hogy az adatok csak egy szakaszon szép exponenciálisak, például a járvány legeleje még máshogy viselkedik, ezért azt le kell választani a becslésből. Az is elképzelhető, hogy több szakasza van a járványnak, melyeknél külön-külön egy exponenciális görbére illeszkednek a pontok, de a különböző szakaszoknak más és más meredeksége. Az ilyen és ehhez hasonló helyzetekre használható az ablakozás: ekkor továbbra is valamennyi pontot látunk, de a görbe illesztése csak az ablakon belül lévő pontok alapján történik. (Így például lehagyható az első néhány pont, vagy kiválasztható egy adott szakasz.)

És még egy fontos dolog a végére: lényeges azt is megvizsgálni, hogy teljesül-e egyáltalán az a feltevésünk, hogy a pontok exponenciális görbére illeszkednek! E célból megjeleníthető az ún. LOESS simítás is, ez egy nemparaméteres módszer, ami magyarul azt jelenti, hogy -- szemben az exponenciális illesztéssel -- nem feltételezi, hogy a függvényforma adott alakú, hanem minden ilyen feltételezéstől mentesen követi az adatokat (pontokat). Ha ez a görbe nagyjából egybeesik az exponenciális illesztéssel, az megnyugtató jel, hiszen azt mondja, hogy nem egy exponenciálistól eltérő adathalmazra kényszerítettünk rá egy exponenciális görbét.

Beállítható, hogy a függőleges tengely logaritmikus beosztású legyen, ez azt jelenti, hogy ha felfelé lépdelünk a tengely mentén, akkor minden lépés ugyanannyi*szoros* (és nem ugyanannyi*val*) történő növekedést jelent; ez azért fontos, mert az exponenciálisnak megvan az a tulajdonsága, hogy ilyen skálázás mellett egy egyenes vonal lesz. (És emberi szemmel sokkal könnyebb egy egyenesre való illeszkedést megítélni.)

Mindkét esetben megjeleníthető az ún. konfidenciaintervallum, ez arról szolgáltat információt, hogy mennyire bizonytalan a görbe becslése. Hiszen ezeket a görbéket véges sok pont alapján határozzuk meg, amik helyzetében véletlen ingadozás is van, így a belőlük számolt görbékben is. Ezt szemlélteti a konfidenciaintervallum: minél szélesebb, annál bizonytalanabb ott a görbe értéke. (Precízen: a konfidenciaintervallum pontjai azok az értékek, amikre igaz, hogy ha az lett volna a valódi érték, akkor még kényelmesen kijöhetett -- a véletlen ingadozásra tekintettel -- az, ami a valóságban ténylegesen ki is jött. A konfidenciaintervallum megbízhatósági szintje szabályozza, hogy mit értünk "kényelmesen" alatt.)

## Matematikai részletek

Jelölje a betegek számát $t$ időben $I\left(t\right)$, ekkor a "növekedési ütem" magyarul a derivált, tehát az a kijelentés, hogy "a növekedési ütem a betegek számával arányos", így írható le matematikai formában:
\[
  \frac{\mathrm{d}I\left(t\right)}{\mathrm{d}t}=rI\left(t\right).
\]
Ez egy egyszerű differenciálegyenlet, melynek megoldása:
\[
  I\left(t\right)=ae^{rt},
\]
ahol az $r$ paraméter a növekedési ráta.

### Exponenciális görbe illesztése

Alapvetően két út között választhatunk. Az egyik lehetőség, hogy eltekintünk az adatok diszkrétségétől, és úgy vesszük mintha az esetszám folytonos változó lenne, és így egyszerű lineáris regressziót használunk. Ehhez persze -- hogy tényleg lineáris legyen -- az esetszámot logaritmálni kell. Ezt lognormális modellnek fogjuk hívni, utalva a hibatag eloszlására (ha a lineárizált modellben normális, akkor az exponenciálás után, tehát az eredeti esetszámok szintjében lognormális lesz a hibatag eloszlása).

A másik lehetőség, hogy figyelembe vesszük, hogy az esetszámok értékei a $\left\{0,1,\ldots\right\}$ halmazból kerülnek ki ("count data"), és ténylegesen ezt a diszkrétséget figyelembe vevő modellt illesztünk. Ez már nem kezelhető lineáris modellként, de szerencsére az általánosított lineáris modell (GLM) keretrendszerébe egyszerűen és kényelmesen illeszkedik. Az exponenciális görbe illesztése az által fog megvalósulni, hogy link függvényként a logaritmust választjuk. Egyedül az eredményváltozó eloszlásáról kell mondani még valamit; ez ilyen adatoknál legtipikusabban Poisson, vagy -- hogy meg tudjuk engedni, hogy a variancia eltérjen a várható értéktől -- negatív binomiális.

#### Lognormális modell

Az illesztés hagyományos legkisebbek négyzetek (OLS) elven történik, a logaritmált adatokon. Elvileg lehetne az eredeti adatokra is exponenciálisat illeszteni nemlineáris legkisebb négyzetek (NLS) módszerével; a kettő csak látszólag ugyanaz, valójában véges mintából becslés esetén nem teljesen, hiszen a más skálán lévő eredményváltozó miatt a reziduumok más súlyt kapnak. A gyakorlatban azonban -- ha lehet algebrailag linearizálni, márpedig itt lehet -- mindenképp preferált az OLS, hiszen összehasonlíthatatlanul stabilabb.

#### Poisson és negatív binomiális modell

A GLM modellek maximum likelihood (ML) elven becsülhetőek, tipikusan iteratívan újrasúlyozott legkisebb négyzetek (IWLS, IRLS) módszerével. Negatív binomiális eloszlás esetén a plusz paraméter becslése miatt kicsit bonyolultabb a helyzet, de lényegében ott is ML becslés történik.

### LOESS nemparaméteres simítás

E módszer lényege, hogy nem tételezünk fel semmilyen függvényformát, hanem "követjük az adatokat" (nem-paraméteres regresszió). A LOESS ezt úgy oldja meg, hogy minden ponton végigmegy, és első lépésben veszi a lokális környezetét: egyfelől sorbarakja az összes többi pontot a kérdéses ponttól vett távolság szerint és a legtávolabbi 25%-ot eldobja, majd a meghagyott pontokat is súlyozza a kérdéses ponttól vett távolság szerint (egész pontosan az $\left[1-\left(d/M)^3\right]^3$ függvény szerint, ahol $d$ a távolság, $M$ pedig a távolságok maximuma a meghagyott pontok között). Az így kapott, szűkített és súlyozott ponthalmazra ezután másodfokú polinomot illeszt (legkisebb négyzetes elven), és az e szerint predikált érték a kérdéses pontban lesz a simítógörbe értéke az adott ponton.

## Számítástechnikai részletek

Az ábrázoláshoz a `ggplot2` csomagot használtam. A lognormális modell becslése `lm`-mel, a Poisson-regresszió `glm`-mel, a negatív binomális modell becslése `MASS::glm.nb`-vel történik. A LOESS simítás a `loess` paranccsal történik (amit a `geom_smooth` hív meg).