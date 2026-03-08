-- machines
CREATE TABLE IF NOT EXISTS machines (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name       VARCHAR(100) NOT NULL,
  location   VARCHAR(100),
  type       VARCHAR(50),
  status     VARCHAR(20) DEFAULT 'active'
             CHECK (status IN ('active','idle','maintenance','offline')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- sensor readings
DROP TABLE IF EXISTS sensor_readings CASCADE;
CREATE TABLE IF NOT EXISTS sensor_readings (
  id BIGSERIAL PRIMARY KEY,
  machine_id UUID NOT NULL REFERENCES machines(id) ON DELETE CASCADE,
  metric VARCHAR(50) NOT NULL,
  value DECIMAL(10,4) NOT NULL,
  unit VARCHAR(20),
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sensor_readings_machine_time 
ON sensor_readings(machine_id, recorded_at DESC);

CREATE INDEX IF NOT EXISTS idx_sensor_readings_time 
ON sensor_readings(recorded_at DESC);

-- alerts
CREATE TABLE IF NOT EXISTS alerts (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  machine_id      UUID REFERENCES machines(id),
  alert_type      VARCHAR(20) CHECK (alert_type IN ('threshold','trend','anomaly')),
  severity        VARCHAR(10) CHECK (severity IN ('warning','critical')),
  metric          VARCHAR(50),
  value           FLOAT,
  threshold       FLOAT,
  message         TEXT,
  acknowledged    BOOLEAN DEFAULT false,
  acknowledged_by VARCHAR(100),
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  resolved_at     TIMESTAMPTZ
);

-- thresholds
CREATE TABLE IF NOT EXISTS alert_thresholds (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  machine_id           UUID REFERENCES machines(id),
  metric               VARCHAR(50),
  warning_value        FLOAT,
  critical_value       FLOAT,
  trend_window_minutes INTEGER DEFAULT 5,
  trend_rate_threshold FLOAT,
  UNIQUE(machine_id, metric)
);
