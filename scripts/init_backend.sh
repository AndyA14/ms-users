#!/bin/bash
# scripts/init_backend.sh

BUCKET_NAME=$1
TABLE_NAME=$2
REGION="us-east-1"

echo "🔍 Verificando Backend S3: $BUCKET_NAME..."

# 1. Crear Bucket si no existe
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
  echo "✅ El bucket $BUCKET_NAME ya existe."
else
  echo "🚧 Creando bucket $BUCKET_NAME..."
  aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$REGION"
  # Bloquear acceso público (Buenas prácticas)
  aws s3api put-public-access-block --bucket "$BUCKET_NAME" \
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
  echo "✅ Bucket creado."
fi

# 2. Crear DynamoDB si no existe
echo "🔍 Verificando DynamoDB Lock: $TABLE_NAME..."
if aws dynamodb describe-table --table-name "$TABLE_NAME" --region "$REGION" 2>/dev/null; then
  echo "✅ La tabla $TABLE_NAME ya existe."
else
  echo "🚧 Creando tabla $TABLE_NAME..."
  aws dynamodb create-table \
    --table-name "$TABLE_NAME" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$REGION"
  echo "✅ Tabla creada."
fi