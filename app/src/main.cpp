#include <iostream>
#include <iomanip>
#include <cstdlib>
#include <string>
#include <cstring>
#include <cctype>
#include <thread>
#include <chrono>
#include <csignal>
#include <functional>
#include <regex>
#include <fstream>
#include <chrono>
#include <unistd.h>
#include "mqtt/async_client.h"
#include "mqtt/topic.h"
#include "base64.h"
#include "json.hpp"
using json = nlohmann::json;

std::string getOrDefault(std::string name, std::string value) {
    if (const char *env_p = std::getenv(name.c_str()))
        return env_p;
    else
        return value;
}

// The client name on the broker
const std::string CLIENT_ID(getOrDefault("CLIENT_ID", "teknoir-app-cpp"));
// The broker/server address
const std::string SERVER_ADDRESS("tcp://" + getOrDefault("MQTT_SERVICE_HOST", "mqtt.kube-system") + ":" +
                                 getOrDefault("MQTT_SERVICE_PORT", "1883"));
// The topic name for input 0
const std::string MQTT_IN_0(getOrDefault("MQTT_IN_0", CLIENT_ID + "/images"));
// The topic name for output 0
const std::string MQTT_OUT_0(getOrDefault("MQTT_OUT_0", CLIENT_ID + "/events"));
// The QoS to use for publishing and subscribing
const int QOS(std::stoi(getOrDefault("QOS", "1")));


/////////////////////////////////////////////////////////////////////////////
// for convenience
using json = nlohmann::json;

const int MAX_BUFFERED_MSGS = 1024;    // Amount of off-line buffering
const std::string PERSIST_DIR{"data-persist"};
const auto SAMPLE_PERIOD = std::chrono::seconds(5);


std::function<void(int)> shutdown_handler;

void signalHandler(int signum) {
    std::cout << "Interrupt signal (" << signum << ") received.\n" << std::flush;
    shutdown_handler(signum);
}

class action_listener : public virtual mqtt::iaction_listener {
    std::string name_;

    void on_failure(const mqtt::token &tok) override {
        std::cout << name_ << " failure";
        if (tok.get_message_id() != 0)
            std::cout << " for token: [" << tok.get_message_id() << "]" << std::endl;
        std::cout << std::endl;
    }

    void on_success(const mqtt::token &tok) override {
        std::cout << name_ << " success";
        if (tok.get_message_id() != 0)
            std::cout << " for token: [" << tok.get_message_id() << "]" << std::endl;
        auto top = tok.get_topics();
        if (top && !top->empty())
            std::cout << "\ttoken topic: '" << (*top)[0] << "', ..." << std::endl;
        std::cout << std::endl;
    }

public:
    action_listener(const std::string &name) : name_(name) {}
};

class callback : public virtual mqtt::callback, public virtual mqtt::iaction_listener {
    // Counter for the number of connection retries
    int nretry_;
    // The MQTT client
    mqtt::async_client &cli_;
    // Options to use if we need to reconnect
    mqtt::connect_options &connOpts_;
    // An action listener to display the result of actions.
    action_listener subListener_;

    void reconnect() {
        std::this_thread::sleep_for(std::chrono::milliseconds(2500));
        try {
            cli_.connect(connOpts_, nullptr, *this);
        } catch (const mqtt::exception &exc) {
            std::cerr << "Error: " << exc.what() << std::endl;
            exit(1);
        }
    }

    // Re-connection failure
    void on_failure(const mqtt::token &tok) override {
        std::cout << "Connection attempt failed" << std::endl;
        if (++nretry_ > 10)
            exit(1);
        reconnect();
    }

    // (Re)connection success
    // Either this or connected() can be used for callbacks.
    void on_success(const mqtt::token &tok) override {}

    // (Re)connection success
    void connected(const std::string &cause) override {
        std::cout << "\nConnection success" << std::endl;
        std::cout << "\nSubscribing to topic '" << MQTT_IN_0 << "'\n"
                  << "\tfor client " << CLIENT_ID
                  << " using QoS" << QOS << "\n" << std::endl;

        cli_.subscribe(MQTT_IN_0, QOS, nullptr, subListener_);
    }

    // Callback for when the connection is lost.
    // This will initiate the attempt to manually reconnect.
    void connection_lost(const std::string &cause) override {
        std::cout << "\nConnection lost" << std::endl;
        if (!cause.empty())
            std::cout << "\tcause: " << cause << std::endl;

        std::cout << "Reconnecting..." << std::endl;
        nretry_ = 0;
        reconnect();
    }

    // Callback for when a message arrives.
    void message_arrived(mqtt::const_message_ptr msg) override {
        std::cout << "Message arrived" << std::endl;
        std::cout << "\ttopic: '" << msg->get_topic() << "'" << std::endl;
    }

    void delivery_complete(mqtt::delivery_token_ptr token) override {}

public:
    callback(mqtt::async_client &cli, mqtt::connect_options &connOpts) //, std::vector<std::string>& objNames)
            : nretry_(0), cli_(cli), connOpts_(connOpts), subListener_("Subscription") {}
};

int main(int argc, char *argv[]) {
    mqtt::connect_options connOpts;
    connOpts.set_keep_alive_interval(20);
    connOpts.set_clean_start(true);
    //connOpts.set_automatic_reconnect(true);
    connOpts.set_mqtt_version(MQTTVERSION_3_1_1); // TODO: MQTTv5

    mqtt::async_client cli(SERVER_ADDRESS, CLIENT_ID); //, MAX_BUFFERED_MSGS, PERSIST_DIR);

    // register signal SIGINT and signal handler and graceful disconnect
    signal(SIGINT, signalHandler);
    shutdown_handler = [&](int signum) {
        // Disconnect
        try {
            std::cout << "Disconnecting from the MQTT broker..." << std::flush;
            cli.stop_consuming();
            cli.disconnect()->wait();
            std::cout << "OK" << std::endl;
        }
        catch (const mqtt::exception &exc) {
            std::cerr << exc.what() << std::endl;
            return 1;
        }

        exit(signum);
    };

    callback cb(cli, connOpts);
    cli.set_callback(cb);

    // Start the connection.
    try {
        std::cout << "Connecting to the MQTT broker at '" << SERVER_ADDRESS << "'..." << std::flush;
        cli.connect(connOpts, nullptr, cb);
    }
    catch (const mqtt::exception &exc) {
        std::cerr << "\nERROR: Unable to connect. "
                  << exc.what() << std::endl;
        return 1;
    }

    while (true) {
        std::cout << "Going to sleep." << std::endl;
        std::this_thread::sleep_for(SAMPLE_PERIOD);
    }

    return 0;
}
