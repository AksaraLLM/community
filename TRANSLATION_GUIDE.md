# Translation & Localization Guide

This guide is for contributors translating AksaraLLM data, prompts, or documentation between English, Indonesian, and Indonesian regional languages (Javanese, Sundanese, Minangkabau, Madurese, Balinese, etc.) or between Malay variants.

---

## 🎯 What we translate

### 1. Eval prompts (highest impact)
We need eval prompts in **multiple Indonesian regional languages** so we can measure how well models actually serve speakers of those languages — not just Bahasa Indonesia.

| Language | ISO 639-1 | Priority |
|---|---|---|
| Bahasa Indonesia | `id` | always |
| Javanese (Jawa) | `jv` | high — 80M speakers |
| Sundanese (Sunda) | `su` | high — 40M speakers |
| Malay | `ms` | high — cross-SEA |
| Minangkabau | `min` | medium |
| Madurese | `mad` | medium |
| Balinese | `ban` | medium |

### 2. SFT instruction data
Instruction–response pairs translated from English (Alpaca, Dolly, etc.) often have:
- **Awkward phrasing** that isn't natural Indonesian
- **Cultural mismatches** (American food, US holidays)
- **Wrong politeness register** (English doesn't have formal/informal split)

We need native speakers to **review and rewrite**, not just translate literally.

### 3. Documentation
Code comments and docs are written in English (international audience). But user-facing tutorials, blog posts, README marketing copy, and community announcements should have **both `EN` and `ID` versions**.

---

## ✍️ Translation principles

### Use natural, contemporary Indonesian
**Avoid**: stilted Malay-influenced register that sounds like 1960s textbooks
**Use**: phrases native speakers use today

| Don't | Do |
|---|---|
| "Para pengguna dapat mengakses fitur tersebut" | "Pengguna bisa pakai fitur itu" |
| "Sebelumnya, kita akan membahas…" | "Sebelum lanjut, kita bahas…" |
| "Hal demikian merupakan pertimbangan penting" | "Itu pertimbangan penting" |

### Localize, don't just translate
| Source (EN) | Bad translation | Good localization |
|---|---|---|
| "I had pancakes for breakfast" | "Saya makan pancake untuk sarapan" | "Saya sarapan martabak telur" |
| "Drive 30 miles north" | "Berkendara 30 mil ke utara" | "Berkendara sekitar 50 km ke utara" |
| "Fall semester" | "Semester gugur" | "Semester ganjil" |

Note: **Don't be too aggressive** with localization — sometimes preserving the source is correct (e.g. translating an article about American politics; "pancake" is fine in food context).

### Preserve technical terms appropriately
| Term | EN | ID (correct) | ID (over-translated, wrong) |
|---|---|---|---|
| token | token | token | "tanda" / "atom" |
| neural network | neural network | jaringan saraf | "jejaring nirsel" |
| training | training | training / pelatihan | "pendidikan" |
| inference | inference | inference / inferensi | "penyimpulan" |
| GPU | GPU | GPU | "Unit Pemroses Grafis" |

Heuristic: if a term is widely used in English by Indonesian developers (e.g. `commit`, `pull request`, `repository`), **keep the English** to avoid confusion.

### Choose the right register

Bahasa Indonesia has formal vs. informal:

| Context | Register | Example |
|---|---|---|
| Eval prompts (general) | semi-formal | "Tolong jelaskan apa itu fotosintesis." |
| Chat assistant identity | semi-formal | "Saya Kiel-Pro, saya bisa membantu kamu dengan…" |
| Documentation | formal-conversational | "Kamu bisa install paket ini dengan perintah…" |
| Marketing copy | conversational | "Bikin LLM Indonesia sendiri. Semua open source." |
| Technical paper | formal | "Pendekatan ini menghasilkan loss yang lebih rendah…" |

Don't mix `kamu` and `Anda` in the same paragraph.

### Bahasa Indonesia ↔ Bahasa Melayu
Indonesian and Malay are mutually intelligible but **not the same**. Don't auto-substitute:

| Indonesian | Malay |
|---|---|
| bisa | boleh |
| keren | hebat |
| sempurna | sempurna |
| mobil | kereta |
| toko | kedai |

If translating to Malay specifically, ensure consistency throughout.

### Regional languages (Jawa, Sunda, etc.)
Each has its own register hierarchy. For Javanese:
- **Ngoko**: informal, peer-to-peer
- **Madya**: semi-formal
- **Krama**: formal, to elders or strangers

For eval prompts, default to **ngoko alus** (gentle informal) unless context demands otherwise.

---

## 🛠️ Workflow

### Translating an eval set

1. **Get the source file** from `aksara-eval/data/<benchmark>_en.jsonl` (or `_id.jsonl`)
2. **Make a copy** as `<benchmark>_<lang>.jsonl` (e.g. `indomamlu_jv.jsonl`)
3. **Translate each entry**:
   - Question
   - All answer choices
   - Reference answer
   - Explanation if present
4. **Preserve the JSON schema exactly**:
   ```json
   {"id": "01", "question": "...", "choices": ["...","..."], "answer": "B", "category": "..."}
   ```
5. **Self-review**: Read through naturally — does it flow? If you hesitate, rewrite.
6. **Sanity check** with `python scripts/validate_jsonl.py <file>`
7. **PR** with title `data: add <benchmark> in <lang>`
8. **Reviewer**: another native speaker, ideally different region

### Translating SFT data

Same as above, but also:
- **Reject** examples where the source is fundamentally English-context-specific (US legal questions, American cultural in-jokes, etc.)
- **Replace** culturally-specific examples with Indonesian equivalents where reasonable
- **Flag** anything you're unsure about as `# REVIEW` comment in the file

---

## 🤝 Style consistency

We maintain a **glossary** of preferred Indonesian translations for technical terms in [`docs/glossary.md`](docs/glossary.md). When in doubt, follow that. If a term is missing, add it via PR.

---

## ❓ Questions

Ping us in `#data-curation` on [Discord](https://discord.gg/aksarallm) or open an issue in `aksara-data`.

Terima kasih sudah membantu! 🙏
