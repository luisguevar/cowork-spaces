#!/bin/bash
sleep 20
/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "CoWork@2026!" -C -i /docker-entrypoint-initdb.d/001_init.sql
echo "Database initialized successfully"