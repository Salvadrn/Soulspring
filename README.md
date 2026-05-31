# Soulspring — iOS App

App SwiftUI de **Soulspring**, clínica y santuario de bienestar enfocado en
hábitos saludables, longevidad celular y bienestar bio-individualizado.
Mide tu salud desde Apple Health / Apple Watch, sostiene tus hábitos con un
sistema de rachas (personales y conjuntas), te sirve un plan
bio-individualizado y te conecta con el Sanctuary.

## Secciones

| Tab | Qué vive ahí |
|-----|--------------|
| **Hoy** | Saludo, racha global con llama, métricas clave (HR, pasos, kcal, sueño) y recomendación del día. |
| **Salud** | Ritmo cardíaco en vivo, HRV, sueño, pasos, BioAge y práctica de respiración 5-5. |
| **Hábitos** | Hábitos con rachas individuales, meta diaria ajustable y **rachas conjuntas** con amigos. |
| **Santuario** | Mapa de locaciones, menú del chef, room service y recordatorios diarios. |
| **Soul AI** | Coach conversacional que conoce tu racha, BioAge, labs y perfil. |
| **Yo** | Perfil, intereses y membresía (Essential / Sanctuary / Longevity). |

## Cómo correrlo

```bash
git clone https://github.com/Salvadrn/Soulspring.git
cd Soulspring
open Soulspring.xcodeproj
```

En Xcode:

1. Target **Soulspring** → *Signing & Capabilities* → elige tu **Development Team** (obligatorio para HealthKit).
2. Selecciona un simulador (iPhone 15 Pro o superior) y corre con ⌘R.
3. En el login, presiona **Ver sin cuenta** para recorrer toda la app con datos de ejemplo.

> Para regenerar `Soulspring.xcodeproj` tras agregar o renombrar archivos:
> `python3 scripts/generate_xcodeproj.py` o `xcodegen generate`.

## Apple Health

`HealthKitManager` lee ritmo cardíaco (serie del día, actual y en reposo),
HRV, pasos, energía activa y análisis de sueño. Sin permisos o sin
dispositivo se cargan datos simulados para que todas las pantallas se vean
completas (modo invitado).

## Rachas

- **Personal:** defines una meta diaria de hábitos; si la cumples, la racha
  crece; si fallas, se reinicia (`StreakEngine`).
- **Conjunta:** enlazas tu racha con la de un amigo; si **cualquiera** rompe
  su meta, la racha conjunta se reinicia.

## Backend (Supabase)

El `LocalBackend` corre todo en `UserDefaults` sin cuenta. Para conectar
Supabase, llena `Services/SupabaseConfig.swift`:

```swift
enum SupabaseConfig {
    static let url     = "https://YOUR-PROJECT.supabase.co"
    static let anonKey = "YOUR-ANON-KEY"
}
```

El resumen de laboratorios y el chat Soul AI son opcionales y se resuelven
del lado del servidor mediante Edge Functions; la app **no** embebe ninguna
API key de proveedores de modelos. Sin Edge Function configurada, los labs
usan un analizador determinista on-device.

## Branding

- **Colores:** moss `#3F5248`, sage `#8FA189`, terracotta `#C68863`,
  gold `#C9A66B`, cream `#F4EDE1`, earth `#6B4F3B`.
- **Tipografía:** New York (serif) para display, SF Pro para body.

## Enlaces

- Sitio / booking: [soulspring.me](https://soulspring.me)
- Instagram: [@soulspring.sanctuary](https://instagram.com/soulspring.sanctuary) · [@soulspring_mx](https://instagram.com/soulspring_mx)
