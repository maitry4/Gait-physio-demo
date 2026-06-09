-- Telemetry Conversion Output
-- Session ID: SESS-CONV-87975
-- Source: dummy_telemetry.txt
INSERT INTO sessions (
  id,
  user_id,
  date,
  duration,
  label,
  score,
  stride_length,
  cadence,
  balance,
  symmetry,
  stance_phase,
  swing_phase,
  double_support,
  notes,
  raw_waveform,
  slm_interpretation
) VALUES (
  'SESS-CONV-87975',
  'PT-JOHN-DOE-001',
  '2026-06-10',
  '00:30',
  'Compensatory Gait',
  72,
  1.15,
  108,
  52,
  64,
  0.63,
  0.37,
  0.19,
  'Telemetry converted from file: dummy_telemetry.txt. Steps detected: 54.',
  '[14.426, 12.005, 7.698, 9.781, 12.037, 7.737, 9.704, 12.054, 7.755, 9.653, 12.08, 7.801, 9.584, 12.112, 7.832, 9.524, 12.127, 7.874, 9.466, 12.16, 7.911, 9.407, 12.182, 7.944, 9.352, 12.201, 8.011, 9.276, 12.215, 8.039, 9.214, 12.225, 8.094, 9.154, 12.247, 8.143, 9.095, 12.255, 8.17, 9.053]',
  'Significant gait asymmetry detected (64% symmetry). Marked offloading of the lower extremity. Clinical rehabilitation advised.'
);
