CREATE TABLE users (
  id UUID PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE devices (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL,
  platform TEXT NOT NULL,
  kind TEXT NOT NULL,
  user_id UUID REFERENCES users (id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE agents (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL,
  platform TEXT NOT NULL,
  last_seen_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE command_logs (
  id UUID PRIMARY KEY,
  source_device_id UUID REFERENCES devices (id),
  target_agent_id UUID REFERENCES agents (id),
  action TEXT NOT NULL,
  status TEXT NOT NULL,
  args JSONB NOT NULL DEFAULT '{}'::JSONB,
  output TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE activity_logs (
  id UUID PRIMARY KEY,
  actor_id TEXT NOT NULL,
  type TEXT NOT NULL,
  detail TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE automation_rules (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL,
  trigger_expression TEXT NOT NULL,
  action_definition JSONB NOT NULL,
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);