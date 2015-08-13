#NoEnv
#NoTrayIcon
SetBatchLines -1

#Include <logging>
#Include <ansi>
#Include <optparser>
#Include <system>
#Include <string>
#Include <datatable>
#Include <arrays>
#Include <queue>
#Include *i %A_ScriptDir%\.versioninfo

get_version() {
	global G_VERSION_INFO

	_log := new Logger("app.mack." A_ThisFunc)
	return _log.Exit(G_VERSION_INFO.NAME "/" G_VERSION_INFO.ARCH "-b" G_VERSION_INFO.BUILD " Copyright (C) 2014 K.-P. Schreiner`n")
}

determine_files(args) {
	_log := new Logger("app.mack." A_ThisFunc)
	
	if (_log.Logs(Logger.INPUT)) {
		_log.Input("args", args)
		if (_log.Logs(Logger.ALL))
			_log.All("args:`n" LoggingHelper.Dump(args))
	}

	if (args.MaxIndex() = "")
		args := ["."]

	file_list := []
	for _i, file_pattern in args {
		refine_file_pattern(file_pattern)
		collect_filenames(file_list, file_pattern)
	}

	if (G_opts["sort_files"] && file_list.MaxIndex() <> "") {
		file_list_string := ""
		loop % file_list.MaxIndex()
			file_list_string .= file_list[A_Index] "`n"
		Sort file_list_string, C
		file_list := StrSplit(file_list_string, "`n")
	}

	if (_log.Logs(Logger.ALL))
		_log.All("file_list:`n" LoggingHelper.Dump(file_list))
	
	return _log.Exit(file_list)
}

collect_filenames(fn_list, dirname) {
	_log := new Logger("app.mack." A_ThisFunc)

	if (_log.Logs(Logger.INPUT)) {
		_log.Input("fn_list", fn_list)
		_log.Input("dirname", dirname)
		if (_log.Logs(Logger.ALL))
			_log.All("fn_list:`n" LoggingHelper.Dump(fn_list))
	}

	refine_file_pattern(dirname)
	loop %dirname%, 1, 0
	{
		if (_log.Logs(Logger.FINEST)) {
			_log.Finest("A_LoopFileAttrib", A_LoopFileAttrib)
			_log.Finest("A_LoopFileFullPath", A_LoopFileFullPath)
			_log.Finest("A_LoopFileName", A_LoopFileName)
		}
		if (G_opts["r"] && InStr(A_LoopFileAttrib, "D")
				&& !RegExMatch(A_LoopFileName, G_opts["match_ignore_dirs"]))
			fn_list := collect_filenames(fn_list, A_LoopFileFullPath)
		else if (!InStr(A_LoopFileAttrib, "D")
				&& (!G_opts["g"] || (G_opts["g"] && RegExMatch(A_LoopFileName, "S)^" G_opts["file_pattern"] "$")))
				&& (G_opts["match_type"] = "" || RegExMatch(A_LoopFileName, G_opts["match_type"]))
				&& !RegExMatch(A_LoopFileName, G_opts["match_ignore_files"])) {
			fn_list.Insert(A_LoopFileFullPath)
		}
	}

	return _log.Exit(fn_list)
}

refine_file_pattern(ByRef file_pattern) {
	_log := new Logger("app.mack." A_ThisFunc)
	
	if (_log.Logs(Logger.INPUT)) {
		_log.Input("file_pattern", file_pattern)
	}
	
	file_attrs := FileExist(file_pattern)
	if (InStr(file_attrs, "D")) {
		SplitPath file_pattern, name
		if (name = "" || !RegExMatch(name, "\*\.?\*?$"))
			file_pattern .= (SubStr(file_pattern, 0) = "\" ? "" : "\") "*.*"
	}
	if (_log.Logs(Logger.OUTPUT)) {
		_log.Output("file_pattern", file_pattern)
	}

	return _log.Exit()
}

search_for_pattern(file_name, regex_opts = "") {
	_log := new Logger("app.mack." A_ThisFunc)

	if (_log.Logs(Logger.INPUT)) {
		_log.Input("file_name", file_name)
		_log.Input("regex_opts", regex_opts)
		if (_log.Logs(Logger.FINEST)) {
			_log.Finest("G_opts[pattern]", G_opts["pattern"])
			_log.Finest("G_opts[g]", G_opts["g"])
			_log.Finest("G_opts[group]", G_opts["group"])
			_log.Finest("G_opts[passthru]", G_opts["passthru"])
			_log.Finest("G_opts[A]", G_opts["A"])
			_log.Finest("G_opts[B]", G_opts["B"])
		}
	}

	before_context := new Queue(G_opts["B"])
	after_context := new Queue(G_opts["A"])

	try {
		f := FileOpen(file_name, "r `n`r")
		if (!f)
			_log.Error("Could not open file " file_name)
		else {
			hit_n := 0
			tabstops := do_modelines(f)
			while (!f.AtEOF) {
				line := RegExReplace(f.ReadLine(), "`t", tabstops)

				parts := test(line, regex_opts, found := 0, column := 0)

				if (found && G_opts["files_wo_matches"]) {
					hit_n++
					break
				} else if (found && !G_opts["v"]) {
					hit_n++
					if (G_opts["A"] > 0) {
						fpos := f.Tell()
						while (!f.AtEOF && A_Index <= G_opts["A"])
							after_context.Push(RegExReplace(f.Readline(), "\n$", "", 1))
						f.Seek(fpos)	
					}
					if (!output(file_name, A_Index, column, hit_n, before_context, after_context, parts))
						break
				} else if ((!found && G_opts["v"]) || G_opts["passthru"]) {
					hit_n++
					if (!output(file_name, A_Index, column, hit_n, "", "", line))
						break
				}

				if (G_opts["B"] > 0)
					before_context.Push(line)	
			}
		}
		if (G_opts["c"] && hit_n > 0)
			Ansi.WriteLine(Ansi.SetGraphic(G_opts["color_filename"]) hit_n " match(es)" Ansi.Reset())
		if (hit_n = 0 && G_opts["files_wo_matches"])
			Ansi.WriteLine(Ansi.SetGraphic(G_opts["color_filename"]) file_name "`n" Ansi.Reset())
	} finally {
		if (f)
			f.Close()
	}

	return _log.Exit()
}

test(ByRef haystack, regex_opts, ByRef found := 0, ByRef first_match_column := 0) {
	search_at := 1
	parts := []
	haystack := RegExReplace(haystack, "`n$", "", 1)
	loop {
		found_at := RegExMatch(haystack, regex_opts "S)" G_opts["pattern"], $, search_at)
		if (found_at > 0) {
			found++
			; if (found = 1)
			; 	haystack := RegExReplace(haystack, "`n$", "", 1)	
			if (A_Index = 1 && G_opts["column"])
				first_match_column := found_at
			if (found_at > 1) {
				parts.Insert(SubStr(haystack, search_at, found_at - search_at))
			}
			if (G_opts["color"])
				parts.Insert(Ansi.SetGraphic(G_opts["color_match"]) $ Ansi.Reset())
			else
				parts.Insert($)
			search_at := found_at + StrLen($)
		} else if (found > 0) {
			parts.Insert(SubStr(haystack, search_at))
		}
	} until (found_at = 0)
		
	return parts
}

output(file_name, line_no, column_no, hit_n, before_ctx, after_ctx, parts) {
	_log := new Logger("app.mack." A_ThisFunc)

	static first_call := true
		 , line_count := 1

	if (_log.Logs(Logger.INPUT)) {
		_log.Input("file_name", file_name)
		_log.Input("line_no", line_no)
		_log.Input("column_no", column_no)
		_log.Input("hit_n", hit_n)
		_log.Input("before_ctx", before_ctx)
		_log.Input("after_ctx", after_ctx)
		_log.Input("parts", parts)
		if (_log.Logs(Logger.ALL)) {
			_log.All("before_ctx:`n" LoggingHelper.Dump(before_ctx))
			_log.All("after_ctx:`n" LoggingHelper.Dump(after_ctx))
			_log.All("parts:`n" LoggingHelper.Dump(parts))
		}
	}
	
	if (hit_n = 1 && (G_opts["g"] | G_opts["files_w_matches"])) {
		if (G_opts["color"])
			line_count += set_line_count(Ansi.WriteLine(Ansi.SetGraphic(G_opts["color_filename"]) file_name Ansi.Reset()))
		else
			line_count += set_line_count(Ansi.WriteLine(file_name))
		return _log.Exit(false)	
	} else {
		if (hit_n = 1 && G_opts["group"]) {
			if (!first_call) {
				Ansi.Write(Ansi.SaveCursorPosition() Ansi.SetGraphic(Ansi.ATTR_REVERSE) "<Eof><Press space to continue or q to quit>" Ansi.Reset())
				Hotkey, IfWinActive, %G_wt%
				Hotkey q, __Quit__
				Hotkey Space, __Space__
				Ansi.Flush()
				Pause, On
				line_count := 1
			} else
				first_call := false
			if (G_opts["color"])
				line_count += set_line_count(Ansi.WriteLine("`n" Ansi.SetGraphic(G_opts["color_filename"]) file_name Ansi.Reset()))
			else
				line_count += set_line_count(Ansi.WriteLine("`n" file_name))
		} else if (!G_opts["group"]) {
			if (G_opts["color"])
				line_count += set_line_count(Ansi.Write(Ansi.SetGraphic(G_opts["color_filename"]) file_name ":" Ansi.Reset()))
			else
				line_count += set_line_count(Ansi.Write(file_name ":"))
		}
		if (before_ctx.Length() > 0) {
			_line_no := A_Index
			_col_no := (column_no = 0 ? "" : " ".Repeat(StrLen(column_no)) " ")
			loop % before_ctx.Length() {
				line_count += set_line_count(Ansi.Write(_line_no - G_opts["B"] + A_Index - 1 ":" before_ctx.Pop()))
				if (G_opts["color"])
					Ansi.WriteLine(Ansi.Reset() Ansi.EraseLine())
			}
		}
		if (column_no = 0) {
			if (G_opts["color"]) {
				line_count += set_line_count(Ansi.Write(Ansi.SetGraphic(G_opts["color_line_no"]) A_Index Ansi.Reset() ":" array_to_string(parts)))
				Ansi.WriteLine(Ansi.Reset() Ansi.EraseLine())
			} else {
				line_count += set_line_count(Ansi.Write(A_Index ":" array_to_string(parts)))
				Ansi.WriteLine()
			}
		} else {
			if (G_opts["color"]) {
				line_count += set_line_count(Ansi.Write(Ansi.SetGraphic(G_opts["color_line_no"]) A_Index Ansi.Reset() ":" Ansi.SetGraphic(G_opts["color_line_no"]) column_no Ansi.Reset() ":" array_to_string(parts)))
				Ansi.WriteLine(Ansi.Reset() Ansi.EraseLine())
			} else {
				line_count += set_line_count(Ansi.Write(A_Index ":" column_no ":" array_to_string(parts)))
				Ansi.WriteLine()
			}
		}
		if (after_ctx.Length() > 0) {
			_line_no := A_Index
			_col_no := (column_no = 0 ? "" : " ".Repeat(StrLen(column_no)) " ")
			loop % after_ctx.Length() {
				line_count += set_line_count(Ansi.Write(_line_no + A_Index ":" after_ctx.Pop()))
				if (G_opts["color"])
					Ansi.WriteLine(Ansi.Reset() Ansi.EraseLine())
				else
					Ansi.WriteLine()
				line_count++
			}
		}
		if (_log.Logs(Logger.Finest))
			_log.Finest("line_count", line_count)
		if (G_opts["group"] && line_count > Console.BufferInfo.srWindow.Bottom - Console.BufferInfo.srWindow.Top) {
			Ansi.Write(Ansi.SaveCursorPosition() Ansi.SetGraphic(Ansi.ATTR_REVERSE) "<Press space to continue or q to quit>" Ansi.Reset())
			Hotkey, IfWinActive, %G_wt%
			Hotkey q, __Quit__
			Hotkey Space, __Space__
			Ansi.Flush()
			Pause, On
			line_count := 1
		}
	}

	if (G_opts["1"])
		goto __Quit__

	return _log.Exit(true)

	__Space__:
		Pause, Off
		Ansi.Write(Ansi.RestoreCursorPosition() Ansi.Reset() Ansi.EraseLine())
		Ansi.Flush()
	return

	__Quit__:
		Ansi.Write(Ansi.RestoreCursorPosition() Ansi.Reset() Ansi.EraseLine())
		Ansi.Flush()
		Ansi.FlushInput()
	exitapp _log.Exit(0)
}

array_to_string(a) {
	if (a.MaxIndex())
		return Arrays.ToString(a, "")
	return a
}

set_line_count(length) {
	_log := new Logger("app.mack." A_ThisFunc)

	if (_log.Logs(Logger.Input))
		_log.Input("length", length)

	return _log.Exit((length // Console.BufferInfo.dwSize.X) + 1)
}

regex_file_pattern_list(file_pattern_string) {
	_log := new Logger("app.mack." A_ThisFunc)

	if (_log.Logs(Logger.INPUT)) {
		_log.Input("file_pattern_string", file_pattern_string)
	}
	
	file_pattern_list := StrSplit(file_pattern_string, "`n")

	for i, entry in file_pattern_list {
		StringReplace entry, entry, ., \., All
		StringReplace entry, entry, ?, ., All
		StringReplace entry, entry, *, .*?, All
		file_pattern_list[i] := "^" entry "$"
	}

	if (_log.Logs(Logger.All))
		_log.All("file_pattern_list:`n" LoggingHelper.Dump(file_pattern_list))

	return _log.Exit(file_pattern_list)
}

regex_file_pattern_string(file_pattern_string) {
	_log := new Logger("app.mack." A_ThisFunc)

	if (_log.Logs(Logger.INPUT))
		_log.Input("file_pattern_string", file_pattern_string)

	file_pattern_string := RegExReplace(file_pattern_string, "^`n", "^(",, 1)
	file_pattern_string := RegExReplace(file_pattern_string, "`n$", ")$",, 1)
	file_pattern_string := RegExReplace(file_pattern_string, "`n", "|")
	StringReplace file_pattern_string, file_pattern_string, ., \., All
	StringReplace file_pattern_string, file_pattern_string, ?, ., All
	StringReplace file_pattern_string, file_pattern_string, *, .*?, All
	VarSetCapacity(file_pattern_string, -1)
	
	return _log.Exit(file_pattern_string)
}

regex_match_list(list) {
	_log := new Logger("app.mack." A_ThisFunc)

	if (_log.Logs(Logger.INPUT)) {
		_log.Input("list", list)
		if (_log.Logs(Logger.ALL))
			_log.All("list:`n" LoggingHelper.Dump(list))
	}

	match := ""
	for i, pattern in list
		match .= (i > 1 ? "|" : "") pattern
	if (match <> "")
		match := "S)^(" match ")$"

	return _log.Exit(match)
}

regex_of_file_pattern(file_pattern) {
	_log := new Logger("app.mack." A_ThisFunc)

	if (_log.Logs(Logger.INPUT))
		_log.Input("file_pattern", file_pattern)

	StringReplace file_pattern, file_pattern, \, \\, All
	StringReplace file_pattern, file_pattern, ., \., All
	StringReplace file_pattern, file_pattern, ?, ., All
	StringReplace file_pattern, file_pattern, *, .*?, All
	StringReplace file_pattern, file_pattern, [, \[, All
	StringReplace file_pattern, file_pattern, ], \], All
	StringReplace file_pattern, file_pattern, {, \{, All
	StringReplace file_pattern, file_pattern, }, \}, All
	StringReplace file_pattern, file_pattern, (, \(, All
	StringReplace file_pattern, file_pattern, ), \), All
	StringReplace file_pattern, file_pattern, +, \+, All

	if (InStr(file_pattern, " ")) {
		file_pattern := "(" RegExReplace(file_pattern, "\s+", "|") ")"
	}

	return _log.Exit(file_pattern)
}

add_to_list(list_name, name) {
	pattern := regex_of_file_pattern(name)

	for _i, entry in G_opts[list_name]
		if (entry = pattern)
			return

	G_opts[list_name].Insert(pattern)	
}

remove_from_list(list_name, name) {
	pattern := regex_of_file_pattern(name)

	for _i, entry in G_opts[list_name]
		if (entry = pattern) {
			G_opts[list_name].Remove(_i)
			return
		}
}

ignore_dir(name, no_opt = "") {
	_log := new Logger("app.mack." A_ThisFunc)

	if (_log.Logs(Logger.INPUT)) {
		_log.Input("name", name)
		_log.Input("no_opt", no_opt)
	}

	if (no_opt = "")
		add_to_list("ignore_dirs", name)
	else
		remove_from_list("ignore_dirs", name)

	return _log.Exit()
}

ignore_file(name, no_opt = "") {
	_log := new Logger("app.mack." A_ThisFunc)

	if (_log.Logs(Logger.INPUT)) {
		_log.Input("name", name)
		_log.Input("no_opt", no_opt)
	}

	if (no_opt = "")
		add_to_list("ignore_files", name)
	else
		remove_from_list("ignore_files", name)

	return _log.Exit()
}

type_list(filetype, no_opt = "") {
	_log := new Logger("app.mack." A_ThisFunc)

	if (_log.Logs(Logger.INPUT)) {
		_log.Input("filetype", filetype)
		_log.Input("no_opt", no_opt)
	}

	if (G_opts["types"][filetype] = "")
		throw _log.Exit(Exception("Unknown filetype: " filetype))

	if (no_opt = "")
		add_to_list("type", G_opts["types"][filetype])
	else
		remove_from_list("type", G_opts["types"][filetype])

	return _log.Exit()
}

del_type(filetype) {
	_log := new Logger("app.mack." A_ThisFunc)

	if (_log.Logs(Logger.INPUT)) {
		_log.Input("filetype", filetype)
	}

	if (G_opts["types"].Remove(filetype) = "")
		throw _log.Exit(Exception("Unkwonw filetype: " filetype))

	return _log.Exit()
}

add_type(filetype_filter) {
	_log := new Logger("app.mack." A_ThisFunc)

	if (_log.Logs(Logger.INPUT))
		_log.Input("filetype_filter", filetype_filter)

	if (!RegExMatch(filetype_filter, "([a-z]+):(.+)", $))
		throw _log.Exit(Exception("Invalid filetype filter: " filetype_filter))

	StringReplace filter, $2, +, %A_Space%, All

	if (G_opts["types"][$1] = "")
		throw _log.Exit(Exception("Unknown filetype: " $1))

	G_opts["types"][$1] .= " " filter

	return _log.Exit()
}

set_type(filetype_filter) {
	_log := new Logger("app.mack." A_ThisFunc)

	if (_log.Logs(Logger.INPUT))
		_log.Input("filetype_filter", filetype_filter)

	if (!RegExMatch(filetype_filter, "([a-z]+):(.+)", $))
		throw _log.Exit(Exception("Invalid filetype filter: " filetype_filter))

	StringReplace filter, $2, +, %A_Space%, All

	if (G_opts["types"][$1] <> "")
		throw _log.Exit(Exception("Filetype already defined: " $1))

	G_opts["types"][$1] := " " filter

	return _log.Exit()
}

help_types() {
	_log := new Logger("app.mack." A_ThisFunc)
	
	dt := new DataTable()
	dt.DefineColumn(new DataTable.Column(, DataTable.COL_RESIZE_USE_LARGEST_DATA))
	dt.DefineColumn(new DataTable.Column())

	for filetype, filter in G_opts["types"]
		dt.AddData([filetype, filter])

	return _log.Exit(dt.GetTableAsString())
}

do_modelines(file) {
	_log := new Logger("app.mack." A_ThisFunc)

	if (_log.Logs(Logger.Input)) {
		_log.Input("file", file)
		if (_log.Logs(Logger.Finest)) {
			_log.Finest("G_opts[tabstop]", G_opts["tabstop"])
			_log.Finest("G_opts[modelines]", G_opts["modelines"])
			_log.Finest("G_opts[modeline_pattern]", G_opts["modeline_pattern"])
			if (_log.Logs(Logger.All)) {
				_log.All("G_opts[modeline_pattern]:`n" LoggingHelper.Dump(G_opts["modeline_pattern"]))
			}
			_log.Finest("G_opts[modeline_expr]", G_opts["modeline_expr"])
		}
	}

	modeline_found := false
	if (G_opts["modelines"]) {
		loop % G_opts["modelines"] {
			line := file.ReadLine()
			if (RegExMatch(line, G_opts["modeline_expr"], $)) {
				tabsize := ""
				loop % G_opts["modeline_pattern"].MaxIndex()
					tabsize .= $tabstop%A_Index%
				if (_log.Logs(Logger.Detail)) {
					_log.Detail("Header modeline found: ", line ": " tabsize)
				}
				modeline_found := true
				break
			}
		}
		if (!modeline_found) {
			search_size := G_opts["modelines"] * 100
			if (file.Length > search_size) {
				file.Seek(-search_size, 2)
				tail_content := file.Read(search_size)
			} else {
				file.Seek(0)
				tail_content := file.Read(search_size := file.Length)
			}
			lines := StrSplit(tail_content, "`n", "`r")
			if (_log.Logs(Logger.Finest)) {
				_log.Finest("search_size", search_size)
				_log.Finest("lines:`n" LoggingHelper.Dump(lines))
			}
			loop % G_opts["modelines"] {
				if (RegExMatch(lines[lines.MaxIndex() - A_Index + 1], G_opts["modeline_expr"], $)) {
					tabsize := $tabstop
					loop % G_opts["modeline_pattern"].MaxIndex()
						tabsize .= $tabstop%A_Index%
					if (_log.Logs(Logger.Detail)) {
						_log.Detail("Trailer modeline found: ", lines[lines.MaxIndex() - A_Index + 1] ": " tabsize)
					}
					modeline_found := true
					break
				}
			}
		}
		file.Seek(0)
	}

	if (!modeline_found)
		tabsize := G_opts["tabstop"]

	return _log.Exit(SubStr("         ", 1, tabsize))
}

main:
	_main := new Logger("app.mack.main")

	OutputDebug Start...
	
	global G_wt
	global G_opts := { "A": 0
					 , "B": 0
					 , "c": false
					 , "column": false
					 , "color": true
					 , "color_filename": Ansi.FOREGROUND_GREEN ";" Ansi.ATTR_BOLD
					 , "color_match": Ansi.FOREGROUND_YELLOW ";" Ansi.ATTR_BOLD ";" Ansi.ATTR_REVERSE
					 , "color_line_no": Ansi.FOREGROUND_YELLOW ";" Ansi.ATTR_BOLD
					 , "context": 0
					 , "h": false
					 , "f": false
					 , "files_w_matches": false
					 , "files_wo_matches": false
		 			 , "g": false
					 , "group": true
					 , "ht": false
					 , "i": false
					 , "ignore_dirs": []
					 , "ignore_files": []
					 , "k": false
					 , "passthru": false
					 , "modelines": 5
					 , "modeline_pattern": [ "^.*?\s+(vi:|vim:|ex:)\s*.*?((ts|tabstop)=(?P<tabstop>\d))"
										   , "^.*?:.*?tabSize=(?P<tabstop>\d):.*?:" ]
					 , "Q": false
					 , "r": true
					 , "sort_files": false
					 , "tabstop": 4
					 , "types": { "autohotkey" : "*.ahk"
								, "batch"      : "*.bat *.cmd"
								, "html"       : "*.htm *.html"
								, "java"       : "*.java *.properties"
								, "js"         : "*.js"
								, "json"       : "*.json"
								, "log"        : "*.log"
								, "md"         : "*.md *.mkd *.markdown"
								, "python"     : "*.py"
								, "tex"        : "*.tex *.latex *.cls *.sty"
								, "text"       : "*.txt *.rtf *.readme"
								, "vim"        : "*.vim"
								, "xml"        : "*.xml *.dtd *.xsl *.xslt *.ent"
								, "yaml"       : "*.yaml *.yml" }
					 , "type": []
					 , "v": false
					 , "version": false
					 , "w": false
					 , "x": ""
					 , "1": false }

	WinGetTitle G_wt, A

	ignore_dir(".svn")
	ignore_dir(".git")
	ignore_dir("CVS")
	ignore_file("#*#")
	ignore_file("*~")
	ignore_file("*.bak")
	ignore_file("*.swp")
	ignore_file("Thumbs.db")
	ignore_file("*.exe")
	ignore_file("*.dll")

	op := new OptParser(["mack [options] <pattern> [file | directory]..."
	                   , "mack -f [options] [directory]..."])
	op.Add(new OptParser.Group("Searching:"))
	op.Add(new OptParser.Boolean("i", "ignore-case", _i, "Ignore case distinctions in pattern"))
	op.Add(new OptParser.Boolean("v", "invert-match", _v, "Select non-matching lines"))
	op.Add(new OptParser.Boolean("w", "word-regexp", _w, "Force pattern to match only whole words"))
	op.Add(new OptParser.Boolean("Q", "literal", _Q, "Quote all metacharacters; pattern is literal"))
	op.Add(new OptParser.Group("`nSearch output:"))
	op.Add(new OptParser.Boolean("l", "files-with-matches", _files_w_matches, "Only print filenames containing matches"))
	op.Add(new OptParser.Boolean("L", "files-without-matches", _files_wo_matches, "Only print filenames with no matches"))
	op.Add(new OptParser.Boolean(0, "passthru", _passthru, "Print all lines, whether matching or not"))
	op.Add(new OptParser.Boolean("1", "", _1, "Stop searching after one match of any kind"))
	op.Add(new OptParser.Boolean("c", "count", _c, "Show number of lines matching per file"))
	op.Add(new OptParser.Boolean(0, "column", _column, "Show the column number of the first match", OptParser.OPT_NEG))
	op.Add(new OptParser.String("A", "after-context", _n_after_ctx, "NUM", "Print NUM lines of trailing context after matching lines",,, G_opts["A"]))
	op.Add(new OptParser.String("B", "before-context", _n_before_ctx, "NUM", "Print NUM lines of leading context before matching lines",,, G_opts["B"]))
	op.Add(new OptParser.String("C", "context", _n_ctx, "NUM", "Print NUM (default 2) lines of output context", OptParser.OPT_OPTARG, 2, G_opts["context"]))
	op.Add(new OptParser.String(0, "tabstop", _tabstop, "size", "Calculate tabstops with width of size (default 8)",,, G_opts["tabstop"]))
	op.Add(new OptParser.String(0, "modelines", _modelines, "lines", "Search modelines (default 5) for tabstop info. Set to 0 to ignore modelines", OptParser.OPT_OPTARG,, 5, G_opts["modelines"]))
	op.Add(new OptParser.Group("`nFile presentation:"))
	op.Add(new OptParser.Boolean(0, "group", _group, "Print a filename heading above each file's results (default: on when used interactively)", OptParser.OPT_NEG, true))
	op.Add(new OptParser.Boolean(0, "color", _color, "Highlight the matching text (default: on)", OptParser.OPT_NEG, G_opts["color"]))
	op.Add(new OptParser.String(0, "color-filename", _color_filename, "color", "", OptParser.OPT_ARG, G_opts["color_filename"], G_opts["color_filename"]))
	op.Add(new OptParser.String(0, "color-match", _color_match, "color", "", OptParser.OPT_ARG, G_opts["color_match"], G_opts["color_match"]))
	op.Add(new OptParser.String(0, "color-line-no", _color_line_no, "color", "Set the color for filenames, matches, and line numbers as ANSI color attributes (e.g. ""7;37"")", OptParser.OPT_ARG, G_opts["color_line_no"], G_opts["color_line_no"]))
	op.Add(new OptParser.Group("`nFile finding:"))
	op.Add(new OptParser.Boolean("f", "", _f, "Only print the files selected, without searching. The pattern must not be specified"))
	op.Add(new OptParser.Boolean("g", "", _g, "Same as -f, but only select files matching pattern"))
	op.Add(new OptParser.Boolean(0, "sort-files", _sort_files, "Sort the found files lexically"))
	op.Add(new OptParser.Boolean("x", "", _x, "Read the list of files to search from STDIN"))
	op.Add(new OptParser.Group("`nFile inclusion/exclusion:"))
	op.Add(new OptParser.Callback(0, "ignore-dir", _ignore_dir, "ignore_dir", "name", "Add/remove directory from list of ignored dirs", OptParser.OPT_ARG | OptParser.OPT_NEG))
	op.Add(new OptParser.Callback(0, "ignore-file", _ignore_file, "ignore_file", "filter", "Add filter for ignoring files", OptParser.OPT_ARG | OptParser.OPT_NEG))
	op.Add(new OptParser.Boolean("r", "recurse", _r, "Recurse into subdirectories (default: on)", OptParser.OPT_NEG, true))
	op.Add(new OptParser.Boolean("k", "known-types", _k, "Include only files of types that are recognized"))
	op.Add(new OptParser.Callback(0, "type", _type, "type_list", "X", "Include/exclude X files", OptParser.OPT_ARG | OptParser.OPT_NEG))
	op.Add(new OptParser.Group("`nFile type specification:"))
	op.Add(new OptParser.Callback(0, "type-set", _type_set, "set_type", "X:FILTER[+FILTER...]", "Files with given FILTER are recognized of type X. This replaces an existing defintion.", OptParser.OPT_ARG))
	op.Add(new OptParser.Callback(0, "type-add", _type_add, "add_type", "X:FILTER[+FILTER...]", "Files with given FILTER are recognized of type X", OptParser.OPT_ARG))
	op.Add(new OptParser.Callback(0, "type-del", _type_del, "del_type", "X", "Remove all filters associated with X", OptParser.OPT_ARG))
	op.Add(new OptParser.Group("`nMiscellaneous:"))
	op.Add(new OptParser.Boolean("h", "help", _h, "This help", OptParser.OPT_HIDDEN))
	op.Add(new OptParser.Boolean(0, "version", _version, "Display version info"))
	op.Add(new OptParser.Boolean(0, "help-types", _ht, "Display all knwon types"))

	RC := 0

	#Include *i %A_ScriptDir%/.version-info

	try {
		args := op.Parse(system.vArgs)
		G_opts["A"] := _n_after_ctx
		G_opts["B"] := _n_before_ctx
		G_opts["c"] := _c
		G_opts["column"] := _column
		G_opts["color"] := _color
		G_opts["color_filename"] := _color_filename
		G_opts["color_match"] := _color_match
		G_opts["color_line_no"] := _color_line_no
		G_opts["context"] := _n_ctx
		G_opts["f"] := _f
		G_opts["files_w_matches"] := _files_w_matches
		G_opts["files_wo_matches"] := _files_wo_matches
		G_opts["g"] := _g
		G_opts["group"] := _group
		G_opts["h"] := _h
		G_opts["ht"] := _ht
		G_opts["i"] := _i
		G_opts["k"] := _k
		G_opts["modelines"] := OptParser.TrimArg(_modelines)
		G_opts["modeline_expr"] := "J)" Arrays.ToString(G_opts["modeline_pattern"], "|")
		G_opts["passthru"] := _passthru
		G_opts["Q"] := _Q
		G_opts["r"] := _r
		G_opts["sort_files"] := _sort_files
		G_opts["tabstop"] := OptParser.TrimArg(_tabstop)
		G_opts["v"] := _v
		G_opts["version"] := _version
		G_opts["w"] := _w
		G_opts["x"] := _x
		G_opts["1"] := _1
		if (_main.Logs(Logger.Finest))
			_log.Finest("G_opts:`n" LoggingHelper.Dump(G_opts))

		if (G_opts["k"])
			for filetype, filter in G_opts["types"]
				type_list(filetype)	
			
		G_opts["match_ignore_dirs"] := regex_match_list(G_opts["ignore_dirs"])
		G_opts["match_ignore_files"] := regex_match_list(G_opts["ignore_files"])
		G_opts["match_type"] := regex_match_list(G_opts["type"])

		if (G_opts["context"] && G_opts["A"] = 0)
			G_opts["A"] := G_opts["context"]

		if (G_opts["context"] && G_opts["B"] = 0)
			G_opts["B"] := G_opts["context"]

		if (_main.Logs(Logger.FINEST))
			_main.Finest("G_opts:`n" LoggingHelper.Dump(G_opts))
		if (G_opts["version"])
			Ansi.WriteLine(get_version())
		else if (G_opts["h"])
			Ansi.WriteLine(op.Usage())
		else if (G_opts["ht"])
			Ansi.Write(help_types())
		else {
			if (!G_opts["f"]) {
				G_opts["pattern"] := Arrays.Shift(args)
				if (_main.Logs(Logger.FINEST))
					_main.Finest("G_opts[pattern]", G_opts["pattern"])
				if (G_opts["pattern"] = "")
					throw Exception("Provide a search pattern")
				if (G_opts["Q"])
					G_opts["pattern"] := "\Q" G_opts["pattern"] "\E"
				if (G_opts["w"])
					G_opts["pattern"] := "\b" G_opts["pattern"] "\b"
				if (G_opts["g"])
					G_opts["file_pattern"] := regex_of_file_pattern(G_opts["pattern"])
				if (_main.Logs(Logger.FINEST))
					_main.Finest("G_opts[file_pattern]", G_opts["file_pattern"])
			}
			file_list := determine_files(args)
			if (G_opts["f"] || G_opts["g"])
				for _i, file_entry in file_list {
					Ansi.WriteLine(file_entry)
				}
			else {
				for _i, file_entry in file_list
					search_for_pattern(file_entry, G_opts["i"] ? "i" : "")
			}
		}
	} catch _ex {
		Ansi.WriteLine(_ex.Message)
		Ansi.WriteLine(op.Usage())
		RC := _ex.Extra
	}

	OutputDebug Done.
	Ansi.FlushInput()
exitapp _main.Exit(RC)
; vim: ts=4:sts=4:sw=4:tw=0:noet
