## Adatok forrása

Az adatok igyekszem

## Görbeillesztés

A járványok kezdeti fázisára gyakran mondjuk a köznyelvben is, hogy "exponenciálisan nő a betegek száma". Ez nem csak köznyelvi szófordulat, hanem matematikailag is pontos megfogalmazás. Sokszor előfordul (például, ha a betegség ellen nincs védőoltás, korábban nem estek át rajta sokan), hogy a kezdeti fázisban a betegek szinte csupa fogékony emberrel kerülnek kapcsolatba, így a betegség terjedését egyedül az szabja meg, hogy hány beteg van: amíg még kevés, addig a betegek száma is lassabban nő, de minél több beteg van, annál jobban nő a megbetegedések számának növekedési *üteme* is. Ez matematikailag az exponenciális függvény

## Matematikai részletek

Jelölje a betegek számát $t$ időben $I\left(t\right)$, ekkor a "növekedési ütem" magyarul a derivált, tehát az, hogy a növekedési ütem a betegek számával arányos, így írható le:
\[
  \frac{\mathrm{d}I\left(t\right)}{\mathrm{d}t}=rI\left(t\right).
\]
Ez egy egyszerű differenciálegyenlet, melynek megoldása:
\[
  I\left(t\right)=I\left(0\right)e^{rt},
\]
ahol az $r$ paraméter a növekedési ráta.

### Exponenciális görbe illesztése

Az illesztés hagyományos legkisebbek négyzetek (OLS) elven történik, a logaritmált adatokon. 