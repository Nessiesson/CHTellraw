/**
 * Given playername and message array, converts the message array to JSON and 
 * sends it to playername with the /tellraw command.
 */

proc _tellraw(@player, @message) {
	if(!ponline(@player)) {
		return();
	}
	@json = associative_array(
		text: '',
		extra: array(),
	);
	if(!is_array(@message)) {
		@message = array(array(@message));
	}
	foreach(@element in @message) {
		@json['extra'][] = _construct_json(@element);
	}
	@json = json_encode(@json);
	scriptas(@player, '*', sudo("/tellraw @player @json"));
}

proc _construct_json(@message) {
	if(array_index_exists(@message, 1)) {
		@json = _construct_json_meta(@message);
		if(array_size(@json) == 0) {
			@json = associative_array();
		}
	} else {
		@json = associative_array();
	}
	@json['text'] = '';
	@json['extra'] = _construct_json_color(@message[0]);
	return(@json);
}

proc _construct_json_meta(@message) {
	@message[1] = to_lower(@message[1]);
	switch(@message[1]) {
		# The URL in open_url _must_ be prefixed by: http:// , else the MC client will crash.
		case 'open_url':
			@meta = _construct_json_click(@message);

			@url = @meta['clickEvent']['value'];
			if(reg_count('https*:\\/\\/', @url) == 0) {
				@url = 'http://' . @url;
			}
			@meta['clickEvent']['value'] = trim(@url);
			@meta['hoverEvent']['value']['extra'] = _construct_json_color('&6Click to open: &r' . @message[0]);

		case 'run_command':
			@meta = _construct_json_click(@message);
			@meta['hoverEvent']['value']['extra'] = _construct_json_color('&eClick to run: &r' . @meta['hoverEvent']['value']['extra'][0]['text']);
			
		case 'suggest_command':
	 		@meta = _construct_json_click(@message);
	
		case 'show_text':
			@meta = _construct_json_hover(@message);
	
		default:
			@meta = associative_array();
	}
	return(@meta);
}

proc _construct_json_click(@message) {
	if(array_index_exists(@message, 2)) {
		@value = @message[2];
	} else {
		@value = @message[0];
	}
	@meta = associative_array(
		clickEvent: associative_array(
			action: @message[1],
			value: _strip_colors(@value),
		),
	);
	@meta = array_merge(@meta, _construct_json_hover(@message));
	return(@meta);
}

proc _construct_json_hover(@message) {
	if(array_index_exists(@message, 2)) {
		@value = @message[2];
	} else {
		@value = @message[0];
	}
	@meta = associative_array(
		hoverEvent: associative_array(
			action: 'show_text',
			value: associative_array(
				text: '',
				extra: _construct_json_color(@value),
			),
		),
	);
	return(@meta);
}

proc _construct_json_color(@string) {
	@colors = associative_array(
		0: 'black',
		1: 'dark_blue',
		2: 'dark_green',
		3: 'dark_aqua',
		4: 'dark_red',
		5: 'dark_purple',
		6: 'gold',
		7: 'dark_gray',
		9: 'blue',
		a: 'green',
		b: 'aqua',
		c: 'red',
		d: 'light_purple',
		e: 'yellow',
		f: 'white',
	);
	@formats = associative_array(
		k: 'obfuscated',
		l: 'bold',
		m: 'strikethrough',
		n: 'underline',
		o: 'italic',
	);
	@json = array();
	@matches = reg_match_all('(?s).+?(?=\u00A7[a-f0-9klmnor]|$)', colorize(@string));
	foreach(@match in @matches) {
		if(substr(@match[0], 0, 1) == '\u00A7') {
			@colorCode = substr(@match[0], 1, 2);
			@formatArray = associative_array(
				text: substr(@match[0], 2),
			);
			if(@colorCode == 'r') {
				@json[] = @formatArray;
				continue()
			}
		} else {
			@formatArray = associative_array(
				text: @match[0],
			);
			@json[] = @formatArray;
			continue();
		}
		if(array_index_exists(@colors, @colorCode)) {
			@formatArray['color'] = @colors[@colorCode];
		}
		if(array_index_exists(@formats, @colorCode)) {
			if(array_size(@json) > 0) {
				@lastArray = @json[-1];
				if(array_index_exists(@lastArray, 'color')) {
					@formatArray['color'] = @lastArray['color'];
				}
				foreach(@format in @formats) {
					if(array_index_exists(@lastArray, @format)) {
						@formatArray[@format] = true;
					}
				}
			}
			@formatArray[@formats[@colorCode]] = true;
		}
		@json[] = @formatArray;
	} else {
		@formatArray = associative_array(
			text: @string,
		);
		@json[] = @formatArray;
	}
	foreach(@key: @entry in @json) {
		if(@entry['text'] == '') {
			array_remove(@json, @key);
		}
	}
	return(@json);
}

proc _last_color(@string) {
	@string = colorize(@string);
	@color = '';
	for(@i = length(@string) - 1, @i >= 0, @i--) {
		if(@string[@i] == '\u00A7') {
			@prevIndex = @i + 1;
			if(reg_match('[0-9a-fklmnor]', @string[@prevIndex])) {
				@color = '&' . @string[@prevIndex] . @color;
			}
			if(reg_match('[0-9a-fr]', @string[@prevIndex])) {
				break();
			}
		}
	}
	return(@color);
}

proc _strip_colors(@string) {
	@string = reg_replace('(?i)\u00A7[0-9A-Fklmnor]', '', @string);
	@string = reg_replace('(?i)&[0-9A-Fklmnor]', '', @string);
	return(@string);
}