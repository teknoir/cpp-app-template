FROM debian:stable as paho_build

RUN apt update && apt-get --no-install-recommends install -y build-essential gcc make cmake cmake-gui cmake-curses-gui libssl-dev git ca-certificates

ENV PAHO_MQTT_HOME=/paho.mqtt
ENV C_INCLUDE_PATH=${PAHO_MQTT_HOME}/include:${C_INCLUDE_PATH}
ENV CPATH=${PAHO_MQTT_HOME}/include:$CPATH
WORKDIR ${PAHO_MQTT_HOME}
RUN git clone -b v1.3.11 https://github.com/eclipse/paho.mqtt.c.git && \
    cd paho.mqtt.c && \
    cmake -Bbuild -H. -DPAHO_HIGH_PERFORMANCE=ON -DPAHO_BUILD_STATIC=ON -DPAHO_BUILD_SHARED=OFF -DPAHO_WITH_SSL=ON -DPAHO_BUILD_DOCUMENTATION=OFF -DPAHO_BUILD_SAMPLES=OFF -DPAHO_ENABLE_TESTING=OFF -DCMAKE_INSTALL_PREFIX=${PAHO_MQTT_HOME} && \
    cmake --build build/ --target install

RUN git clone -b v1.2.0 https://github.com/eclipse/paho.mqtt.cpp && \
    cd paho.mqtt.cpp && \
    cmake -Bbuild -H. -DPAHO_BUILD_STATIC=ON -DPAHO_BUILD_SHARED=OFF -DPAHO_WITH_SSL=ON -DPAHO_BUILD_DOCUMENTATION=OFF -DPAHO_BUILD_SAMPLES=OFF -DCMAKE_INSTALL_PREFIX=${PAHO_MQTT_HOME} -DCMAKE_PREFIX_PATH=${PAHO_MQTT_HOME} && \
    cmake --build build/ --target install

##########################
FROM debian:stable as app_build

RUN apt update && apt-get --no-install-recommends install -y build-essential gcc make cmake cmake-gui cmake-curses-gui libssl-dev git

ENV PAHO_MQTT_HOME=/paho.mqtt
COPY --from=paho_build ${PAHO_MQTT_HOME}/lib /usr/lib
COPY --from=paho_build ${PAHO_MQTT_HOME}/include /usr/include

WORKDIR /app
ADD app /app
RUN cmake -Bbuild -H. -DCMAKE_INSTALL_PREFIX=/app && \
    cmake --build build/ --target install

##########################
FROM debian:stable-slim

WORKDIR /usr/bin
COPY --from=app_build /app/bin /usr/bin

STOPSIGNAL SIGINT
CMD ["/usr/bin/teknoir-app"]