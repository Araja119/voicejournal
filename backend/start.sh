#!/bin/sh

echo "=== VoiceJournal Backend Starting ==="
echo "Deployment source: GitHub"
echo "DATABASE_URL host: $(echo $DATABASE_URL | sed 's|.*@\(.*\)/.*|\1|')"

# Wait for Railway's internal network to initialize
echo "Waiting 15 seconds for network initialization..."
sleep 15

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
