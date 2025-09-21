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
    "grafana")
        TASK_FAMILY="medisupply-grafana"
        CONTAINER_NAME="grafana"
        CONTAINER_PORT=3000
        USE_ECS_UPDATE=true
        ;;
    "prometheus")
        TASK_FAMILY="medisupply-prometheus"
        CONTAINER_NAME="prometheus"
        CONTAINER_PORT=9090
        USE_ECS_UPDATE=true
        ;;
    *)
        echo "❌ Unknown service: $SERVICE_NAME"
        exit 1
        ;;
esac

echo "📋 Service Configuration:"
echo "   Task Family: $TASK_FAMILY"
if [ -z "$USE_ECS_UPDATE" ]; then
    echo "   Deployment Group: $DEPLOYMENT_GROUP"
fi
echo "   Container: $CONTAINER_NAME:$CONTAINER_PORT"

# Get current task definition to copy its configuration
echo "🔍 Getting current task definition..."
CURRENT_TASK_DEF=$(aws ecs describe-task-definition \
    --task-definition $TASK_FAMILY \
    --query 'taskDefinition' \
    --region $AWS_REGION)

if [ $? -ne 0 ]; then
    echo "❌ Failed to get current task definition for $TASK_FAMILY"
    exit 1
fi

# Update the container image and create new task definition revision
echo "🔄 Creating new task definition with updated image..."

# Create a clean task definition file with updated image
echo "$CURRENT_TASK_DEF" | jq --arg image_uri "$IMAGE_URI" --arg container_name "$CONTAINER_NAME" '{
    family: .family,
    taskRoleArn: .taskRoleArn,
    executionRoleArn: .executionRoleArn,
    networkMode: .networkMode,
    containerDefinitions: (.containerDefinitions | map(
        if .name == $container_name then
            .image = $image_uri
        else
            .
        end
    )),
    volumes: .volumes,
    requiresCompatibilities: .requiresCompatibilities,
    cpu: .cpu,
    memory: .memory
}' > /tmp/task_def_${SERVICE_NAME}.json

NEW_TASK_DEF_ARN=$(aws ecs register-task-definition \
    --region $AWS_REGION \
    --cli-input-json file:///tmp/task_def_${SERVICE_NAME}.json \
    --query 'taskDefinition.taskDefinitionArn' \
    --output text)

if [ $? -ne 0 ] || [ -z "$NEW_TASK_DEF_ARN" ]; then
    echo "❌ Failed to register new task definition revision"
    exit 1
fi

echo "✅ New task definition registered: $NEW_TASK_DEF_ARN"

# Handle deployment based on service type
if [ "$USE_ECS_UPDATE" = true ]; then
    echo "🔄 Updating ECS service directly (no CodeDeploy)..."

    # Update the service with new task definition
    aws ecs update-service \
        --cluster $ECS_CLUSTER \
        --service $TASK_FAMILY \
        --task-definition $NEW_TASK_DEF_ARN \
        --region $AWS_REGION \
        --query 'service.serviceName' \
        --output text

    if [ $? -eq 0 ]; then
        echo "✅ ECS service updated successfully!"
        echo "🔄 ECS will rolling update to new task definition"
        echo "🌐 Monitor in AWS Console: https://console.aws.amazon.com/ecs/home?region=$AWS_REGION#/clusters/$ECS_CLUSTER/services"
    else
        echo "❌ Failed to update ECS service"
        exit 1
    fi

    # Cleanup and exit
    rm -f /tmp/task_def_${SERVICE_NAME}.json
    echo "🎉 ECS service update completed successfully!"
    exit 0
fi

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

if [ $? -ne 0 ] || [ -z "$DEPLOYMENT_ID" ]; then
    echo "❌ Failed to create CodeDeploy deployment"
    echo "Check AWS console for deployment details"
    exit 1
fi

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
rm -f /tmp/task_def_${SERVICE_NAME}.json

echo "🎉 Blue-Green deployment initiated successfully!"