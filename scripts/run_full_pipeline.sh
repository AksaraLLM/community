#!/bin/bash
# ══════════════════════════════════════════════════════════════════════
#  AksaraLLM — Full Pipeline Runner
# ══════════════════════════════════════════════════════════════════════
# Runs the ENTIRE pipeline end-to-end, from tokenizer training to a
# ready-to-use model: tokenizer -> pre-training -> SFT -> DPO -> HF export
# -> (optional) eval -> quick demo generation. See community/GETTING_STARTED.md
# for what each step does and why.
#
# Defaults are a *fast smoke test* (tiny "nano" model, few steps, the small
# sample data in aksara-data/samples/) that finishes in a few minutes on
# CPU — this proves the whole pipeline actually works end to end. Pass
# --size/--max-steps/--corpus/etc. to scale it up into a real training run.
#
# Assumes the sibling-directory layout from GETTING_STARTED.md:
#   <root>/aksaraLLM  <root>/aksara-tokenizer  <root>/aksara-data
#   <root>/aksara-train  <root>/aksara-eval  <root>/community
#
# Usage:
#   bash run_full_pipeline.sh                          # quick smoke test
#   bash run_full_pipeline.sh --root /path/to/AksaraLLM
#   bash run_full_pipeline.sh --size mini --max-steps 2000 \
#       --corpus /path/to/real/corpus/ --vocab-size 32000 \
#       --sft-data /path/to/real/sft.jsonl --dpo-data /path/to/real/dpo.jsonl \
#       --hf-repo AksaraLLM/aksarallm-mini
# ══════════════════════════════════════════════════════════════════════

set -e

# ── Defaults (fast smoke test) ──
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SIZE="nano"
MAX_STEPS=30
EVAL_INTERVAL=10      # low on purpose: best_model.pt/latest.pt only save on eval steps
VOCAB_SIZE=2000
CORPUS=""             # empty = use bundled sample corpus
SFT_DATA=""           # empty = use bundled sample + identity_core
DPO_DATA=""           # empty = use bundled sample
ORG="komunitas AksaraLLM"
HF_REPO=""
SKIP_INSTALL=false
SKIP_EVAL=true         # eval needs a real trained model to be meaningful; opt-in
RUN_DIR="$ROOT/pipeline_run"

print_step()  { echo -e "\n\033[1;32m[STEP] $1\033[0m"; }
print_info()  { echo -e "\033[1;36m       -> $1\033[0m"; }
print_error() { echo -e "\033[1;31m[!] $1\033[0m"; }

# ── Parse args ──
while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) ROOT="$2"; shift 2 ;;
    --size) SIZE="$2"; shift 2 ;;
    --max-steps) MAX_STEPS="$2"; shift 2 ;;
    --vocab-size) VOCAB_SIZE="$2"; shift 2 ;;
    --corpus) CORPUS="$2"; shift 2 ;;
    --sft-data) SFT_DATA="$2"; shift 2 ;;
    --dpo-data) DPO_DATA="$2"; shift 2 ;;
    --org) ORG="$2"; shift 2 ;;
    --hf-repo) HF_REPO="$2"; shift 2 ;;
    --skip-install) SKIP_INSTALL=true; shift ;;
    --run-eval) SKIP_EVAL=false; shift ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) print_error "Unknown argument: $1"; exit 1 ;;
  esac
done

AKSARALLM="$ROOT/aksaraLLM"
TOKENIZER_REPO="$ROOT/aksara-tokenizer"
DATA_REPO="$ROOT/aksara-data"
EVAL_REPO="$ROOT/aksara-eval"

for repo in "$AKSARALLM" "$TOKENIZER_REPO" "$DATA_REPO"; do
  if [ ! -d "$repo" ]; then
    print_error "Repo not found: $repo (expected sibling-directory layout, see GETTING_STARTED.md; override with --root)"
    exit 1
  fi
done

[ -z "$CORPUS" ] && CORPUS="$DATA_REPO/samples/corpus_sample"
mkdir -p "$RUN_DIR"

echo "════════════════════════════════════════════════════════════"
echo "  AksaraLLM Full Pipeline — size=$SIZE max-steps=$MAX_STEPS"
echo "  Root: $ROOT"
echo "  Run dir: $RUN_DIR"
echo "════════════════════════════════════════════════════════════"

# ── Step 0: dependencies ──
if [ "$SKIP_INSTALL" = false ]; then
  print_step "0/8  Installing Python dependencies"
  pip install -q -r "$AKSARALLM/requirements.txt"
  print_info "aksaraLLM requirements installed"
else
  print_info "Skipping dependency install (--skip-install)"
fi

# ── Step 1: tokenizer ──
print_step "1/8  Training tokenizer"
TOKENIZER_DIR="$RUN_DIR/tokenizer"
if [ -f "$TOKENIZER_DIR/tokenizer.json" ]; then
  print_info "Tokenizer already exists at $TOKENIZER_DIR, skipping"
else
  (cd "$TOKENIZER_REPO" && python3 scripts/train_tokenizer_20b.py --dry-run)
  print_info "Dry-run OK"
  (cd "$TOKENIZER_REPO" && python3 scripts/train_tokenizer_20b.py \
      --input "$CORPUS" --out "$TOKENIZER_DIR" --vocab-size "$VOCAB_SIZE")
  print_info "Tokenizer saved to $TOKENIZER_DIR"
fi

# ── Step 2: identity + core knowledge seed data ──
print_step "2/8  Generating identity & core knowledge seed data"
IDENTITY_JSONL="$RUN_DIR/identity_core.jsonl"
(cd "$DATA_REPO" && python3 generators/identity_core.py --org "$ORG" --out "$IDENTITY_JSONL")
print_info "Saved to $IDENTITY_JSONL (see aksara-data/datasheets/MODEL_DATASHEET.md)"

# ── Step 3: pre-training from scratch ──
print_step "3/8  Pre-training from scratch ($SIZE, $MAX_STEPS steps)"
PRETRAIN_DIR="$RUN_DIR/pretrain"
(cd "$AKSARALLM" && python3 train.py \
    --size "$SIZE" --max-steps "$MAX_STEPS" \
    --tokenizer-path "$TOKENIZER_DIR" \
    --output-dir "$PRETRAIN_DIR")
print_info "Pre-training checkpoints in $PRETRAIN_DIR"

# ── Step 4: SFT ──
print_step "4/8  Instruction-tuning (SFT)"
if [ -z "$SFT_DATA" ]; then
  SFT_DATA="$RUN_DIR/sft_combined.jsonl"
  cat "$DATA_REPO/samples/sft_sample.jsonl" "$IDENTITY_JSONL" > "$SFT_DATA"
  print_info "Using bundled sample SFT data + identity_core -> $SFT_DATA"
fi
SFT_DIR="$RUN_DIR/sft"
(cd "$AKSARALLM" && python3 sft.py \
    --checkpoint "$PRETRAIN_DIR/best_model.pt" \
    --data "$SFT_DATA" \
    --tokenizer-path "$TOKENIZER_DIR" \
    --output-dir "$SFT_DIR" \
    --epochs 1 --batch-size 2)
print_info "SFT checkpoints in $SFT_DIR"

# ── Step 5: DPO ──
print_step "5/8  Alignment (DPO)"
[ -z "$DPO_DATA" ] && DPO_DATA="$DATA_REPO/samples/dpo_sample.jsonl"
DPO_DIR="$RUN_DIR/dpo"
(cd "$AKSARALLM" && python3 dpo.py \
    --sft-checkpoint "$SFT_DIR/sft_best.pt" \
    --data "$DPO_DATA" \
    --tokenizer-path "$TOKENIZER_DIR" \
    --output-dir "$DPO_DIR" \
    --epochs 1 --batch-size 2)
print_info "DPO checkpoints in $DPO_DIR"

FINAL_CHECKPOINT="$DPO_DIR/dpo_best.pt"

# ── Step 6: export / upload (optional) ──
if [ -n "$HF_REPO" ]; then
  print_step "6/8  Exporting + uploading to HuggingFace ($HF_REPO)"
  (cd "$AKSARALLM" && python3 upload_to_hf.py \
      --checkpoint "$FINAL_CHECKPOINT" \
      --tokenizer-path "$TOKENIZER_DIR" \
      --repo "$HF_REPO" --sft)
  print_info "Uploaded to https://huggingface.co/$HF_REPO"
else
  print_step "6/8  Skipping HF upload (no --hf-repo given)"
fi

# ── Step 7: eval (optional — needs a real HF-format model to be meaningful) ──
if [ "$SKIP_EVAL" = false ] && [ -n "$HF_REPO" ] && [ -d "$EVAL_REPO" ]; then
  print_step "7/8  Running Aksara-Indo-Bench"
  (cd "$EVAL_REPO" && python -m aksara_indo_bench.run --model "$HF_REPO" --tasks all --out "$RUN_DIR/eval_results.json")
  print_info "Results: $RUN_DIR/eval_results.json"
else
  print_step "7/8  Skipping eval (pass --run-eval and --hf-repo to enable)"
fi

# ── Step 8: quick sanity generation ──
print_step "8/8  Quick sanity check — generating from the final checkpoint"
(cd "$AKSARALLM" && python3 demo.py --checkpoint "$FINAL_CHECKPOINT" --prompt "Indonesia adalah" --max-tokens 60)

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  DONE! Pipeline artifacts in: $RUN_DIR"
echo "    Tokenizer:  $TOKENIZER_DIR"
echo "    Pre-train:  $PRETRAIN_DIR"
echo "    SFT:        $SFT_DIR"
echo "    DPO:        $DPO_DIR"
echo ""
echo "  This was a smoke test (tiny model, sample data) — scale it up with:"
echo "    bash $(basename "$0") --size mini --max-steps 5000 --corpus /path/to/real/corpus/ \\"
echo "        --vocab-size 32000 --sft-data /path/to/real/sft.jsonl --dpo-data /path/to/real/dpo.jsonl"
echo "════════════════════════════════════════════════════════════"
