## Három fontos megjegyzés elöljáróban

1. Ezt a projektet hobbiként, szabadidőmben, mindenféle hivatalos támogatás nélkül, kizárólag nyilvánosan elérhető információforrásokra támaszkodva végzem. Ebből adódóan az eredmények nem tekinthetőek semmilyen szerv hivatalos álláspontjának, valamint -- bár természetesen igyekeztem a lehető legjobb tudásom szerint eljárni -- a helyességére sincs hivatalos pecsét.

2. Ennek közvetlen folyományaként: minden észrevételt, megjegyzést, dicséretet, kritikát, javaslatot a lehető legnagyobb örömmel veszek! (És, amennyiben lehet, igyekszem felhasználni a továbbfejlesztéshez.) Email-címem: <ferenci.tamas@nik.uni-obuda.hu>. Ha valaki jártas ebben, akkor bátran nyisson a Github-on issue-t. A felhasznált adatbázist, valamint az elemzést végző szkripteket teljes terjedelmükben nyilvánosságra hoztam (lásd a fejlécben lévő linket).

3. A projekt elsődleges célközönségét a szakmában dolgozók jelentik, de minden tőlem telhetőt megtettem, hogy itt, illetve az egyes pontok Magyarázat nevű füleiben -- ha a statisztikai részleteket nem is -- de az eredmények jelentését, értelmét, és mindenekelőtt a belőle levonható következtetéseket minden érdeklődő laikus számára érthetően megmagyarázzam. Ettől elválasztva, tömören igyekeztem az adott módszer matematikai hátterét és számítástechnikai megvalósítást is összefoglalni a Magyarázat füleken.

## Mi ez az egész projekt?

Az utóbbi évtizedekben egyre többet és többet megértettünk azokból a tényezőkből, melyek a járványok kitörését és lefutását meghatározzák. Kialakult egy új tudományterület, a biostatisztika, az epidemiológia, a biomatematika elemeiből építkezve, mely arra a felismerésre épül, hogy ezen tényezők (biológiaitól egészen a szociológiai tényezőkig) összhatásaként kialakuló járványlefutás matematikai eszközökkel leírható. Ennek a pontossága elért arra a szintre, hogy ez az eszköztár többé már nem csak az elméleti alapkutatóknak érdekes, hanem a létező legkonkrétabb gyakorlati kérdések eldöntösében is létfontosságú segítséget tud adni a szakembereknek.

Mekkora egy járvány kitörésnek a veszélye? Ha kitört, milyen lefutásra számíthatunk, tehát hány betegre és milyen időbeli eloszlásban? Az egyes beavatkozások hogyan módosítják ezt? Ennek alapján: mi az optimális eszköz a járvány megfékezésére, vagy legalábbis lelassítására? Ilyen és ehhez hasonló kérdésekben mind segítik a választ a megfelő módszerek; talán már ennyi is mutatja, hogy miért nagyon is lényeges a gyakorlati alkalmazásuk.

Az immár Magyarországot is elért koronavírus-járvány sajnálatosan jó alkalmat ad ezen módszerek gyakorlatba átültetésére. Itt a feladat egy már kitört járványra történő válaszadás (angol szóval: outbreak response). Ezen a weboldalon ennek az eszközeit igyekszem felhasználni

- jól kezelhető formában (weboldal, melyen teljesen testreszabhatóak a számítások, de közben semmilyen programozási ismeret nem igényel),
- átfogóan (lehetőleg teljeskörűen megvalósítva az outbreak response-hoz fontos számításokat),
- teljesen transzparensen, a 'nyílt tudomány' jegyében.

E módszerek kapcsán egyre fontosabb kérdést jelent a számítási háttér is. Szerencsére a technika fejlődése lehetővé teszi, hogy a szükséges számításokat gyakorlatilag folyamatosan, valós időben futtassuk.

Bár a konkrét cél a koronavírus-járványra adott válasz támogatása, valójában a kifejlesztett kódom bármilyen más járványnál is felhasználható, csak az esetszámokat kell kicserélni. Éppen ezért azt remélem, hogy az itt leírt ismeretek, illetve ez keretrendszer később is fogja tudni támogatni a magyar járványügyiseket.

## Mik a fontos eredmények?

Alapvetően két célunk van outbreak response során. Az egyik, hogy leírjuk a járvány aktuális helyzetét, megfelelően választott mutatószámokkal, mely jelzi a jelenlegi helyzetet. Másrészt, és talán ez a még fontosabb, hogy előrejelzéseket tegyünk a jövőre nézve. Ezen előrejelzések egy része empirikus: nincs ismeret mögötte arról, hogy mi a háttérben lévő 

## Mik a projekt egyes komponensei?

A projekt több pontból épül fel, melyek közül a bal oldali menüben lehet választani.

- A *Járványgörbe* mutatja a megbetegedések számának időbeli alakulását, azaz a járvány lefutását. Felhasználható a járvány alakulásának áttekintésére, illetve 