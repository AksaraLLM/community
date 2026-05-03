# Good First Issues — Cara Mulai Berkontribusi di AksaraLLM

> Daftar tugas konkret yang bisa dikerjakan kontributor baru, **tanpa GPU, tanpa pengalaman ML mendalam**.

Cara pakai dokumen ini:
1. Pilih satu task yang menarik dan sesuai skill kamu.
2. Buka GitHub issue baru di repo yang relevan dengan judul `[Good First Issue] <task>` (atau cari issue eksisting dengan label `good first issue`).
3. Tulis di komentar: "Saya mau ambil ini." — supaya tidak ada duplikasi pekerjaan.
4. Tunggu maintainer respond (~1–3 hari), lalu buat PR.

Skala kesulitan: 🟢 pemula · 🟡 menengah · 🔴 advanced

---

## 📚 Dokumentasi & Translation

### 🟢 D-001: Translate AksaraLLM org README ke Bahasa Inggris penuh
- **Repo**: `.github`
- **What**: Saat ini `profile/README.md` campur Indonesia/English. Buat versi `profile/README.id.md` murni Indonesia + jaga `profile/README.md` murni English.
- **Skill**: bahasa Indonesia + Inggris
- **Effort**: 30–60 menit

### 🟢 D-002: Tulis tutorial "Run AksaraLLM di Laptop Saya" di blog Medium / dev.to
- **Repo**: berhubungan, tidak commit ke repo
- **What**: Tutorial step-by-step pakai Ollama / llama.cpp untuk Kiel-Pro-0.5B-v3-chat di Windows/Mac/Linux. Sertakan screenshot.
- **Skill**: writer + basic terminal
- **Effort**: 2–3 jam

### 🟢 D-003: Add CONTRIBUTING.md yang lebih detail per-repo
- **Repos**: `aksaraLLM`, `aksara-data`, `aksara-train`, `aksara-eval`, `aksara-tokenizer`
- **What**: Generic `community/CONTRIBUTING.md` ada, tapi tiap repo punya struktur dev sendiri (env setup, test command, lint). Tulis CONTRIBUTING.md ringkas per repo.
- **Skill**: bisa baca repo + jelaskan workflow
- **Effort**: 1–2 jam per repo

### 🟢 D-004: Tulis 1 page "Glossary" istilah ML/LLM dalam Bahasa Indonesia
- **Repo**: `community/docs/glossary.md`
- **What**: Daftar 30–50 istilah (tokenization → "tokenisasi", attention → "perhatian", quantization → "kuantisasi"…) dengan penjelasan singkat dan contoh.
- **Skill**: ML basics + bahasa Indonesia
- **Effort**: 2 jam

---

## 📊 Data Curation

### 🟢 DC-001: Verifikasi 100 sampel SFT untuk kesesuaian kultural Indonesia
- **Repo**: `aksara-data`
- **What**: Kami punya dataset SFT translated dari Alpaca, Dolly, dll. Sebagian translation buruk atau context Indonesia tidak tepat. Review 100 example, flag yang salah.
- **Skill**: native Indonesian, tahu konteks lokal
- **Effort**: 2–3 jam

### 🟢 DC-002: Translate 50 prompt eval ke Bahasa Jawa dan Sunda
- **Repo**: `aksara-eval`
- **What**: Kita lagi bangun multilingual eval. Butuh terjemahan natural prompts ke Jawa (krama / ngoko) dan Sunda.
- **Skill**: native Jawa atau Sunda
- **Effort**: 2–3 jam per bahasa

### 🟡 DC-003: Bikin 100 multiple-choice questions tentang budaya Indonesia
- **Repo**: `aksara-eval`
- **What**: Test apakah model paham budaya Indonesia (sejarah, kuliner, geografi, tokoh, tradisi). Format JSONL: `{"question": "...", "choices": ["A", "B", "C", "D"], "answer": "C"}`. Jangan ambil dari Wikipedia langsung — bikin original.
- **Skill**: pengetahuan budaya Indonesia + format data
- **Effort**: 3–5 jam

### 🟡 DC-004: Audit lisensi semua source dataset di `aksara-data`
- **Repo**: `aksara-data`
- **What**: Buat tabel lengkap source × license (CC-BY, MIT, Apache, ODC, dll). Flag yang ambigu.
- **Skill**: terbiasa baca lisensi data
- **Effort**: 3–5 jam

### 🟢 DC-005: Submit Indonesian text public domain ke Project Gutenberg
- **Repo**: extern (link only)
- **What**: Kalau kamu tahu literatur klasik Indonesia (Pramoedya, Chairil Anwar, dll.) yang sudah masuk public domain, bantu submit ke Project Gutenberg / Wikisource. Akan kita tarik nanti sebagai data training.
- **Skill**: rajin
- **Effort**: bervariasi

---

## 🧪 Evaluation & Testing

### 🟢 E-001: Run `aksara-eval` pada Sahabat-AI dan upload result
- **Repo**: `aksara-eval`
- **What**: Eval harness sudah jalan untuk model AksaraLLM. Run yang sama pada `GoToCompany/llama3-8b-cpt-sahabatai-v1-instruct` (atau model SEA-LION / Cendol / Komodo). Hasil masuk ke leaderboard kita.
- **Skill**: bisa run Python script + GPU/Colab
- **Effort**: 1–2 jam (mostly waiting)

### 🟢 E-002: Bikin unit test untuk `aksara_audit/eval_harness.py`
- **Repo**: `aksaraLLM` (hosted di `aksara_audit/`)
- **What**: 5–10 unit test sederhana untuk `perplexity_hf`, `generate_hf`, dll. Gunakan model dummy 1M parameter agar cepat.
- **Skill**: pytest, basic transformers
- **Effort**: 2–3 jam

### 🟡 E-003: Add IndoMMLU-style benchmark
- **Repo**: `aksara-eval`
- **What**: Re-implement IndoMMLU ([IndoNLP](https://github.com/IndoNLP/indo-mmlu)) sebagai modul di eval harness kita. License-compatible, attribute properly.
- **Skill**: Python, paham eval methodology
- **Effort**: 4–6 jam

---

## 💻 Code & Infrastructure

### 🟢 CI-001: Add GitHub Actions CI untuk lint + format check
- **Repo**: setiap repo (terutama `aksara-train`, `aksara-data`, `aksara-eval`)
- **What**: Workflow `.github/workflows/lint.yml` yang run `ruff check` + `ruff format --check`. Block PR kalau gagal.
- **Skill**: GitHub Actions, ruff
- **Effort**: 30 menit per repo

### 🟢 CI-002: Add `pre-commit` hooks
- **Repo**: setiap repo
- **What**: `.pre-commit-config.yaml` dengan ruff, end-of-file-fixer, trailing-whitespace, check-yaml. README update untuk install.
- **Skill**: pre-commit
- **Effort**: 30 menit per repo

### 🟢 I-001: Modelfile improvements untuk Ollama Hub
- **Repo**: model GGUF repos (e.g. `Kiel-Pro-0.5B-v3-chat-GGUF`)
- **What**: Modelfile sudah ada. Tweak: tambah `PARAMETER num_ctx 4096`, system prompt yang lebih bagus, license metadata. Test dengan `ollama create`.
- **Skill**: Ollama
- **Effort**: 30 menit per model

### 🟡 I-002: Bikin Docker image untuk inference Kiel-Pro-0.5B-v3-chat
- **Repo**: new repo `aksara-inference` atau `aksaraLLM`
- **What**: Multi-stage Dockerfile yang serve model via FastAPI + OpenAI-compatible endpoint. Push ke GitHub Container Registry.
- **Skill**: Docker, FastAPI
- **Effort**: 4–6 jam

### 🟡 I-003: Ollama Hub publishing automation
- **Repo**: new repo
- **What**: Script + GitHub Action yang otomatis push GGUF baru ke Ollama Hub setiap release model.
- **Skill**: Ollama API, GitHub Actions
- **Effort**: 4 jam

### 🔴 I-004: Federated training proof-of-concept
- **Repo**: new repo
- **What**: Bikin demo PySyft / Flower yang train LoRA 0.5B distributed di 3+ machine community. Eksotik tapi viral.
- **Skill**: distributed systems, ML
- **Effort**: 1–2 minggu

---

## 🎨 Design & Branding

### 🟢 B-001: Bikin logo SVG yang lebih bagus
- **Repo**: `.github`
- **What**: Logo current PNG. Bikin versi SVG (vector) supaya scalable, dengan variant dark/light mode.
- **Skill**: graphic design
- **Effort**: 2–4 jam

### 🟢 B-002: Bikin slide deck "AksaraLLM 5-min pitch" untuk presentasi konferensi
- **Repo**: `community/assets/`
- **What**: 10-slide pitch deck (ide, status, roadmap, how to help). Format: PPTX + Google Slides + PDF.
- **Skill**: presentasi
- **Effort**: 3–4 jam

### 🟢 B-003: Bikin landing page (Tailwind + statis)
- **Repo**: new repo `aksarallm-website`
- **What**: Single-page site di `aksarallm.org` (atau GitHub Pages) yang mirror org profile dengan visual lebih bagus.
- **Skill**: HTML/CSS/Tailwind
- **Effort**: 4–8 jam

---

## 📢 Community & Outreach

### 🟢 C-001: Setup Discord channel structure + bots
- **Repo**: tidak commit, koordinasi dengan core team
- **What**: Discord template channels (`#announcements`, `#general`, `#data`, `#training`, `#help`, `#showcase`, `#showcase-id`), role hierarchy, anti-spam bot, GitHub-bot integration.
- **Skill**: Discord admin
- **Effort**: 2–3 jam

### 🟢 C-002: Submit "Show HN" / Reddit / IndoNLP komunitas
- **Repo**: tidak commit
- **What**: Tulis post pendek (300–500 kata) untuk Hacker News, r/MachineLearning (bulanan thread), r/Indonesia, r/LocalLLaMA, IndoNLP discord. Sertakan link demo + repo.
- **Skill**: writer, terbiasa di komunitas tech
- **Effort**: 1–2 jam

### 🟢 C-003: Tulis 1 blog post "Apa itu LLM" untuk audiens Indonesia
- **Repo**: tidak commit (Medium / dev.to)
- **What**: Penjelasan ringan untuk pembaca non-teknis. Apa itu LLM, beda dengan chatbot biasa, kenapa AksaraLLM penting.
- **Skill**: science writer
- **Effort**: 3–4 jam

---

## 🤝 Cara Submit

1. **Pilih task** dari daftar atas
2. Buat **GitHub issue** di repo terkait dengan judul `[GFI] <ID task>: <ringkasan>`
3. Tag maintainer: `@CahyokPutra` (atau di Discord)
4. Setelah dapat go, **fork repo, buat branch `feat/<id-task>`**, kerjakan, push, **buka PR** dengan reference ke issue
5. Tunggu review (1–3 hari biasanya)
6. Setelah merged, kamu masuk **CONTRIBUTORS.md** dan dapat shoutout di Discord 🎉

Pertanyaan? Tanya di **[Discord #help](https://discord.gg/aksarallm)**.
