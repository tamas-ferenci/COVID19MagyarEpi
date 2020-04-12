## Alapgondolat

Az előrejelzések többféle módszeren is alapulhatnak. Egy részük empirikus: nem törődik azzal, hogy mi a háttérben lévő jelenség működése, egyszerűen a tapasztalt múltbeli viselkedést "meghosszabbítja" a jövőre nézve. Ilyen módszerekkel jellemzően rövid távú előrejelzések adhatóak.

A módszerek másik része figyelembe veszi a háttérben lévő folyamatok mechanizmusát (ilyen értelemben szokták ezeket "mechanisztikus" modelleknek nevezni). Számos különböző elven alapuló mechanisztikus modellt próbáltak ki és használtak több-kevesebb sikerrel az epidemiológiában: a legklasszikusabb és máig tartóan legnagyobb hatásúak a kompartment modellek (ezekről részletesebben lesz szó később), újabban népszerűek a mikroszimulációk, melyek minden egyes ember viselkedését szimulálják valamilyen szabályszerűség alapján, és a hálózatelméleten alapuló modellek, melyek az embereket és a köztük lévő, fertőzés átadására alkalmas kapcsolatokat a matematikai gráf fogalmának feleltetik meg, és az ottani ismereteket alkalmazzák a járványok terjedésének leírására.

Amit minden előrejelzésnél meg kell érteni: nincs olyan, hogy ez "a" lefutása a járványnak (amit mi előrejelzünk). Különösen hosszabb távon, meghatározó módon fog számítani, hogy mit teszünk: mik a kormányzati intézkedések, milyen az emberek viselkedése. E nélkül értelme sincs mit mondani, csak a "ha-akkor" típusú kijelentéseknek, tehát a szcenárióelemzéseknek van értelme.

### Empirikus előrejelzés

Ez a módszer a talán legkézenfekvőbb: a tényadatokra illesztett görbét (lásd a Járványgörbe pontnál!) egyszerűen meghosszabbítjuk. Statisztikailag precízebben szólva: ha megvan a modellünk -- melyet a jelenlegi és múltbeli dátumok adatai alapján becsültünk --, lekérjük a becsléseit jövőbeli dátumokra is.

Jelenleg ez a pont az exponenciális görbe illesztését és előrevetítését támogatja.

Ennek pontosságához természetesen fontos, hogy maga az illesztés jó legyen; ehhez beállíthatjuk, hogy a görbe melyik részére illesztünk (ablakozás). Fontos, hogy az ablakozás helyességét, értelmességét itt nem láthatjuk, azt minden esetben a Járványgörbe pont alapján ellenőrizzük!

Az eredményeket megjeleníthetjük grafikonon vagy táblázaton és beállíthatjuk az előrejelzett napok számát is. A Járványgörbe ponthoz hasonlóan logaritmikussá tehetjük a függőleges tengelyt, és megjeleníthetjük a konfidenciaintervallumot is.

Van mód szcenárióelemzésre is e pont alatt, azaz megtehetjük, hogy megvizsgáljuk, hogy akkor mi történik, ha a jövőbeli növekedés nem annyi, mint ami a meglevő esetszámokból következne, hanem annál több vagy kevesebb. Ezzel különféle -- optimistább vagy pesszimistább -- forgatókönyvek is felvázolhatóak.

### Kompartment modell

A kompartment modellek az epidemiológia legnépszerűbb modellje fertőző betegségek terjedésének leírására, előrejelzése. Az alapgondolat, hogy az embereket (például egy ország lakosságát) csoportokra bontjuk, mégpedig hézag- és átfdedésmentesen: mindenki pontosan egy csoportba tartozik, nincs olyan, akik kettőbe, vagy olyan aki egyikbe se. Ezek a csoportok egymástól különböznek, mindjárt pontosan ki is derül, hogy miben, de magukon belül homogének: a benne lévő embereket mind pontosan ugyanolyannak feltételezzük, amik között nincsenek különbségek (például életkorban, nemben, lakhelyben). Azt is feltételezzük, hogy a csoportok tökéletesen keverednek egymással, tehát nem fordulhat elő, hogy egy csoportba tartozó emberek elvonulnak egy megyébe és csak egymással érintkeznek. Az ilyen csoportokat hívjuk kompartmentnek.

Az epidemiológia legklasszikusabb ilyen modellje a SIR-modell, mely épp a kompertmentek tulajdonságáról kapta a nevét. Ez a modell az embereket három ilyen csoportba osztja: vannak fogékonyak (S, susceptible), fertőzöttek akik egyúttal fertőzőképesek is (I, infectious) és gyógyultak vagy más szóval "eltávolítottak" (R, recovered vagy removed); a modell szempontjából ugyanis mindegy lesz, hogy valaki úgy kerül ki a fertőzött csoportból, hogy meghal vagy meggyógyul, a lényeg, hogy többé nem fertőz és nem is fogékony a fertőzésre. Én a továbbiakban gyógyultat fogok mondani az egyszerűség kedvéért.

És akkor most jöjjön a lényeg: a viselkedés! Mert ugye ez a modell attól mechanizmus-alapú, hogy mond valamit a jelenség működéséről. Íme, amit a SIR-modell mond.

Először is: a fogékony csoportból az emberek csak a fertőzött csoportba tudnak kerül, onnan pedig csak a gyógyult csoportba. Már ez is mond valamit arról, hogy mit feltételezünk a betegség mechanizmusáról: a fogékony előbb mindenképp beteg kell legyen, de ami még sokkal fontosabb, hogy a beteg nem válhat újra fogékonnyá! Magyarra lefordítva: ezzel azt feltételezzük, hogy a betegség élethosszig tartó immunitást ad. Vannak fertőző betegségek, melyek nem ilyenek és többször is el lehet őket kapni, ez esetben a SIR-modell nem lesz helytálló. (Használható helyette például SIS-modell, aminek -- a nevével ellentétben -- csak két kompartmentje van, ám a I-ből vissza lehet jutni újra az S-be.)

Másodszor: a SIR-modell nyilatkozik a dolog dinamikájáról, tehát időbeli lefutásáról is, arról, hogy az emberek időben tekintve hogyan kerülnek át egyik csoportból a másikba. A SIR-modell lényege ugyanis, hogy nyomon követi az egyes kompartmentekben lévő emberek számát! Ez három szám lesz, hány fogékonyunk van adott pillanatban, hány fertőzöttünk van adott pillanatban, hány gyógyultunk van adott pillanatban; és mindezek időben változnak (szebben szólva: az idő függvényei lesznek).

A SIR-modell kulcsa, hogy megadja, hogy az átmenetek, fogékonyből fertőzött lesz, fertőzöttből gyógyult lesz, milyen ütemben történnek. (Egész pontosan azt adja meg, hogy az egyes csoportok létszáma milyen gyorsan változik.) A másodikra azt feltételezi, hogy ez az ütem egyenesen arányos a fertőzöttek létszámával: az, hogy milyen gyorsan fogynak a fertőzöttek -- vagy, ami ezzel egyenértékű, milyen gyorsan gyűlnek a gyógyultak -- attól függ, hogy mennyi fertőzött van. Jelölje ezt az arányossági tényezőt $\gamma$. Ez magyarra lefordítva azt jelenti, hogy a fertőzöttek gyógyulása nem függ semmilyen külső körülménytől, állandó rátájú. Félreértés ne essék, hogy ki mennyi idő alatt gyógyul meg, az nem egy fix érték! Van aki lassabban, van aki gyorsabban, tehát a gyógyulási időnek eloszlása van, de a fenti kikötés belátható, hogy azt jelenti, hogy ez az eloszlás egy nevezetes eloszlás (az exponenciális), és hogy ennek a gyógyulási időnek, ami egyúttal a fertőzőképesség hossza is, a várható értéke épp $1/\gamma$. Mondjuk, ha $\gamma=0,\!2$, akkor a betegek *átlagosan* 5 nap alatt gyógyulnak meg (persze van aki több, van aki kevesebb). Megfordítva: ha a betegek átlagosan 5 nap alatt gyógyulnak meg, akkor megtudtuk, hogy $\gamma=0,2$.

Érdekesebb a helyzet a megfertőződéssel. Itt ugyanis az ütem (hogy milyen gyorsan fogynak a fogékonyak és -- ami ezzel egyenlő -- milyen gyorsan szaporodnak a fertőzöttek) már két dologtól is függ: a fogékonyak számától *és* a fertőzöttek számától. Egész egyszerűen azért, mert a fertőzés létrejöttéhez egy fogékony és egy fertőzött ember érintkezése kell! Ha feltesszük, hogy tényleg tökéletes a keveredés a csoportok között, akkor belátható, hogy a megfertőződés ütem a fogékonyak és a fertőzöttek számának *szorzatával* lesz arányos. (Ez intuitíve érthető: a szorzat kicsi, ha bármelyik tagja kicsi. Akkor is lassan szaporodnak a fertőzöttek, ha kevés fogékony van, hiszen limitált, hogy hány emberből tud egyáltalán fertőzött lenni, és akkor is, ha kevés a fertőzött, hiszen ekkor korlátozott számú góc kelti csak az újabb fertőzéseket.) Jelöljük az arányossági tényezőt $\beta$-val. Ez annak a mérőszáma, hogy egy embernek egy időegység alatt hány fertőzés átadására alkalmas kontaktusa van. De ami talán még érdekesebb, hogy ebben a modellben igaz lesz a következő összefüggés: $R=\frac{\beta}{\gamma}$, tehát a reprodukciós szám igen egyszerűen kiadódik ebből a két paraméterből! Avagy, megint csak megfordítva, ha ismerjük a reprodukciós szám értékét, akkor ismerjük $\beta$-t is (feltéve, hogy $\gamma$-t már meghatároztuk).

És kész is, ezzel teljesen specifikáltuk a SIR-modellt!

Az ilyen modelleket tipikusan grafikusan szokták megadni, ami nagyon jól áttekinthetővé tesz őket. A kompartmentek kis dobozok, a köztük lehetséges mozgási irányokat nyilak jelzik, az adott nyíl mentén történő mozgás ütemét pedig a nyílra írva felirat. Ilyen módon valóban minden fenti komponens rajta van az ábrán. Íme a SIR-modell a fenti megadásban:

![SIR modell](SIR.png)

Íme, ezzel kész is vagyunk: ez a legegyszerűbb kompartmentális epidemiológiai modell. Természetesen milliónyi egyszerűsítése van, kezdve a fent felsoroltakkal, hogy a csoportok tökéletesen keverednek, tehát, hogy nincsen semmilyen (életkori, nemi stb.) strukturáltság, hogy a betegség átvészelése végleges immunitást ad, de idevehetjük azt is, hogy nincs születés, és nincs -- betegségen kívüli okokból -- halálozás... Ennek ellenére jó kiindulópont, és egyben építőkő a bonyolultabb, de cserében realisztikusabb modellek felé.

Ez a pont egy ún. diszkrét idejű, diszkrét állapotterű, sztochasztikus SE<sub>2</sub>I<sub>3</sub>R modellt használ; ebből a sok vicces kifejezésből most egy dolog fontos: hogy sztochasztikus. A fent kifejtett modell alapváltozata determinisztikus: ha megadjuk a kezdőértékeket (hány fogékony van kezdetben, hány beteg, hány gyógyult) az egyértelműen meghatározza a teljes lefutást, tehát minden egyes csoport létszáma minden egyes napon egyetlen, első pillanatban pontosan meghatározott érték. Csakhogy a valóság nem ilyen. Vannak véletlenszerű jelenségek, arra, hogy egy nap hányan betegednek meg, nem jó azt, mondani, hogy "123-an!". Igen, lehessen a várható értéke 123, de engedjük meg, hogy -- véletlentől függően! -- éppen 122 vagy 124 legyen a tényleges érték. Ha viszont ezt tesszük, onnantól kezdve a csoportok létszámának alakulása is véletlen: egyszer lefuttatva a modellt kapunk egy alakulást, még egyszer lefuttatva egy másikat, harmadszor futtatva egy harmadik. Éppen ezért az itt látható eredmények úgy készültek, hogy a modell nagyon sokszor (300-szor) lefut, és a közepes értéket -- a pontonkénti mediánt -- mutatja a vastag görbe, körülötte a halványabb sáv az a tartomány, amiben a futtatások 95%-a esett az adott pillanatban. Hogy a dolog jobban érzékelhető legyen, 100 konkrét futás eredménye is ábrázolva van, vékony vonallal.

Adódik a kérdés, hogy akkor most nemsokára napi 300 ezer betegünk lesz?! (Napi?) Igen, mert a modell nem tételez fel semmit az $R$ változásáról! Amit itt látunk, az lényegében az az eset, hogy elindítjuk a dolgot, ráadásul egy elég nagy, 2 feletti $R$-ről, és utána nem csinálunk semmit, hagyjuk, hogy alakuljon a járvány, ahogy magától alakulna. Egy ilyen, kontroll nélküli kitörésnél tényleg ennyire extrém lenne a helyzet. De pont ezért persze nem is ez az igazán érdekes, hanem a szcenárióelemzés: az ábra jobb oldalán lévő táblázatban összeállíthatjuk az $R$ alakulását, és a szimuláció ennek megfelelően fog lefutni. (A változtatások dátumát függőleges fekete vonalak fogják jelölni az ábrán.)

## Matematikai részletek

### Empirikus előrejelzés

Ennek legyártása egyszerű predikció. A konfidenciaintervallumot az általánosított modellek esetében először link skálán határozom meg, $n-2$ szabadságfokú $t$-eloszlással, majd exponenciálom. (Mivel az exponenciálás szigorúan monoton transzformáció, így a konfidenciaintervallum széleit nem kell módosítani, megőrzi a lefedést.)

### Kompartment modell

A használt modell egy SE<sub>2</sub>I<sub>3</sub>R kompartment modell, ami annyiban módosítja a szokásos SEIR modellt (itt az E a lappangó betegek csoportja, akik már fertőzöttek, de még nem fertőzőek), hogy két E és három I kompartmentet fűz egymás után:

![SEIR modell](SEIR.png)

Ennek nagyon egyszerű az oka: egy kompartment esetében a kompartmentben töltött idő -- állandó rátájú kilépés esetén -- exponenciális eloszlású, több esetén pedig emiatt exponenciálisok összege (azaz gamma eloszlás, ebben a speciális esetben szokták Erlang eloszlásnak is nevezni), és egész egyszerűen az empirikus adatok azt mutatják, hogy a fertőzőképesség, illetve a betegség hosszának az eloszlása a valóságban tényleg nem exponenciális. Azért választottam $k=2$-t a lappangási idő eloszlására, és $k=3$-at a betegség időtartamának eloszlására, mert Wearing és mtsai egy [2005-ös cikkükben](https://journals.plos.org/plosmedicine/article?id=10.1371/journal.pmed.0020174) ezt javasolták a SARS-ra.

A fenti modell szokásos felírása a következő differenciálegyenletekből áll:

$$
\begin{equation*}
 \frac{\mathrm{d}S}{\mathrm{d}t} &= -\beta S \left(I_1+I_2+I_3) \\
 \frac{\mathrm{d}E_1}{\mathrm{d}t} &= \beta S \left(I_1+I_2+I_3) - 2\alpha E_1 \\
\end{equation*}
$$

A szokványos SIR/SEIR modellek problémája, hogy folytonos idejűek és folytonos állapotterűek. Az előbbi a kisebb gond, végül is az idő tényleg folytonos -- csak az a baj, hogy a járványügyi adatok gyűjtése viszont diszkrét, legjobb esetben is napi. Ezért a folytonos idejű modelleknél már eleve trükközni kell, hogy ehhez igazodni lehessen a becslésnél. Még nagyobb probléma a diszkrét állapottér: persze egymillió betegnél nem nagyon számít, ha a modell szerinte egymillió *és fél* beteg van, de az 1,5 beteg az probléma lehet. További gond a SIR/SEIR modelleknél, hogy a közvetlen jellemző a fertőzöttek száma egy adott pillanatban, márpedig a járványügyi adatszolgáltatások primer módon általában inkább a napi esetszámról adnak információt.

Az általam használt SEIR modell ezért egy olyan variáns mely diszkrét idejű, és diszkrét állapotterű, tehát az idő a természetes számok halmazán van értelmezve, csakúgy mint az egyes kompartmentek létszáma.

A másik alapvető különbség, hogy a szokványos SIR/SEIR-modellek determinisztikusak. Szerencsére ez könnyen feloldható a fenti diszkrétségi közelítéssel is kombinálva:

A becslés részben megfigyelt Markov-folyamatok elméletén alapszik. Ebben 