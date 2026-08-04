# Panduan Lengkap: Dari Nol Sampai Menjalankan AksaraLLM

Panduan ini menuntun kamu menjalankan **seluruh pipeline AksaraLLM** — dari
melatih tokenizer sampai punya model yang bisa diajak ngobrol — melewati
semua repo di organisasi ini. Semuanya dari nol; tidak ada langkah yang
mem-fine-tune model pihak ketiga.

## 0. Persiapan

**Struktur folder** — clone semua repo ini sebagai *sibling directories*
(banyak script saling mereferensikan lewat path relatif `../nama-repo`):

```
AksaraLLM/
├── aksaraLLM/          # arsitektur model, training loop, SFT/DPO, demo
├── aksara-tokenizer/   # trainer tokenizer BPE khusus Indonesia
├── aksara-data/        # pipeline kurasi data (kualitas, dekontaminasi, CAI-revision)
├── aksara-train/       # orkestrasi training skala besar/TPU
├── aksara-eval/        # Aksara-Indo-Bench (evaluasi)
└── community/          # dokumen ini, governance, RFC
```

```bash
mkdir AksaraLLM && cd AksaraLLM
git clone https://github.com/AksaraLLM/aksaraLLM.git
git clone https://github.com/AksaraLLM/aksara-tokenizer.git
git clone https://github.com/AksaraLLM/aksara-data.git
git clone https://github.com/AksaraLLM/aksara-train.git
git clone https://github.com/AksaraLLM/aksara-eval.git
git clone https://github.com/AksaraLLM/community.git
```

**Kebutuhan:**
- Python 3.10+
- Untuk tokenizer saja: `pip install tokenizers huggingface_hub` (ringan, tidak butuh torch)
- Untuk training/eval: `pip install -r aksaraLLM/requirements.txt` (torch, transformers, datasets, dst)
- GPU disarankan untuk pre-training (CPU bisa untuk skala `nano`/`micro` sekadar smoke-test)
- Akun HuggingFace + token (`huggingface-cli login` atau `export HF_TOKEN=...`) kalau mau upload checkpoint

---

## 1. Latih Tokenizer

Tokenizer harus dilatih **sekali di awal**, sebelum pre-training — semua
tahap berikutnya (pre-training, SFT, DPO) memakai tokenizer yang sama.

```bash
cd aksara-tokenizer

# Sanity check dulu (2 detik, tidak butuh data nyata)
python3 scripts/train_tokenizer_20b.py --dry-run

# Coba dulu dengan sample corpus kecil yang sudah disediakan (lihat format
# JSONL-nya di aksara-data/samples/corpus_sample/wiki_sample.jsonl)
python3 scripts/train_tokenizer_20b.py \
    --input ../aksara-data/samples/corpus_sample/ \
    --out ./aksara-tokenizer-sample \
    --vocab-size 2000

# Training sungguhan dari korpus JSONL kamu (field "text" per baris,
# format sama seperti sample di atas — ganti dengan korpus nyata)
python3 scripts/train_tokenizer_20b.py \
    --input /path/ke/korpus/ \
    --out ./aksara-tokenizer-20b \
    --vocab-size 131072
```

Simpan path `./aksara-tokenizer-20b` — ini dipakai di semua langkah berikutnya
lewat flag `--tokenizer-path`.

---

## 2. Siapkan Data Pre-training

Default pre-training memakai Wikipedia Indonesia (`wikimedia/wikipedia`,
config `20231101.id`) secara otomatis — tidak perlu langkah manual untuk
smoke-test. Untuk korpus custom (scraping sendiri, gabungan sumber lain):

```bash
cd aksara-data

# Bersihkan korpus (dedup, quality scoring) — lihat quality/auditor.py
python3 quality/auditor.py

# WAJIB sebelum training skala besar: pastikan korpus tidak overlap dengan
# soal-soal di aksara-eval (kalau tidak, skor benchmark jadi tidak valid)
python3 quality/decontaminate.py --corpus /path/ke/korpus/ --report-only
python3 quality/decontaminate.py --corpus /path/ke/korpus/ --out /path/ke/korpus-bersih/
```

---

## 3. Pre-training dari Nol

**Skala kecil (laptop/Colab/Kaggle, smoke-test arsitektur):**

```bash
cd aksaraLLM
pip install -r requirements.txt

python3 train.py --size mini \
    --tokenizer-path ../aksara-tokenizer/aksara-tokenizer-20b
```

Preset skala tersedia: `nano` (~10M) → `micro` → `mini` → `small` → `medium`
→ `large` → `xlarge` (~1B). Lihat `aksarallm/config.py` untuk detail tiap
preset.

**Skala besar / TPU** (lihat repo `aksara-train`):

```bash
cd ../aksara-train

python3 pretrain.py --size xlarge \
    --tokenizer-path ../aksara-tokenizer/aksara-tokenizer-20b \
    --gradient-checkpointing \
    --hf-repo AksaraLLM/aksarallm-xlarge-pretrain
```

Opsi penting yang tersedia di kedua entry point (`train.py` dan `pretrain.py`):
- `--precision {auto,bf16,fp16,fp32}` — default `auto` (bf16 kalau GPU mendukung)
- `--gradient-checkpointing` — hemat VRAM besar, ~30% lebih lambat
- `--resume <path>` — lanjutkan dari checkpoint yang terputus
- `--dataset` / `--dataset-config` — ganti korpus HuggingFace

Training bisa diberhentikan kapan saja (`latest.pt` auto-tersimpan tiap
`eval_interval` step) dan dilanjutkan dengan `--resume`.

---

## 4. Instruction-Tuning (SFT)

Butuh dataset instruksi JSONL: `{"instruction": ..., "input": ..., "output": ...}`
— lihat `aksara-data/samples/sft_sample.jsonl` untuk contoh formatnya, atau
`aksara-data/generators/` untuk bikin/olah datanya (kontribusi data lewat
website juga masuk ke sini).

**Data identitas & pengetahuan dasar Indonesia** — jalankan sekali untuk
menghasilkan `identity_core.jsonl`, lalu gabungkan ke dataset SFT kamu (lihat
`aksara-data/datasheets/MODEL_DATASHEET.md` untuk isi & bobot training yang disarankan):

```bash
cd ../aksara-data
python3 generators/identity_core.py --org "Nama/Organisasi Kamu" --out generators/identity_core.jsonl
cd ../aksaraLLM
```

```bash
python3 sft.py \
    --checkpoint checkpoints/aksarallm-mini/best_model.pt \
    --data data/sft_id.jsonl \
    --tokenizer-path ../aksara-tokenizer/aksara-tokenizer-20b \
    --epochs 3
```

Loss otomatis di-mask supaya hanya token *jawaban* yang dilatih, bukan
prompt-nya — jangan khawatir soal ini, sudah ditangani.

**(Opsional) Perbaiki kualitas data SFT dengan self-critique & revision**
(metode Constitutional AI, lihat `aksara-data/generators/constitutional_revision.py`
dan `constitutions/default.json` untuk prinsip yang dipakai — file ini bisa
kamu edit sendiri):

```bash
cd ../aksara-data
python3 generators/constitutional_revision.py \
    --input drafts.jsonl --model AksaraLLM/aksarallm-mini-sft --out revised.jsonl
```

---

## 5. Alignment (DPO)

Butuh dataset preferensi JSONL: `{"prompt": ..., "chosen": ..., "rejected": ...}`.

```bash
cd ../aksaraLLM
python3 dpo.py \
    --sft-checkpoint checkpoints/sft/sft_best.pt \
    --data data/dpo_id.jsonl \
    --tokenizer-path ../aksara-tokenizer/aksara-tokenizer-20b \
    --beta 0.1 --lr 5e-7
```

---

## 6. Upload & Konversi Format

Checkpoint mentah (`.pt`) tidak bisa langsung dipakai `AutoModelForCausalLM`.
`upload_to_hf.py` mengonversinya ke format `transformers` standar lewat
`aksarallm.hf_export` sebelum upload:

```bash
python3 upload_to_hf.py \
    --checkpoint checkpoints/sft/sft_best.pt \
    --tokenizer-path ../aksara-tokenizer/aksara-tokenizer-20b \
    --repo AksaraLLM/aksarallm-mini-sft --sft
```

Sekarang repo itu bisa langsung dipakai:
```python
from transformers import AutoTokenizer, AutoModelForCausalLM
tok = AutoTokenizer.from_pretrained("AksaraLLM/aksarallm-mini-sft")
model = AutoModelForCausalLM.from_pretrained("AksaraLLM/aksarallm-mini-sft")
```

**Konversi ke GGUF** (untuk Ollama/LM Studio/llama.cpp):
```bash
bash scripts/convert_gguf.sh AksaraLLM/aksarallm-mini-sft
```

---

## 7. Evaluasi

```bash
cd ../aksara-eval
pip install transformers datasets torch

python -m aksara_indo_bench.run --model AksaraLLM/aksarallm-mini-sft --tasks all --out results.json
```

Menjalankan IndoMMLU (pengetahuan), COPAL-ID (penalaran), NusaX-sentiment
(bahasa daerah), Aksara-Safety (custom) — lihat `aksara-eval/README.md`.

---

## 8. Coba Modelnya

```bash
cd ../aksaraLLM

# CLI cepat, langsung dari checkpoint mentah
python3 demo.py --checkpoint checkpoints/sft/sft_best.pt --mode chat

# CLI interaktif dengan tools (baca file, jalankan perintah, dst)
python3 aksara_cli.py --model local --model-path checkpoints/sft/sft_best.pt

# Web UI (butuh repo HF yang sudah diexport ke format standar, lihat langkah 6)
python3 demo/gradio_chat.py --model AksaraLLM/aksarallm-mini-sft
```

---

## Ringkasan Alur

```
aksara-tokenizer          aksara-data
  (latih tokenizer)   →   (kurasi data, dekontaminasi)
        │                        │
        └──────────┬─────────────┘
                    ▼
              aksaraLLM/train.py   (atau aksara-train/pretrain.py untuk skala besar)
                    │  pre-training dari nol
                    ▼
              aksaraLLM/sft.py     ← data instruksi (aksara-data)
                    │  instruction-tuning
                    ▼
              aksaraLLM/dpo.py     ← data preferensi (aksara-data)
                    │  alignment
                    ▼
              upload_to_hf.py      → format transformers standar
                    │
        ┌───────────┼───────────────┐
        ▼           ▼               ▼
  aksara-eval   demo.py/aksara_cli  convert_gguf.sh
  (evaluasi)    (coba modelnya)     (Ollama/llama.cpp)
```

Untuk berkontribusi data, compute, atau kode — lihat
[CONTRIBUTING.md](CONTRIBUTING.md), [GPU_DONATIONS.md](GPU_DONATIONS.md), dan
[GOVERNANCE.md](GOVERNANCE.md).
