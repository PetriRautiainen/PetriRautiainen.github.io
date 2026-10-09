# Project instructions

This is Petri Rautiainen's personal Finnish analytics website for finance professionals and potential future employers. Keep it separate from all employer systems, data, code, credentials, and internal information.

- Use public data with suitable terms or explicitly labelled synthetic examples. Cite primary sources; verify numeric claims against actual calculations.
- Organize content under Data, Osakkeet, Korot, Vaihtoehtoiset sijoitukset, Riskienhallinta, and Minusta.
- Lead with a question. Prioritize clear prose, figures, interpretation, limitations, and follow-up questions. Keep formulas sparse and Python/R code folded by default.
- New posts start with `draft: true`. For publication explicitly requested by the user, finish and verify the post before setting `draft: false` and pushing to the confirmed publication repository. An idea alone is a request to prepare a draft.
- Keep source and results reproducible. This initial workflow has Quarto only; it does not install R/Python libraries. Before adding executable chunks, configure the matching runtime or commit locally frozen outputs into `_freeze`. Standard fenced Python/R examples do not execute.
- Computational results are frozen by default. Explicitly re-render the changed computational article before pushing; do not reuse stale output after code or data changes.
- Default `quarto render` uses `website.draft-mode: gone`. Verify draft content is absent from the public output and search; Quarto may emit a blank draft page. Preview drafts with `quarto render --profile preview`; its output goes to `_preview`, separate from the public `_site` directory.
- Run a successful public render and verify internal links, navigation, draft exclusion, and layout before initial publication. Do not claim deployed status until GitHub confirms a successful run and reachable Pages URL.
- Do not fabricate credentials, contacts, degrees, work history, empirical findings, domain ownership, or published articles.
- Use existing personal GitHub authentication; never ask for secrets in chat. Do not connect employer accounts.
- Keep changes scoped. Do not add dependencies, analytics, third-party tracking, subscriptions, or services without a reason grounded in the user's request.

