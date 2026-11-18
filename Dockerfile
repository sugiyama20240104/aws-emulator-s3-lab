FROM public.ecr.aws/aws-cli/aws-cli:2.34.20 AS base
FROM base AS package-arm64
ARG rpm_arch=aarch64
FROM base AS package-amd64
ARG rpm_arch=x86_64

FROM package-${TARGETARCH} AS lab
ARG rpm_arch
ADD https://downloads.aws.com/aws-emulator/packages/aws-emulator/LTS/latest/aws-emulator-${rpm_arch}.rpm /tmp/emulator.rpm
RUN rpm -i /tmp/emulator.rpm && rm /tmp/emulator.rpm \
    && mkdir -p /home/emulator && chown 1000:1000 /home/emulator
COPY examples/ /opt/lab/
ENV HOME=/home/emulator \
    AWS_ENDPOINT_URL=https://127.0.0.1:9297 \
    AWS_SHARED_CREDENTIALS_FILE=/home/emulator/.aws/emulator/9297/emulator_credentials \
    AWS_CONFIG_FILE=/home/emulator/.aws/emulator/9297/config \
    AWS_CA_BUNDLE=/home/emulator/.aws/emulator/9297/ca.pem \
    AWS_EC2_METADATA_DISABLED=true AWS_DISABLE_HOST_PREFIX_INJECTION=true \
    AWS_REGION=us-east-1 AWS_DEFAULT_REGION=us-east-1 AWS_PAGER="" \
    EMULATOR_TELEMETRY=off
USER 1000:1000
WORKDIR /home/emulator
ENTRYPOINT ["aws-emulator"]
