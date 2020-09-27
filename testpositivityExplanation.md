## Alapgondolat

A tesztpozitivitás azt mutatja meg, hogy adott napon az elvégzett tesztek mekkora hányada lett pozitív.

Első ránézésre ("pozitívak aránya") ez valamiféle súlyosság mérőszáma, de erről nincs szó, hiszen függ a teszteléstől is, ami viszont -- bizonyos korlátokon belül -- döntés kérdése, megnövelésével tetszőlegesen lecsökkentő az arány, ugyanazon járványügyi helyzetben is.

Ez azonban épp azt mutatja meg, hogy akkor mire jó a mutató: *a tesztelés elégségességének mérésére*. Így nézve pont szerencsés, hogy egyszerre határozza meg az esetek és a tesztek száma, hiszen azt mondja, hogy ha nagyon el is szabadul a járvány, akkor is megjavítható a mutató, ha többet tesztelünk -- ami épp az, amit tenni kell, ha elszabadul a járvány. A tesztpozitivitás tehát lényegében azt méri, hogy a tesztelési aktivitás arányban áll-e a járványügyi helyzet súlyosságával.

Ha azt tapasztaljuk, hogy a tesztpozitivitás megnő, az arra utal: a rendszer nem képes még arra sem, hogy a detektált esetek növekedésével arányban emelje a tesztek számát. Minél magasabb a tesztpozitivitás, annál nagyobb részét nem találjuk meg vélhetően az eseteknek (és ezért annál kevésbé megbízható a detektált esetek járványgörbéje és minden abból számolt mutató!). Az Egészségügyi Világszervezet ajánlása 5%-os tesztpozitivitást irányoz elő; az ábrán ezt jelöli a vízszintes piros vonal. Természetesen fontos újra hangsúlyozni, hogy nem csak a tesztpozitivitás aktuális értéke, hanem a trendje is fontos.

(Valójában persze ez sem igaz tökéletesen, hiszen a tesztelések számán túl az is fontos kérdés, hogy milyen mintázat szerint tesztelünk, például mennyire megszorítóan értelmezzük a kontaktus-személyek tesztelését, és ez akár időben is változhat még ugyanazon országon esetében is, de ezeket a kérdéseket már csak finomabb és több adatot igénylő elemzéssel lehetne vizsgálni.)

Fontos, hogy a tesztpozitivitást ne keverjük össze a népesség átfertőzöttségével (tehát, hogy az emberek mekkora hányada fertőzött). A tesztpozitivitás csak akkor mérné az átfertőzöttséget, ha a teszteket a lakosság egy véletlenszerűen kiválasztott részén végeznék, és bár néha ilyenre is van példa, mint Magyarországon a H-UNCOVER vizsgálat esetében, de a tesztek túlnyomó részét egy nagyon nem véletlenszerű csoporton végzik (tünetei vannak, ismert fertőzött kontaktus-személye stb.). Az ő körükben természetesen sokkal magasabb a fertőzöttek aránya, mint általában a lakosságban.

## Matematikai részletek

A tesztpozitivitás egyszerűen a napi esetszám és a napi teszt-szám hányadosa. A simítógörbét spline-regresszióval határoztam meg, binomiális eredményváltozót feltételezve (ahol az $n$ a tesztek, a $k$ a pozitívak, tehát az esetek száma volt).

## Számítástechnikai részletek

Az ábrázoláshoz a `ggplot2` csomagot használtam, a simítógörbe becslése `mgcv::gam`-mal történt (amit a `geom_smooth` hív meg).

## Irodalmi hivatkozások

- World Health Organization. (2020). Public health criteria to adjust public health and social measures in the context of COVID-19: annex to considerations in adjusting public health and social measures in the context of COVID-19, 12 May 2020. World Health Organization. (https://apps.who.int/iris/handle/10665/332073 accessed 04 September 2020).