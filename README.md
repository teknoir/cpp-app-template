# Teknoir App C++ Template
A small footprint c++ app.
A base for building c++ apps on the teknoir platform.

## Build
```bash
gcloud builds submit . --config=cloudbuild.yaml --timeout=3600 --substitutions=SHORT_SHA="$(date +v%Y%m%d)-$(git describe --tags --always --dirty)-$(git diff | shasum -a256 | cut -c -6)"
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
docker run -it --rm -e HMQ_SERVICE_HOST=<YOUR IP> tekn0ir/teknoir-app-cpp:amd64
```
To stop the example press `ctrl-c`.


## Legacy build and publish docker images
```bash
docker build -t tekn0ir/teknoir-app-cpp:amd64 -f amd64.Dockerfile .
docker push tekn0ir/teknoir-app-cpp:amd64


```