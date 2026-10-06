# Security Policy

## Reporting Security Vulnerabilities

We take the security of Thinai seriously. If you discover a security vulnerability or potential threat in this repository, please report it responsibly.

**Do NOT report security vulnerabilities through public GitHub issues, discussions, pull requests, or public chat channels.**

### How to Report

Please report security vulnerabilities privately using GitHub's **Private Vulnerability Reporting**:

1. Navigate to the **Security** tab of the repository on GitHub.
2. Under "Vulnerability reporting", click **Report a vulnerability** (or open a private security advisory).
3. Fill out the details as requested.

This mechanism ensures your report is delivered securely and privately to project maintainers without exposing the vulnerability prematurely.

---

## What to Include in a Report

To help us triage and resolve the issue quickly, please provide as much context as possible:

- **Type of vulnerability** (e.g., prompt injection bypass, unauthorized local port exposure, memory corruption in native assets, insecure data storage).
- **Step-by-step reproduction instructions** or a minimal Proof of Concept (PoC).
- **Impact assessment** explaining what an attacker could achieve.
- **Affected versions and environment details** (Android version, device model, app version/commit hash).
- Any proposed mitigations or fixes, if available.

---

## Secrets and Credentials Policy

- **Never commit secrets:** Contributors must never commit API keys, private keys, certificates, keystores, environment credentials, or personal tokens to this repository.
- If you notice that credentials or secrets were committed anywhere in the codebase or pull requests, please notify project maintainers immediately via private security advisory.
