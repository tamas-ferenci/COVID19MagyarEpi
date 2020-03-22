## Adatok forrása

Az adatokat egyelőre kézzel gépelem be az NNK adatközlései alapján, naponta. Remélem ez csak átmeneti helyzet addig, amíg normális formátumban elérhető (=gépi úton feldolgozható, napi bontású) hazai adatközlés nem jön létre.

## Alapgondolat

Járványok során gyakran elhangzik a köznyelvben is, hogy "exponenciálisan nő a betegek száma". Ez nem csak köznyelvi szófordulat, hanem matematikailag is pontos megfogalmazás. Sokszor előfordul (például a járvány kezdeti fázisában, ha a betegség ellen nincs védőoltás, korábban nem estek át rajta sokan), hogy a betegek szinte csupa fogékony emberrel kerülnek kapcsolatba, így a betegség terjedését egyetlen egy dolog korlátozza: az, hogy hány beteg van. Amíg még kevés, addig a betegek száma is lassabban nő, de minél több beteg van, annál jobban nő a megbetegedések számának növekedési *üteme* is. Ez matematikailag az exponenciális függvény, melynek jellemzője épp ez: hogy minél nagyobb az értéke, annál gyorsabban nő.

Ebben a pontban két dolgot lehet megtenni. Az egyik, hogy a megbetegedések napi számának ábrázolásával képet lehet kapni a járvány helyzetéről; ezt szokás járványgörbének nevezni. (Bár a hivatalos adatközlések gyakran azt adják meg, hogy adott időpontig *összesen* hány beteg volt -- ennek a szép neve: kumulált esetszám -- az epidemiológiai vizsgálatokhoz általában a napi esetszámra kell áttérni. Szokás ezt incidenciának is nevezni, ami igazából az esetek száma osztva a háttérben lévő populáció nagyságával; tipikusan úgy szokták megadni, hogy hány beteg jut százezer lakosra. Amíg egy országon belül nézzük a betegeket, ennek az osztásnak jellemzően nincs nagy jelentősége, mert a járvány lefutásának ideje alatt olyan nagyon nem változik meg az ország lélekszáma.)

A másik feladat ami ebben a komponensben végrehajtható, az a görbeillesztés az esetszámokra. Ha tudjuk, hogy exponenciális a növekedés, miért nem illesztjük rá a -- matematikailag ismert -- exponenciális görbét? Ez azért fontos, mert ha rápasszítunk egy ilyet (tehát megkeressük a legjobban illeszkedő exponenciálisat), akkor annak paraméterei bizonyos értelemben tisztán, az esetszámok lévő ingadozás jelentette zajtól megtisztítva mutatják, hogy mi a betegszám növekedési üteme. Márpedig ez a szám sok további számításhoz fontos input-adat.

Ami nagyon fontos lehet, hogy pontosan mely pontokra illesztjük a görbét: elképzelhető, hogy az adatok csak egy szakaszon szép exponenciálisak, például a járvány legeleje még máshogy viselkedik, ezért azt le kell választani a becslésből. Az is elképzelhető, hogy több szakasza van a járványnak, melyeknél külön-külön egy exponenciális görbére illeszkednek a pontok, de a különböző szakaszoknak más és más meredeksége. Az ilyen és ehhez hasonló helyzetekre használható az ablakozás: ekkor továbbra is valamennyi pontot látunk, de a görbe illesztése csak az ablakon belül lévő pontok alapján történik. (Így például lehagyható az első néhány pont, vagy kiválasztható egy adott szakasz.)

És még egy fontos dolog a végére: lényeges azt is megvizsgálni, hogy teljesül-e egyáltalán az a feltevésünk, hogy a pontok exponenciális görbére illeszkednek! E célból megjeleníthető az ún. LOESS simítás is, ez egy nemparaméteres módszer, ami magyarul azt jelenti, hogy -- szemben az exponenciális illesztéssel -- nem feltételezi, hogy a függvényforma adott alakú, hanem minden ilyen feltételezéstől mentesen követi az adatokat (pontokat). Ha ez a görbe nagyjából egybeesik az exponenciális illesztéssel, az megnyugtató jel, hiszen azt mondja, hogy nem egy exponenciálistól eltérő adathalmazra kényszerítettünk rá egy exponenciális görbét.

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

Az illesztés hagyományos legkisebbek négyzetek (OLS) elven történik, a logaritmált adatokon: megkeressük azt az $\widehat{a}$ és $\widehat{r}$ értékeket, amelyekkel a modell szerint becsült betegszámok ($\widehat{I}\left(t\right)=\widehat{a}e^{\widehat{r}t}$) a legközelebb vannak a tényleges $I\left(t\right)$ betegszámokhoz. A módszer onnan kapta a nevét, hogy a "legközelebb van" kitételt úgy értjük, hogy minden időpillanatban vesszük az eltérést a modell szerint becsült és a tényleges érték között, ezt négyzetre emeljük (hogy megszabaduljunk az előjeltől -- a statisztikus viccekkel szemben ha egyszer 10-zel alábecslünk egyszer meg 10-zel fölé, az nem jelenti azt, hogy tökéletesek voltunk), majd ezeket az eltérésnégyzeteket összeadjuk. Ez jellemzi adott görbe illesztésének a jóságát; az összes lehetséges görbe (ami jelen esetben a két paraméterrel egyenértékű) közül azt választjuk, hogy ez minimális legyen.

Egész pontosan, mivel logaritmált adatokon dolgozunk, így $\widehat{a}+\widehat{r}t$ lesz a becsült érték és $\log I\left(t\right)$ a tényleges. Ezt lineáris modellnek hívják, és ez adja a logaritmálás okát: az ilyen modellek összehasonlíthatatlanul biztosabban és kényelmesebben becsülhetőek, mint az eredeti, nemlineáris modell.

Összefoglalva, a görbe illesztéséhez megoldandó feladat:

\[
  \left(\widehat{a},\widehat{r}\right) = \argmin_{} \sum_{t=1}^T \left[\left(\widehat{a}+\widehat{r}t\right)-\log I\left(t_i\right)\right]^2
\]
ahol $t_1, t_2, \ldots, t_n$ azok az időpontok, amikor megfigyelésünk van. (Természetesen az is idetartozik, ha akkor éppen 0 volt az esetszám)

Mivel lineáris a helyzet, így ennek könnyen számolható, sőt, zárt alakú megoldása van, melyet bármely standard statisztika tankönyv tartalmaz. Csak a végeredményt közölve:

TODO

#### Poisson és negatív binomiális modell

Ezek a modellek már 

### LOESS nemparaméteres simítás

E módszer lényege, hogy nem tételezünk fel semmilyen függvényformát, hanem "követjük az adatokat". 

TODO

## Számítástechnikai részletek

Az ábrázoláshoz a `ggplot2` csomagot használtam, a lineáris regresszió becslését és a LOESS simítást egyaránt a `stat_smooth`-on keresztül hívtam meg (előbbi eset az `lm`, utóbbi a `loess` meghívását használja).