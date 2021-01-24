// (C) 2020-2021 StunxFS. All rights reserved. Use of this source code
// is governed by an MIT license that can be found in the LICENSE file.
module binary

import os
import x.json2 as json
import strings
import regex

// FontsWidthsConfig holds the pixel widths of characters in various game fonts.
pub struct FontsWidthsConfig {
pub:
	fonts           map[string]map[string]int
	default_font_id string
}

pub fn load_fontwidths(filepath string) ?FontsWidthsConfig {
	bytes := os.read_file(filepath) ?
	r := json.raw_decode(bytes) ?
	raw := r.as_map()
	mut fonts_ := map[string]map[string]int{}
	for k, v in raw['fonts'].as_map() {
		mut ms := map[string]int{}
		for k1, v1 in v.as_map() {
			ms[k1] = v1.int()
		}
		fonts_[k] = ms
	}
	return FontsWidthsConfig{
		fonts: fonts_
		default_font_id: raw['defaultFontId'].str()
	}
}

pub const (
	test_fontid = 'TEST'
)

pub fn (fw &FontsWidthsConfig) format_text(_text string, max_width int, font_id string) ?string {
	if !fw.is_font_id_valid(font_id) && font_id.len > 0 && font_id != binary.test_fontid {
		mut valid_fontids := []string{len: fw.fonts.len}
		mut i := 0
		for k, _ in fw.fonts {
			valid_fontids[i] = k
			i++
		}
		return error('unknown fontID "$font_id" used in format(). list of valid fontIDs are "$valid_fontids"')
	}
	text := _text.replace('\n', ' ')
	mut formatted_sb := strings.new_builder(100)
	mut curline_sb := strings.new_builder(100)
	mut cur_width := 0
	mut is_first_line := true
	mut is_first_word := true
	mut pos := 0
	for pos < text.len {
		end_pos, word := fw.get_next_word(text[pos..])
		if word.len == 0 {
			break
		}
		pos += end_pos
		if fw.is_line_break(word) {
			cur_width = 0
			formatted_sb.write(curline_sb.str())
			formatted_sb.write(word)
			formatted_sb.write('\\n')
			if fw.is_paragraph_break(word) {
				is_first_line = true
			} else {
				is_first_line = false
			}
			is_first_word = true
			curline_sb = strings.new_builder(100)
		} else {
			mut word_width := 0
			if !is_first_word {
				word_width += fw.get_rune_pixel_width(` `, font_id)
			}
			word_width += fw.get_word_pixel_width(word, font_id)
			if cur_width + word_width > max_width && curline_sb.len > 0 {
				formatted_sb.write(curline_sb.str())
				if is_first_line {
					formatted_sb.write('\\n')
					is_first_line = false
				} else {
					formatted_sb.write('\\l')
				}
				formatted_sb.write('\\n')
				is_first_word = false
				curline_sb = strings.new_builder(100)
				curline_sb.write(word)
				cur_width = word_width
			} else {
				cur_width += word_width
				if !is_first_word {
					curline_sb.write(' ')
				}
				curline_sb.write(word)
				is_first_word = false
			}
		}
	}
	if curline_sb.len > 0 {
		formatted_sb.write(curline_sb.str())
	}
	return formatted_sb.str()
}

fn (fw &FontsWidthsConfig) get_next_word(text string) (int, string) {
	mut escape := false
	mut end_pos := 0
	mut start_pos := 0
	mut found_non_space := false
	mut found_regular_rune := false
	mut end_on_next := false
	mut control_code_level := 0
	for pos, char in text {
		if end_on_next {
			return pos, text[start_pos..pos]
		}
		if escape && (char == `l` || char == `n` || char == `p`) {
			if found_regular_rune {
				return end_pos, text[start_pos..end_pos]
			}
			end_on_next = true
		} else if char == `\\` && control_code_level == 0 {
			escape = true
			if !found_regular_rune {
				start_pos = pos
			}
			found_non_space = true
			end_pos = pos
		} else {
			if char == ` ` {
				if found_non_space && control_code_level == 0 {
					return pos, text[start_pos..pos]
				}
			} else {
				if !found_non_space {
					start_pos = pos
				}
				found_regular_rune = true
				found_non_space = true
				if char == `[` {
					control_code_level++
				} else if char == `]` {
					if control_code_level > 0 {
						control_code_level--
					}
				}
			}
			escape = false
		}
	}
	if !found_non_space {
		return text.len, ''
	}
	return text.len, text[start_pos..]
}

fn (fw &FontsWidthsConfig) is_line_break(word string) bool {
	return word == '\\n' || word == '\\l' || word == '\\p'
}

fn (fw &FontsWidthsConfig) is_paragraph_break(word string) bool {
	return word == '\\p'
}

fn (fw &FontsWidthsConfig) get_word_pixel_width(_word string, font_id string) int {
	word, mut word_width := fw.process_control_codes(_word, font_id)
	for _, r in word {
		word_width += fw.get_rune_pixel_width(r, font_id)
	}
	return word_width
}

fn (fw &FontsWidthsConfig) process_control_codes(word string, font_id string) (string, int) {
	mut width := 0
	mut re := regex.regex_opt('{[^}]*}') or { panic(err) }
	positions := re.find_all_str(word)
	for _, pos in positions {
		code := word[pos[0]..pos[1]]
		width += fw.get_control_code_pixel_width(code, font_id)
	}
	stripped_word := re.replace(word, '')
	return stripped_word, width
}

fn (fw &FontsWidthsConfig) get_rune_pixel_width(r rune, font_id string) int {
	if font_id == binary.test_fontid {
		return 10
	}
	return fw.read_width_from_font_config(r.str(), font_id)
}

fn (fw &FontsWidthsConfig) get_control_code_pixel_width(code string, font_id string) int {
	if font_id == binary.test_fontid {
		return 100
	}
	return fw.read_width_from_font_config(code, font_id)
}

fn (fw &FontsWidthsConfig) is_font_id_valid(font_id string) bool {
	return font_id in fw.fonts
}

const (
	fallback_width = 0
)

fn (fw &FontsWidthsConfig) read_width_from_font_config(value string, font_id string) int {
	if font_id !in fw.fonts {
		return binary.fallback_width
	}
	font := fw.fonts[font_id]
	if value !in font {
		if 'default' !in font {
			return binary.fallback_width
		}
		default_width := font['default']
		return default_width
	}
	return font[value]
}
