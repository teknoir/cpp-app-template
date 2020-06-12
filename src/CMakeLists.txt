CMAKE_MINIMUM_REQUIRED(VERSION 2.8)

file(GLOB SOURCE_FILES "*.cpp")
add_executable( tester ${SOURCE_FILES} )

target_link_libraries(tester paho-mqttpp3)
target_link_libraries(tester paho-mqtt3a)

set(INSTALL_TARGETS
	tester
)

## install binaries
install(TARGETS tester RUNTIME DESTINATION bin)