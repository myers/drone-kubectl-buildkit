FROM alpine:3.15

RUN apk --no-cache add curl ca-certificates bash

RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
  && chmod +x kubectl \
  && mv kubectl /usr/local/bin
RUN curl -LO https://github.com/vmware-tanzu/buildkit-cli-for-kubectl/releases/download/v0.1.5/linux-v0.1.5.tgz \
  && tar zxf linux-v0.1.5.tgz -C /usr/local/bin \
  && rm linux-v0.1.5.tgz
RUN chown root: /usr/local/bin/* && chmod +x /usr/local/bin/*
RUN mkdir /drone
WORKDIR /drone

RUN apk --no-cache add libc6-compat

COPY plugin.sh /usr/local/bin
CMD ["/usr/local/bin/plugin.sh"]