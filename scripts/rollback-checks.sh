#!/bin/bash
# Pre-deploy checks for the Rollback workflow.
# Validates the rollback target, confirms the image and ECS service exist,
# and downloads the service's current task definition to task-definition.json.
#
# Required environment variables:
#   IMAGE_SHA, ECR_REPOSITORY, ECS_CLUSTER, ECS_SERVICE, GITHUB_REF

set -euo pipefail

fail() {
  echo "::error::$1"
  exit 1
}

: "${ECR_REPOSITORY:?ECR_REPOSITORY is not set}"
: "${ECS_CLUSTER:?ECS_CLUSTER is not set}"
: "${ECS_SERVICE:?ECS_SERVICE is not set}"
GITHUB_OUTPUT="${GITHUB_OUTPUT:-/dev/null}"

# 1. Rollback target
[ "${GITHUB_REF:-}" = "refs/heads/main" ] || fail "Run the rollback from the main branch."
[ -n "${IMAGE_SHA:-}" ] || fail "A rollback target SHA is required."
[[ "$IMAGE_SHA" =~ ^[0-9a-f]{40}$ ]] ||
  fail "'$IMAGE_SHA' is not a full 40-character lowercase Git SHA. Mutable tags such as latest are not allowed."

# 2. Image exists in ECR
digest=$(aws ecr describe-images \
  --repository-name "$ECR_REPOSITORY" \
  --image-ids imageTag="$IMAGE_SHA" \
  --query 'imageDetails[0].imageDigest' \
  --output text) ||
  fail "Image tag $IMAGE_SHA was not found in ECR repository $ECR_REPOSITORY."
echo "Found $ECR_REPOSITORY:$IMAGE_SHA ($digest)"

# 3. ECS service exists and is active
task_definition_arn=$(aws ecs describe-services \
  --cluster "$ECS_CLUSTER" \
  --services "$ECS_SERVICE" \
  --query "services[?status=='ACTIVE'] | [0].taskDefinition" \
  --output text)
[ "$task_definition_arn" != "None" ] ||
  fail "ECS service $ECS_SERVICE was not found or is not active in cluster $ECS_CLUSTER."

# 4. Current task definition, used as the base for the rollback
aws ecs describe-task-definition \
  --task-definition "$task_definition_arn" \
  --query taskDefinition \
  > task-definition.json
current_image=$(jq -r '.containerDefinitions[] | select(.name == "legacy-api") | .image' task-definition.json)
echo "Currently running $current_image ($task_definition_arn)"

{
  echo "digest=$digest"
  echo "previous-image=$current_image"
  echo "previous-task-definition=$task_definition_arn"
} >> "$GITHUB_OUTPUT"
