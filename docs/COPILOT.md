# COPILOT PROMPTS (kort)
- “Lag migrasjon for users-tabell (uuid, email unik, created_at), aktiver RLS, policy: eier kan SELECT.”
- “Lag outbox-trigger for docs.insert som skriver topic=doc.created + payload {id, created_by}.”
- “Lag seed for dev: dev@norsain.com. Idempotent.”
- “Lag RLS-test som verifiserer at bruker ikke ser andres rader.”
