DNS_NAME="dpres-langfuse.uksouth.cloudapp.azure.com"
CERT_NAME="dpres-langfuse"
PFX_PASS='ParseDivorce7!'

openssl req -x509 -newkey rsa:2048 -sha256 -days 825 -nodes \
  -keyout "${CERT_NAME}.key" \
  -out "${CERT_NAME}.crt" \
  -subj "/CN=${DNS_NAME}" \
  -addext "subjectAltName=DNS:${DNS_NAME}"
openssl pkcs12 -export \
  -out "${CERT_NAME}.pfx" \
  -inkey "${CERT_NAME}.key" \
  -in "${CERT_NAME}.crt" \
  -passout pass:"${PFX_PASS}"