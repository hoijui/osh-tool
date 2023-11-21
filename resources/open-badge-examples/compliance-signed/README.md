<!--
SPDX-FileCopyrightText: 2023 Robin Vobruba <hoijui.quaero@gmail.com>

SPDX-License-Identifier: CC0-1.0
-->

# `osh`-tool - Open Badge examples - Compliance Signed

## Key-pair generation

### RSA

### Generate x.509 certificate

ES256 with the certificate (public part) in PEM encoding (as required for Open Badges),
and the private-key in DER encoding (as required for `obadgen`).

```shell
REQUIRED_TOOLS=("bc" "sed" "awk" "repvar" "obadgen" "openssl")

VARIABLES_FILE="assertion-gen.vars.txt"
OB_HOSTING_BASE="https://raw.githubusercontent.com/hoijui/osh-tool/master/resources/open-badge-examples/compliance-signed"
KEY_FILE_BASE="issuer-key"
PRIV_KEY="$KEY_FILE_BASE.x509.priv.der"
CERT="$KEY_FILE_BASE.x509.cert.pem"
PUB_KEY="$KEY_FILE_BASE.x509.pub.pem"
ALG="es256"
RECIPIENT_URL="https://gitlab.com/OSEGermany/ohloom/"
RECIPIENT_IDENTITY_CLEAR="$RECIPIENT_URL"
IMG_EXT="svg"
OSH_TOOL_REPORT_JSON_URL=https://osegermany.gitlab.io/ohloom/osh-report.json
OSH_TOOL_REPORT_JSON=osh-report.json
wget \
    -O "$OSH_TOOL_REPORT_JSON" \
    "$OSH_TOOL_REPORT_JSON_URL"
COMPLIANCE_FACTOR_MIN="0.8"
COMPLIANCE_FACTOR="$(yq r -P -j "$OSH_TOOL_REPORT_JSON" 'stats.ratings.compliance.factor')"

if (( $(echo "$COMPLIANCE_FACTOR < $COMPLIANCE_FACTOR_MIN" | bc -l) ))
then
    >&2 echo -e "ERROR: Project reached an osh-tool compliance factor of $COMPLIANCE_FACTOR,\nbut at least $COMPLIANCE_FACTOR_MIN is required.\n-> Assertion not granted!"
    return 1
fi

cat > "$VARIABLES_FILE" << EOF
ASSERTION_TEMPLATE_PATH="assertion-TEMPLATE.json"
ASSERTION_FILE_PATH="assertion-gen.json"
# ISSUER_ID="https://raw.githubusercontent.com/hoijui/obadgen/master/res/ob-ents/issuer-with-key.json"
BADGE_CLASS_ID="$OB_HOSTING_BASE/badge-class.json"
ASSERTION_ID="https://some-domain.com/anywhere/does-not-even-have-to-exist/because-signed/badge-assertion-with-key.json"
PROJECT_NAME="OHLOOM"
RECIPIENT_SALT="dfvnk097t6iubasr"
RECIPIENT_IDENTITY_HASH="sha256\$$(printf '%s%s' "$RECIPIENT_IDENTITY_CLEAR" "$RECIPIENT_SALT" | sha256sum - | sed -e 's/ .*//')"
EVIDENCE_1="https://osegermany.gitlab.io/ohloom/osh-report.html"
EVIDENCE_2="https://osegermany.gitlab.io/ohloom/osh-report.md"
EVIDENCE_3="https://osegermany.gitlab.io/ohloom/osh-report.json"
EVIDENCE_4="COMPLIANCE_FACTOR=$COMPLIANCE_FACTOR"
DATE_ISSUED_ON="$(date --iso-8601=seconds)"
DATE_EXPIRES="$(date --iso-8601=seconds --date="2099-12-30")"
SOURCE_IMAGE="../../media/img/osh-tool-sample-badge-signed.$IMG_EXT"
BAKED_IMAGE="assertion-gen-baked.$IMG_EXT"
COMPLIANCE_PERCENT="$(yq r -P -j "$OSH_TOOL_REPORT_JSON" 'stats.ratings.compliance.percent')"
EOF

gen_key=false
if $gen_key
then
    openssl req \
        -new \
        -x509 \
        -subj "/C=DE/ST=Berlin/L=Berlin/O=OSEG/OU=SW-Dev/CN=ose-germany.de/emailAddress=open-badges-123@ose-germany.de" \
        -sha256 \
        -nodes \
        -pkeyopt ec_paramgen_curve:prime256v1 \
        -newkey ec \
        -keyform DER \
        -keyout "$PRIV_KEY" \
        -days 730 \
        -outform PEM \
        -out "$CERT"

    openssl ec \
        -in "$PRIV_KEY" \
        -inform DER \
        -pubout \
        -outform PEM \
        -out "$PUB_KEY"

    # Sets the publicKeyPem property
    # in an Open Badge 2.0 CryptographicKey JSON-LD file
    pkp_val=$(awk 1 ORS='\\n' "$PUB_KEY")
    pkp_line=$(printf '  "publicKeyPem": "%s"\n' "$pkp_line")
    sed -i '/"publicKeyPem":/c\'"$pkp_line" "issuer-key.json"
fi

repvar \
    --variables-file "$VARIABLES_FILE" \
    < "$ASSERTION_TEMPLATE_PATH" \
    > "$ASSERTION_FILE_PATH"

# Signs and bakes the assertion to $BAKED_IMAGE
obadgen \
    --assertion "$ASSERTION_FILE_PATH" \
    --signing-algorithm "$ALG" \
    --key "$PRIV_KEY" \
    --source-image "$SOURCE_IMAGE" \
    --baked "$BAKED_IMAGE"
```
