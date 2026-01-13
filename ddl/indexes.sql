--Create Indexes
CREATE INDEX idx_trade_ts ON trade USING BRIN(timestamp);
CREATE INDEX idx_trade_instr ON trade(instrument_id);
CREATE INDEX idx_trade_expiry ON trade(expiry_id);