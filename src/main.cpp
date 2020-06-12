#include <iostream>
#include <cstdlib>
#include <string>
#include <cstring>
#include <cctype>
#include <thread>
#include <chrono>
#include "mqtt/async_client.h"
#include "mqtt/topic.h"
#include "base64.h"
#include "json.hpp"

// for convenience
using json = nlohmann::json;

/////////////////////////////////////////////////////////////////////////////

std::string getOrDefault(std::string name, std::string value)
{
    if(const char* env_p = std::getenv(name.c_str()))
        return env_p;
    else
        return value;
}

const int MAX_BUFFERED_MSGS = 1024;	// Amount of off-line buffering
const std::string PERSIST_DIR { "data-persist" };

void handleImageMsg(mqtt::const_message_ptr msg, mqtt::topic* topic_out)
{
    std::cout << msg->get_topic() << " : " << msg->get_payload_str() << std::endl;

    auto j = json::parse(msg->get_payload_str());
    std::string decoded = base64_decode(j["image_data"].get<std::string>());
    std::string encoded = base64_encode(reinterpret_cast<const unsigned char*>(decoded.c_str()), decoded.length());
    j["image_data"] = encoded;

    topic_out->publish(j.dump());
}

int main(int argc, char* argv[])
{
	// The broker/server address
	const std::string SERVER_ADDRESS("tcp://"+getOrDefault("HMQ_SERVICE_HOST", "hmq.kube-system")+":"+getOrDefault("HMQ_SERVICE_PORT", "1883"));
	// The topic name for output 0
	const std::string MQTT_OUT_0(getOrDefault("MQTT_OUT_0", "classification/result"));
	// The topic name for input 0
	const std::string MQTT_IN_0(getOrDefault("MQTT_IN_0", "camera/images"));
	// The QoS to use for publishing and subscribing
	const int QOS = 1;
	// Tell the broker we don't want our own messages sent back to us.
	const bool NO_LOCAL = true;

	mqtt::connect_options connOpts;
	connOpts.set_keep_alive_interval(20);
	connOpts.set_clean_start(true);
	connOpts.set_automatic_reconnect(true);
	connOpts.set_mqtt_version(MQTTVERSION_3_1_1);

	mqtt::async_client cli(SERVER_ADDRESS, ""); //, MAX_BUFFERED_MSGS, PERSIST_DIR);

    // Set topics: in and out
	mqtt::topic topic_in { cli, MQTT_IN_0, QOS };
	mqtt::topic topic_out { cli, MQTT_OUT_0, QOS };

	// Set the callback for incoming messages
	cli.set_message_callback([topic_in, topic_out](mqtt::const_message_ptr msg) mutable {
	    if (msg->get_topic() == topic_in.get_name())
	        handleImageMsg(msg, &topic_out);
	});

	// Start the connection.
	try {
		std::cout << "Connecting to the MQTT broker at '" << SERVER_ADDRESS
			<< "'..." << std::flush;
		auto tok = cli.connect(connOpts);
		tok->wait();

		// Subscribe to the topic using "no local" so that
		// we don't get own messages sent back to us

		std::cout << "Ok\nJoining the topics..." << std::flush;
		auto subOpts = mqtt::subscribe_options(NO_LOCAL);
		topic_in.subscribe(subOpts)->wait();
		topic_out.subscribe(subOpts)->wait();
		std::cout << "Ok" << std::endl;
	}
	catch (const mqtt::exception& exc) {
		std::cerr << "\nERROR: Unable to connect. "
			<< exc.what() << std::endl;
		return 1;
	}

    std::string usrMsg;
	while (std::getline(std::cin, usrMsg) && !usrMsg.empty()) {
		usrMsg = "test: " + usrMsg;
		topic_in.publish(usrMsg);
	}

	// Just block till user tells us to quit.
    while (std::tolower(std::cin.get()) != 'q')
        ;

	// Disconnect

	try {
		std::cout << "Disconnecting from the MQTT broker..." << std::flush;
		cli.disconnect()->wait();
		std::cout << "OK" << std::endl;
	}
	catch (const mqtt::exception& exc) {
		std::cerr << exc.what() << std::endl;
		return 1;
	}

 	return 0;
}