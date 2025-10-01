# Security Policy

Hvis du finner en sårbarhet:
- E-post: hs@norsain.com

Retningslinjer
- Ingen secrets i repo. Bruk GCP Secret Manager + OIDC fra GitHub Actions.
- Rotasjon: 90 dager (prod 75–90). Varsle 14/7/1 dager før.
- Ikke publiser nøkler i issues/PRs. Maskér logger og dumps.
