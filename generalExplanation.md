## Három fontos megjegyzés elöljáróban

1. Ezt a projektet hobbiként, szabadidőmben, mindenféle hivatalos támogatás nélkül, kizárólag nyilvánosan elérhető információforrásokra támaszkodva végzem. Ebből adódóan az eredmények nem tekinthetőek semmilyen szerv hivatalos álláspontjának, valamint -- bár természetesen igyekeztem a lehető legjobb tudásom szerint eljárni -- a helyességére sincs hivatalos pecsét.

2. Ennek közvetlen folyományaként: minden észrevételt, megjegyzést, dicséretet, kritikát, javaslatot a lehető legnagyobb örömmel veszek! (És, amennyiben lehet, igyekszem felhasználni a továbbfejlesztéshez.) Email-címem: <ferenci.tamas@nik.uni-obuda.hu>. Ha valaki jártas ebben, akkor bátran nyisson a Github-on issue-t. A felhasznált adatbázist, valamint az elemzést végző szkripteket teljes terjedelmükben nyilvánosságra hoztam (lásd a fejlécben lévő linket).

3. A projekt elsődleges célközönségét a szakmában dolgozók jelentik, de minden tőlem telhetőt megtettem, hogy a Magyarázat fülekben -- ha a statisztikai részleteket nem is -- de az eredmények jelentését, értelmét, és mindenekelőtt a belőle levonható következtetéseket minden érdeklődő laikus számára érthetően megmagyarázzam. Ettől elválasztva, tömören igyekeztem az adott módszer matematikai hátterét is összefoglalni.

## Mi ez az egész projekt?

Az utóbbi évtizedekben egyre többet és többet megértettünk azokból a tényezőkből, melyek a járványok kitörését és lefutását meghatározzák. Kialakult egy új tudományterület, mely ezen tényezők

egyrészt leírni a járvány aktuális helyzetét, megfelelően választott mutatószámokkal, mely jelzi a jelenlegi helyzetet. Másrészt, és talán ez a még fontosabb, lehetővé teszi, hogy előrejelzéseket tegyünk a jövőre nézve. Ezen előrejelzések egy része empirikus: nincs ismeret mögötte arról, hogy 

## Mik az egyes komponensek?

- A *Járványgörbe* mutatja a megbetegedések számának időbeli alakulását, azaz a járvány lefutását. Felhasználható n