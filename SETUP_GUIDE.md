# PlantNFC – Xcode Setup Guide 🌿

A complete step-by-step guide to get the PlantNFC app running on your iPhone **for free**.

---

## Vereisten
- **Mac** met macOS 13+ (Xcode werkt alleen op macOS)
- **Xcode 15+** → [Download gratis op Mac App Store](https://apps.apple.com/app/xcode/id497799835)
- **Je iPhone** met iOS 17+
- **Een USB/Lightning kabel**
- **Gratis Apple ID** (iCloud account)

---

## Stap 1: Maak een nieuw Xcode project

1. Open **Xcode** → **File → New → Project**
2. Kies **iOS → App**
3. Vul in:
   - **Product Name:** `PlantNFC`
   - **Team:** selecteer je Apple ID (of "Add Account" om je Apple ID toe te voegen)
   - **Bundle Identifier:** `com.jouwnaam.plantnfc`
   - **Interface:** `SwiftUI`
   - **Language:** `Swift`
   - **Storage:** `Core Data` ✅ aanvinken
4. Sla op in de map van je voorkeur

---

## Stap 2: Voeg de bronbestanden toe

Kopieer alle bestanden uit de `PlantNFC/` map naar je Xcode project:

```
PlantNFC/
├── PlantNFCApp.swift              ← vervang het gegenereerde bestand
├── Info.plist                     ← voeg toe / vervang
├── PlantNFC.entitlements          ← voeg toe
│
├── Theme/
│   └── AppTheme.swift
│
├── Data/
│   ├── PersistenceController.swift
│   ├── Plant+Extensions.swift
│   └── PlantNFC.xcdatamodeld/    ← vervang het gegenereerde .xcdatamodeld
│       └── PlantNFC.xcdatamodel/
│           └── contents
│
├── Managers/
│   ├── NFCManager.swift
│   └── NotificationManager.swift
│
├── Background/
│   └── BackgroundTaskManager.swift
│
└── Views/
    ├── PlantListView.swift
    ├── PlantDetailView.swift
    ├── AddEditPlantView.swift
    ├── NFCScanSheet.swift
    └── Components/
        ├── PlantRowView.swift
        └── StatusBadge.swift
```

**In Xcode:** rechtsklik op de projectmap → **Add Files to "PlantNFC"...**
Selecteer alle mappen tegelijk en kies **"Create groups"**.

---

## Stap 3: CoreData model instellen

1. In Xcode: zoek het bestaande `.xcdatamodeld` bestand in de navigator
2. Verwijder het door het te selecteren → Delete
3. Voeg het meegeleverde `PlantNFC.xcdatamodeld` toe (rechtsklik → Add Files)

**Of:** klik op het `.xcdatamodeld` bestand in Xcode en voeg handmatig de entity toe:

| Attribuut | Type |
|---|---|
| `id` | UUID |
| `name` | String |
| `emoji` | String |
| `nfcID` | String (Optional) |
| `waterIntervalHours` | Double |
| `lastWatered` | Date (Optional) |
| `createdAt` | Date |

> [!IMPORTANT]
> Controleer dat **Codegen** is ingesteld op **Class Definition** voor de `PlantEntity`.

---

## Stap 4: Capabilities toevoegen

1. Klik op je **project** in de navigator (bovenaan)
2. Selecteer **Signing & Capabilities**
3. Voeg toe met **+ Capability:**

| Capability | Waarvoor |
|---|---|
| **Near Field Communication Tag Reading** | NFC scannen |
| **Background Modes** → "Background fetch" + "Background processing" | Achtergrond |
| **Push Notifications** | (optioneel: skip bij gratis Apple ID) |

4. Klik op je **entitlements** bestand en controleer dat `com.apple.developer.nfc.readersession.formats` aanwezig is met waarde `TAG`.

---

## Stap 5: Info.plist aanvullen

Zorg dat je `Info.plist` de volgende keys bevat (of voeg ze toe via Xcode):

| Key | Value |
|---|---|
| `NFCReaderUsageDescription` | PlantNFC leest NFC-tags... |
| `BGTaskSchedulerPermittedIdentifiers` | `com.plantnfc.refresh` |
| `UIBackgroundModes` | `fetch`, `processing` |

---

## Stap 6: App op je iPhone zetten (gratis!)

1. Verbind je iPhone met USB
2. Kies je iPhone als **run destination** bovenaan Xcode
3. De eerste keer: **iPhone** → Instellingen → Algemeen → VPN & Apparaatbeheer → vertrouw je Apple ID
4. Druk op **▶ Run** (of `Cmd + R`)
5. De app wordt geïnstalleerd en opent direct ✅

> [!NOTE]
> **Elke 7 dagen** moet je opnieuw vanuit Xcode builden (gratis certificaat verloopt). Je kunt de app gewoon openen via ▶ Run, dit duurt maar 30 seconden.

---

## Stap 7: NFC testen

### Op de Simulator (geen iPhone nodig)
- Open de app in de Simulator
- Tik op **"Simuleer NFC Scan"** (oranje knop) – dit simuleert een echte scan
- Alle functionaliteit werkt: timer reset, notificaties, opslag

### Op je echte iPhone
- Koop NFC NTAG215 of NTAG213 stickers (Amazon, ~€5 voor 10 stuks)
- Plak een sticker op je plant
- Open de app → Plant → "Scan NFC-tag"
- Houd je iPhone (bovenkant) bij de sticker

---

## Probleemoplossing

| Probleem | Oplossing |
|---|---|
| "No team selected" | Xcode → Signing → kies je Apple ID |
| NFC niet beschikbaar | CoreNFC werkt niet op simulator, gebruik mock knop of echte iPhone |
| App crasht bij start | Controleer dat CoreData model naam exact "PlantNFC" is |
| Notificaties komen niet | Instellingen → Notificaties → PlantNFC → Sta toe |
| Certificaat verlopen | Open Xcode → ▶ Run, nieuwe build lost dit op |

---

## Aanbevolen NFC Tags

| Type | Gebruik |
|---|---|
| NTAG213 | ✅ Goedkoopst, werkt prima |
| NTAG215 | ✅ Meer opslag (niet nodig maar ook prima) |
| NTAG216 | ✅ Maximale opslag |

> Koop "NFC NTAG stickers" op Amazon, AliExpress, of Conrad. ~€0,50 per stuk.
