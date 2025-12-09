# FastAPI AWS Lambda Deployment Guide

This guide covers building, testing, and deploying a FastAPI application as an AWS Lambda function using Docker containers.

---

## Prerequisites

- Docker installed locally
- AWS CLI configured with appropriate credentials
- AWS account with ECR and Lambda access
- Kong Gateway access (for API gateway integration)

---

## Part 1: Local Development & Testing

### Project Directory
```bash
cd /Users/tonyodonnell/Kong-Lambda-Docker-FastAPI
```

> **Note:** Does not work off iCloud Drive

### Build Docker Image

Build the FastAPI image with FastAPI, Mangum, and Uvicorn:

```bash
docker buildx build --platform linux/amd64 --provenance=false -t docker-image:fastapi .
```

### Run Container Locally

```bash
# // docker run --platform linux/amd64 -d -p 9001:8080 docker-image:test lambda_function.handler
docker run --platform linux/amd64 -p 9001:8080 docker-image:fastapi lambda_function.handler
```

<span style='font-size: 10px;font-family: monospace, Consolar, DejaVu Sans Mono, Lucida Console, Courier, "Courier New";'>docker run --platform linux/amd64 -p 9001:8080 docker-image:fastapi lambda_function.handler
09 Dec 2025 21:13:15,980 [INFO] (rapid) exec '/var/runtime/bootstrap' (cwd=/var/task, handler=)</span>

<span style='font-size: 12px; color: green; font-family: monospace, Consolar, DejaVu Sans Mono, Lucida Console, Courier, "Courier New";'>DOCKER LOG: 09 Dec 2025 21:29:23,628 [INFO] (rapid) exec '/var/runtime/bootstrap' (cwd=/var/task, handler=)</span>

Port mapping: `HOST_PORT:CONTAINER_PORT` → `9001:8080`

### Test Lambda Function Locally

Once the container is running on port 9001, test with:

```bash
# Basic invocation
curl "http://localhost:9001/2015-03-31/functions/function/invocations" -d '{}'
```

```bash
# With payload
curl "http://localhost:9001/2015-03-31/functions/function/invocations" -d '{"payload":"hello Tony world!"}'
```

**Expected Response:**
```
Hello from AWS Lambda using Python3.12.12 (main, Nov  3 2025, 10:02:13) [GCC 11.5.0 20240719 (Red Hat 11.5.0-5)]!
```

---

## Part 2: AWS Deployment


> **Important:** Refresh AWS credentials before running this command
> AWS Account
> Copy and paste the following text in your AWS credentials file (~/.aws/credentials)
> [129269632956_EasyJet-App-PowerUser]
aws_access_key_id=xxxxxxxxxxxxxx
aws_secret_access_key=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
aws_session_token=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx==

### Step 1: Configure AWS Credentials

```bash
aws configure
```

### Step 2: Authenticate with ECR

```bash
aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin 129269632956.dkr.ecr.eu-west-1.amazonaws.com
```
<span style='font-size: 10px;font-family: monospace, Consolar, DejaVu Sans Mono, Lucida Console, Courier, "Courier New";'>Login Succeeded</span>


### Step 3: Create ECR Repository

Create Repository 

```bash
aws ecr create-repository \
  --repository-name kong-lambda-docker-fastapi \
  --region eu-west-1 \
  --image-scanning-configuration scanOnPush=true \
  --image-tag-mutability MUTABLE
```

**Repository Details:**
- **Repository URI:** `129269632956.dkr.ecr.eu-west-1.amazonaws.com/kong-lambda-docker-fastapi`
- **ARN:** `arn:aws:ecr:eu-west-1:129269632956:repository/kong-lambda-docker-fastapi`
- **Region:** eu-west-1

if already created, use get repo details command
```bash
aws ecr describe-repositories --repository-names kong-lambda-docker-fastapi
````

### Step 4: Tag and Push Image to ECR

```bash
# Tag the image
docker tag docker-image:fastapi 129269632956.dkr.ecr.eu-west-1.amazonaws.com/kong-lambda-docker-fastapi:latest

# Push to ECR
docker push 129269632956.dkr.ecr.eu-west-1.amazonaws.com/kong-lambda-docker-fastapi:latest
```

onyodonnell@Tonys-MacBook-Pro-2 Kong-Lambda-Docker-FastAPI % docker push 129269632956.dkr.ecr.eu-west-1.amazonaws.com/kong-lambda-docker-fastapi:latest
The push refers to repository [129269632956.dkr.ecr.eu-west-1.amazonaws.com/kong-lambda-docker-fastapi]
4348d3342ecf: Pushed 
9b21889975c3: Pushed 
17a598296246: Pushed 
d9dc62378ebc: Pushing [====>                                              ]  13.63MB/146.1MB
fba96b1ad933: Pushing [===========================>                       ]  19.92MB/36.86MB
9f1343d9f789: Pushing [==============================>                    ]  6.291MB/10.16MB
4f4fb700ef54: Layer already exists 
99fbe4cf46bd: Pushed 
17e472487fbd: Pushed 
78ffe3fc4d71: Pushed 
ee9fd57969cb: Pushed 

### Step 5: Create IAM Role for Lambda

Create the execution role (skip if `lambda-ex` role already exists):

```bash
aws iam create-role --role-name lambda-ex --assume-role-policy-document '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}'
```

**Role Details:**
- **Role Name:** lambda-ex
- **Role ARN:** `arn:aws:iam::129269632956:role/lambda-ex`
- **Role ID:** AROAR4GISB66LKLCITVVL

### Step 6: Create Lambda Function

```bash
aws lambda create-function \
  --function-name kong-lambda-docker-fastapi \
  --package-type Image \
  --code ImageUri=129269632956.dkr.ecr.eu-west-1.amazonaws.com/kong-lambda-docker-fastapi:latest \
  --role arn:aws:iam::129269632956:role/lambda-ex \
  --region eu-west-1
```

### Step 7: Test Lambda Function

```bash
aws lambda invoke --function-name kong-lambda-docker-fastapi response.json
```

**Expected Output:**
```json
{
  "StatusCode": 200,
  "ExecutedVersion": "$LATEST"
}
```

Check `response.json` for the function response.

---

## Part 3: Kong Gateway Configuration

### Kong Konnect Setup

Navigate to: **Gateway Manager** → **ej-eiapmm-dev Control Plane**

#### 1. Gateway Service
- **Service Name:** `kong-lambda-docker-fastapi-svc`

#### 2. Route Configuration
- **Route Name:** `kong-lambda-docker-fastapi-rte`
- **Service:** kong-lambda-docker-fastapi

#### 3. Lambda Plugin Configuration

Configure the following plugin settings:

| Setting | Value |
|---------|-------|
| **AWS Assume Role ARN** | ~~arn:aws:iam::129269632956:role/service-role/Kong-FastAPI5-role-y71mime5~~ (DEPRECATED)<br>**New ARN:** TBC |
| **AWS IMDS Protocol Version** | v2 |
| **AWS Gateway Compatible Payload** | 1.0 |
| **AWS Role Session Name** | kong |
| **Function Name** | TBC |

### API Endpoint

```
https://api-dev.test.easyjet.com/main
```

---

## Architecture Diagrams

### Kong Service Configuration
![Kong Service](https://github.com/jsdads11/kong-lambda-docker-fastapi/blob/main/images/kong-svc.jpg?raw=true)

### Kong Route Configuration
![Kong Route](https://github.com/jsdads11/kong-lambda-docker-fastapi/blob/main/images/kong-rte.jpg?raw=true)

### Kong Lambda Plugin
![Kong Lambda Plugin](https://github.com/jsdads11/kong-lambda-docker-fastapi/blob/main/images/kong-lambda-plugin.jpg?raw=true)

### Lambda Function Summary
![Lambda Summary](https://github.com/jsdads11/kong-lambda-docker-fastapi/blob/main/images/aws-kong-lambda-docker-fastapi-summary.jpg?raw=true)

### IAM Role Policies
![Lambda Policy](https://github.com/jsdads11/kong-lambda-docker-fastapi/blob/main/images/LambdaPolicyAssumeRoles.jpg?raw=true)

### Elastic Kong Access Logs
![Elastic Logs](https://github.com/jsdads11/kong-lambda-docker-fastapi/blob/main/images/elastic-kong-access-log-search.jpg?raw=true)

---

## AWS Resources Reference

### IAM Roles
- **APIM-DEV-EKS-NODEGROUP-ROLE**
  - Permissions modified in: `LambdaPolicyAssumeRoles`

### EKS Cluster
- **Cluster:** apim-dev
- **Namespace:** apim-dev-kong-comm-gateway-kong/
- **ReplicaSet:** apim-dev-kongg-commm-gateway-kong-85795555fcd-44kw
- **Pod IP:** 10.117.72.81
- **App Label:** apim-dev-kong-comm-gateway-kong

![EKS Cluster](https://github.com/jsdads11/kong-lambda-docker-fastapi/blob/main/images/AWS_EKS-Cluster-apim-dev.jpg?raw=true)

---

## Troubleshooting

### Common Issues

1. **Docker build fails on iCloud Drive**
   - Solution: Work from local directory outside iCloud

2. **ECR authentication expires**
   - Solution: Re-run the `aws ecr get-login-password` command

3. **Lambda invocation fails**
   - Check IAM role permissions
   - Verify image was pushed successfully to ECR
   - Review Lambda function logs in CloudWatch

4. **Kong gateway returns 500 error**
   - Verify Lambda plugin configuration
   - Check assume role ARN is correct
   - Review Kong access logs in Elastic

---

## Additional Commands

### Verify Repository
```bash
aws ecr describe-repositories --repository-names kong-lambda-docker-fastapi
```

### Get IAM Role Details
```bash
aws iam get-role --role-name lambda-ex
```

### Update Lambda Function
```bash
aws lambda update-function-code \
  --function-name kong-lambda-docker-fastapi \
  --image-uri 129269632956.dkr.ecr.eu-west-1.amazonaws.com/kong-lambda-docker-fastapi:latest
```