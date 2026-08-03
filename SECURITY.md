# SECURITY

This document describes the security controls implemented in the hardened CI/CD pipelines for the Example Voting App. It identifies the security tools used throughout the project, explains why each tool is configured as either a **Gate** or a **Signal**, documents the project's baseline management approach, and describes how each security scanner is obtained and verified.

## 1. Security Controls

| Security Tool | Purpose | Gate / Signal | Reason |
|---------------|---------|---------------|--------|
| TruffleHog | Detects verified secrets throughout the Git history. | **Gate** | Verified secrets represent an immediate security risk and must prevent the pipeline from publishing or deploying a Docker image. |
| GitLeaks | Detects potential hardcoded secrets using pattern matching and entropy analysis. | **Signal** | GitLeaks may report false positives. Findings are reviewed and, where appropriate, documented using the project's baseline process. |
| Hadolint | Analyses Dockerfiles for security and container best practices. | **Signal** | Most findings are recommendations that improve image quality but do not necessarily justify blocking deployment. |
| Dependency Audit | Scans application dependencies for known vulnerabilities. | **Signal** | The Example Voting App contains known legacy dependencies inherited from the upstream project. Treating these findings as a Gate would prevent demonstration of the complete CI/CD workflow. |
| Semgrep | Performs Static Application Security Testing (SAST) on the application source code. | **Signal** | Static analysis findings require developer review before determining whether they represent genuine security issues. |
| Trivy | Scans Docker images for known operating system and application dependency vulnerabilities. | **Signal** | The Example Voting App contains known legacy vulnerabilities inherited from the upstream project. These findings are documented rather than used to block deployment. |

## 2. Baseline Management

This project maintains the following baseline file:

| Baseline File | Purpose | Review Requirement |
|---------------|---------|--------------------|
| `security/baselines/gitleaks-baseline.json` | Documents accepted GitLeaks findings inherited from the upstream Example Voting App that cannot reasonably be corrected within the scope of this project. | Each baseline entry should include a written justification and a review date so it can be reassessed during future security reviews. |

Baselines are used only to document accepted findings inherited from the upstream project. They are **not** used to suppress newly introduced vulnerabilities or verified secrets.

## 3. Scanner Acquisition and Verification

To provide a consistent and reproducible scanning environment, every security tool is executed from a dedicated Docker image rather than being installed directly on the Jenkins Build Agent.

Each scanner is obtained from its official container image and encapsulated within a dedicated project Dockerfile stored under `security/dockerfiles/`. During pipeline execution, Jenkins invokes reusable shell scripts located in `security/scripts/`, which execute the corresponding scanner inside its container.

This approach provides the following benefits:

- Consistent scanner versions across all pipeline executions.
- No security tools installed directly on the Jenkins Build Agent.
- Simplified Jenkinsfiles through reusable automation scripts.
- Isolated execution environment for every scanner.
- Easier maintenance and future scanner upgrades by updating a single Dockerfile or script.
