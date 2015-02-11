/**
 * Given playername and message array, converts the message array to JSON and 
 * sends it to playername with the /tellraw command.
 */

proc _tellraw(@player, @message) {
	if(!ponline(@player)) {
		return();
	}
	@json = _json(@message);
	sudo("/tellraw @player @json");
}

proc _tellraw_broadcast(@message) {
	@json = _json(@message);
	foreach(@player in all_players()) {
		sudo("/tellraw @player @json");
	}
}

proc _tellraw_permission(@permission, @message) {
	@json = _json(@message);
	foreach(@player in all_players()) {
		if(has_permission(@player, @permission)) {
			sudo("/tellraw @player @json");
		}
	}
}

proc _json(@message) {
	if(!is_array(@message)) {
		@message = associative_array(
			text: @message
		);
	}
	@json = associative_array(
		text: "",
		extra: array(),
	);
	foreach(@element in @message) {
		@json["extra"][] = _construct_json(@element);
	}
	@json = colorize(json_encode(@json));
	return(@json);
}

proc _construct_json(@message) {
	@json = associative_array(
		text: "",
	);
	foreach(@tag: @value in @message) {
		@tag = to_lower(@tag);
		switch(@tag) {
			case "text":
				@json["text"] = @value;
				break();
			case "extra":
				@json["extra"] = @value;
				break();
			case "open_url":
			case "run_command":
			case "change_page":
			case "suggest_command":
				@json["clickEvent"] = associative_array(
					action: @tag,
					value: @value,
				);
				break();
			case "show_text":
			case "show_item":
			case "show_achievement":
			case "show_entity":
				@json["hoverEvent"] = associative_array(
					action: @tag,
				);
				if(typeof(@value) == "string") {
					@json["hoverEvent"]["value"] = @value;
				} else {
					@json["hoverEvent"]["value"] = replace(json_encode(@value), "\"", "\u0022");
				}
				break();
			default:
				console("[JSON] Unknown \"@tag\" tag.");
		}
	}
	return(@json);
}
