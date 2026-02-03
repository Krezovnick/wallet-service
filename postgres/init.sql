-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create read-only user for monitoring
CREATE USER wallet_monitor WITH PASSWORD 'monitor_password';
GRANT CONNECT ON DATABASE walletdb TO wallet_monitor;
GRANT USAGE ON SCHEMA public TO wallet_monitor;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO wallet_monitor;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO wallet_monitor;

-- Create function for checking wallet existence
CREATE OR REPLACE FUNCTION wallet_exists(wallet_uuid UUID)
RETURNS BOOLEAN AS \$\$
BEGIN
    RETURN EXISTS (SELECT 1 FROM wallets WHERE wallet_id = wallet_uuid);
END;
\$\$ LANGUAGE plpgsql;
