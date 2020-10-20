## Alapgondolat

A többlethalálozás gondolatához legegyszerűbb úgy eljutni, hogy a halálozási szám azon problémájából indulunk ki, hogy érzékeny arra, hogy mi a haláloki besorolások definíciója. Amint láttuk, ez a haláloki adatgyűjtések szükségszerű problémája, nem egy kiküszöbölhető hiba. Akkor mi lenne, ha egyáltalán nem törődnénk a halálokkal, egyszerűen csak azt számolnánk, hogy hányan halnak meg (bármi miatt is)...? Ez az össz-halálozás (angolosan szólva minden okból bekövetkező -- all cause -- halálozás), elérhető napi, de legrosszabb esetben heti felbontással, nem és életkor szerint bontva.

A kérdés, ami azonnal felvetődik, hogy rendben, de akkor honnan tudjuk, hogy mi a járvány hatása? Ha 100-an belehalnak egy nap a vizsgált betegségbe, az tudjuk, hogy rossz, de ha 100-an halnak meg összesen egy nap? Akkor az mit jelent? Ha egyébként 200-an halnának meg, akkor az kimondottan jó, ha 50-en, akkor egyáltalán nem. A válasz a kérdésre: hasonlítsuk a dolgot a múltbeli adatokhoz! Ez a legjobb kapaszkodónk arra, hogy "egyébként hányan halnának meg"! Természetesen egy sor dologra oda kell figyelnünk, például, hogy a halálozásoknak van egy jellegzetes éven belüli mintázata -- mindig télen van a legtöbb, nyáron a legkevesebb -- ezt szokás szezonális mintázatnak nevezni, ezért nem hasonlíthatunk akármilyen időponthoz a múltból, a halálozásoknak van hosszú távú trendje is, amire figyelni kell, ha előrevítünk, hogy idén hány lett volna, ha nincs járvány és így tovább. A lényeg, hogy az így előrevetített "várt" halálozások számát kivonva a ténylegesen megfigyelt számból kapjuk meg a többlethalálozást.

Ez a megoldás azonnal és komplettül megoldja a haláloki besorolás problémáját, hiszen ilyen besorolásra nincs is szükség. A másik nagy előnye, hogy azonnal és ez már tényleg komplettül megoldja a tesztelési aktivitástól való függés problémáját.

Cserében viszont van egy nagyon nagy ára is, ami a fentiekből már érzékelhető: az, hogy nettó mutató, ami a járvány *összes*, direkt és indirekt hatását egybeméri. Hiszen a járványnak nem csak a direkt hatása van (azaz, hogy van aki belehal), hanem indirekt hatásai is. Ráadásul ezek lehetnek pozitívak és negatívak is. Például pozitív indirekt hatása, hogy a bevezett intézkedések, távolságtartás, kézmosás stb. segítenek megelőzni az összes többi légúti betegség terjedését is. De akár extrémebb dolgokra is gondolhatunk, például, hogy az otthonmaradásra való buzdítás miatt a közúti balesetben meghaltak száma is csökken. Igen ám, de vannak indirekt negatív hatások is: az egészségügyi rendszer átállítása, részben leállítás miatt más betegségben szenvedők ellátása nehezedik meg, szenved halasztást, szűrőprogramok lehetetlenednek el stb., de itt is gondolhatunk még áttételesebb -- de sajnos nem irreális -- dolgokra, például, hogy nő az öngyilkosságok száma, vagy, hogy a munkanélküliség növekedése is jól ismerten rontja az egészségi állapotot.

A többlethalálozás mindezek elkülönítését nem teszi lehetővé, csak a "végeredményt" látjuk. Éppen ezért használata is inkább arra korlátozódik, hogy megítéljük, hogy "nagyon nagy baj nincs-e". (Értsd: nem szökik-e fel nagyon a többlethalálozás. Persze kis baj lehet, hiszen azt az indirekt hatások kompenzálhatják. A fordított eset is elképzelhető, tehát, hogy az indirekt hatások adnak sok halottat, de ez kevésbé valószínű.) Mindemellett persze az a limitáció is ott van, hogy az egész egy becsült előrejelzésen nyugszik -- azt valójában senki nem tudhatja biztosan, hogy mennyi halálozás lett volna, ha nem lett volna járvány! -- ebből is látszik, hogy az eredmények miért kezelendőek óvatosan.

A többlethalálozás adatnak még egy baja van: az, hogy lassú, a leglassabb az összes mutatónk között. És itt most nem csak a biológiai késleltetésekről beszélünk. Értelemszerűen minden olyan biológiai késleltetés (lappangási idő, kórházba kerülésig eltelő idő, kórházban a halálig eltelő idő), ami a halál késleltetését adja, az megjelenik itt is, csakhogy itt még megjelenik egy nagyon komoly adminisztratív késleltetés is: amíg a betegségbe belehaltak száma relatíve gyorsan elérhetővé válik a halál bekövetkezése után (hiszen a betegség miatt kórházban levőkről van közel valós idejű adat), addig az összes elhunytról csak a halottvizsgálati bizonyítványok összesítéséből vagy az elektronikus anyakönyvi rendszer adataiból fogunk értesülni. Ennek késleltetése tetemes (több hét, akár hónap), ami még hozzájön pluszban a többi késleltetéshez.

## Matematikai részletek

A valószínűségi modellünk:
\[
	Y_t \mid \varepsilon_t \sim \text{Poi}\left(\mu_t\left[1+f\left(t\right)\right]\varepsilon_t\right),
\]
ahol $\varepsilon_t$ nem feltétlenül fehérzaj, lehet autokorrelált, az adatok autokorreláltságának elszámolására (a napi adat erősen az, a heti nem feltétlenül); legyen többváltozós normális AR($p$) szerinti kovarianciamátrixszal. Ezen felül
\[
	\mu_t = N_t \exp\left[\alpha\left(t\right)+s\left(t\right)+w\left(t\right)\right],
\]
ahol $\alpha\left(t\right)$ a hosszú távú -- lassan változó -- trend, $s\left(t\right)$ az éven belüli mintázat (szezonalitás), $w\left(t\right)$ pedig a hét napja hatás (ha napi adatunk van), és $N_t$ a háttérpopuláció. $f\left(t\right)$ lesz a keresett többlet (szorzóként, hiszen log link mellett multiplikatív az egész modell). A modell becslése cseles, ML, de óvatosan kell eljárni ($\varepsilon_t$ is elég általános, és $f\left(t\right)$ is nézhet ki furcsán, pl. szakadása van).

## Számítástechnikai részletek

Az ábrázoláshoz a `ggplot2` csomagot használtam, a többlethalálozás modellezése az `excessmort` csomaggal történt.

## Irodalmi hivatkozások

- Acosta, Rolando J and Irizarry, Rafael A. Monitoring Health Systems by Estimating Excess Mortality. (https://www.medrxiv.org/content/10.1101/2020.06.06.20120857v2).