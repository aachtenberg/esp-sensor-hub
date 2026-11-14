#!/bin/bash

# ESP32 Device Control via MQTT
#
# Sends a command to an esp-sensor-hub device and waits for the firmware's
# confirmation event. The script subscribes BEFORE publishing so a fast reply
# can't be missed, and resends on an interval to catch battery-powered devices
# during their short wake window.

# Default configuration
MQTT_BROKER="${MQTT_BROKER:-192.168.0.167}"
DEVICE_NAME="${DEVICE_NAME:-Spa}"
RETRY_INTERVAL=2
MAX_ATTEMPTS=15

usage() {
    cat << EOF
ESP32 Device Control via MQTT

Usage: $0 <command> [arguments] [options]

Commands:
  deepsleep <seconds>   Configure deep sleep interval (0-3600 seconds)
                        0 = disable deep sleep
                        Example: $0 deepsleep 30

  disable-sleep         Shortcut to disable deep sleep (retries until confirmed)

  enable-sleep <secs>   Shortcut to enable deep sleep (1-3600 seconds)
                        Example: $0 enable-sleep 30

  interval <seconds>    Configure sensor reading interval (5-3600 seconds)
                        Example: $0 interval 60

  status                Request a fresh status update (falls back to showing
                        the broker's cached status if the device doesn't answer)

  restart               Restart the device

  config                Start the WiFi configuration portal (temperature-sensor)

  monitor               Monitor all device topics (temperature, status, events)

Options:
  -b, --broker <ip>     MQTT broker IP (default: $MQTT_BROKER)
  -d, --device <name>   Device name (default: $DEVICE_NAME)
                        Spaces become dashes, as in the firmware topics
  -r, --retry <count>   Maximum send attempts (default: $MAX_ATTEMPTS)
                        Use 0 for infinite retries
  -i, --interval <sec>  Seconds between attempts (default: $RETRY_INTERVAL)
  -h, --help            Show this help message

Environment Variables:
  MQTT_BROKER           Default MQTT broker IP
  DEVICE_NAME           Default device name

Requires mosquitto_pub/mosquitto_sub (apt install mosquitto-clients).
jq is optional and used to pretty-print JSON.

Examples:
  # Enable deep sleep with 30 second interval
  $0 deepsleep 30

  # Set sensor reading interval to 60 seconds
  $0 interval 60

  # Disable deep sleep (continuous operation, retries until confirmed)
  $0 disable-sleep

  # Restart device with infinite retries
  $0 -d Spa -r 0 restart

  # Request status from a device whose name contains a space
  $0 status -d "Pump House"

  # Monitor all topics
  $0 monitor

EOF
    exit "${1:-0}"
}

die() {
    echo "Error: $*" >&2
    exit 1
}

# Fail cleanly if an option is the last argument and has no value
require_value() {  # $1 = option name, $2 = number of remaining arguments
    [ "$2" -ge 2 ] || die "$1 requires a value"
}

# Parse command line options
COMMAND=""
ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        -b|--broker)
            require_value "$1" $#
            MQTT_BROKER="$2"
            shift 2
            ;;
        -d|--device)
            require_value "$1" $#
            DEVICE_NAME="$2"
            shift 2
            ;;
        -r|--retry)
            require_value "$1" $#
            [[ "$2" =~ ^[0-9]+$ ]] || die "--retry must be a non-negative integer (0 for infinite)"
            MAX_ATTEMPTS="$2"
            shift 2
            ;;
        -i|--interval)
            require_value "$1" $#
            [[ "$2" =~ ^[1-9][0-9]*$ ]] || die "--interval must be a positive integer"
            RETRY_INTERVAL="$2"
            shift 2
            ;;
        deepsleep|disable-sleep|enable-sleep|interval|status|restart|monitor|config)
            [ -z "$COMMAND" ] || die "only one command allowed (got '$COMMAND' and '$1')"
            COMMAND="$1"
            shift
            # Collect the command's own (non-option) arguments; options may follow
            while [[ $# -gt 0 ]] && [[ ! "$1" =~ ^- ]]; do
                ARGS+=("$1")
                shift
            done
            ;;
        *)
            echo "Error: Unknown option: $1" >&2
            echo "Use -h or --help for usage information" >&2
            exit 1
            ;;
    esac
done

if [ -z "$COMMAND" ]; then
    echo "Error: No command specified" >&2
    usage 1
fi

for tool in mosquitto_pub mosquitto_sub; do
    command -v "$tool" >/dev/null 2>&1 \
        || die "$tool not found. Install it with: sudo apt install mosquitto-clients"
done

# MQTT Topics. The firmware replaces spaces with dashes (sanitizeDeviceName).
TOPIC_BASE="esp-sensor-hub/${DEVICE_NAME// /-}"
COMMAND_TOPIC="$TOPIC_BASE/command"
STATUS_TOPIC="$TOPIC_BASE/status"
EVENTS_TOPIC="$TOPIC_BASE/events"

INFINITE_MODE="false"
[ "$MAX_ATTEMPTS" -eq 0 ] && INFINITE_MODE="true"

# Background listener state, cleaned up on any exit (including Ctrl+C)
LISTEN_PID=""
LISTEN_FILE=""

cleanup() {
    [ -n "$LISTEN_PID" ] && kill "$LISTEN_PID" 2>/dev/null
    [ -n "$LISTEN_FILE" ] && rm -f "$LISTEN_FILE"
}
trap cleanup EXIT
trap 'exit 130' INT TERM

print_header() {
    echo ""
    echo "=========================================="
    echo "  ESP32 Device Control via MQTT"
    echo "=========================================="
    echo "Device: $DEVICE_NAME ($TOPIC_BASE)"
    echo "Broker: $MQTT_BROKER"
    echo "Command: $1"
    echo "=========================================="
    echo ""
}

# Pretty-print JSON when jq is available, otherwise print as-is
pretty() {
    if command -v jq >/dev/null 2>&1 && jq . <<< "$1" 2>/dev/null; then
        return
    fi
    printf '%s\n' "$1"
}

# Subscribe to the device's status and events topics in the background.
# -R drops the broker's cached (retained) status so only fresh messages count.
# A probe message on a private topic confirms the subscription is live before
# anything is published.
start_listener() {
    LISTEN_FILE=$(mktemp) || die "mktemp failed"
    local probe_topic="mqtt-device-control/probe/$$"

    mosquitto_sub -h "$MQTT_BROKER" -R -v \
        -t "$STATUS_TOPIC" -t "$EVENTS_TOPIC" -t "$probe_topic" > "$LISTEN_FILE" 2>&1 &
    LISTEN_PID=$!

    local i
    for ((i = 0; i < 25; i++)); do
        kill -0 "$LISTEN_PID" 2>/dev/null \
            || die "cannot subscribe on broker $MQTT_BROKER: $(cat "$LISTEN_FILE")"
        mosquitto_pub -h "$MQTT_BROKER" -t "$probe_topic" -m ready 2>/dev/null
        grep -qxF "$probe_topic ready" "$LISTEN_FILE" && return 0
        sleep 0.2
    done
    die "broker $MQTT_BROKER did not confirm the subscription within 5s"
}

# Print the first payload received on <topic> whose event name and message
# match. An empty event or message pattern matches anything.
find_reply() {  # $1 = topic, $2 = event name, $3 = message regex
    local event_str="\"event\":\"$2\"" msg_re="\"message\":\"$3" topic payload
    while read -r topic payload; do
        [ "$topic" = "$1" ] || continue
        [ -n "$2" ] && [[ "$payload" != *"$event_str"* ]] && continue
        [ -n "$3" ] && ! [[ "$payload" =~ $msg_re ]] && continue
        printf '%s\n' "$payload"
        return 0
    done < "$LISTEN_FILE"
    return 1
}

# Publish a command every RETRY_INTERVAL seconds until the device confirms it.
#   $1 command payload    $2 topic carrying the reply
#   $3 event name         $4 message regex (both may be empty)
#   $5 success text       $6 "true" = retry forever
# Returns 0 on success, 1 on timeout, 2 if the device rejected the command.
send_command() {
    local cmd="$1" reply_topic="$2" event="$3" msg_re="$4" success="$5" infinite="${6:-false}"
    local attempt=0 tick reply label

    print_header "$cmd"
    if [ "$infinite" = "true" ]; then
        echo "Sending every ${RETRY_INTERVAL}s until confirmed - Press Ctrl+C to stop"
    else
        echo "Sending every ${RETRY_INTERVAL}s, up to $MAX_ATTEMPTS attempts - Press Ctrl+C to stop"
    fi
    echo ""

    start_listener

    while [ "$infinite" = "true" ] || [ "$attempt" -lt "$MAX_ATTEMPTS" ]; do
        attempt=$((attempt + 1))
        label="$attempt"
        [ "$infinite" = "true" ] || label="$attempt/$MAX_ATTEMPTS"
        echo "[$(date '+%H:%M:%S')] [Attempt $label] Sending: $cmd"

        mosquitto_pub -h "$MQTT_BROKER" -t "$COMMAND_TOPIC" -m "$cmd" \
            || echo "[$(date '+%H:%M:%S')] Publish failed - is the broker reachable?"

        # Check for a reply every 0.2s until the next attempt is due
        for ((tick = 0; tick < RETRY_INTERVAL * 5; tick++)); do
            if reply=$(find_reply "$reply_topic" "$event" "$msg_re"); then
                echo "[$(date '+%H:%M:%S')] RECEIVED on $reply_topic:"
                pretty "$reply"
                echo ""
                echo "✓ SUCCESS! $success"
                echo ""
                return 0
            fi
            if reply=$(find_reply "$EVENTS_TOPIC" "command_error" ""); then
                echo "[$(date '+%H:%M:%S')] RECEIVED on $EVENTS_TOPIC:"
                pretty "$reply"
                echo ""
                echo "✗ Device rejected the command"
                return 2
            fi
            sleep 0.2
        done
    done

    echo ""
    echo "✗ No confirmation after $MAX_ATTEMPTS attempts"
    echo "Device may be in deep sleep. Try again or increase retry attempts (-r 0 = infinite)."
    return 1
}

# Show the broker's cached (retained) status, clearly labelled as such
show_cached_status() {
    local cached
    cached=$(mosquitto_sub -h "$MQTT_BROKER" -t "$STATUS_TOPIC" -C 1 -W 3 2>/dev/null)
    [ -n "$cached" ] || return
    echo ""
    echo "Last cached status on the broker (may be stale):"
    pretty "$cached"
}

# Validate the command's seconds argument and store it in SECS
require_seconds() {  # $1 = min, $2 = max
    local value="${ARGS[0]}"
    [ -n "$value" ] || die "$COMMAND requires a seconds argument ($1-$2). Example: $0 $COMMAND 30"
    [[ "$value" =~ ^[0-9]{1,5}$ ]] && (( 10#$value >= $1 && 10#$value <= $2 )) \
        || die "$COMMAND: seconds must be between $1 and $2"
    SECS=$((10#$value))
}

# temperature-sensor confirms 0 as "Deep sleep set to 0 seconds",
# bme280-sensor as "Deep sleep disabled"
deep_sleep_command() {  # $1 = seconds, $2 = infinite
    if [ "$1" -eq 0 ]; then
        send_command "deepsleep 0" "$EVENTS_TOPIC" "deep_sleep_config" \
            "Deep sleep (set to 0 seconds|disabled)" "Deep sleep disabled" "$2"
    else
        send_command "deepsleep $1" "$EVENTS_TOPIC" "deep_sleep_config" \
            "Deep sleep set to $1 seconds" "Deep sleep enabled ($1 seconds)" "$2"
    fi
}

monitor_topics() {
    print_header "Monitor All Topics"
    echo "Subscribing to $TOPIC_BASE/# - Press Ctrl+C to stop"
    echo ""

    mosquitto_sub -h "$MQTT_BROKER" -t "$TOPIC_BASE/#" -v | while IFS= read -r line; do
        echo "[$(date '+%H:%M:%S')] ${line%% *}"
        pretty "${line#* }"
        echo ""
    done
}

# Execute command
case "$COMMAND" in
    deepsleep)
        require_seconds 0 3600
        deep_sleep_command "$SECS" "$INFINITE_MODE"
        ;;

    enable-sleep)
        require_seconds 1 3600
        deep_sleep_command "$SECS" "$INFINITE_MODE"
        ;;

    disable-sleep)
        deep_sleep_command 0 "true"
        ;;

    interval)
        require_seconds 5 3600
        send_command "interval $SECS" "$EVENTS_TOPIC" "sensor_interval_config" \
            "Sensor reading interval set to $SECS seconds" \
            "Sensor interval set to $SECS seconds" "$INFINITE_MODE"
        ;;

    status)
        send_command "status" "$STATUS_TOPIC" "" "" "Fresh status received" "$INFINITE_MODE" \
            || { rc=$?; show_cached_status; exit "$rc"; }
        ;;

    restart)
        send_command "restart" "$EVENTS_TOPIC" "device_restart" "" \
            "Device restarting" "$INFINITE_MODE"
        ;;

    config)
        send_command "config" "$EVENTS_TOPIC" "config_portal" "Starting" \
            "WiFi config portal started - join the device's setup AP" "$INFINITE_MODE"
        ;;

    monitor)
        monitor_topics
        ;;
esac
