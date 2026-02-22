# PlantNFC 🌿 – Windows Setup via Codemagic

Volledige handleiding voor Windows-gebruikers om de app op iPhone te krijgen **zonder Mac en zonder $99/jaar**.

---

## Overzicht van de aanpak

```
Windows PC  →  GitHub  →  Codemagic (Mac cloud)  →  .ipa bestand
                                                         ↓
                                                    Sideloadly (Windows)
                                                         ↓
                                                    iPhone ✅
```

---

## Stap 1: GitHub account aanmaken (gratis)

1. Ga naar [github.com](https://github.com) → "Sign up"
2. Maak een gratis account aan

---

## Stap 2: Repository aanmaken op GitHub

1. Klik op **"New repository"** (groene knop)
2. Naam: `PlantNFC`
3. Zet op **Private** (jouw code is dan niet zichtbaar voor anderen)
4. Klik **"Create repository"**

---

## Stap 3: Git installeren op Windows

1. Download Git: [git-scm.com/download/win](https://git-scm.com/download/win)
2. Installeer met standaardinstellingen
3. Open **Git Bash** (rechtsklik op bureaublad → "Git Bash Here")

---

## Stap 4: Code uploaden naar GitHub

Open **Git Bash** en voer deze commando's uit:

```bash
# Navigeer naar de plants map
cd /c/Users/Julien/Desktop/plants

# Initialiseer git
git init

# Voeg alle bestanden toe
git add .

# Eerste commit
git commit -m "PlantNFC iOS app - eerste versie"

# Koppel aan GitHub (vervang JOUW_GEBRUIKERSNAAM met je GitHub naam)
git remote add origin https://github.com/JOUW_GEBRUIKERSNAAM/PlantNFC.git

# Upload
git branch -M main
git push -u origin main
```

---

## Stap 5: Codemagic account aanmaken (gratis)

1. Ga naar [codemagic.io](https://codemagic.io)
2. Klik **"Get started for free"**
3. Login met je **GitHub account** → geef toegang
4. Klik op **"Add application"**
5. Selecteer je **PlantNFC** repository
6. Kies **"iOS App"**
7. Codemagic detecteert automatisch de `codemagic.yaml`

---

## Stap 6: Apple ID koppelen aan Codemagic

> Dit is nodig voor een echte iPhone build. Codemagic gebruikt je gratis Apple ID.

1. In Codemagic → rechtsboven → **Teams** → jouw team
2. → **Integrations** → **Apple Developer Portal** → **Connect**
3. Log in met je Apple ID (ook gratis Apple IDs werken!)
4. Codemagic vraagt om een **App-specifiek wachtwoord**:
   - Ga naar [appleid.apple.com](https://appleid.apple.com)
   - → Beveiliging → App-specifieke wachtwoorden → **Genereer wachtwoord**
   - Naam: `Codemagic`
   - Kopieer het wachtwoord → plak in Codemagic

---

## Stap 7: Omgevingsvariabele instellen

In Codemagic → jouw app → **Environment variables**:

| Variabele | Waarde | Beveiligd |
|---|---|---|
| `APPLE_TEAM_ID` | Jouw Team ID (zie hieronder) | ✅ |

**Hoe vind je je Team ID?**
- Ga naar [developer.apple.com/account](https://developer.apple.com/account)
- Log in → rechtsboven staat je **Team ID** (bijv. `ABC123DEF4`)

---

## Stap 8: Build starten

1. In Codemagic → klik op jouw PlantNFC app
2. Kies workflow: **"PlantNFC – iPhone Build"**
3. Klik **"Start new build"**
4. Wacht ~10-15 minuten
5. Je ontvangt een email met de download van het `.ipa` bestand ✅

---

## Stap 9: App installeren op iPhone (via Sideloadly)

**Sideloadly** is een gratis Windows-tool om apps te installeren zonder App Store.

1. Download: [sideloadly.io](https://sideloadly.io)
2. Installeer Sideloadly
3. Verbind iPhone met USB → vertrouw de computer
4. Sleep het `.ipa` bestand naar Sideloadly
5. Vul je Apple ID in (gratis account)
6. Klik **"Start"**
7. Op iPhone: Instellingen → Algemeen → VPN & Apparaatbeheer → vertrouw je Apple ID
8. ✅ Open PlantNFC!

> **Elke 7 dagen** moet je opnieuw sideloaden (gratis certificaat). Dit duurt ~2 minuten.

---

## Gratis limieten overzicht

| Service | Gratis limiet |
|---|---|
| GitHub | Onbeperkt private repos |
| Codemagic | 500 build-minuten/maand (~30 builds) |
| Sideloadly | Onbeperkt |
| Apple ID (gratis) | 3 apps tegelijk op 1 iPhone |

---

## Problemen?

| Probleem | Oplossing |
|---|---|
| Build mislukt: "No signing identity" | Controleer Apple ID koppeling in Codemagic |
| Build mislukt: "XcodeGen not found" | Controleer of `project.yml` in de root staat |
| Sideloadly: "App not trusted" | Instellingen → Algemeen → VPN & Apparaatbeheer → vertrouw |
| App crasht meteen | Zet `APPLE_TEAM_ID` correct in Codemagic |

---

## Bestandsstructuur controleren

Zorg dat je repository er zo uitziet:

```
PlantNFC/                    ← dit is je GitHub repository root
├── project.yml              ← XcodeGen config ✅
├── codemagic.yaml           ← Codemagic config ✅
├── .gitignore               ✅
├── SETUP_GUIDE.md
└── PlantNFC/                ← Swift bronbestanden
    ├── PlantNFCApp.swift
    ├── Info.plist
    ├── PlantNFC.entitlements
    ├── Theme/
    ├── Data/
    ├── Managers/
    ├── Background/
    └── Views/
```
