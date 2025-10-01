-- 0000_extensions.sql: Aktiver nødvendige extensions for pgvector, hashing og trigram-søk.
-- Beste praksis 2025: Enable kun essensielle extensions tidlig for å støtte vector embeddings og sikkerhet.

create extension if not exists vector; -- For embeddings og vector-søk (pgvector).
create extension if not exists pgcrypto; -- For gen_random_uuid() og hashing (f.eks. MD5 checksum).
create extension if not exists pg_trgm; -- For trigram-baserte fuzzy tekst-søk i hybrid queries.
