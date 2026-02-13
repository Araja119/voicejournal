#!/bin/sh

echo "=== VoiceJournal Backend Starting ==="

# Debug: show DATABASE_URL host and test DNS
echo "DATABASE_URL host: $(echo $DATABASE_URL | sed 's|.*@\(.*\)/.*|\1|')"
echo "Testing DNS resolution..."
nslookup postgres.railway.internal 2>&1 || echo "DNS lookup failed"
echo "Testing TCP connectivity..."
nc -z -w 5 postgres.railway.internal 5432 && echo "TCP connection OK" || echo "TCP connection FAILED"

# Wait for Railway's internal network to initialize
echo "Waiting 10 seconds for network initialization..."
sleep 10

echo "Retesting connectivity..."
nc -z -w 5 postgres.railway.internal 5432 && echo "TCP connection OK" || echo "TCP connection FAILED"

# Try migrations, but don't fail if database isn't ready yet
echo "Attempting database migrations..."
if npx prisma migrate deploy; then
    echo "Migrations completed successfully!"
else
    echo "WARNING: Migrations failed (database may not be ready yet)"
    echo "The app will start anyway and retry connections..."
fi

echo "Starting server..."
exec node dist/index.js
