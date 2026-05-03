# Security Policy

## Supported Versions

| Component | Supported |
|---|---|
| Latest model release on HuggingFace (e.g. `AksaraLLM/AksaraLLM-Qwen-1.5B-v5-public`) | ✅ |
| Latest commit on `main` of any AksaraLLM GitHub repo | ✅ |
| Older model checkpoints / archived repos | ❌ (best-effort only) |

## Reporting a Vulnerability

Please **do not** open a public issue for security-related concerns.

### How to report

1. Email: `security@aksarallm.org` *(or, if not yet set up, `cahyoahmad10@gmail.com` with subject prefix `[AksaraLLM Security]`)*
2. Or use GitHub's [private vulnerability reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability) feature on the affected repository.

### What to include

- Affected repo, model, or release
- A clear description of the issue
- Reproduction steps or PoC if possible
- Your assessment of impact (data leak, code exec, model misuse, etc.)
- Whether you'd like to be credited in the fix announcement

### Response timeline

- **Acknowledgment**: within 5 business days
- **Initial assessment**: within 14 days
- **Fix or mitigation**: depends on severity. For high/critical issues we aim for a patch within 30 days; for medium/low we may schedule for the next release.

We follow [coordinated disclosure](https://en.wikipedia.org/wiki/Responsible_disclosure). Please give us time to address the issue before public disclosure.

## Scope

### In scope

- **Code repos**: vulnerabilities in our training, data, evaluation, or tokenizer code (e.g. RCE in `scripts/`, unsafe deserialization, dependency CVEs we've shipped)
- **Models**: clear safety / alignment failures (jailbreaks that produce harmful instructions for clearly harmful tasks like weapon creation, CSAM, malware, etc.). We expect reasonable models to refuse these.
- **Data pipeline**: leaks of personally identifiable information (PII) in our published corpora that we should have filtered
- **Infrastructure**: leaked credentials, exposed buckets, misconfigured CI

### Out of scope

- General hallucinations or factual errors (these are inherent to LLMs and should be filed as regular issues with the `quality` label)
- Reproducing prompts that get the model to be slightly impolite or refuse benign requests
- Issues requiring physical access or compromise of the user's local machine
- Self-XSS or social-engineering attacks

## Safe harbor

Good-faith security research on AksaraLLM resources is welcomed. We will not pursue legal action against researchers who:

- Make a good-faith effort to avoid privacy violations, data destruction, and service disruption
- Stop testing as soon as harm is identified
- Report vulnerabilities promptly via the channels above
- Give us reasonable time to fix before public disclosure

## Hall of fame

Researchers who have responsibly disclosed issues will be acknowledged here (with permission):

*— No reports yet. Be the first!*
