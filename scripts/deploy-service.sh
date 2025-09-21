#!/bin/bash

# Blue-Green Deployment Script using CodeDeploy
# Usage: ./deploy-service.sh <service-name> <image-uri>

set -e

SERVICE_NAME=$1
IMAGE_URI=$2

if [ -z "$SERVICE_NAME" ] || [ -z "$IMAGE_URI" ]; then
    echo "❌ Usage: $0 <service-name> <image-uri>"
    echo "   Example: $0 orders-service 123456789.dkr.ecr.us-east-1.amazonaws.com/medisupply/orders-service:abc123"
    exit 1
fi

ECS_CLUSTER="medisupply-cluster"
AWS_REGION="us-east-1"
CODEDEPLOY_APP="medisupply-ecs-app"

echo "🚀 Starting Blue-Green deployment for $SERVICE_NAME"
echo "📦 Image: $IMAGE_URI"

# Map service names to their configurations
case $SERVICE_NAME in
    "orders-service")
        TASK_FAMILY="medisupply-orders-service"
        DEPLOYMENT_GROUP="medisupply-orders-service-dg"
        CONTAINER_NAME="orders-service"
        CONTAINER_PORT=8001
        ;;
    "inventory-service")
        TASK_FAMILY="medisupply-inventory-service"
        DEPLOYMENT_GROUP="medisupply-inventory-service-dg"
        CONTAINER_NAME="inventory-service"
        CONTAINER_PORT=8002
        ;;
    *)
        echo "❌ Unknown service: $SERVICE_NAME"
        exit 1
        ;;
esac

echo "📋 Service Configuration:"
echo "   Task Family: $TASK_FAMILY"
echo "   Deployment Group: $DEPLOYMENT_GROUP"
echo "   Container: $CONTAINER_NAME:$CONTAINER_PORT"

# Get current task definition
echo "🔍 Getting current task definition..."
CURRENT_TASK_DEF=$(aws ecs describe-task-definition \
    --task-definition $TASK_FAMILY \
    --query 'taskDefinition' \
    --region $AWS_REGION)

# Update container image in task definition
echo "🔄 Creating new task definition with updated image..."
NEW_TASK_DEF=$(echo $CURRENT_TASK_DEF | jq --arg IMAGE "$IMAGE_URI" --arg CONTAINER "$CONTAINER_NAME" '
    .containerDefinitions |= map(
        if .name == $CONTAINER then
            .image = $IMAGE
        else
            .
        end
    ) |
    del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .placementConstraints, .compatibilities, .registeredAt, .registeredBy)
')

# Register new task definition
echo "📝 Registering new task definition..."
NEW_TASK_DEF_ARN=$(echo $NEW_TASK_DEF | aws ecs register-task-definition \
    --region $AWS_REGION \
    --cli-input-json file:///dev/stdin \
    --query 'taskDefinition.taskDefinitionArn' \
    --output text)

echo "✅ New task definition registered: $NEW_TASK_DEF_ARN"

# Create AppSpec for CodeDeploy
echo "📄 Creating AppSpec for CodeDeploy..."
cat > /tmp/appspec_${SERVICE_NAME}.json << EOF
{
  "version": "0.0",
  "Resources": [
    {
      "TargetService": {
        "Type": "AWS::ECS::Service",
        "Properties": {
          "TaskDefinition": "$NEW_TASK_DEF_ARN",
          "LoadBalancerInfo": {
            "ContainerName": "$CONTAINER_NAME",
            "ContainerPort": $CONTAINER_PORT
          }
        }
      }
    }
  ]
}
EOF

echo "🚀 Starting CodeDeploy Blue-Green deployment..."
DEPLOYMENT_ID=$(aws deploy create-deployment \
    --application-name $CODEDEPLOY_APP \
    --deployment-group-name $DEPLOYMENT_GROUP \
    --revision "revisionType=AppSpecContent,appSpecContent={content='$(cat /tmp/appspec_${SERVICE_NAME}.json | jq -c .)'}" \
    --region $AWS_REGION \
    --query 'deploymentId' \
    --output text)

echo "✅ CodeDeploy deployment started!"
echo "📊 Deployment ID: $DEPLOYMENT_ID"
echo ""
echo "🔄 Traffic Shifting Schedule (Linear 10% every minute):"
echo "   Minute 0: 0% → 10% traffic to new version"
echo "   Minute 1: 10% → 20% traffic to new version"
echo "   ..."
echo "   Minute 9: 90% → 100% traffic to new version"
echo ""
echo "🌐 Monitor deployment:"
echo "   AWS Console: https://console.aws.amazon.com/codesuite/codedeploy/deployments/$DEPLOYMENT_ID"
echo "   CLI: aws deploy get-deployment --deployment-id $DEPLOYMENT_ID"
echo ""
echo "⏱️  Total deployment time: ~10 minutes for complete traffic shift"
echo "🔙 Automatic rollback enabled on health check failures"

# Cleanup
rm -f /tmp/appspec_${SERVICE_NAME}.json

echo "🎉 Blue-Green deployment initiated successfully!"