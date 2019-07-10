; ahk: console
class Mack {

	static Option := Mack.setDefaults()
	static Sel_Types_Option := ""
	static First_Call := true

	setDefaults() {
		dv :=  {  A						: 0
				, B				  		: 0
				, c				  		: false
				, column		  		: false
				, color			  		: true
				, color_filename  		: Ansi.FOREGROUND_GREEN ";" Ansi.ATTR_BOLD
				, color_match	  		: Ansi.FOREGROUND_YELLOW ";" Ansi.ATTR_BOLD ";" Ansi.ATTR_REVERSE
				, color_line_no	  		: Ansi.FOREGROUND_YELLOW ";" Ansi.ATTR_BOLD
				, color_context	  		: Ansi.FOREGROUND_BLUE ";" Ansi.ATTR_BOLD
				, context		  		: 2
				, f				  		: false
				, file_pattern    		: ""
				, filename		  		: true
				, files_from	  		: ""
				, files_w_matches 		: false
				, files_wo_matches		: false
				, g               		: false
				, group			  		: true
				, h				  		: false
				, ht			  		: false
				, i				  		: false
				, ignore_dirs	  		: []
				, ignore_files	  		: []
				, k				  		: false
				, line			  		: true
				, match_ignore_dirs		: ""
				, match_ignore_files	: ""
				, match_type			: ""
				, match_type_ignore		: ""
				, modelines				: 5
				, modeline_pattern		: [ "^.*?\s+(vi:|vim:|ex:)\s*.*?((ts|tabstop)=(?P<tabstop>\d+))"
										  , "^.*?:.*?tabSize=(?P<tabstop>\d+):.*?:" ]
				, modeline_expr			: ""
				, o						: false
				, output		  		: ""
				, pager			  		: true
				, passthru		  		: false
				, Q				  		: false
				, r               		: true
				, sort_files	  		: false
				, tabstop		  		: 4
				, types					: { "autohotkey": "*.ahk"
										  , "batch"     : "*.bat *.cmd"
                    	 			      , "css"       : "*.css"
                    	 			      , "html"      : "*.htm *.html"
                    	 			      , "java"      : "*.java *.properties"
                    	 			      , "js"        : "*.js"
                    	 			      , "json"      : "*.json"
                    	 			      , "log"       : "*.log"
                    	 			      , "md"        : "*.md *.mkd *.markdown"
                    	 			      , "python"    : "*.py"
                    	 			      , "ruby"      : "*.rb *.rhtml *.rjs *.rxml *.erb *.rake *.spec"
                    	 			      , "shell"     : "*.sh"
                    	 			      , "tex"       : "*.tex *.latex *.cls *.sty"
                    	 			      , "text"      : "*.txt *.rtf *.readme"
                    	 			      , "vim"       : "*.vim"
                    	 			      , "xml"       : "*.xml *.dtd *.xsl *.xslt *.ent"
                    	 			      , "yaml"      : "*.yaml *.yml" }
				, types_expr			: Mack.regularExpressionOfTypeList()
				, type					: []
				, type_ignore			: []
				, v				  		: false
				, version		  		: false
				, w				  		: false
				, x				  		: false
				, 1				  		: false }

		Mack.option := dv
		Mack.setDefaultIgnoreDirs()
		Mack.setDefaultIgnoreFiles()
		Mack.setDefaultModelineExpression()
	}

	setDefaultIgnoreDirs() {
		maintainDirectoriesToIgnore(".svn")
		maintainDirectoriesToIgnore(".git")
		maintainDirectoriesToIgnore("CVS")
	}

	setDefaultIgnoreFiles() {
		maintainFilesToIgnore("#*#")
		maintainFilesToIgnore("*~")
		maintainFilesToIgnore("*.bak")
		maintainFilesToIgnore("*.swp")
		maintainFilesToIgnore("*.exe")
		maintainFilesToIgnore("*.dll")
		maintainFilesToIgnore("Thumbs.db")
	}

	setDefaultModelineExpression() {
		Mack.option.modeline_expr := "J)" Arrays.toString(Mack.option.modeline_pattern, "|")
	}

	getVersionInfo() {
		global G_VERSION_INFO
		return G_VERSION_INFO.NAME "/" G_VERSION_INFO.ARCH "-b" G_VERSION_INFO.BUILD " Copyright (C) 2014-2018 K.-P. Schreiner`n"
	}

	printKnownFileTypes() {
		dt := new DataTable()
		dt.defineColumn(new DataTable.column(, DataTable.COL_RESIZE_USE_LARGEST_DATA))
		dt.defineColumn(new DataTable.column.wrapped(50))

		for filetype, filter in Mack.option.types {
			dt.addData([filetype, filter])
		}

		return dt.getTableAsString()
	}

	/*
	 * Method:	determine_files
	 *			Find all matching files.
	 *
	 * Parameters:
	 *			args - Files and Directories to examine
	 *
	 * Returns:
	 *			A list of matching files or empty list.
	 *
	 * Remarks:
	 *			If args is empty, the current directory will be used.
	 */
	; TODO: Refactor!
	determine_files(args) {
		_log := new Logger("class." A_ThisFunc)
		
		if (_log.logs(Logger.INPUT)) {
			_log.input("args", args)
			if (_log.logs(Logger.finer)) {
				_log.finer("args:`n" LoggingHelper.dump(args))
			}
		}

		if (args.maxIndex() = "") {
			args := ["."]
		}

		file_list := ""	; CAVEAT: This will force collect_filenames to create a new list at first loop iteration and fill the list up every further iteration
		for _i, file_pattern in args {
			file_pattern := Mack.refineFileOrPathPattern(file_pattern)
			file_list := Mack.collect_filenames(file_pattern, file_list)
		}

		if (_log.logs(Logger.finest)) {
			_log.finest("Mack.option.sort_files", Mack.option.sort_files)
		}
		if (Mack.option.sort_files && file_list.maxIndex() <> "") {
			file_list_string := ""
			loop % (file_list.maxIndex()-1) {
				file_list_string .= file_list[A_Index] "`n"
			}
			file_list_string .= file_list[file_list.maxIndex()]
			Sort file_list_string, C
			file_list := StrSplit(file_list_string, "`n")
		}

		if (_log.logs(Logger.finer)) {
			_log.finer("file_list:`n" LoggingHelper.dump(file_list))
		}
		
		return _log.exit(file_list)
	}

	refineFileOrPathPattern(fileOrPathPattern) {
		refinedPathPattern := fileOrPathPattern
		isDirectory := InStr(FileExist(fileOrPathPattern), "D")
		if (isDirectory) {
			RegExMatch(fileOrPathPattern, "(?P<Backslash>\\)?(?P<Wildcard>\*\.?\*?)?$", hasMatching)
			if (!hasMatchingBackslash)
				refinedPathPattern .= "\"
			if (!hasMatchingWildcard)
				refinedPathPattern .= "*.*"
		}

		return refinedPathPattern
	}

	/*
	 * Method:	collect_filenames
	 *			gather all files to search for the pattern or to list for -f / -g option.
	 *
	 * Parameter:
	 *			fn_list - a list object to store the filenames.
	 *			dirname - the directory to start the search in.
	 *
	 * Returns:
	 *			A list with matching files.
	 */
	; TODO: Refactor
	collect_filenames(dirname, fn_list = "") {
		_log := new Logger("class." A_ThisFunc)

		if (!IsObject(fn_list)) {
			fn_list := []
		}

		if (_log.logs(Logger.INPUT)) {
			_log.input("dirname", dirname)
			if (_log.logs(Logger.ALL)) {
				_log.all("fn_list:`n" LoggingHelper.dump(fn_list))
			}
		}

		dirname := Mack.refineFileOrPathPattern(dirname)
		loop Files, %dirname%, DF	; NOWARN
		{
			if (_log.logs(Logger.FINEST)) {
				_log.finest("A_LoopFileAttrib", A_LoopFileAttrib)
				_log.finest("A_LoopFileFullPath", A_LoopFileFullPath)
				_log.finest("A_LoopFileName", A_LoopFileName)
				_log.finest("Mack.option.g", Mack.option.g)
				_log.finest("Mack.option.r", Mack.option.r)
				_log.finest("Mack.option.file_pattern", Mack.option.file_pattern)
				_log.finest("Mack.option.match_type", Mack.option.match_type)
				_log.finest("Mack.option.match_type_ignore", Mack.option.match_type_ignore)
				_log.finest("Mack.option.match_ignore_dirs", Mack.option.match_ignore_dirs)
				_log.finest("Mack.option.match_ignore_files", Mack.option.match_ignore_files)
			}
			if (Mack.option.r && InStr(A_LoopFileAttrib, "D") 
					&& (Mack.option.match_ignore_dirs = "" || !RegExMatch(A_LoopFileName, Mack.option.match_ignore_dirs))) {
				if (_log.logs(Logger.info)) {
					_log.info("Search in " A_LoopFileName)
				}
				fn_list := Mack.collect_filenames(A_LoopFileFullPath, fn_list)
			} else if (!InStr(A_LoopFileAttrib, "D")
					&& (!Mack.option.g || (Mack.option.g && RegExMatch(A_LoopFileName, Mack.option.file_pattern)))
					&& (Mack.option.match_type = "" || RegExMatch(A_LoopFileName, Mack.option.match_type))
					&& (Mack.option.match_type_ignore = "" || !RegExMatch(A_LoopFileName, Mack.option.match_type_ignore))
					&& (Mack.option.match_ignore_files = "" || !RegExMatch(A_LoopFileName, Mack.option.match_ignore_files))) {
				fn_list.push(A_LoopFileFullPath)
				if (_log.logs(Logger.info)) {
					_log.info("Add " A_LoopFileName)
				}
			} else {
				if (_log.logs(Logger.detail)) {
					_log.detail("Discard " A_LoopFileName)
				}
			}
		}

		if (_log.logs(Logger.output)) {
			_log.output("fn_list: Collected " fn_list.maxIndex() " file(s)")
			_log.all("fn_list:`n" LoggingHelper.dump(fn_list))
		}

		return _log.exit(fn_list)
	}

	addOrReturnListEntry(listName, entryToAdd) {
		pattern := Mack.convertFileTypePatternToRegularExpression(entryToAdd)
		try {
			return Mack.positionInList(listName, pattern)
		} catch {
			return Mack.option[listName].push(pattern)
		}
	}

	removeListEntry(listName, entryToRemove) {
		pattern := Mack.convertFileTypePatternToRegularExpression(entryToRemove)
		return Mack.option[listName].removeAt(Mack.positionInList(listName
			, pattern))
	}

	positionInList(listName, lookForEntry) {
		for listIndex, listContent in Mack.option[listName] {
			if (listContent = lookForEntry)
				return listIndex
		}

		throw Exception("EntryNotInList:" listName "[" lookForEntry "]"
			, A_ThisFunc)
	}

	regularExpressionOfTypeList() {
		typeListAsRegularExpression := "("
		for fileType, filePattern in Mack.option.types {
			typeListAsRegularExpression .= (A_Index = 1 ? "" : "|") fileType
		}
		typeListAsRegularExpression .= ")"

		return typeListAsRegularExpression
	}

	convertFileTypePatternToRegularExpression(filePattern) {
		convertedEscapeChars := RegExReplace(filePattern, "[+.\\\[\]\{\}\(\)]"
			, "\$0")
		convertedQuestionMarks := StrReplace(convertedEscapeChars, "?", ".")
		convertedAsterisks := StrReplace(convertedQuestionMarks, "*", ".*?")

		if (InStr(convertedAsterisks, " "))
			convertedAsterisks := "(" RegExReplace(convertedAsterisks, "\s+"
				, "|") ")"
		
		return convertedAsterisks
	}

	convertArrayToRegularExpression(inputArray) {
		regularExpression := ""
		for i, item in inputArray {
			regularExpression .= (i > 1 ? "|" : "") item
		}
		if (regularExpression <> "") {
			regularExpression := "S)^(" regularExpression ")$"
		}

		return regularExpression
	}

	/*
	 * Method:	do_modelines
	 *			Check if modelines are available to set the tabsize.
	 *
	 * Parameter:
	 *			file - FileObject to examine.
	 *
	 * Returns:
	 *			Number of spaces according to the tabsize of a modeline; otherwise default.
	 *
	 * Remarks:
	 *			The first Mack.Option.modelines will be checked for a Mack.Option.modeline_pattern. 
	 *			If no one is found, the last 100*Mack.Option.modlines bytes of the file will be checked for Mack.Option.modeline_pattern.
	 *			The tabsize will be stored in the Mack.Option.tabsize property.
	 */
	do_modelines(file) {
		_log := new Logger("class." A_ThisFunc)

		if (_log.logs(Logger.input)) {
			_log.input("file", file)
			if (_log.logs(Logger.finest)) {
				_log.finest("Mack.option.tabstop", Mack.option.tabstop)
				_log.finest("Mack.option.modelines", Mack.option.modelines)
				_log.finest("Mack.option.modeline_pattern", Mack.option.modeline_pattern)
				if (_log.logs(Logger.all)) {
					_log.all("Mack.option.modeline_pattern:`n" LoggingHelper.dump(Mack.option.modeline_pattern))
				}
				_log.finest("Mack.option.modeline_expr", Mack.option.modeline_expr)
			}
		}

		modeline_found := false
		if (Mack.option.modelines) {
			loop % Mack.option.modelines {
				line := file.readLine()
				try {
					if (RegExMatch(line, Mack.option.modeline_expr, $)) {
						
						loop % Mack.option.modeline_pattern.maxIndex() {
							tabsize := $tabstop
						}
						if (_log.logs(Logger.detail)) {
							_log.detail("Header modeline found #" A_Index " in " line ": " tabsize)
						}
						modeline_found := true
						break
					}
				} catch _ex {								; NOTEST: Would happen, if an invalid regex for modeline patterns is provided.
					_log.severe(LoggingHelper.dump(_ex))	; NOTEST: Will not be tested, because the pattern is hardcoded.
				}
			}
			if (!modeline_found) {
				search_size := Mack.option.modelines * 100
				if (file.length > search_size) {
					file.seek(-search_size, 2)
					tail_content := file.read(search_size)
				} else {
					file.seek(0)
					tail_content := file.read(search_size := file.length)
				}
				lines := StrSplit(tail_content, "`n", "`r")
				if (_log.logs(Logger.finest)) {
					_log.finest("search_size", search_size)
					_log.finest("lines:`n" LoggingHelper.Dump(lines))
				}
				loop % Mack.Option.modelines {
					if (RegExMatch(lines[lines.MaxIndex() - A_Index + 1], Mack.Option.modeline_expr, $)) {
						tabsize := $tabstop
						loop % Mack.Option.modeline_pattern.MaxIndex() {
							tabsize .= $tabstop%A_Index%
						}
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

		if (!modeline_found) {
			if (_log.Logs(Logger.Finest)) {
				_log.Finest("Mack.Option.tabstop", Mack.Option.tabstop)
			}
			tabsize := Mack.Option.tabstop
		}

		if (_log.Logs(Logger.Finest)) {
			_log.Finest("tabsize", tabsize)
		}

		return _log.Exit(SubStr("         ", 1, tabsize))
	}

	/*
	 * Method:	test
	 *			Search a text for a regualar pattern.
	 *
	 * Parameter:
	 *			haystack - The text to examine.
	 *			regex_opts - Regex options to change behaviour of the regex parser.
	 *			found - Indicates if the pattern was found within haystack.
	 *			first_match_column - Indicates the column where the pattern matches for the first time.
	 *
	 * Returns:
	 *			A list of "parts" representing the result.
	 */
	test(ByRef haystack, regex_opts, ByRef found := 0, ByRef first_match_column := 0) {
		_log := new Logger("class." A_ThisFunc)

		if (_log.Logs(Logger.Input)) {
			_log.Input("haystack", haystack)
			_log.Input("regex_opts", regex_opts)
			_log.Input("found", found)
			_log.Input("Mack.Option.pattern", Mack.Option.pattern)
			_log.Input("Mack.Option.column", Mack.Option.column)
			_log.Input("Mack.Option.color_match", Mack.Option.color_match)
			_log.Finest("Mack.Option.output", Mack.Option.output)
		}

		search_at := 1
		parts := []
		haystack := RegExReplace(haystack, "`n$", "", 1)
		loop {
			found_at := RegExMatch(haystack, regex_opts "S)" Mack.Option.pattern, $, search_at)
			if (_log.Logs(Logger.Finest)) {
				_log.Finest("found_at", found_at)
				_log.Finest("$", $)
			}
			if (found_at > 0) {
				if (A_Index = 1 && Mack.Option.column) {
					first_match_column := found_at
				}

				if (Mack.Option.output) {
					pattern := Mack.Option.output
					while (RegExMatch(pattern, "\$(\d+)", arg_no)) {
						if (arg_no1 = 0) {
							arg_no1 := ""
						}
						pattern := RegExReplace(pattern, "\Q" arg_no "\E", $%arg_no1%)
					}
					found := true
					parts.Push(pattern)
					break
				} else {
					found++
					if (found_at > 1) {
						parts.Push(SubStr(haystack, search_at, found_at - search_at))
					}
					if (Mack.Option.color) {
						parts.Push(Ansi.SetGraphic(Mack.Option.color_match) $ Ansi.Reset())
					} else {
						parts.Push($)
					}
					search_at := found_at + StrLen($)
				}
			} else if (found > 0) {
				parts.Push(SubStr(haystack, search_at))
			}
		} until (found_at = 0)

		if (_log.Logs(Logger.Output)) {
			_log.Output("found", found)
			_log.Output("first_match_column", first_match_column)
			if (_log.Logs(Logger.ALL)) {
				_log.ALL("parts:`n" LoggingHelper.Dump(parts))
			}
		}

		return _log.Exit(parts)
	}

	/*
	 * Method:	output
	 *			Assemble the output, by using the given format options.
	 *
	 * Parameter:
	 *			file_name - Name of the file.
	 *			line_no	- Line number.
	 *			column_no - Column number.
	 *			hit_n - nth hit within the line.
	 *			before_ctx - A list of context lines before the matched text.
	 *			after_ctx - A list of context lines after the matched text.
	 *			parts - A list of matching/non-matching text and escape sequences.
	 *
	 * Returns:
	 *			- true to continue with normal processing.
	 *			- false to stop processing of the current file.
	 *			- -1 to stop processing of the current file and any following files.
	 */
	output(file_name, line_no, column_no, hit_n, before_ctx, after_ctx, parts) {
		_log := new Logger("class." A_ThisFunc)

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


		if (hit_n = 1 && (Mack.Option.g || Mack.Option.files_w_matches)) {
			if (!Mack.Option.c) {
				if (Mack.Option.color) {
					Mack.process_line(Ansi.SetGraphic(Mack.Option.color_filename) file_name Ansi.Reset())
				} else {
					Mack.process_line(file_name)
				}
				return _log.Exit(false)	
			}
		} else {
			if (hit_n = 1 && Mack.Option.group) {
				if (!Mack.First_Call) {
					Mack.process_line(" ")
				} else {
					Mack.First_Call := false
				}
				if (Mack.Option.color) {
					Mack.process_line(Ansi.SetGraphic(Mack.Option.color_filename) file_name Ansi.Reset())
				} else {
					Mack.process_line(file_name)
				}
			}
			if (Mack.Option.color) {
				line_file_name := Ansi.SetGraphic(Mack.Option.color_filename) file_name ":" Ansi.Reset()
			} else {
				line_file_name := file_name ":"
			}

			if (after_ctx.Length() > 0) {
				loop % after_ctx.Length() {
					Mack.process_line(after_ctx.Pop())
				}
			}

			if (before_ctx.Length() > 0) {
				loop % before_ctx.Length() {
					Mack.process_line(before_ctx.Pop())
				}
			}

			if (column_no = 0) {
				if (!Mack.Option.files_w_matches) {
					if (Mack.Option.color) {
						Mack.process_line((Mack.Option.filename ? line_file_name : "")
						. (Mack.Option.line ? Ansi.SetGraphic(Mack.Option.color_line_no) A_Index Ansi.Reset() ":" : "")
						. Mack.arrayOrStringToString(parts) Ansi.Reset() Ansi.EraseLine())
					} else {
						Mack.process_line((Mack.Option.filename ? line_file_name : "")
						. (Mack.Option.line ? A_Index ":" : "") Mack.arrayOrStringToString(parts))
					}
				}
			} else {
				if (!Mack.Option.files_w_matches) {
					if (Mack.Option.color) {
						Mack.process_line((Mack.Option.filename ? line_file_name : "")
						. (Mack.Option.line ? Ansi.SetGraphic(Mack.Option.color_line_no) A_Index Ansi.Reset() ":" : "")
						. Ansi.SetGraphic(Mack.Option.color_line_no) column_no Ansi.Reset() ":" Mack.arrayOrStringToString(parts)
						. Ansi.Reset() Ansi.EraseLine())
					} else {
						Mack.process_line((Mack.Option.filename ? line_file_name : "")
						. (Mack.Option.line ? A_Index ":" : "") column_no ":" Mack.arrayOrStringToString(parts))
					}
				}
			}
		}

		if (Mack.Option.1) {
			if (Mack.Option.color) {
				Mack.process_line(Ansi.SetGraphic(Mack.Option.color_filename) file_name Ansi.Reset())
			} else {
				Mack.process_line(file_name)
			}

			Ansi.Flush()
			Ansi.FlushInput()

			return _log.Exit(-1)
		}

		return _log.Exit(true)
	}

	/*
	 * Method:	process_line
	 *			Prepare text for output.
	 *
	 * Parameters:
	 *			line - The text to display.
	 *
	 * Remarks:
	 *			If context is printed before or after the found text, 
	 *			"..." will displayed as an block-separator if the lines are not 
	 *			in sequence.
	 *
	 * Returns:
	 *			The prepard text, written thru the pager.
	 */
	process_line(line) {
		_log := new Logger("class." A_ThisFunc)

		static last_line_no := 0

		if (_log.Logs(Logger.Input)) {
			_log.Input("line", line)
		}

		if (Mack.Option.A || Mack.Option.B) {
			if (RegExMatch(Ansi.PlainStr(line), "^(?P<line_no>\d+)", $)) {
				if ($line_no - last_line_no > 1) {
					Pager.writeHardWrapped("...")
				}
			}
			last_line_no := $line_no
		}

		return _log.Exit(Pager.writeHardWrapped(Ansi.Readable(line, Mack.Option.color)))
	}

	arrayOrStringToString(inputValue) {
		if (inputValue.maxIndex()) {
			return Arrays.ToString(inputValue, "")
		}

		return inputValue 
	}

	/*
	 * Method:	search_for_pattern
	 *			Search for pattern and process output of the results.
	 *			
	 * Parameter:
	 *			file_name - File name
	 *			regex_opts - Options for RegEx parser
	 */
	search_for_pattern(file_name, regex_opts = "") {
		_log := new Logger("class." A_ThisFunc)

		if (_log.Logs(Logger.INPUT)) {
			_log.Input("file_name", file_name)
			_log.Input("regex_opts", regex_opts)
			if (_log.Logs(Logger.FINEST)) {
				_log.Finest("Mack.Option.pattern", Mack.Option.pattern)
				_log.Finest("Mack.Option.g", Mack.Option.g)
				_log.Finest("Mack.Option.group", Mack.Option.group)
				_log.Finest("Mack.Option.passthru", Mack.Option.passthru)
				_log.Finest("Mack.Option.A", Mack.Option.A)
				_log.Finest("Mack.Option.B", Mack.Option.B)
			}
		}

		before_context := new Queue(Mack.Option.B)
		after_context := new Queue(Mack.Option.A)

		cont := true

		try {
			f := FileOpen(file_name, "r `n")
			if (!f) {
				_log.Severe("Could not open file " file_name)	; NOTEST: Difficult to test. The file would have to be deleted after collecting filename
			} else {
				hit_n := 0
				tabstops := Mack.do_modelines(f)
				last_col := 0
				while (!f.AtEOF) {
					line := RegExReplace(f.ReadLine(), "\t", tabstops)

					parts := Mack.test(line, regex_opts, found := 0, column := 0)
					last_col := (column = 0 ? last_col : column)

					if (found && _log.Logs(Logger.Finest)) {
						_log.Finest("Found pattern: " line)
						_log.Finest("last_col", last_col)
						_log.Finest("parts:`n" LoggingHelper.Dump(parts))
					}

					if (found && Mack.Option.files_wo_matches) {
						; if the line matches but only files w/o matches should be listed: skip
						hit_n++
						break
					} else if (found && !Mack.Option.v) {
						; if the line matches and invert-match is disabled: output results
						hit_n++
						cont := Mack.output(file_name, A_Index, column, hit_n, before_context, after_context, parts)
						if (cont != true) {
							break
						}
					} else if ((!found && Mack.Option.v) || Mack.Option.passthru) {
						; if the line doesn't match, but invert-match or passthru is enabled: output results
						hit_n++
						cont := Mack.output(file_name, A_Index, column, hit_n, "", "", line)
						if (cont != true) {
							break
						}
					} else {
						if (Mack.Option.A > 0 && after_context.Length() < Mack.Option.A && hit_n) {
							; if after-context is enabled and the context-buffer isn't full and we had a hit before: Add line to context-buffer (for colored or uncolored output)
							if (Mack.Option.color) {
								after_context.Push(a_line := Ansi.SetGraphic(Mack.Option.color_context) (Mack.Option.filename ? file_name ":" : "") A_Index ":" (last_col = 0 ? "" : " ".Repeat(StrLen(last_col)) " ") line Ansi.Reset())
							} else {
								after_context.Push(a_line := "+" (Mack.Option.filename ? file_name ":" : "") A_Index ":" (last_col = 0 ? "" : " ".Repeat(StrLen(last_col))) line)
							}
							if (_log.Logs(Logger.Finest)) {
								_log.Finest("Pushing line to after-context: ", a_line)
								if (_log.Logs(Logger.All)) {
									_log.All("after_context:`n" LoggingHelper.Dump(after_context))
								}
							}
						} else if (Mack.Option.B > 0) {
							; if before-context is enabled, collect the lines to the buffer (colored or uncolored) to have it ready to display if a following line is matching
							if (Mack.Option.color) {
								before_context.Push(b_line := Ansi.SetGraphic(Mack.Option.color_context) (Mack.Option.filename ? file_name ":" : "") A_Index ":" (last_col = 0 ? "" : " ".Repeat(StrLen(last_col)) " ") line Ansi.Reset())	
							} else {
								before_context.Push(b_line := "-" (Mack.Option.filename ? file_name ":" : "") A_Index ":" (last_col = 0 ? "" : " ".Repeat(StrLen(last_col))) line)	
							}
							if (_log.Logs(Logger.Finest)) {
								_log.Finest("Pushing line to before-context: ", b_line)
								if (_log.Logs(Logger.All)) {
									_log.All("before_context:`n" LoggingHelper.Dump(before_context))
								}
							}
						}
					}
				}
			}
			if (hit_n = 0 && Mack.Option.files_wo_matches) {
				; if the line doen't match but files w/o matches should be displayed: Process output
				if (Mack.Option.color) {
					Mack.process_line(Ansi.SetGraphic(Mack.Option.color_filename) file_name Ansi.Reset())
				} else if (!Mack.Option.c) {
					Mack.process_line(file_name)
				}
				G_file_count++
			}
		} finally {
			if (f) {
				f.Close()
			}
			; Are there after-context-lines to print?
			if (after_context.Length() > 0) {
				loop % after_context.Length() {
					Mack.process_line(after_context.Pop())
				}
			}
			; Print hit count?
			if (Mack.Option.c && hit_n > 0) {
				if (!Mack.Option.files_w_matches) {
					if (Mack.Option.color) {
						Mack.process_line(Ansi.SetGraphic(Mack.Option.color_filename) hit_n " match(es)" Ansi.Reset())
					} else {
						Mack.process_line(hit_n " match(es)")
					}
				} else {
					Mack.process_line(Ansi.SetGraphic(Mack.Option.color_filename) file_name ":" hit_n Ansi.Reset())
				}
				G_file_count++
				G_hit_count += hit_n
			}
		}

		return _log.Exit(cont)
	}

	/*
	 * Method:	cli
	 *			Create the command line interface.
	 *
	 * Returns:
	 *			OptParser object.
	 */
	cli() {
		_log := new Logger("class." A_ThisFunc)

		op := new OptParser(["mack [options] [--] <pattern> [file | directory]..."
						   , "mack -f [options] [--] [directory]..."]
						   , OptParser.PARSER_ALLOW_DASHED_ARGS, "MACK_OPTIONS")
		op.Add(new OptParser.Group("Searching:"))
		op.Add(new OptParser.Boolean("i", "ignore-case", Mack.Option, "i", "Ignore case distinctions in pattern"))
		op.Add(new OptParser.Boolean("v", "invert-match", Mack.Option, "v", "Select non-matching lines"))
		op.Add(new OptParser.Boolean("w", "word-regexp", Mack.Option, "w", "Force pattern to match only whole words"))
		op.Add(new OptParser.Boolean("Q", "literal", Mack.Option, "Q", "Quote all metacharacters; pattern is literal"))
		op.Add(new OptParser.Group("`nSearch output:"))
		op.Add(new OptParser.Boolean("l", "files-with-matches", Mack.Option, "files_w_matches", "Only print filenames containing matches"))
		op.Add(new OptParser.Boolean("L", "files-without-matches", Mack.Option, "files_wo_matches", "Only print filenames with no matches"))
		op.Add(new OptParser.String(0, "output", Mack.Option, "output", "EXPR", "Output the evaluation of EXPR for each line (turns of text highlighting)", OptParser.OPT_ARG))
		op.Add(new OptParser.Boolean("o", "", Mack.Option, "o", "Show only the part of a line matching PATTERN. Same as --output $0"))
		op.Add(new OptParser.Boolean(0, "passthru", Mack.Option, "passthru", "Print all lines, whether matching or not"))
		op.Add(new OptParser.Boolean("1", "", Mack.Option, "1", "Stop searching after one match of any kind"))
		op.Add(new OptParser.Boolean("c", "count", Mack.Option, "c", "Show number of lines matching per file"))
		op.Add(new OptParser.Boolean(0, "filename", Mack.Option, "filename", "Suppress prefixing filename on output (default)", OptParser.OPT_NEG|OptParser.OPT_NEG_USAGE))
		op.Add(new OptParser.Boolean(0, "line", Mack.Option, "line", "Show the line number of the match", OptParser.OPT_NEG|OptParser.OPT_NEG_USAGE, Mack.Option.line))
		op.Add(new OptParser.Boolean(0, "column", Mack.Option, "column", "Show the column number of the first match", OptParser.OPT_NEG|OptParser.OPT_NEG_USAGE))
		op.Add(new OptParser.String("A", "after-context", Mack.Option, "A", "NUM", "Print NUM lines of trailing context after matching lines", OptParser.OPT_ARG))
		op.Add(new OptParser.String("B", "before-context", Mack.Option, "B", "NUM", "Print NUM lines of leading context before matching lines", OptParser.OPT_ARG))
		op.Add(new OptParser.String("C", "context", Mack.Option, "context", "NUM", "Print NUM (default 2) lines of output context", OptParser.OPT_OPTARG, Mack.Option.context))
		op.Add(new OptParser.String(0, "tabstop", Mack.Option, "tabstop", "size", "Calculate tabstops with width of size (default 8)",,, Mack.Option.tabstop))
		op.Add(new OptParser.String(0, "modelines", Mack.Option, "modelines", "lines", "Search modelines (default 5) for tabstop info. Set to 0 to ignore modelines", OptParser.OPT_OPTARG,, 5, Mack.Option.modelines))
		op.Add(new OptParser.Group("`nFile presentation:"))
		op.Add(new OptParser.Boolean(0, "pager", Mack.Option, "pager", "Send output through a pager (default)", OptParser.OPT_NEG, Mack.Option.pager))
		op.Add(new OptParser.Boolean(0, "group", Mack.Option, "group", "Print a filename heading above each file's results (default: on when used interactively)", OptParser.OPT_NEG, true))
		op.Add(new OptParser.Boolean(0, "color", Mack.Option, "color", "Highlight the matching text (default: on)", OptParser.OPT_NEG, Mack.Option.color))
		op.Add(new OptParser.String(0, "color-filename", Mack.Option, "color_filename", "color", "", OptParser.OPT_ARG, Mack.Option.color_filename, Mack.Option.color_filename))
		op.Add(new OptParser.String(0, "color-match", Mack.Option, "color_match",  "color", "", OptParser.OPT_ARG, Mack.Option.color_match, Mack.Option.color_match))
		op.Add(new OptParser.String(0, "color-line-no", Mack.Option, "color_line_no", "color", "Set the color for filenames, matches, and line numbers as ANSI color attributes (e.g. ""7;37"")", OptParser.OPT_ARG, Mack.Option.color_line_no, Mack.Option.color_line_no))
		op.Add(new OptParser.Group("`nFile finding:"))
		op.Add(new OptParser.Boolean("f", "", Mack.Option, "f", "Only print the files selected, without searching. The pattern must not be specified"))
		op.Add(new OptParser.Boolean("g", "", Mack.Option, "g", "Same as -f, but only select files matching pattern"))
		op.Add(new OptParser.Boolean(0, "sort-files", Mack.Option, "sort_files", "Sort the found files lexically"))
		op.Add(new OptParser.String(0, "files-from", Mack.Option, "files_from", "FILE", "Read the list of files to search from FILE", OptParser.OPT_ARG)) ; TODO: Implement --files-from option
		op.Add(new OptParser.Boolean("x", "", Mack.Option, "x", "Read the list of files to search from STDIN")) ; TODO Implement -x option
		op.Add(new OptParser.Group("`nFile inclusion/exclusion:"))
		op.Add(new OptParser.Callback(0, "ignore-dir"
			, Mack.option, "ignore_dir"
			, "maintainDirectoriesToIgnore", "name"
			, "Add/remove directory from list of ignored dirs"
			, OptParser.OPT_ARG | OptParser.OPT_NEG))
		op.Add(new OptParser.Callback(0, "ignore-file"
			, Mack.option, "ignore_file"
			, "maintainFilesToIgnore", "filter"
			, "Add filter for ignoring files"
			, OptParser.OPT_ARG | OptParser.OPT_NEG))
		op.Add(new OptParser.Boolean("r", "recurse", Mack.Option, "r", "Recurse into subdirectories (default: on)", OptParser.OPT_NEG, true))
		op.Add(new OptParser.Boolean("k", "known-types", Mack.Option, "k", "Include only files of types that are recognized"))
		op.Add(new OptParser.Callback(0, "type"
			, Mack.Option, "type_inex" ; CAVEAT: type_inex will never be set due to the callback function... that's a bit confusing!?!
			, "maintainTypeFilter", "X"
			, "Include/exclude X files"
			, OptParser.OPT_ARG | OptParser.OPT_OPTARG
			| OptParser.OPT_NEG | OptParser.OPT_NEG_USAGE))
		op.Add(new OptParser.Group("`nFile type specification:"))
		op.Add(new OptParser.Callback(0, "type-set", Mack.Option, "type_set", "addFileTypePattern", "X:FILTER[+FILTER...]", "Files with given FILTER are recognized of type X. This replaces an existing defintion.", OptParser.OPT_ARG))
		op.Add(new OptParser.Callback(0, "type-add", Mack.Option, "type_add", "addNewFileType", "X:FILTER[+FILTER...]", "Files with given FILTER are recognized of type X", OptParser.OPT_ARG))
		op.Add(new OptParser.Callback(0, "type-del", Mack.Option, "type_del", "removeFileType", "X", "Remove all filters associated with X", OptParser.OPT_ARG))
		op.Add(new OptParser.Group("`nMiscellaneous:"))
		op.Add(new OptParser.Boolean(0, "env", Mack.Option, "__env_dummy", "Ignore environment variable MACK_OPTIONS", OptParser.OPT_NEG|OptParser.OPT_NEG_USAGE))
		op.Add(new OptParser.Boolean("h", "help", Mack.Option, "h", "This help", OptParser.OPT_HIDDEN))
		op.Add(new OptParser.Boolean(0, "version"
			, Mack.option, "version"
			, "Display version info"))
		op.Add(new OptParser.Boolean(0, "help-types"
			, Mack.option, "ht"
			, "Display all known types"))
		op.Add(Mack.Sel_Types_Option := new OptParser.Generic(Mack.Option.types_expr, Mack.Option, "sel_types", OptParser.OPT_MULTIPLE|OptParser.OPT_NEG))

		return _log.Exit(op)
	}

	run(args) {
		_log := new Logger("class." A_ThisFunc)

		if (_log.Logs(Logger.Input)) {
			_log.Input("args:`n" LoggingHelper.Dump(args))
		}

		Mack.First_Call := true
		Mack.setDefaults()

		RC := 0

		try {
			op := Mack.cli()
			args := op.Parse(args)
			if (_log.Logs(Logger.Finest)) {
				_log.Finest("args:`n" LoggingHelper.Dump(args))
				_log.All("Mack.Option:`n" LoggingHelper.Dump(Mack.Option))
			}

			if (Mack.Option.k) {
				for filetype, filter in Mack.Option.types {
					maintainTypeFilter(filetype)
				}
			}

			if (Mack.Option.sel_types) {
				for i, filetype in Mack.Option.sel_types {
					if (SubStr(filetype, 1, 1) = "!") {
						maintainTypeFilter(SubStr(filetype, 2), true)
					} else {
						maintainTypeFilter(filetype)
					}
				}
			}

			Mack.Option.match_ignore_dirs := Mack.convertArrayToRegularExpression(Mack.Option.ignore_dirs)
			Mack.Option.match_ignore_files := Mack.convertArrayToRegularExpression(Mack.Option.ignore_files)
			Mack.Option.match_type := Mack.convertArrayToRegularExpression(Mack.Option.type)
			Mack.Option.match_type_ignore := Mack.convertArrayToRegularExpression(Mack.Option.type_ignore)

			if (Mack.Option.A = "") {
				Mack.Option.A := 0
			}

			if (Mack.Option.B = "") {
				Mack.Option.B := 0
			}

			if (Mack.Option.context > 0 && Mack.Option.A = 0) {
				Mack.Option.A := Mack.Option.context
			}

			if (Mack.Option.context > 0 && Mack.Option.B = 0) {
				Mack.Option.B := Mack.Option.context
			}

			Pager.enablePager := Mack.Option.pager

			if (Mack.Option.o) {
				Mack.Option.color_match := Ansi.Reset()
				Mack.Option.output := "$0"
			}

			if (_log.Logs(Logger.FINEST)) {
				_log.Info("Options prepared")
				_log.Finest("Mack.Option:`n" LoggingHelper.Dump(Mack.Option))
			}
			if (Mack.Option.version) {
				Ansi.WriteLine(Mack.getVersionInfo())
			} else if (Mack.Option.h) {
				Ansi.WriteLine(op.Usage())
			} else if (Mack.option.ht) {
				Ansi.Write(Mack.printKnownFileTypes())
			} else {
				if (!Mack.Option.f) {
					Mack.Option.pattern := Arrays.Shift(args)
					if (_log.Logs(Logger.FINEST)) {
						_log.Finest("Mack.Option.pattern", Mack.Option.pattern)
					}
					if (Mack.Option.pattern = "") {
						throw Exception("Provide a search pattern")
					}
					if (Mack.Option.Q) {
						Mack.Option.pattern := "\Q" Mack.Option.pattern "\E"
					}
					if (Mack.Option.w) {
						Mack.Option.pattern := "\b" Mack.Option.pattern "\b"
					}
					if (Mack.Option.g) {
						Mack.Option.file_pattern := Mack.Option.pattern
					}
					if (_log.Logs(Logger.FINEST)) {
						_log.Finest("Mack.Option.file_pattern", Mack.Option.file_pattern)
					}
				}
				file_list := Mack.determine_files(args)
				if (Mack.Option.f || Mack.Option.g) {
					for _i, file_entry in file_list {
						Pager.writeWordWrapped(file_entry)
					}
				} else {
					Console.RefreshBufferInfo()
					x := 0
					for _i, file_entry in file_list {
						x := Mack.search_for_pattern(file_entry, Mack.Option.i ? "i" : "")
						if (x = -1) {
							return _log.Exit(result)
						}
					}
				}
			}
		} catch _ex {
			Ansi.WriteLine(_ex.Message)
			Ansi.WriteLine(op.Usage())
			RC := _ex.Extra
		}

		return _log.Exit(result)
	}
}

#NoEnv						; NOTEST-BEGIN
#NoTrayIcon
#SingleInstance off
SetBatchLines -1

#Include <logging>
#Include <ansi>
#Include c:\work\ahk\projects\lib2\optparser.ahk
#Include <system>
#Include <string>
#Include <datatable>
#Include <arrays>
#Include <queue>
#include <pager>
#Include *i %A_ScriptDir%\.versioninfo

main:
	_main := new Logger("app.mack.main")

	global G_wt

	WinGetTitle G_wt, A

	RC := Mack.run(System.vArgs)
	Ansi.FlushInput()

exitapp _main.Exit(RC)		; NOTEST-END

	
maintainDirectoriesToIgnore(directoryName, noOptGiven = "") {
	if (noOptGiven) {
		Mack.removeListEntry("ignore_dirs", directoryName)
	} else {
		Mack.addOrReturnListEntry("ignore_dirs", directoryName)
	}
}

maintainFilesToIgnore(fileName, noOptGiven = "") {
	if (noOptGiven) {
		index := Mack.removeListEntry("ignore_files", fileName)
	} else {
		index := Mack.addOrReturnListEntry("ignore_files", fileName)
	}

	return index
}

removeFileType(fileType) {
	currentValue := Mack.option.types.delete(fileType)
	if (currentValue = "")
		throw Exception("InvalidFiletype:" fileType)

	Mack.Option.regex_of_types := Mack.regularExpressionOfTypeList()
	Mack.Sel_Types_Option.stExpr := Mack.Option.regex_of_types

	return currentValue
}

addFileTypePattern(fileTypeFilter) {
	if (!RegExMatch(fileTypeFilter, "([a-z]+):(.+)", $)) {
		throw Exception("InvalidFiletypeFilter:" fileTypeFilter)
	}

	if (Mack.option.types[$1] = "") {
		throw Exception("UnknownFiletype:" $1)
	}

	Mack.Option.types[$1] .= " " StrReplace($2, "+", " ")
}

addNewFileType(fileTypeFilter) {
	if (!RegExMatch(fileTypeFilter, "([a-z]+):(.+)", $)) {
		throw Exception("InvalidFiletypeFilter:" fileTypeFilter)
	}

	if (Mack.Option.types[$1] <> "") {
		throw Exception("FiletypeAlreadyDefined:" $1)
	}

	Mack.Option.types[$1] := StrReplace($2, "+", " ")
	Mack.Option.regex_of_types := Mack.regularExpressionOfTypeList()
	Mack.Sel_Types_Option.stExpr := Mack.Option.regex_of_types
}

maintainTypeFilter(filetype, noOptGiven = "") {
	if (Mack.Option.types[filetype] = "") {
		throw Exception("UnknownFiletype:" filetype)
	}

	if (noOptGiven) {
		index := Mack.addOrReturnListEntry("type_ignore"
			, Mack.option.types[filetype])
	} else {
		index := Mack.addOrReturnListEntry("type"
			, Mack.option.types[filetype])
	}

	return index
}
; vim: ts=4:sts=4:sw=4:tw=0:noet
