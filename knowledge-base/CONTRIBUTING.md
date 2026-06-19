# Contributing to the Knowledge Base

This directory serves as a curated knowledge source for [Azure SRE Agent](https://learn.microsoft.com/azure/sre-agent/) and human operators. It is consumed by AI agents via **web page** sources (GitHub-rendered Markdown URLs), so every article must follow the conventions below.

---

## Article Format

### Required Front Matter

Start every article with a metadata block:

```markdown
# Title — SAP Edge Integration Cell on Azure

> **Audience**: SRE, Platform Engineering (choose applicable)
> **Last verified**: Month YYYY
> **Related IaC**: [link to relevant Terraform/Bicep directory if applicable]
```

### Structure Rules

1. **One topic per file** — each article must be independently understandable.
2. **H2 for major sections, H3 for sub-procedures** — agents use heading hierarchy for precise section retrieval.
3. **Use tables for structured data** — especially for:
   - Symptom / Cause / Resolution (troubleshooting)
   - Parameter / Description / Example (configuration)
   - Metric / Threshold / Rationale (monitoring)
4. **Severity tags** — use `Critical`, `High`, `Medium`, `Low` for troubleshooting entries:
   ```markdown
   | Severity | **Critical** |
   |----------|-------------|
   ```
5. **Command blocks with context** — add a comment explaining when to run:
   ```bash
   # Check node health after scaling
   kubectl get nodes -o wide
   ```
6. **Link to authoritative sources** — SAP notes, Microsoft Learn, upstream docs. Use a `## Related Resources` section at the bottom.
7. **No inline images** — agents consume text; describe visuals in prose or tables.

### Naming Convention

- File names: lowercase, hyphenated, descriptive (e.g., `troubleshooting.md`, `certificate-rotation.md`).
- Add new articles to the [index table in README.md](README.md).

---

## Adding a New Article

1. Create a new `.md` file in `knowledge-base/` following the format above.
2. Add an entry to the **Article Index** table in [`knowledge-base/README.md`](README.md).
3. If the article references IaC files, ensure links are relative and valid (link checker runs daily).
4. Submit a pull request — the link-watcher CI will verify all URLs.

---

## Updating Existing Articles

- Update the `Last verified` date in the front matter.
- If you change headings, verify downstream agents aren't referencing old section anchors (though the SRE Agent re-crawls periodically).
- Keep the **Diagnostics Summary Table** in `troubleshooting.md` in sync when adding new issues.

---

## What Belongs Here vs. in Sample READMEs

| Content Type | Location |
|-------------|----------|
| Terraform variable docs, step-by-step deploy | Sample `README.md` (e.g., `quickstart/aks/README.md`) |
| Architecture, operational procedures, troubleshooting | `knowledge-base/` |
| IaC code changes | `quickstart/` or `production-ready/` directories |

The knowledge base **references** sample READMEs and IaC files but does not duplicate their content.
