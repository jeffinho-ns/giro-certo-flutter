#!/usr/bin/env bash
# Dispara uma corrida de teste (criar + despachar) para validar push/alarme
# em TODOS os motoboys elegíveis do sistema.
#
# O despacho chama announceOrderToRiders na API:
#   - Push FCM type=delivery_offer ("Nova corrida disponível")
#   - Socket broadcast delivery:new_order_offer (app aberto)
#
# Uso rápido:
#   LOGIN_EMAIL='loja@exemplo.com' LOGIN_PASSWORD='senha' \
#     ./scripts/disparar-corrida-teste.sh
#
# Opções:
#   API_URL=https://giro-certo-api.onrender.com
#   FORCE_POSTPAID=1     # se a loja estiver em prepaid, muda p/ postpaid_pix só neste teste
#   CANCEL_AFTER=90      # cancela o pedido após N segundos (evita alguém aceitar de verdade)
#   VALUE=25 DELIVERY_FEE=8
#   STORE_LAT=-23.55 STORE_LNG=-46.63 DEST_LAT=-23.56 DEST_LNG=-46.64
#
# Requisitos: curl + jq
# Conta: lojista com partnerId (não use conta de motoboy).

set -euo pipefail

API_URL="${API_URL:-https://giro-certo-api.onrender.com}"
API_URL="${API_URL%/}"
EMAIL="${LOGIN_EMAIL:-}"
PASSWORD="${LOGIN_PASSWORD:-}"
FORCE_POSTPAID="${FORCE_POSTPAID:-0}"
CANCEL_AFTER="${CANCEL_AFTER:-0}"
VALUE="${VALUE:-25}"
# deliveryFee no create é recalculado pela API via quote; enviamos um valor placeholder.
DELIVERY_FEE="${DELIVERY_FEE:-8}"
NOTES="${NOTES:-TESTE ALARME — ignore se aparecer no app de produção}"

need_bin() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "❌ Falta o comando '$1'. Instala e tenta de novo."
    exit 1
  }
}

need_bin curl
need_bin jq

if [[ -z "$EMAIL" || -z "$PASSWORD" ]]; then
  cat <<'EOF'
❌ Define LOGIN_EMAIL e LOGIN_PASSWORD (conta de LOJISTA).

Exemplo:
  LOGIN_EMAIL='loja@exemplo.com' LOGIN_PASSWORD='senha' \
    ./scripts/disparar-corrida-teste.sh

Opcional (loja em pré-pago):
  FORCE_POSTPAID=1 LOGIN_EMAIL='...' LOGIN_PASSWORD='...' ./scripts/disparar-corrida-teste.sh

Cancelar após 90s (ninguém fica com a corrida):
  CANCEL_AFTER=90 LOGIN_EMAIL='...' LOGIN_PASSWORD='...' ./scripts/disparar-corrida-teste.sh
EOF
  exit 1
fi

echo "⚠️  Isto notifica TODOS os motoboys elegíveis (DeliveryRegistration / perfil TRABALHO),"
echo "    sem bloqueio e sem corrida ativa — incluindo produção se a API for a do Render."
echo ""

json_field() {
  # json_field <json> <jq-filter>
  echo "$1" | jq -r "$2 // empty"
}

http_json() {
  # http_json METHOD PATH [BODY]
  local method="$1"
  local path="$2"
  local body="${3:-}"
  local tmp
  tmp="$(mktemp)"
  local code
  if [[ -n "$body" ]]; then
    code="$(curl -sS -o "$tmp" -w '%{http_code}' -X "$method" \
      "${API_URL}${path}" \
      -H "Authorization: Bearer ${TOKEN}" \
      -H "Content-Type: application/json" \
      -d "$body")"
  else
    code="$(curl -sS -o "$tmp" -w '%{http_code}' -X "$method" \
      "${API_URL}${path}" \
      -H "Authorization: Bearer ${TOKEN}" \
      -H "Content-Type: application/json")"
  fi
  HTTP_CODE="$code"
  HTTP_BODY="$(cat "$tmp")"
  rm -f "$tmp"
}

echo "🔐 Login lojista: $EMAIL @ $API_URL"
LOGIN="$(curl -sS -X POST "$API_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "$(jq -n --arg e "$EMAIL" --arg p "$PASSWORD" '{email:$e,password:$p}')")"

TOKEN="$(json_field "$LOGIN" '.token')"
PARTNER_ID="$(json_field "$LOGIN" '.user.partnerId')"
USER_NAME="$(json_field "$LOGIN" '.user.name')"
USER_ROLE="$(json_field "$LOGIN" '.user.role')"

if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
  echo "❌ Login falhou:"
  echo "$LOGIN" | jq '.' 2>/dev/null || echo "$LOGIN"
  exit 1
fi

if [[ -z "$PARTNER_ID" || "$PARTNER_ID" == "null" ]]; then
  echo "❌ Esta conta não tem partnerId (não é lojista). Usa a conta da loja."
  echo "   user.role=$USER_ROLE name=$USER_NAME"
  exit 1
fi

echo "✅ Logado: $USER_NAME (partnerId=$PARTNER_ID)"

# Dados da loja
http_json GET "/api/partners/me"
if [[ "$HTTP_CODE" != "200" ]]; then
  echo "❌ Falha ao ler /partners/me (HTTP $HTTP_CODE):"
  echo "$HTTP_BODY" | jq '.' 2>/dev/null || echo "$HTTP_BODY"
  exit 1
fi

# /partners/me devolve { partner: {...} }
STORE_NAME="$(json_field "$HTTP_BODY" '.partner.name // .name')"
STORE_ADDRESS="$(json_field "$HTTP_BODY" '.partner.address // .address')"
STORE_LAT="$(json_field "$HTTP_BODY" '.partner.latitude // .latitude')"
STORE_LNG="$(json_field "$HTTP_BODY" '.partner.longitude // .longitude')"
PAY_MODE="$(json_field "$HTTP_BODY" '.partner.delivery_payment_collection_mode // .partner.deliveryPaymentCollectionMode // .delivery_payment_collection_mode // .deliveryPaymentCollectionMode')"
PAY_MODE="${PAY_MODE:-prepaid}"

STORE_NAME="${STORE_NAME:-Loja Teste}"
STORE_ADDRESS="${STORE_ADDRESS:-Endereço da loja}"
if [[ -z "$STORE_LAT" || "$STORE_LAT" == "null" ]]; then STORE_LAT="-23.5505"; fi
if [[ -z "$STORE_LNG" || "$STORE_LNG" == "null" ]]; then STORE_LNG="-46.6333"; fi
# Destino ~1 km a nordeste da loja (placeholder; API recalcula taxa)
DEST_LAT="${DEST_LAT:-}"
DEST_LNG="${DEST_LNG:-}"
if [[ -z "$DEST_LAT" || -z "$DEST_LNG" || "$DEST_LAT" == "null" || "$DEST_LNG" == "null" ]]; then
  DEST_LAT="$(python3 - <<PY
print(round(float("$STORE_LAT") + 0.008, 6))
PY
)"
  DEST_LNG="$(python3 - <<PY
print(round(float("$STORE_LNG") + 0.008, 6))
PY
)"
fi

ORIGINAL_PAY_MODE="$PAY_MODE"
echo "🏪 Loja: $STORE_NAME | modo pagamento: $PAY_MODE"
echo "📍 Loja GPS: $STORE_LAT,$STORE_LNG → destino: $DEST_LAT,$DEST_LNG"

restore_pay_mode() {
  if [[ "${DID_FORCE_POSTPAID:-0}" != "1" ]]; then
    return 0
  fi
  echo "↩️  Restaurando modo de pagamento para: $ORIGINAL_PAY_MODE"
  http_json PATCH "/api/partners/me/delivery-payment-collection-mode" \
    "$(jq -n --arg m "$ORIGINAL_PAY_MODE" '{mode:$m}')"
  if [[ "$HTTP_CODE" != "200" && "$HTTP_CODE" != "204" ]]; then
    echo "⚠️  Não consegui restaurar o modo (HTTP $HTTP_CODE). Ajusta manualmente no app."
    echo "$HTTP_BODY" | jq '.' 2>/dev/null || true
  else
    echo "✅ Modo restaurado: $ORIGINAL_PAY_MODE"
  fi
}
trap restore_pay_mode EXIT

if [[ "$PAY_MODE" == "prepaid" || -z "$PAY_MODE" ]]; then
  if [[ "$FORCE_POSTPAID" == "1" ]]; then
    echo "🔧 Loja em prepaid → mudando temporariamente para postpaid_pix (FORCE_POSTPAID=1)"
    http_json PATCH "/api/partners/me/delivery-payment-collection-mode" \
      '{"mode":"postpaid_pix"}'
    if [[ "$HTTP_CODE" != "200" && "$HTTP_CODE" != "204" ]]; then
      echo "❌ Não consegui mudar para postpaid_pix (HTTP $HTTP_CODE):"
      echo "$HTTP_BODY" | jq '.' 2>/dev/null || echo "$HTTP_BODY"
      exit 1
    fi
    DID_FORCE_POSTPAID=1
    PAY_MODE="postpaid_pix"
  else
    cat <<EOF
❌ Esta loja está em modo prepaid: o despacho exige pagamento Asaas antes do alarme.

Opções:
  1) Roda de novo com FORCE_POSTPAID=1 (recomendado para teste rápido)
  2) No app do lojista: Configurações → modo de cobrança → pós-pago PIX
EOF
    exit 1
  fi
fi

CREATE_BODY="$(jq -n \
  --arg sid "$PARTNER_ID" \
  --arg sn "$STORE_NAME" \
  --arg sa "$STORE_ADDRESS" \
  --argjson slat "$STORE_LAT" \
  --argjson slng "$STORE_LNG" \
  --arg da "Destino teste alarme — Rua Próxima" \
  --argjson dlat "$DEST_LAT" \
  --argjson dlng "$DEST_LNG" \
  --arg rn "Cliente Teste Alarme" \
  --arg rp "11999999999" \
  --arg notes "$NOTES" \
  --argjson value "$VALUE" \
  --argjson fee "$DELIVERY_FEE" \
  '{
    storeId:$sid,
    storeName:$sn,
    storeAddress:$sa,
    storeLatitude:$slat,
    storeLongitude:$slng,
    deliveryAddress:$da,
    deliveryLatitude:$dlat,
    deliveryLongitude:$dlng,
    recipientName:$rn,
    recipientPhone:$rp,
    notes:$notes,
    value:$value,
    deliveryFee:$fee,
    priority:"normal"
  }')"

echo ""
echo "📦 Criando pedido..."
http_json POST "/api/delivery" "$CREATE_BODY"
if [[ "$HTTP_CODE" != "201" ]]; then
  echo "❌ Criar pedido falhou (HTTP $HTTP_CODE):"
  echo "$HTTP_BODY" | jq '.' 2>/dev/null || echo "$HTTP_BODY"
  exit 1
fi

ORDER_ID="$(json_field "$HTTP_BODY" '.id // .order.id')"
ORDER_STATUS="$(json_field "$HTTP_BODY" '.status // .order.status')"
INTERNAL="$(json_field "$HTTP_BODY" '.internalCode // .order.internalCode')"
echo "✅ Pedido criado: id=$ORDER_ID status=$ORDER_STATUS code=${INTERNAL:-n/a}"

echo ""
echo "📣 Despachando (dispara FCM + socket para motoboys)..."
http_json POST "/api/delivery/${ORDER_ID}/dispatch"
if [[ "$HTTP_CODE" != "200" ]]; then
  echo "❌ Despacho falhou (HTTP $HTTP_CODE):"
  echo "$HTTP_BODY" | jq '.' 2>/dev/null || echo "$HTTP_BODY"
  CODE="$(json_field "$HTTP_BODY" '.code')"
  if [[ "$CODE" == "PAYMENT_REQUIRED_PREPAID" || "$HTTP_CODE" == "402" ]]; then
    echo ""
    echo "Dica: a loja ainda exige pagamento. Roda com FORCE_POSTPAID=1."
  fi
  exit 1
fi

DISPATCHED_STATUS="$(json_field "$HTTP_BODY" '.order.status // .status')"
echo "✅ Despachado: status=${DISPATCHED_STATUS:-pending}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Agora verifica nos telemóveis dos motoboys:"
echo "  • App em background / bloqueado → push \"Nova corrida disponível\""
echo "  • App aberto → modal/alarme de oferta (~25s)"
echo " Pedido: $ORDER_ID"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Nos logs do Render procura: [FCM] OK ... type=delivery_offer"
echo "(quem não tem token FCM registado não recebe push; o socket só chega se o app estiver ligado)"

if [[ "$CANCEL_AFTER" =~ ^[0-9]+$ ]] && [[ "$CANCEL_AFTER" -gt 0 ]]; then
  echo ""
  echo "⏳ Aguardando ${CANCEL_AFTER}s e cancelando o pedido de teste..."
  sleep "$CANCEL_AFTER"
  http_json PATCH "/api/delivery/${ORDER_ID}/status" \
    '{"status":"cancelled","reason":"teste alarme — cancelamento automático"}'
  if [[ "$HTTP_CODE" == "200" ]]; then
    echo "✅ Pedido cancelado: $ORDER_ID"
  else
    echo "⚠️  Cancelamento falhou (HTTP $HTTP_CODE). Cancela manualmente no app/admin."
    echo "$HTTP_BODY" | jq '.' 2>/dev/null || echo "$HTTP_BODY"
  fi
fi

echo ""
echo "Pronto."
