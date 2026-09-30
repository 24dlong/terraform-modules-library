# Minimal test image for verifying the nextjs-lambda module by hand: a static
# HTTP server behind the AWS Lambda Web Adapter extension. Not an application
# build; the real Next.js image is published by the application repository.
#checkov:skip=CKV_DOCKER_2:Lambda does not use Docker HEALTHCHECK; the Web Adapter readiness check covers startup.
FROM public.ecr.aws/docker/library/python:3.13-alpine

COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:1.0.1 /lambda-adapter /opt/extensions/lambda-adapter

WORKDIR /srv
RUN printf '<!doctype html><html><body><h1>nextjs-lambda placeholder</h1></body></html>\n' > index.html

ENV AWS_LWA_PORT=8080
USER nobody

CMD ["python", "-m", "http.server", "8080", "--directory", "/srv"]
