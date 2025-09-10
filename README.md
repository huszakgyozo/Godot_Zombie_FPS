# Godot_Zombie_FPS

Ez a projekt egy alap FPS rendszert valósít meg Godot 4.4 alatt, amely tartalmazza a játékos mozgását, fegyverkezelést és ellenséges AI-t.

---

## Funkciók összesítve

- **Játékos mozgás**: séta, futás, ugrás, guggolás, kamera forgatás egérrel.  
- **Fegyverkezelés**: több fegyver kezelése, lövés (single/auto), közelharc, újratöltés, fegyver cserélés.  
- **Fegyver és kamera effektek**: recoil, fegyver mozgás, torkolattűz és füst  
- **Ellenséges AI (zombi)**: NavigationAgent3D alapú mozgás, adott távolságból támadás, lövés követése, animációk.

---

## Gombok

| Akció | Input |
|-------|-------------|
| Mozgás előre/hátra/balra/jobbra | `move_forward`, `move_back`, `move_left`, `move_right` |
| Futás | `sprint` |
| Ugrás | `jump` |
| Guggolás | `crouch` |
| Lövés | `fire` |
| Újratöltés | `reload` |
| Közelharc | `melee` |
| Célzás (ADS) | `aim` |
| Következő / előző fegyver | `next_weapon`, `previous_weapon` |
| Kilépés a játékból | `exit` |
| Kamera forgatás | Egérmozgás |

---
