# Teknoir Paho MQTT C++ Demo
A small footprint mqqtt app.

## Build
```bash
gcloud builds submit . --config=cloudbuild.yaml --timeout=3600
```

## Build locally
```bash
mkdir build
cd build
cmake ..
make
make install
```

## Run locally
```bash
docker run -it --rm -p 1883:1883 -p 9001:9001 --name mqtt-broker eclipse-mosquitto
# and in another terminal window run:
docker run -it --rm -e HMQ_SERVICE_HOST=<YOUR IP> tekn0ir/paho-app-cpp:amd64
```

## Legacy build and publish docker images
```bash
docker build -t tekn0ir/paho-app-cpp:amd64 -f amd64.Dockerfile .
docker push tekn0ir/paho-app-cpp:amd64


```