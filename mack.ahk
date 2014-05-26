#NoEnv
SetBatchLines -1

#Include <logging>
#Include <console>
#Include <optparser>
#Include <system>
#Include <string>

get_version() {
	_log := new Logger("app.mack." A_ThisFunc)
	return _log.Exit("mack version " _CFG.CFG_VERSION " " G_CFG.CFG_ARCH " " G_CFG.CFG_BUILD "`n")
}

determine_files(args) {
	_log := new Logger("app.mack." A_ThisFunc)
	
	if (_log.Logs(Logger.INPUT)) {
		_log.Input("args", args)
		if (_log.Logs(Logger.ALL))
			_log.All("args:`n" LoggingHelper.Dump(args))
	}

	file_list := []
	for _i, file_pattern in args {
		refine_file_pattern(file_pattern)
		collect_filenames(file_list, file_pattern)
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
		}
		if (G_opts["r"] && InStr(A_LoopFileAttrib, "D") && !RegExMatch(A_LoopFileName, G_opts["match_ignore_dirs"]))
			fn_list := collect_filenames(fn_list, A_LoopFileFullPath)
		else if (!RegExMatch(A_LoopFileName, G_opts["match_ignore_dirs"]) && !RegExMatch(A_LoopFileName, G_opts["match_ignore_files"]))
			fn_list.Insert(A_LoopFileFullPath)
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

	match := "^("
	for i, pattern in list
		match .= (i > 1 ? "|" : "") pattern
	match .= ")$"

	return _log.Exit(match)
}

regex_of_file_pattern(file_pattern) {
	_log := new Logger("app.mack." A_ThisFunc)

	if (_log.Logs(Logger.INPUT))
		_log.Input("file_pattern", file_pattern)

	StringReplace file_pattern, file_pattern, \, \\, All
	StringReplace file_pattern, file_pattern, ., \., All
	StringReplace file_pattern, file_pattern, *, .*?, All
	StringReplace file_pattern, file_pattern, ?, ., All
	StringReplace file_pattern, file_pattern, [, \[, All
	StringReplace file_pattern, file_pattern, ], \], All
	StringReplace file_pattern, file_pattern, {, \{, All
	StringReplace file_pattern, file_pattern, }, \}, All
	StringReplace file_pattern, file_pattern, (, \(, All
	StringReplace file_pattern, file_pattern, ), \), All
	StringReplace file_pattern, file_pattern, +, \+, All

	return _log.Exit(file_pattern)
}

add_to_list(list_name, name) {
	G_opts[list_name].Insert(regex_of_file_pattern(name))	
}

add_ignore_dir(name, no_opt) {
	_log := new Logger("app.mack." A_ThisFunc)

	if (_log.Logs(Logger.INPUT)) {
		_log.Input("name", name)
		_log.Input("no_opt", no_opt)
	}

	if (no_opt = "")
		add_to_list("ignore_dirs", name)
	else
		add_to_list("no_ignore_dirs", name)

	_log.Exit()
}

add_ignore_file(name, no_opt) {
	_log := new Logger("app.mack." A_ThisFunc)

	if (_log.Logs(Logger.INPUT)) {
		_log.Input("name", name)
		_log.Input("no_opt", no_opt)
	}

	if (no_opt = "")
		add_to_list("ignore_files", name)
	else
		add_to_list("no_ignore_files", name)

	_log.Exit()
}

main:
	_main := new Logger("app.mack.main")
	
	global G_opts := { "h": false
					 , "f": false
		 			 , "g": false
					 , "ignore_dirs": [ "\.svn", "\.git", "CVS" ]
					 , "no_ignore_dirs": []
					 , "ignore_files": [ "#.*#", ".*~", ".*\.bak", "Thumbs\.db" ]
					 , "no_ignore_files": []
					 , "r": true
					 , "version": false }

	op := new OptParser(["mack [options] <pattern> [file | directory]..."
	                   , "mack -f [options] [directory]..."])
	op.Add(new OptParser.Group("Searching:"))
	op.Add(new OptParser.Group("`nSearch output:"))
	op.Add(new OptParser.Group("`nFile presentation:"))
	op.Add(new OptParser.Group("`nFile finding:"))
	op.Add(new OptParser.Boolean("f", "", _f, "Only print the files selected, without searching. The pattern must not be specified"))
	op.Add(new OptParser.Boolean("g", "", _g, "Same as -f, but only select files matching pattern"))
	op.Add(new OptParser.Group("`nFile inclusion/exclusion:"))
	op.Add(new OptParser.Callback(0, "ignore-dir", _ignore_dir, "add_ignore_dir", "name", "Add/remove directory from list of ignored dirs", OptParser.OPT_ARG | OptParser.OPT_NEG))
	op.Add(new OptParser.Callback(0, "ignore-file", _ignore_file, "add_ignore_file", "filter", "Add filter for ignoring files", OptParser.OPT_ARG))
	op.Add(new OptParser.Boolean("r", "recurse", _r, "Recurse into subdirectories (default: on)", OptParser.OPT_NEG, true))
	op.Add(new OptParser.Group("`nFile type specification:"))
	op.Add(new OptParser.Group("`nMiscellaneous:"))
	op.Add(new OptParser.Boolean("h", "help", _h, "This help", OptParser.OPT_HIDDEN))
	op.Add(new OptParser.Boolean(0, "version", _v, "Display version info"))

	RC := 0

	#Include *i %A_ScriptDir%/.version-info

	try {
		args := op.Parse(system.vArgs)
		G_opts["h"] := _h
		G_opts["f"] := _f
		G_opts["g"] := _g
		G_opts["r"] := _r
		G_opts["version"] := _v
		G_opts["match_ignore_dirs"] := regex_match_list(G_opts["ignore_dirs"])
		G_opts["match_ignore_files"] := regex_match_list(G_opts["ignore_files"])

		if (_main.Logs(Logger.FINEST))
			_main.Finest("G_opts:`n" LoggingHelper.Dump(G_opts))

		if (G_opts["version"])
			Console.Write(get_version() "`n")
		else if (G_opts["h"])
			Console.Write(op.Usage() "`n")
		else {
			if (!G_opts["f"])
				pattern := Arrays.Shift(args)
			file_list := determine_files(args)
			if (G_opts["f"])
				for _i, file_entry in file_list
					Console.Write(_i " " file_entry "`n")
		}
	} catch _ex {
		Console.Write(_ex.Message "`n")
		Console.Write(op.Usage() "`n")
		RC := 1
	}

exitapp _main.Exit(RC)
