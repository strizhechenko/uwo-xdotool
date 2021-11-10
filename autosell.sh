#!/bin/bash

set -euE

declare AMOUNT="${AMOUNT:-2990}"
declare TARGET="${TARGET:-640000}"
declare PORTION="${PORTION:-}"
declare COST="${COST:-388}"

if [ -z "$PORTION" -a -n "${PRICE:-}" -a -n "${COST:-}" ]; then
	PORTION="$((TARGET / (PRICE-COST) + 1))"
fi

declare WINDOW_ID
declare MARKET_KEEPER="400 300"
declare SELL_BUTTON_OFFSET="77 52"
declare GOOD_BUTTON="100 130"
declare OK_BUTTON="660 420"

find_window() {
	local rdp_title="FreeRDP:"
	local rdp_window_id="$(xdotool search --name "$rdp_title")"
	WINDOW_ID=$rdp_window_id
	return 0
}

click() {
	[ "$(xdotool getactivewindow)" != "$WINDOW_ID" ] && echo 'FAIL' && exit 1
	xdotool click --window=$WINDOW_ID "${@:-1}"
	return 0
}

move() {
	xdotool mousemove --window="$WINDOW_ID" "$@"
	return 0
}

click_at() {
	move "$1" "$2"
	sleep 0.1
	shift 2
	click "${@:-1}"
	return 0
}

write() {
        xdotool type --window="$WINDOW_ID" "$1"
        sleep 0.1
        xdotool key --window="$WINDOW_ID" "KP_Enter"
        sleep 0.5
        return 0
}

# TODO: sleep scaling, usleep / $(())
_main() {
	click_at $MARKET_KEEPER --repeat 2 --delay 500 1
	sleep 0.5
	xdotool mousemove_relative $SELL_BUTTON_OFFSET
	sleep 0.1
	click
	sleep 1
	click_at $GOOD_BUTTON
	write "$PORTION"
	click_at $OK_BUTTON
	sleep 0.5
	return 0
}

main() {
	local attempts
	find_window
	xdotool windowactivate "$WINDOW_ID"
	sleep 0.1
	xdotool key Escape
	sleep 0.1
	xdotool key Escape
	while [[ "$((AMOUNT/PORTION))" -gt 0 ]]; do
		attempts="$((AMOUNT/PORTION))"
		echo "$(date +%H:%M:%S) GOODS LEFT: $AMOUNT ATTEMPTS: $attempts MINUTES: $((attempts * 4 / 60))"
		if [ -n "${PRICE:-}" -a -n "${COST:-}" ]; then
			echo TARGET=$TARGET AMOUNT=$AMOUNT PRICE=$PRICE COST=$COST ./autosell.sh
		fi
		_main "$@"
		AMOUNT=$((AMOUNT-PORTION))
	done
	return 0
}

main "$@"
echo "$0 DONE"
exit 0
