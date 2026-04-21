# Soulspring — iOS App

Aplicación SwiftUI para **Soulspring**, clínica y santuario de bienestar
enfocada en hábitos saludables, longevidad celular y bienestar
bio-individualizado. La app acompaña al usuario en su día a día:
mide su salud desde Apple Health / Apple Watch, sostiene sus hábitos con
un sistema de rachas (personales y conjuntas con amigos), le sirve un
plan bio-individualizado y lo conecta con el Sanctuary.

---

## Estructura del proyecto

```
Soulspring/
├── SoulspringApp.swift              App entry + flow gating
├── Theme/
│   ├── SoulTheme.swift              Paleta, tipografía, gradientes, radii
│   ├── SoulComponents.swift         Tarjetas, tiles, botones, rings
│   └── RachaFlame.swift             Llama de racha (inspirada en Duolingo)
├── Models/
│   ├── UserProfile.swift            Perfil, intereses, edad, actividad, tier
│   ├── Habit.swift                  Hábitos + streak por hábito
│   ├── Recommendation.swift         Catálogo + engine de recomendaciones
│   ├── SanctuaryModels.swift        Comidas, lugares, recordatorios, pedidos
│   └── SharedStreak.swift           Rachas conjuntas con amigos
├── Services/
│   ├── AppStore.swift               Estado global (perfil, hábitos, auth)
│   ├── HealthKitManager.swift       Lectura Apple Health + Apple Watch
│   ├── StreakEngine.swift           Motor de rachas global
│   ├── SoulBackend.swift            Protocolo + LocalBackend + SupabaseBackend
│   ├── SupabaseConfig.swift         URL + anon key del proyecto Supabase
│   └── SoulLinks.swift              URLs externas (booking, Instagram)
├── Features/
│   ├── MainTabView.swift            Tab root: Hoy · Salud · Hábitos · Santuario · Yo
│   ├── Onboarding/
│   │   ├── LoginView.swift          Login con "Ver sin cuenta"
│   │   └── OnboardingView.swift     Formulario (intereses de salud)
│   ├── Home/HomeView.swift          Dashboard + racha + quick actions
│   ├── Heart/HeartRateView.swift    "Mide tu salud" — estudio cardíaco + breath
│   ├── Habits/HabitsView.swift      Hábitos + rachas personales + conjuntas
│   ├── Recommendations/             Feed personalizado
│   ├── Sanctuary/SanctuaryView.swift  Mapa · Cocina · Room service · Rutina
│   └── Profile/ProfileView.swift    Perfil + membresía (financiera)
└── SupportingFiles/
    ├── Info.plist                   Permisos (Health, motion, location, push)
    └── Soulspring.entitlements      HealthKit entitlement
```

---

## Secciones principales

| Sección         | Qué vive ahí |
|-----------------|-------------|
| **Login**       | Correo/contraseña o **Ver sin cuenta** (datos de ejemplo). |
| **Onboarding**  | Formulario que guía al usuario hacia sus intereses de salud, edad, nivel de actividad, intención y meta diaria de racha. |
| **Hoy**         | Saludo, racha global con llama, métricas clave (HR, pasos, kcal, sueño), recomendación del día, recordatorios horizontales, botones a **Agendar cita** e **Instagram de la cocina**. |
| **Salud**       | Ritmo cardíaco en vivo, gráfica del día con Charts, HR en reposo, HRV, sueño, pasos, práctica de respiración 5-5. |
| **Hábitos**     | Lista de hábitos con rachas individuales, meta diaria ajustable, **rachas conjuntas** con amigos y flujo de invitación. |
| **Santuario**   | Mapa con localizaciones Soulspring, menú del chef del Sanctuary, Room service, recordatorios diarios. |
| **Yo**          | Perfil, intereses, **membresía financiera** (Essential $500, Sanctuary $1,800, Longevity $4,200 MXN/mes), conectar Apple Health, cerrar sesión. |

---

## Sistema de rachas

### Racha personal (global)
El usuario define una **meta diaria** (ej. 3 hábitos al día). Cada día que
cumpla ese mínimo la racha crece; si falla, se reinicia. `StreakEngine`
calcula: días actuales, más larga, progreso de hoy y calendario de 14
días. El logo es una llama personalizada (`RachaFlame`) con gradiente
terracota → dorado (paleta Soulspring, espíritu Duolingo).

### Rachas conjuntas
Permite enlazar tu racha con la de un amigo. Si **alguno de los dos**
rompe su meta diaria, la racha conjunta se reinicia. Micro-accountability
social sin ruido.

---

## Apple Health & Apple Watch

`HealthKitManager` lee:

- Ritmo cardíaco (serie del día, HR actual, HR en reposo)
- Variabilidad cardíaca (HRV SDNN)
- Pasos y energía activa
- Análisis de sueño

Cuando no hay permisos o no hay dispositivo, se cargan datos simulados
para que todas las pantallas se vean completas (modo invitado).

---

## Branding

- **Colores**: moss `#3F5248`, sage `#8FA189`, terracotta `#C68863`,
  gold `#C9A66B`, cream `#F4EDE1`, earth `#6B4F3B`.
- **Tipografía**: New York (serif del sistema) para display, SF Pro para
  body — consistente con el feel editorial del sitio Soulspring.
- **Componentes**: tarjetas suaves con sombra cálida, gradientes
  orgánicos, llama de racha con *flicker* sutil.

---

## Supabase

El proyecto está listo para conectarse a Supabase. Llena los datos en
`Services/SupabaseConfig.swift`:

```swift
enum SupabaseConfig {
    static let url     = "https://YOUR-PROJECT.supabase.co"
    static let anonKey = "YOUR-ANON-KEY"
}
```

Tablas sugeridas (todas con `user_id uuid references auth.users`):

- `profiles` — name, age_bracket, activity_level, interests[], goal, tier
- `habits` + `habit_checks`
- `reminders`
- `orders` (room service)
- `health_snapshots`
- `friends` + `shared_streaks` + `shared_streak_days`

Activa Row Level Security con `user_id = auth.uid()`.

Mientras tanto el `LocalBackend` persiste en `UserDefaults` y deja que
todo corra sin cuenta.

---

## Enlaces externos

- Booking: [soulspring.me](https://soulspring.me)
- Instagram cocina / Sanctuary: [@soulspring.sanctuary](https://instagram.com/soulspring.sanctuary)
- Instagram Soulspring MX: [@soulspring_mx](https://instagram.com/soulspring_mx)
- Sitio: [soulspring.world](https://soulspring.world)

---

## Cómo correrlo en Xcode

El proyecto ya incluye `Soulspring.xcodeproj` listo para abrir:

```bash
git clone <repo>
cd Soulspring
open Soulspring.xcodeproj
```

En Xcode:

1. Selecciona el target **Soulspring** → *Signing & Capabilities*.
2. Elige tu **Development Team** (obligatorio para HealthKit). El bundle id
   `mx.soulspring.app` se puede cambiar si ya está tomado.
3. Selecciona un simulador (iPhone 15 Pro o superior) y corre con ⌘R.

En el primer arranque verás la pantalla de login. Presiona
**Ver sin cuenta** para recorrer todas las secciones con datos de ejemplo.

### Regenerar el proyecto

El `Soulspring.xcodeproj` se genera a partir del árbol de archivos y puede
regenerarse cuando agregues o renombres archivos:

```bash
# Opción A — script sin dependencias
python3 scripts/generate_xcodeproj.py

# Opción B — XcodeGen (brew install xcodegen)
xcodegen generate
```

Ambos caminos producen un proyecto equivalente. Usa el que prefieras.
