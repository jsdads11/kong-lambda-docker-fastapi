import sys

def handler(event, context):
    return 'lambda_function: Hello from AWS Lambda with FastAPI using Python' + sys.version + '!'
