#!/bin/sh

echo "=== VoiceJournal Backend Starting ==="

# Wait for Railway's internal network to initialize
echo "Waiting 20 seconds for network initialization..."
sleep 20

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
