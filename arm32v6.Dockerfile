FROM balenalib/raspberry-pi-debian:buster-build as paho_build

RUN [ "cross-build-start" ]

RUN apt update && apt-get --no-install-recommends install -y build-essential gcc make cmake cmake-gui cmake-curses-gui libssl-dev git

ENV PAHO_MQTT_HOME=/paho.mqtt
ENV C_INCLUDE_PATH=${PAHO_MQTT_HOME}/include:${C_INCLUDE_PATH}
ENV CPATH=${PAHO_MQTT_HOME}/include:$CPATH
WORKDIR ${PAHO_MQTT_HOME}
RUN git clone https://github.com/eclipse/paho.mqtt.c.git && \
    cd paho.mqtt.c && git checkout v1.3.1 && \
    cmake -Bbuild -H. -DPAHO_WITH_SSL=TRUE -DPAHO_BUILD_DOCUMENTATION=FALSE -DPAHO_BUILD_SAMPLES=FALSE -DPAHO_ENABLE_TESTING=FALSE -DCMAKE_INSTALL_PREFIX=${PAHO_MQTT_HOME} && \
    cmake --build build/ --target install

RUN git clone https://github.com/eclipse/paho.mqtt.cpp && \
    cd paho.mqtt.cpp && \
    cmake -Bbuild -H. -DPAHO_BUILD_DOCUMENTATION=FALSE -DPAHO_BUILD_SAMPLES=FALSE -DCMAKE_INSTALL_PREFIX=${PAHO_MQTT_HOME} -DCMAKE_PREFIX_PATH=${PAHO_MQTT_HOME} && \
    cmake --build build/ --target install

RUN [ "cross-build-end" ]

##########################
FROM  balenalib/raspberry-pi-debian:buster-build as app_build

RUN [ "cross-build-start" ]

RUN apt update && apt-get --no-install-recommends install -y build-essential gcc make cmake cmake-gui cmake-curses-gui libssl-dev git

ENV PAHO_MQTT_HOME=/paho.mqtt
COPY --from=paho_build ${PAHO_MQTT_HOME}/lib /usr/lib
COPY --from=paho_build ${PAHO_MQTT_HOME}/include /usr/include

WORKDIR /app
ADD . /app
RUN cmake -Bbuild -H. -DCMAKE_INSTALL_PREFIX=/app && \
    cmake --build build/ --target install

RUN [ "cross-build-end" ]

##########################
FROM  balenalib/raspberry-pi-debian:buster-build as app_release

RUN [ "cross-build-start" ]

RUN apt update && apt-get --no-install-recommends install -y openssl

ENV PAHO_MQTT_HOME=/paho.mqtt
COPY --from=paho_build ${PAHO_MQTT_HOME}/lib /usr/lib
COPY --from=app_build /app/bin /usr/bin

CMD ["/usr/bin/tester", "tek", "noir"]

RUN [ "cross-build-end" ]
