#!/bin/bash
# Cifra un fichero de copia, genera su huella y lo sube a la nube.
# Uso: cifrar_subir.sh <fichero>
set -euo pipefail

FICHERO="$1"
CLAVE_PUBLICA="backup-abd@aeropuerto.example"   # solo clave publica
NUBE="nube:abd-backups-cifrados"                # remoto rclone (region UE)
MES=$(date +%Y/%m)

# 1) Cifrado AES-256 con la clave publica (la privada NO esta en el servidor)
gpg --batch --yes --cipher-algo AES256 --compress-algo none \
    --recipient "$CLAVE_PUBLICA" \
    --output "$FICHERO.gpg" --encrypt "$FICHERO"

# 2) Huella de integridad del fichero ya cifrado
sha256sum "$FICHERO.gpg" > "$FICHERO.gpg.sha256"

# 3) Subida por TLS con cifrado del lado servidor como segunda capa
rclone copy "$FICHERO.gpg" "$NUBE/$MES/" \
    --s3-server-side-encryption AES256 --checksum
rclone copy "$FICHERO.gpg.sha256" "$NUBE/$MES/"

# 4) Verificar que lo subido coincide con lo local
rclone check "$(dirname "$FICHERO")" "$NUBE/$MES/" \
    --include "$(basename "$FICHERO").gpg" --one-way