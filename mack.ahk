#NoEnv
SetBatchLines -1

#Include <logging>
#Include <console>
#Include <optparser>
#Include <system>
#Include <string>
#Include <datatable>
#Include <arrays>

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

	if (args.MaxIndex() = "")
		args := ["."]

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
			_log.Finest("A_LoopFileName", A_LoopFileName)
		}
		if (G_opts["r"] && InStr(A_LoopFileAttrib, "D")
				&& !RegExMatch(A_LoopFileName, G_opts["match_ignore_dirs"]))
			fn_list := collect_filenames(fn_list, A_LoopFileFullPath)
		else if (!InStr(A_LoopFileAttrib, "D")
				&& (G_opts["match_type"] = "" || RegExMatch(A_LoopFileName, G_opts["match_type"]))
				&& !RegExMatch(A_LoopFileName, G_opts["match_ignore_files"]))
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

search_for_pattern(file_name) {
	_log := new Logger("app.mack." A_ThisFunc)

	if (_log.Logs(Logger.INPUT))
		_log.Input("file_name", file_name)

	if (_log.Logs(Logger.FINEST))
		_log.Finest("G_opts[pattern]", G_opts["pattern"])

	try {
		f := FileOpen(file_name, "r-r`r")
		if (!f)
			_log.Error("Could not open file " file_name)
		else {
			while (!f.AtEOF) {
				line := f.ReadLine()
				if (RegExMatch(line, "S)" G_opts["pattern"]))
					Console.Write(line)
			}
		}
	} finally {
		if (f)
			f.Close()
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
	StringReplace file_pattern, file_pattern, *, .*?, All
	StringReplace file_pattern, file_pattern, ?, ., All
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

main:
	_main := new Logger("app.mack.main")

	OutputDebug Start...
	
	global G_opts := { "h": false
					 , "f": false
		 			 , "g": false
					 , "ht": false
					 , "ignore_dirs": []
					 , "ignore_files": []
					 , "k": false
					 , "r": true
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
								, "xml"        : "*.xml *.dtd *.xsl *.xslt *.ent"
								, "yaml"       : "*.yaml *.yml" }
					 , "type": []
					 , "version": false }

	ignore_dir(".svn")
	ignore_dir(".git")
	ignore_dir("CVS")
	ignore_file("#*#")
	ignore_file("*~")
	ignore_file("*.bak")
	ignore_file("*.swp")
	ignore_file("Thumbs.db")

	op := new OptParser(["mack [options] <pattern> [file | directory]..."
	                   , "mack -f [options] [directory]..."])
	op.Add(new OptParser.Group("Searching:"))
	op.Add(new OptParser.Group("`nSearch output:"))
	op.Add(new OptParser.Group("`nFile presentation:"))
	op.Add(new OptParser.Group("`nFile finding:"))
	op.Add(new OptParser.Boolean("f", "", _f, "Only print the files selected, without searching. The pattern must not be specified"))
	op.Add(new OptParser.Boolean("g", "", _g, "Same as -f, but only select files matching pattern"))
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
	op.Add(new OptParser.Boolean(0, "version", _v, "Display version info"))
	op.Add(new OptParser.Boolean(0, "help-types", _ht, "Display all knwon types"))

	RC := 0

	#Include *i %A_ScriptDir%/.version-info

	try {
		args := op.Parse(system.vArgs)
		G_opts["f"] := _f
		G_opts["g"] := _g
		G_opts["h"] := _h
		G_opts["ht"] := _ht
		G_opts["k"] := _k
		G_opts["r"] := _r
		G_opts["version"] := _v

		if (G_opts["k"])
			for filetype, filter in G_opts["types"]
				type_list(filetype)	
			
		G_opts["match_ignore_dirs"] := regex_match_list(G_opts["ignore_dirs"])
		G_opts["match_ignore_files"] := regex_match_list(G_opts["ignore_files"])
		G_opts["match_type"] := regex_match_list(G_opts["type"])

		if (_main.Logs(Logger.FINEST))
			_main.Finest("G_opts:`n" LoggingHelper.Dump(G_opts))
		if (G_opts["version"])
			Console.Write(get_version() "`n")
		else if (G_opts["h"])
			Console.Write(op.Usage() "`n")
		else if (G_opts["ht"])
			Console.Write(help_types(), "`n")
		else {
			if (!G_opts["f"]) {
				G_opts["pattern"] := Arrays.Shift(args)
				if (_main.Logs(Logger.FINEST))
					_main.Finest("G_opts[pattern]", G_opts["pattern"])
			}
			file_list := determine_files(args)
			if (G_opts["f"])
				for _i, file_entry in file_list
					Console.Write(file_entry "`n")
			else {
				for _i, file_entry in file_list
					search_for_pattern(file_entry)
			}
		}
	} catch _ex {
		Console.Write(_ex.Message "`n")
		Console.Write(op.Usage() "`n")
		RC := 1
	}

	OutputDebug Done.
exitapp _main.Exit(RC)
