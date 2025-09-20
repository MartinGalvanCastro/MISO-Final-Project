#!/bin/bash

set -e

echo "🔍 Validating deployment readiness..."

# Check AWS credentials
echo "Checking AWS credentials..."
aws sts get-caller-identity > /dev/null
echo "✅ AWS credentials configured"

# Check ECR repositories
echo "Checking ECR repositories..."
for repo in orders-service inventory-service prometheus grafana; do
    if aws ecr describe-repositories --repository-names "medisupply/$repo" > /dev/null 2>&1; then
        echo "✅ ECR repository medisupply/$repo exists"
    else
        echo "❌ ECR repository medisupply/$repo not found"
        exit 1
    fi
done

# Check ECS cluster
echo "Checking ECS cluster..."
if aws ecs describe-clusters --clusters medisupply-cluster --query 'clusters[0].status' --output text | grep -q "ACTIVE"; then
    echo "✅ ECS cluster medisupply-cluster is active"
else
    echo "❌ ECS cluster medisupply-cluster not active"
    exit 1
fi

# Check ECS services
echo "Checking ECS services..."
for service in medisupply-orders-service medisupply-inventory-service medisupply-prometheus medisupply-grafana; do
    if aws ecs describe-services --cluster medisupply-cluster --services $service --query 'services[0].status' --output text | grep -q "ACTIVE"; then
        echo "✅ ECS service $service is active"
    else
        echo "❌ ECS service $service not active"
        exit 1
    fi
done

# Check ALB
echo "Checking Application Load Balancer..."
if aws elbv2 describe-load-balancers --names medisupply-alb --query 'LoadBalancers[0].State.Code' --output text | grep -q "active"; then
    echo "✅ ALB medisupply-alb is active"
    ALB_DNS=$(aws elbv2 describe-load-balancers --names medisupply-alb --query 'LoadBalancers[0].DNSName' --output text)
    echo "🌐 ALB DNS: $ALB_DNS"
else
    echo "❌ ALB medisupply-alb not active"
    exit 1
fi

# Check if Docker images exist in ECR
echo "Checking Docker images in ECR..."
for repo in orders-service inventory-service prometheus grafana; do
    if aws ecr list-images --repository-name "medisupply/$repo" --query 'imageIds[?imageTag==`latest`]' | grep -q "latest"; then
        echo "✅ Latest image exists in medisupply/$repo"
    else
        echo "⚠️  No latest image in medisupply/$repo (will be built by CI/CD)"
    fi
done

echo ""
echo "🎉 Deployment validation complete!"
echo ""
echo "📋 Next steps:"
echo "1. Push code changes to trigger CI/CD pipeline"
echo "2. Monitor deployment in GitHub Actions"
echo "3. Access services via ALB: http://$ALB_DNS"
echo ""
echo "🔗 Service endpoints:"
echo "   Orders API: http://$ALB_DNS/api/v1/orders"
echo "   Inventory API: http://$ALB_DNS/api/v1/inventory"
echo "   Prometheus: http://$ALB_DNS/prometheus"
echo "   Grafana: http://$ALB_DNS/grafana"