## Alapgondolat

Egy betegség "veszélyességének" legalapvetőbb mérőszáma a *halálozási arány*, különösen, ha az nem elhanyagolhatóan kicsi. Természetesen egy sor egyéb jellemző is fontos a járvány terhe szempontjából, hiszen nem csak a belehalás a probléma, hanem a szenvedés, az esetleges marandó károk, az egészségügyi ellátórendszer terhelése, a munkából kiesés stb. stb. is, de a halálozás a talán legdirektebb mutató, illetve általában jól együttmozog a többi típusú teherrel is.

A halálozási arány számítása egy éppen zajló járvány közben nem nyilvánvaló feladat. A kézenfekvő formula ("összes halálozás osztva az összes esettel") jól működik a járvány *után*, ha már minden eset -- így vagy úgy -- de lezáródott.

Valójában ez sem teljesen igaz, hiszen egyrészt a halálok meghatározása sem nyilvánvaló kérdés -- erről részletesebben lásd a 'Járványgörbe (halálozások száma)' pont magyarázatát! -- másrészt az esetek száma, tehát a nevező sem problémamentes, hiszen mi van azokkal, akik nem mentek orvoshoz a tüneteikkel? Vagy orvoshoz mentek, de nem tesztelték le őket? Vagy egyáltalán nem is voltak tüneteik? Az előbbi kérdéstől most eltekintünk, adottnak vesszük, hogy mi egy ország definíciója erre, de az utóbbi problémára még hangsúlyosan visszatérünk.

Kezdjük a történetet az elején. Ami bizonyos, hogy ez a képlet a járvány *közben* nem alkalmazható. A probléma, hogy az "összes eset" egy része még zajlik, szép szóval élve: aktív, vagy nem lezárt eset, ott fekszenek a kórházban, és mi sem tudhatjuk mi lesz a kimenetük. A képlet csak akkor lenne helyes, ha kivétel nélkül mindegyikük meggyógyul, de ha bárki meghal közülük, akkor a képlet már torzított lesz, hiszen akkor ennek a halálozásnak a számlálóban is szerepelnie kellett *volna*, hiszen a neki megfelelő beteg a nevezőben szerepelt... de nem lesz ott, mert most még mi sem tudhatjuk, hogy meg fog halni. Azaz a képlet *alá fogja becsülni* a halálozási rátát, hiszen a vetítési alapban szereplő betegek egy része sajnos *majd még* meg *fog* halni, de a jövőben, így a képlet ezekkel nem tud számolni -- pedig kellene.

Szerencsére, ha van információnk a betegség fellépésétől a halálozásig eltelő idő eloszlásáról, azon esetek révén akik végül meghaltak, akkor ez a torzítás statisztikai eszközökkel kiküszöbölhető. Gondoljunk arra, hogy ha minden elhunyt pontosan 10 nappal a diagnózis után hal meg, akkor egyszerűen elég annyit tenni, hogy a halálozások számát a 10 nappal _ezelőtti_ esetszámmal osztjuk. A valóságban bonyolultabb a helyzet, hiszen a diagnózistól a halálig eltelő idő valójában sztochasztikus, lehet kevés is meg lehet sok is, de ha ismerjük ezeknek a valószínűségeit, akkor megfelelő matematikai eszközökkel a korrekció ez esetben is elvégezhető.

Nevezzük a naiv számítás eredményét nyers halálozási aránynak, a fenti korrekcióval kapott értéket pedig korrigált halálozási rátának.

Ez utóbbi biztos jobb, hiszen eltüntetett egy alábecslést, de még mindig van egy, teljesen más problémakör: az, hogy hány esetet találunk meg. Tételezzük fel, hogy a súlyos eseteket (pláne a halálozásokat) mind megtaláljuk, de az enyhébbek, urambocsá' tünetmentesek kérdésesek, erősen múlnak azon, hogy az ország mennyit tesztel. Könnyen látható, hogy ha valamely ország nagyon kiterjedten tesztel, rengeteg enyhe esetet is megtalál, akkor az ő hányadosában nagy lesz a nevező -- de ez nem baj, hiszen ez egy reálisabb érték. Viszont ha egy ország kevésbé intenzíven tesztel, kevesebb enyhe esetet talál meg, akkor a nevezője kisebb lesz, és így a halálozási rátája abnormálisan nagy lesz.

(Néha szokták a korrekciót egyszerűen úgy megoldani, hogy a halottak számát a lezárt esetekkel osztják, tehát a gyógyultak és a halottak összegével. Ez egy roppant egyszerű és szellemes megoldás a fenti problémára, és nem is rossz tulajdonságú becslő, csak az a baja, hogy az adatok egy részét -- a még nem lezárt eseteket -- egyáltalán nem használja, és ez különösen egy járvány elején érzékeny veszteség lehet: azáltal, hogy kevesebb adatból számolódik, nagyobb lesz a bizonytalansága.)

Megjegyzendő, hogy bárhogy is számolunk, a járvány kezdete óta összesített adatokat használó mutatók kevésbé alkalmasak a menet közbeni változások érzékelésére, mert nem annyira érzékenyek: ha a valódi halálozási arány le- vagy felmegy, akkor ezek a mutatók is követik, de csak lassan, mert a korábbi adatok "felhígítják" a mutató értékét. Márpedig az ilyen változások detektálása egy "valós idejű" mutatóval fontos lehet, hiszen jelezheti például, ha a járvány más kockázatú csoportra terjed rá, ha javul a kezelés hatásossága az orvosi fejlődés miatt, romlik az ellátórendszer túlterhelése miatt, más súlyosságú lefolyást okozó mutáns jelenik meg stb. (Persze ne feledjük, hogy mindezek hatását mi egyben látjuk.) A dolog ára, hogy az ilyen mutató mindig szükségképp bizonytalanabb, hiszen kevesebb adatból számolódik. Természetesen sajnos mindez érzékeny a felderítési arány változására.

A felderítési aránytól való függés gondolatát kicsit tovább is vihetjük, és így egy lehetséges eszközt nyerünk az "aluldetektálás" (tehát az esetek, például nem kellően kiterjedt tesztelés miatti, nem megtalálásának) a mérésére.

Az ötlet a következő. Vegyünk egy országot, ami nagyjából hasonlít a miénkhez, de sokkal többet tesztel. (Pl. Németországot hazánk esetében.) Azt látjuk, hogy ott jóval kisebb a korrigált halálozási arány. Vajon minek tudható ez be?

- A vírus valamilyen biológiai okból veszélyesebb nálunk (szinte kizárt, vagy legfeljebb valamilyen variáns eltérő földrajzi elterjedtsége miatt lehet)
- Az egészségügyi ellátásunk ennyivel rosszabb (ebben a tekintetben nem valószínű, különösen, hogy ennek a betegségnek amúgy sincs igazán átütő oki terápiája, inkább csak az ellátórendszer esetleges túlterhelése okozhat ilyet)
- A betegek ennyivel kockázatosabbak nálunk, például idősebbek vagy több a társbetegségük (szóba jöhet, de azért nagy különbség sem a korfában, sem a társbetegségek arányban nincs, reálisabban az képzelhető el, hogy nem általában mások a betegek, hanem inkább egy bizonyos csoportban -- például a fiatalok között -- indul be terjedés)

Ha azonban olyan a helyzet, hogy ezek kizárhatóak nagy valószínűséggel, akkor mi marad magyarázatként? Az, hogy a németek –- a több tesztelés hatására –- több beteget találtak meg, pontosabban szólva, jobban megtalálták az összes beteget. Azaz azért jobb náluk a halálozás, mert a nevezőjük (a reálisnak megfelelően) nagyobb!

Most jöjjön a központi feltevés: tételezzük fel, hogy mivel a fenti három okot kilőttük, így *valójában* a mi halálozási arányunk is *ugyanannyi*, mint a németeké. (Itt természetesen már korrigált arányról beszélünk.) Nevezzük ezt a valódi értéket, amit, újra ismételjük meg, egy hozzánk -- korösszetételében, társbetegségében, fejlettségében -- hasonló, de nagyon sokat tesztelő ország adatként fogunk megszerezni, *benchmark halálozási aránynak*. Legyen mondjuk ez 1% a példa kedvéért. Kiszámoljuk a korrigált halálozási arányunkat, és 10%-ot kapunk. Mi a magyarázat? Innen már világosan látszik az okfejtés vége: az, hogy a mi nevezőnk tizedakkora, mint a valóság! Ezért lett ilyen nagy az arány; ha 10-szer annyi betegre osztanánk rá, akkor máris 1% lenne nálunk is. Elfogadva tehát, hogy a benchmark mortalitás a *valódi* érték nálunk is, ezzel a logikával tudunk következtetni az aluldetektálásra. Ha pedig ennek az értéke megvan, akkor ezzel beszorozva a jelentett esetszámainkat, arra is kapunk becslést, hogy mi a tényleges -- de kellő tesztelés híján sajnos nem detektált -- esetszám.

Fontos hangsúlyozni, hogy ez a módszer -- a fenti benchmark-kal -- az egyes országok közti esetfelderítési hatékonyságot igyekszik megragadni, _nem_ valamennyi fertőzött megtalálását tűzi ki célul. Valójában ugyanis, és itt érkezünk a második kulcsgondolathoz, a halálozási arányt igazából az összes fertőzött számához kellene viszonyítani (angol rövidítéssel ezt szokták IFR-nek nevezni, szemben a fentivel, amit CFR-nek hívnak), hiszen _ez_ jellemzi a betegség súlyosságát igazából: nyilván nem lehet a betegség súlyosságának a mérőszáma olyasvalami, ami attól is függ, hogy mennyit tesztelünk. A CFR egybeméri a két dolgot, az IFR viszont _tisztán_ a betegség súlyosságát jellemzi. Ez lenne tehát a valódi cél, csakhogy ennek meghatározása nem könnyű: honnan tudhatjuk, hogy mennyi az összes fertőzött? Erre is vannak módszerek, de ez már egy másik kérdés. Ráadásul az IFR valójában nem is egyetlen, konstans szám, rendkívül függ például az életkortól. Azaz, ha tehetjük, jobb ezt mint az életkor függvényét kezelni, különben az eredmény az adott ország korfájától is függeni fog.

A fenti benchmark nem ezt ragadja meg: a világ legjobban tesztelő országában sem várható, hogy minden fertőzöttet (nem tünetes esetet!) megtaláljon. Éppen ezért a fenti számítás is azt célozza meg, hogy kimutassuk, a "reálisan" teszteléssel megtalálható fertőzöttek mekkora részét sikerül ténylegesen detektálni. (Ahol a "reálisan" szó alatt azt értjük, ami más országnak sikerült.) És azt nevezi aluldetektálásnak, _nem_ azt, hogy a fertőzöttek mekkora részét sikerült megtalálni.

Természetesen ez utóbbi is érdekes kérdés, hiszen ha megfordítjuk a logikánkat, és az IFR-t vesszük ismertnek, akkor ebből vissza lehetne következtetni a valóban fertőzöttek számára. Ez már egy másik vizsgálat tárgya lehetne.

## Matematikai részletek

A számításhoz Nishiura és mtsai módszerét használjuk, mely röviden összefoglalva az alábbi logikát követi.

Jelölje $c_t$ az esetszámot a $t$-edik napon, $d_t$ pedig a halálozások számát, a megfelelő kumulált értékek legyenek $C_t = \sum_{i=1}^t c_i$ és $D_t = \sum_{i=1}^t d_i$. Ekkor a nyers becslő nyilván:
\[
  b_t = \frac{D_t}{C_t}.
\]

De hogyan tudjuk ezt korrigálni? Ehhez szükségünk lesz a halálos eseteknél a halálozási idő eloszlására, jelölje ezt $f_j$ (diszkretizált eloszlás, tehát $j$ a nap száma). Ekkor a $t$-edik napon meghalók száma felírható úgy, mint a $t$-edik napon meghaló _és_ $t-j$-edik napon megfertőződőek számának összege, $j=0, 1, \ldots$ (hiszen ezek kizáró események, amikből pontosan egy teljesül). A $t$-edik napon meghaló és $t-j$-edik napon megfertőződöttek száma binomiális eloszlású $\left(c_{t-j}, \pi f_j\right)$ paraméterekkel, ahol $\pi$ a valódi halálozási valószínűség. Ha ezt _közelítjük_ $\left(c_{t-j} f_j, \pi \right)$-vel, akkor -- feltéve, hogy ezek függetlenek -- az összegük is binomális lesz $\left(\sum_{j=0}^{\infty} c_{t-j} f_j, \pi \right)$ paraméterekkel.

Innen két irányban haladhatunk tovább. Vagy ezt használjuk fel, a halálozási helyzet aktuális mérésére ("valós idejű" mutató), vagy továbbvisszük belőle, hogy ez alapján $D_t$ eloszlása binomiális $\left(\sum_{i=1}^t \sum_{j=0}^{\infty} c_{i-j} f_j, \pi \right)$ paraméterekkel, és így a járvány egész lefutása alapján számolunk. Az utóbbi stabilabb, de az előbbivel lehet jobban kimutatni az esetleges menet közbeni változásokat, ahogy szó is volt róla.

Most, hogy az eloszlás megvan, továbbmehetünk akár maximum likelihood elven, akár bayes-i becsléssel.

## Számítástechnikai részletek

A modellt nem bayes-i, hanem frekventista (maximum likelihood) elven becsültem meg, ehhez a `bbmle` csomagot használtam.

## Irodalmi hivatkozások

- Hiroshi Nishiura, Don Klinkenberg, Mick Roberts, Johan A P Heesterbeek. Early epidemiological assessment of the virulence of emerging infectious diseases: a case study of an influenza pandemic. PLoS One. 2009 Aug 31;4(8):e6852. doi: 10.1371/journal.pone.0006852. [https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0006852](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0006852).
- A C Ghani, C A Donnelly, D R Cox, J T Griffin, C Fraser, T H Lam, L M Ho, W S Chan, R M Anderson, A J Hedley, G M Leung. Methods for estimating the case fatality ratio for a novel, emerging infectious disease. Am J Epidemiol. 2005 Sep 1;162(5):479-86. doi: 10.1093/aje/kwi230. [https://academic.oup.com/aje/article/162/5/479/82647](https://academic.oup.com/aje/article/162/5/479/82647)
