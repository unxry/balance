CREATE TABLE IF NOT EXISTS sync_stream_state (
  source_id bigint NOT NULL REFERENCES sources(id),
  stream_key text NOT NULL,
  etag text,
  last_modified text,
  last_success_at timestamptz,
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY(source_id, stream_key)
);
