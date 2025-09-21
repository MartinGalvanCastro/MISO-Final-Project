# Blue-Green Deployments with Service Discovery - Research Plan

## Current Issue

**Problem**: AWS ECS Service Connect is incompatible with CodeDeploy blue-green deployments.

**Error Encountered**:
```
InvalidParameterException: DeploymentController#type CODE_DEPLOY is not supported by ECS Service Connect.
```

**Current Workaround**: Using ALB for internal service-to-service communication instead of service discovery.

## Current Architecture

```
┌─────────────────┐    ┌─────────────────┐
│ orders-service  │────▶│ External ALB    │────▶┌─────────────────┐
│                 │    │ (public)        │     │ inventory-service│
│ Uses ALB for    │    │                 │     │                 │
│ internal calls  │    │ /api/v1/orders  │     │ /api/v1/inventory│
└─────────────────┘    │ /api/v1/inventory│     └─────────────────┘
                       └─────────────────┘
```

**Issues with Current Approach**:
- ✅ Works for blue-green deployments
- ❌ All internal traffic goes through public ALB (security/performance concern)
- ❌ No true service discovery (hardcoded ALB URLs)
- ❌ Single point of failure
- ❌ Higher latency for internal calls

## Research Areas

### 1. AWS-Native Solutions

#### Option A: Internal Application Load Balancer
**Research**: Create dedicated internal ALB for service-to-service communication
- **Pros**: Network isolation, supports blue-green at ALB level
- **Cons**: Additional cost, more complex routing
- **Investigation**: Cost analysis, routing complexity, security implications

#### Option B: ECS Service Discovery + Custom Blue-Green Orchestration
**Research**: Build custom blue-green deployment logic that manages service discovery
- **Pros**: True service discovery, AWS native
- **Cons**: Complex orchestration logic required
- **Investigation**: Lambda-based orchestration, service registry state management

#### Option C: AWS App Mesh
**Research**: Service mesh solution that might support blue-green
- **Pros**: Advanced traffic management, observability
- **Cons**: Additional complexity, learning curve
- **Investigation**: App Mesh + CodeDeploy compatibility, cost implications

### 2. Third-Party Service Mesh Solutions

#### Option D: Istio on ECS
**Research**: Deploy Istio service mesh on ECS Fargate
- **Pros**: Industry standard, advanced features
- **Cons**: Complex setup, resource overhead
- **Investigation**: ECS Fargate compatibility, operational complexity

#### Option E: Consul Connect
**Research**: HashiCorp Consul for service discovery and connect for service mesh
- **Pros**: Mature service discovery, good ECS integration
- **Cons**: Additional infrastructure to manage
- **Investigation**: ECS integration patterns, blue-green workflows

### 3. Application-Level Solutions

#### Option F: Environment-Aware Service Discovery
**Research**: Application logic that routes to correct service versions
- **Pros**: Simple, application controlled
- **Cons**: Application complexity, not infrastructure-native
- **Investigation**: Environment variable patterns, service naming conventions

#### Option G: Feature Flags + Canary Releases
**Research**: Use feature flags instead of infrastructure-level blue-green
- **Pros**: Fine-grained control, gradual rollouts
- **Cons**: Application code changes required
- **Investigation**: LaunchDarkly/split.io integration, canary patterns

## Priority Research Order

### Phase 1: Quick Wins (1-2 weeks)
1. **Internal ALB Pattern** - Most straightforward AWS-native solution
2. **Environment-Aware Discovery** - Simple application-level approach

### Phase 2: Advanced Solutions (1 month)
3. **Custom Blue-Green with Service Discovery** - Lambda orchestration
4. **AWS App Mesh Integration** - Evaluate enterprise readiness

### Phase 3: Long-term Solutions (2-3 months)
5. **Third-party Service Mesh** - If AWS solutions insufficient
6. **Hybrid Approach** - Combine multiple patterns

## Success Criteria

A successful solution must provide:
- ✅ True blue-green deployments (instant rollback)
- ✅ Service discovery (no hardcoded URLs)
- ✅ Network security (private communication)
- ✅ High availability (no single points of failure)
- ✅ Operational simplicity (maintainable by small team)
- ✅ Cost effectiveness (reasonable AWS costs)

## Decision Framework

| Solution | Blue-Green | Service Discovery | Security | Complexity | Cost |
|----------|------------|-------------------|----------|------------|------|
| Current ALB | ✅ | ❌ | ⚠️ | Low | Low |
| Internal ALB | ✅ | ⚠️ | ✅ | Medium | Medium |
| Custom Orchestration | ✅ | ✅ | ✅ | High | Low |
| App Mesh | ✅ | ✅ | ✅ | High | High |
| Istio | ✅ | ✅ | ✅ | Very High | Medium |

## Next Steps

1. **Document current ALB approach** (ensure it works reliably)
2. **Research internal ALB pattern** (quick win)
3. **Prototype custom orchestration** (high value if successful)
4. **Evaluate App Mesh** (AWS native long-term solution)

## Resources

- [AWS ECS Service Connect Documentation](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-connect.html)
- [AWS CodeDeploy Blue-Green Documentation](https://docs.aws.amazon.com/codedeploy/latest/userguide/applications-create-blue-green.html)
- [AWS App Mesh Documentation](https://docs.aws.amazon.com/app-mesh/)
- [ECS Blue-Green Best Practices](https://aws.amazon.com/blogs/containers/)

## Current Status

- **Date**: September 21, 2025
- **Status**: Using ALB workaround, research phase initiated
- **Owner**: DevOps team
- **Next Review**: 2 weeks from implementation