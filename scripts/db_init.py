# Script para otorgar permiso de inicio de sesión al usuario admin de la base de datos de Spilo (Patroni + PSQL)

import subprocess, sys, os

superuser = os.environ["PGUSER_SUPERUSER"]
superpass = os.environ["PGPASSWORD_SUPERUSER"]
admin     = os.environ["PGUSER_ADMIN"]
adminpass = os.environ["PGPASSWORD_ADMIN"]

def psql(host, user, password, sql):
    return subprocess.run([
        "docker", "run", "--rm", "--network", "scienclassifier_red_distribuida",
        "-e", f"PGPASSWORD={password}",
        "postgres:17-alpine",
        "psql", "-h", host, "-U", user, "-d", "postgres", "-tAc", sql
    ], capture_output=True, text=True)

primary = None
for node in ["patroni1", "patroni2", "patroni3"]:
    result = psql(node, superuser, superpass, "SELECT pg_is_in_recovery();")
    if result.returncode == 0 and result.stdout.strip() == "f":
        primary = node
        break

if not primary:
    print("ERROR: No se encontró ningún primary. ¿Está Patroni corriendo?")
    sys.exit(1)

print(f"Primary encontrado: {primary}")
psql(primary, superuser, superpass,
     f"ALTER ROLE {admin} WITH LOGIN PASSWORD '{adminpass}';")
print(f"Usuario '{admin}' habilitado correctamente.")