FROM balenalib/raspberrypi3-debian:buster-build

RUN [ "cross-build-start" ]

#labeling
LABEL mantainer="Anders Åslund <teknoir@teknoir.se>" \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.name="asset-tracker" \
    org.label-schema.description="Docker running Raspbian including Coral Edge-TPU libraries" \
    org.label-schema.url="https://www.teknoir.se" \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url="https://github.com/tekn0ir" \
    org.label-schema.vendor="Anders Åslund" \
    org.label-schema.version=$VERSION \
    org.label-schema.schema-version="1.0"

ENV READTHEDOCS True


RUN echo "deb https://packages.cloud.google.com/apt coral-edgetpu-stable main" | sudo tee /etc/apt/sources.list.d/coral-edgetpu.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - && \
    apt-get update && \
    apt-get install -y --no-install-recommends --allow-downgrades \
    libedgetpu1-std python3-dev python3-pip python3-setuptools python3-wheel python3-numpy python3-pil python3-matplotlib python3-zmq python3-opencv

#RUN apt-get update && \
#    apt-get install -y --no-install-recommends --allow-downgrades \
#    build-essential wget feh pkg-config libjpeg-dev zlib1g-dev \
#    libfreetype6-dev libxml2 libopenjp2-7 \
#    libatlas-base-dev libjasper-dev libqtgui4 libqt4-test \
#    python3-dev python3-pip python3-setuptools python3-wheel python3-numpy python3-pil python3-matplotlib python3-zmq \
#    libusb-dev libusb-1.0-0-dev
#
#ENV LIBUSB_LIBDIR /usr/lib/arm-linux-gnueabihf
#ENV LIBUSB_INCDIR /usr/include/libusb-1.0
#
##installing edge-tpu library
#WORKDIR /opt
#RUN wget https://github.com/google-coral/edgetpu-platforms/releases/download/v1.9.2/edgetpu_api_1.9.2.tar.gz -O edgetpu_api.tar.gz --trust-server-names \
#    && tar xzf edgetpu_api.tar.gz \
#    && rm edgetpu_api.tar.gz \
#    && cd /opt/edgetpu_api/ \
#    && chmod +x install.sh \
#    && sed -i 's/MODEL=\$(cat \/proc\/device-tree\/model)/MODEL="Raspberry Pi 3 Model B Rev 1\.1"/g' install.sh \
#    && sed -i 's/read USE_MAX_FREQ/USE_MAX_FREQ="No"/g' install.sh \
#    && cat install.sh \
#    && bash install.sh -y \
#    && ln -s /usr/lib/arm-linux-gnueabihf/libedgetpu.so.1.0 /usr/lib/arm-linux-gnueabihf/libedgetpu.so

RUN [ "cross-build-end" ]
