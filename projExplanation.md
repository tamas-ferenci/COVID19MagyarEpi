## Alapgondolat

Az előrejelzések többféle módszeren is alapulhatnak. Egy részük empirikus: nem törődik azzal, hogy mi a háttérben lévő jelenség működése, egyszerűen a tapasztalt múltbeli viselkedést "meghosszabbítja" a jövőre nézve. Ilyen módszerekkel jellemzően rövid távú előrejelzések adhatóak.

A módszerek másik része figyelembe veszi a háttérben lévő folyamatok mechanizmusát (ilyen értelemben szokták ezeket "mechanisztikus" modelleknek nevezni). Számos különböző elven alapuló mechanisztikus modellt próbáltak ki és használtak több-kevesebb sikerrel az epidemiológiában: a legklasszikusabb és máig tartóan legnagyobb hatásúak a kompartment modellek (ezekről részletesebben lesz szó később), újabban népszerűek a mikroszimulációk, melyek minden egyes ember viselkedését szimulálják valamilyen szabályszerűség alapján, és a hálózatelméleten alapuló modellek, melyek az embereket és a köztük lévő, fertőzés átadására alkalmas kapcsolatokat a matematikai gráf fogalmának feleltetik meg, és az ottani ismereteket alkalmazzák a járványok terjedésének leírására.

### Empirikus előrejelzés

Ez a módszer a talán legkézenfekvőbb: a tényadatokra illesztett görbét (lásd a Járványgörbe pontnál!) egyszerűen meghosszabbítjuk. Statisztikailag precízebben szólva: ha megvan a modellünk -- melyet a jelenlegi és múltbeli dátumok adatai alapján becsültünk --, lekérjük a becsléseit jövőbeli dátumokra is.

Jelenleg ez a pont az exponenciális görbe illesztését és előrevetítését támogatja.

Ennek pontosságához természetesen fontos, hogy maga az illesztés jó legyen; ehhez beállíthatjuk, hogy a görbe melyik részére illesztünk (ablakozás). Fontos, hogy az ablakozás helyességét, értelmességét itt nem láthatjuk, azt minden esetben a Járványgörbe pont alapján ellenőrizzük!

Az eredményeket megjeleníthetjük grafikonon vagy táblázaton és beállíthatjuk az előrejelzett napok számát is. A Járványgörbe ponthoz hasonlóan logaritmikussá tehetjük a függőleges tengelyt, és megjeleníthetjük a konfidenciaintervallumot is.

Van mód szcenárióelemzésre is e pont alatt, azaz megtehetjük, hogy megvizsgáljuk, hogy akkor mi történik, ha a jövőbeli növekedés nem annyi, mint ami a meglevő esetszámokból következne, hanem annál több vagy kevesebb. Ezzel különféle -- optimistább vagy pesszimistább -- forgatókönyvek is felvázolhatóak.

### Kompartment modell

TODO
