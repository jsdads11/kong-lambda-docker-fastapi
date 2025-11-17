# FastAPI AWS Lambda Python

## 1. Create Local Runnable version of Docker FastAPI AWS Lambda code.
### Docker AWS Lambda Python

cd /Users/tonyodonnell/Kong-Lambda-Docker-FastAPI

Local run of container
````
docker buildx build --platform linux/amd64 --provenance=false -t docker-image:fastapi .
````
````
docker run --platform linux/amd64 -p 9001:8080 docker-image:fastapi
````
port mapping  HOST_PORT:CONTAINER_PORT <9001:8080>

docker run --platform linux/amd64 -d -p 9001:8080 docker-image:test lambda_function.handler

curl http://localhost:9001/lamdbda_function 

curl -v http://localhost:8080/

curl "http://localhost:9001/2015-03-31/functions/function/invocations" -d '{}'

sleep 2 && curl "http://localhost:9001/2015-03-31/functions/function/invocations" -d '{}'

#### Perfect! The server is now running successfully on port 9001. 

The Lambda function is responding correctly. You can now test it with:

•  curl "http://localhost:9001/2015-03-31/functions/function/invocations" -d '{}'

•  curl "http://localhost:9001/2015-03-31/functions/function/invocations" -d '{"payload":"hello world!"}'

---

# 2. Now deploy Docker FastAPI AWS Lambda code to AWS as a Lambda Python

### Set up AWS Lambda Environment and Deploy via ECR

Set AWS Creds and Configs
````
aws configure
````
// run get-login-passward command below as a single command
````
aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin 129269632956.dkr.ecr.eu-west-1.amazonaws.com
````
// repository name must be lower-caseq
````
aws ecr create-repository --repository-name kong-lambda-docker-fastapi --region eu-west-1 --image-scanning-configuration scanOnPush=true --image-tag-mutability MUTABLE
````
// ws ecr describe-repositories --repository-names kong-lambda-docker-fastapi
````
{
    "repositories": [
        {
            "repositoryArn": "arn:aws:ecr:eu-west-1:129269632956:repository/kong-lambda-docker-fastapi",
            "registryId": "129269632956",
            "repositoryName": "kong-lambda-docker-fastapi",
            "repositoryUri": "129269632956.dkr.ecr.eu-west-1.amazonaws.com/kong-lambda-docker-fastapi",
            "createdAt": "2025-11-16T10:52:54.194000+00:00",
            "imageTagMutability": "MUTABLE",
            "imageScanningConfiguration": {
                "scanOnPush": true
            },
            "encryptionConfiguration": {
                "encryptionType": "AES256"
            }
        }
    ]
}
````

// "repositoryUri": "905418199363.dkr.ecr.eu-west-1.amazonaws.com/ong-lambda-docker-fastapi"

// tag and push image to AWS ECR
````
docker tag docker-image:test 129269632956.dkr.ecr.eu-west-1.amazonaws.com/kong-lambda-docker-fastapi:latest
````
````
docker push 129269632956.dkr.ecr.eu-west-1.amazonaws.com/kong-lambda-docker-fastapi:latest
````

<span style="color: #179803ff; font-family: Babas; font-size: 1em;">
The push refers to repository [129269632956.dkr.ecr.eu-west-1.amazonaws.com/kong-lambda-docker-fastapi] <br>
61f7e5d657a2: Pushed 
cf3f8ccf59bb: Pushing [==================================================>]  2.963MB/2.963MB  <br>
4f4fb700ef54: Pushed  <br>
6c44d335f0cb: Pushing [==================================>                ]  25.17MB/36.89MB  <br>
a4ec5d732ea0: Pushing [=========================>                         ]  5.243MB/10.14MB  <br>
2831a7d11c1a: Pushed  <br>
e1f9c820f9c2: Pushing [===>                                               ]  10.49MB/146.1MB  <br>
fff8749513cc: Pushed  <br>
74de38b4a9b6: Pushing [==================================================>]  1.696MB/1.696MB  <br>
0123fd21151e: Pushed  <br>
ee7f93ab0035: Pushed  <br>
</span>
<br>

// create role (may already exist)
````
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
````
// output (aws iam get-role --role-name lambda-ex)
````
{
    "Role": {
        "Path": "/",
        "RoleName": "lambda-ex",
        "RoleId": "AROAR4GISB66LKLCITVVL",
        "Arn": "arn:aws:iam::129269632956:role/lambda-ex",
        "CreateDate": "2025-11-15T19:06:47+00:00",
        "AssumeRolePolicyDocument": {
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
        }
    }
}
````
// create lambda function kong-lambda-docker-fastapi
// <span style="color: #985203ff"> Need to refresh credentials aws config </span>
````
aws lambda create-function --function-name kong-lambda-docker-fastapi --package-type Image --code ImageUri=129269632956.dkr.ecr.eu-west-1.amazonaws.com/kong-lambda-docker-fastapi:latest --role arn:aws:iam::129269632956:role/lambda-ex --region eu-west-1
````
````
aws lambda invoke --function-name kong-lambda-docker-fastapi response.json
````
output. ( >> response.json file)

````
{
    "StatusCode": 200,
    "ExecutedVersion": "$LATEST"
}
(END)
````
<br>
curl "http://localhost:9001/2015-03-31/functions/function/invocations" -d '{}'

<span style="color: #179803ff; font-family: Babas; font-size: 1.1em;"><br> 
"Hello from AWS Lambda using Python3.12.12 (main, Nov  3 2025, 10:02:13) [GCC 11.5.0 20240719 (Red Hat 11.5.0-5)]!"%
<span>

---

# Set up Kong to call the API

Goto Kong Konnect
Gateway Manmager
ej-eiapmm-dev Control Plane
- Gateway Services
  - kong-lambda-docker-fastapi-svc
- Routes
  - kong-lambda-docker-fastapi-rte # kong-lambda-docker-fastapi
- Lambda Plug-in on Route
  - Aws Assume Role Arn =
      - <span style="color: #985203ff"> WAS: FAST15: arn:aws:iam::129269632956:role/service-role/Kong-FastAPI5-role-y71mime5 </span>
      - <span style="color: #037910ff"> NOW </span>
  - Aws Imds Protocol Version = v2
  - Awsgateway Compatible Payload Version = 1.0
  - Aws Role Session Name = kong
  - Function Name = 

## CLONE ME for above (check role type upon creation AWS service or 3rd parties etc)
find AWS IAM ROLES Kong-FastAPI5-role-y71mime5
# CLONE ME



![alt text](https://github.com/jsdads11/kong-lambda-docker-fastapi/blob/main/images/kong-svc.jpg?raw=true)

![alt text](https://github.com/jsdads11/kong-lambda-docker-fastapi/blob/main/images/kong-rte.jpg?raw=true)

![alt text](https://github.com/jsdads11/kong-lambda-docker-fastapi/blob/main/images/kong-lambda-plugin.jpg?raw=true)

# kong-lambda-docker-fastapi

## to test
run via kong service endpoint 

### ??? - check with Chirang
````
https://api-dev.test.easyjet.com/main
````
---
#### Lambda kong-lambda-docker-fastapi-summary

Kong Plug In Lambda details

![alt text](https://github.com/jsdads11/kong-lambda-docker-fastapi/blob/main/images/aws-kong-lambda-docker-fastapi-summary.jpg?raw=true)

---
#### Lambda Plugin Kong Route 

Kong Plug In Lambda details

![alt text](https://github.com/jsdads11/kong-lambda-docker-fastapi/blob/main/images/LambdaPolicyAssumeRoles.jpg?raw=true)

---
#### elastic kong access log search.jpg

elastic kong-access log search

![alt text](https://github.com/jsdads11/kong-lambda-docker-fastapi/blob/main/images/elastic-kong-access-log-search.jpg?raw=true)

---
#### Lambda polciy
IAM Roles APIM-DEV-EKS-NODEGROUP-ROLE

Lambda Modify permissions in LambdaPolicyAssumeRoles

![alt text](https://github.com/jsdads11/kong-lambda-docker-fastapi/blob/main/images/LambdaPolicyAssumeRoles.jpg?raw=true)


---
#### AWS_EKS-Cluster-apim-dev

apim-dev-kong-comm-gateway-kong/

Controlled by 
ReplicaSet/apim-dev-kongg-commm-gateway-kong-85795555fcd-44kw
IP=10.117.72.81
app=apim-dev-kong-comm-gateway-kong

![alt text](https://github.com/jsdads11/kong-lambda-docker-fastapi/blob/main/images/AWS_EKS-Cluster-apim-dev.jpg?raw=true)