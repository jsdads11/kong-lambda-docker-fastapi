FROM public.ecr.aws/lambda/python:3.12
COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.9.1 /lambda-adapter /opt/extensions/lambda-adapter
ENV PORT=8000
WORKDIR /var/task
COPY requirements.txt ./
RUN python -m pip install -r requirements.txt
COPY *.py ./
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]

# Local run of container

# docker buildx build --platform linux/amd64 --provenance=false -t docker-image:fastapi .
# docker run --platform linux/amd64 -p 9001:8080 docker-image:fastapi

## port mapping  HOST_PORT:CONTAINER_PORT <9001:8080>
## docker buildx build --platform linux/amd64 --provenance=false -t docker-image:fastapi . 
## docker run --platform linux/amd64 -p 9001:8080 docker-image:fastapi
## docker run --platform linux/amd64 -d -p 9001:8080 docker-image:test lambda_function.handler

# curl http://localhost:9001/lamdbda_function 
# curl -v http://localhost:8080/
# curl "http://localhost:9001/2015-03-31/functions/function/invocations" -d '{}'
# sleep 2 && curl "http://localhost:9001/2015-03-31/functions/function/invocations" -d '{}'

#Perfect! The server is now running successfully on port 9001. 

#The Lambda function is responding correctly. You can now test it with:
#•  curl "http://localhost:9001/2015-03-31/functions/function/invocations" -d '{}'
#•  curl "http://localhost:9001/2015-03-31/functions/function/invocations" -d '{"payload":"hello world!"}'