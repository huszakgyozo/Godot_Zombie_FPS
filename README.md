# Godot_Zombie_FPS

Ez a projekt egy alap FPS rendszert valósít meg Godot 4.4 alatt, amely tartalmazza a játékos mozgását, fegyverkezelést és ellenséges AI-t.
Felhasznált godot eszköz: FPS Hands 0.8.1
https://godotengine.org/asset-library/asset/3715

---

## Funkciók összesítve

- **Játékos mozgás**: séta, futás, ugrás, guggolás, kamera forgatás egérrel.  
- **Fegyverkezelés**: több fegyver kezelése, lövés (single/auto), közelharc, újratöltés, fegyver cserélés.  
- **Fegyver és kamera effektek**: recoil, fegyver mozgás, torkolattűz és füst  
- **Ellenséges AI (zombi)**: NavigationAgent3D alapú mozgás, adott távolságból támadás, lövés követése, animációk.
- **Zombi és játékos**: játékos és zombi sebzés kezelés.
- **Játékos interakció**: játékos meg tud fogni egy adott objektumot és utána fel és le tudja mozgatni.

---

## Gombok

| Akció | Input |
|-------|-------------|
| Mozgás előre/hátra/balra/jobbra | `w`, `s`, `a`, `d` |
| Futás | `shift` |
| Ugrás | `space` |
| Guggolás | `ctrl` |
| Lövés | `bal egérgomb` |
| Újratöltés | `r` |
| Közelharc | `v` |
| Célzás (ADS) | `jobb egérgomb` |
| Következő / előző fegyver | `e`, `q` |
| Kilépés a játékból | `esc` |
| Kamera forgatás | Egérmozgás |
| Objektum megfogás | `f` |
| Objektum fel/le mozgatás | `nyil fel`,`nyil le` |

---
