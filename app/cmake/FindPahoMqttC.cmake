# find the Paho MQTT C library
set(_PAHO_MQTT_C_LIB_NAME paho-mqtt3a)
find_package(OpenSSL REQUIRED)

find_library(PAHO_MQTT_C_LIBRARIES NAMES ${_PAHO_MQTT_C_LIB_NAME})
unset(_PAHO_MQTT_C_LIB_NAME)
find_path(PAHO_MQTT_C_INCLUDE_DIRS NAMES MQTTAsync.h)

add_library(PahoMqttC::PahoMqttC UNKNOWN IMPORTED)

set_target_properties(PahoMqttC::PahoMqttC PROPERTIES
    IMPORTED_LOCATION "${PAHO_MQTT_C_LIBRARIES}"
    INTERFACE_INCLUDE_DIRECTORIES "${PAHO_MQTT_C_INCLUDE_DIRS}"
    IMPORTED_LINK_INTERFACE_LANGUAGES "C")
if(PAHO_WITH_SSL)
    set_target_properties(PahoMqttC::PahoMqttC PROPERTIES
            INTERFACE_COMPILE_DEFINITIONS "OPENSSL=1"
            INTERFACE_LINK_LIBRARIES "OpenSSL::SSL;OpenSSL::Crypto")
endif()

include(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(PahoMqttC
    REQUIRED_VARS PAHO_MQTT_C_LIBRARIES PAHO_MQTT_C_INCLUDE_DIRS)