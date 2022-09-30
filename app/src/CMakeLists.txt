CMAKE_MINIMUM_REQUIRED(VERSION 2.8)

file(GLOB SOURCE_FILES "*.cpp")
add_executable( teknoir-app ${SOURCE_FILES} )

target_link_libraries(teknoir-app paho-mqttpp3)
target_link_libraries(teknoir-app paho-mqtt3as)
target_link_libraries(teknoir-app pthread ssl crypto)

set(INSTALL_TARGETS
	teknoir-app
)

## install binaries
install(TARGETS teknoir-app RUNTIME DESTINATION bin)