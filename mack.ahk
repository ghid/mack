; ahk: console
#Include <PrintLineData>

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
		Mack.option.modeline_expr := "J)"
			. Arrays.toString(Mack.option.modeline_pattern, "|")
	}

	getVersionInfo() {
		global G_VERSION_INFO
		return G_VERSION_INFO.NAME "/" G_VERSION_INFO.ARCH
			. "-b" G_VERSION_INFO.BUILD
			. " Copyright (C) 2014-2018 K.-P. Schreiner`n"
	}

	printKnownFileTypes() {
		dt := new DataTable()
		dt.defineColumn(new DataTable.column(
			, DataTable.COL_RESIZE_USE_LARGEST_DATA))
		dt.defineColumn(new DataTable.column.wrapped(50))

		for filetype, filter in Mack.option.types {
			dt.addData([filetype, filter])
		}

		return dt.getTableAsString()
	}

	determineFilesForSearch(args) {
		if (args.maxIndex() = "") {
			file_list := Mack.collectFileNames(".\*.*")
		} else {
			loop % args.maxIndex() {
				file_pattern := Mack.refineFileOrPathPattern(args[A_Index])
				file_list := Mack.collectFileNames(file_pattern
					, (A_Index > 1 ? file_list : ""))
			}
		}

		if (Mack.option.sort_files && file_list.maxIndex() <> "") {
			file_list := Mack.sortFileList(file_list)
		}

		return file_list
	}

	sortFileList(fileList) {
		fileListAsString := ""
		numberOfEntries := fileList.maxIndex()
		loop % numberOfEntries {
			fileListAsString .= fileList[A_Index]
				. (A_Index < numberOfEntries ? "`n" : "")
		}
		Sort fileListAsString, C
		sortedFileList := StrSplit(fileListAsString, "`n")

		return sortedFileList
	}

	refineFileOrPathPattern(fileOrPathPattern) {
		refinedPathPattern := fileOrPathPattern
		isDirectory := InStr(FileExist(fileOrPathPattern), "D")
		if (isDirectory) {
			RegExMatch(fileOrPathPattern
				, "(?P<Backslash>\\)?(?P<Wildcard>\*\.?\*?)?$", hasMatching)
			if (!hasMatchingBackslash)
				refinedPathPattern .= "\"
			if (!hasMatchingWildcard)
				refinedPathPattern .= "*.*"
		}

		return refinedPathPattern
	}

	collectFileNames(directoryName, listOfFileNames = "") {
		if (!IsObject(listOfFileNames)) {
			listOfFileNames := []
		}

		directoryName := Mack.refineFileOrPathPattern(directoryName)
		loop Files, %directoryName%, DF	; NOWARN
		{
			if (Mack.isMatchingDirectory(A_LoopFileName, A_LoopFileAttrib)) {
				listOfFileNames := Mack.collectFileNames(A_LoopFileFullPath
					, listOfFileNames)
			} else if (Mack.isMatchingFile(A_LoopFileName, A_LoopFileAttrib)) {
				listOfFileNames.push(A_LoopFileFullPath)
			}
		}

		return listOfFileNames
	}

	isMatchingDirectory(directoryName, directoryAttributes) {
		return (InStr(directoryAttributes, "D")
			&& Mack.option.r
			&& (Mack.option.match_ignore_dirs = ""
			|| !RegExMatch(directoryName, Mack.option.match_ignore_dirs)))
	}

	isMatchingFile(fileName, fileAttributes) {
		return (!InStr(fileAttributes, "D")
			&& (!Mack.option.g
				|| (Mack.option.g && RegExMatch(fileName
					, Mack.option.file_pattern)))
			&& (Mack.option.match_type = ""
				|| RegExMatch(fileName, Mack.option.match_type))
			&& (Mack.option.match_type_ignore = ""
				|| !RegExMatch(fileName, Mack.option.match_type_ignore))
			&& (Mack.option.match_ignore_files = ""
				|| !RegExMatch(fileName, Mack.option.match_ignore_files)))
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

	setTabstop(file) {
		tabstop := 0
		if (Mack.option.modelines) {
			tabstop := Mack.fromModelineAtTopOfFile(file)
			if (!tabstop)
				tabstop := Mack.fromModelineAtBottomOfFile(file)
			file.seek(0)
		}

		return " ".repeat(tabstop ? tabstop : Mack.option.tabstop)
	}

	fromModelineAtTopOfFile(file) {
		tabstop := 0
		while (tabstop == 0 && A_Index <= Mack.option.modelines) {
			try {
				line := file.readLine()
				if (RegExMatch(line, Mack.option.modeline_expr, $))
					tabstop := $tabstop
			} catch ex {
				OutputDebug % ex.What ": " ex.Message		; NOTEST: Will not be tested, because the pattern is hardcoded.
				throw ex									; NOTEST
			}
		}
		return tabstop
	}

	fromModelineAtBottomOfFile(file) {
		tabstop := 0
		readAt := file.length
		while (tabstop == 0 && A_Index <= Mack.option.modelines) {
			try {
				line := Mack.readLineFromBottomOfFile(file, readAt)
				if (RegExMatch(line, Mack.option.modeline_expr, $))
					tabstop := $tabstop
				else
					readAt -= StrLen(line)
			} catch ex {
				OutputDebug % ex.What ": " ex.Message
				if (ex.Message != "EndOfFile")
					throw ex
			}
		}
		return tabstop
	}

	readLineFromBottomOfFile(file, readAt) {
		line := ""
		while (readAt >= 0)	{
			file.seek(readAt)
			charAt := file.read(1)
			line := charAt . line
			if (charAt == "`n")
				return line
			readAt--
		}
		throw Exception("EndOfFile", A_ThisFunc)
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
	; test(ByRef haystack, regex_opts, ByRef found := 0, ByRef first_match_column := 0) {
	test(ByRef haystack, regex_opts, ByRef found := 0) {
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
					PrintLineData.columnNumberInLine := found_at
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

	processOutput() {
		if (PrintLineData.hitNumber = 1 && (Mack.Option.g || Mack.Option.files_w_matches)) {
			if (!Mack.Option.c) {
				Mack.processLine(Mack.prepareFileNameForOutput(PrintLineData.fileName))
				return false
			}
		} else {
			if (PrintLineData.hitNumber = 1 && Mack.Option.group) {
				if (!Mack.First_Call) {
					Mack.processLine(" ")
				} else {
					Mack.First_Call := false
				}
				Mack.processLine(Mack.prepareFileNameForOutput(PrintLineData.fileName))
			}
			Mack.printContextIfNecessary()
			if (!Mack.Option.files_w_matches) {
				Mack.printMatchLine(Mack.prepareFileNameForOutput(PrintLineData.fileName ":"))
			}
		}

		if (Mack.Option.1) {
			Ansi.Flush()
			Ansi.FlushInput()
			return -1
		}

		return true
	}

	prepareFileNameForOutput(fileName) {
		if (Mack.option.color) {
			printFileName := Ansi.SetGraphic(Mack.Option.color_filename)
				. fileName
				. Ansi.Reset()
		} else {
			printFileName := fileName
		}
		return printFileName
	}

	printMatchLine(lineFileName) {
		lineNumber := PrintLineData.lineNumberInFile
		columnNumber := PrintLineData.columnNumberInLine
		if (Mack.Option.color) {
			coloredLineNumber := Ansi.SetGraphic(Mack.option.color_line_no) lineNumber Ansi.Reset()
			coloredColumnNumber := Ansi.SetGraphic(Mack.option.color_line_no) columnNumber Ansi.Reset()
			Mack.processLine((Mack.option.filename ? lineFileName : "")
				. (Mack.option.line ? coloredLineNumber ":"  : "")
				. (columnNumber ? coloredColumnNumber ":" : "")
				. Mack.arrayOrStringToString(PrintLineData.text)
				. Ansi.Reset() Ansi.EraseLine())
		} else {
			Mack.processLine((Mack.option.filename ? lineFileName : "")
				. (Mack.option.line ? lineNumber ":" : "")
				. (columnNumber ? columnNumber ":" : "")
				. Mack.arrayOrStringToString(PrintLineData.text))
		}
	}

	printContextIfNecessary() {
		if (PrintLineData.contextAfterHit.Length() > 0) {
			loop % PrintLineData.contextAfterHit.Length() {
				Mack.processLine(PrintLineData.contextAfterHit.Pop())
			}
		}

		if (PrintLineData.contextBeforeHit.Length() > 0) {
			loop % PrintLineData.contextBeforeHit.Length() {
				Mack.processLine(PrintLineData.contextBeforeHit.Pop())
			}
		}
	}

	processLine(line) {
		Mack.printContextSeparatorIfNecessary(line)
		return Pager.writeHardWrapped(Ansi.readable(line, Mack.Option.color))
	}

	printContextSeparatorIfNecessary(line) {
		static lastPrintedLineNo := 0

		if (Mack.option.A || Mack.option.B) {
			if (RegExMatch(Ansi.plainStr(line), "^(?P<LineNo>\d+)", contains)) {
				if (containsLineNo - lastPrintedLineNo > 1) {
					Pager.writeHardWrapped("...")
				}
			}
			lastPrintedLineNo := containsLineNo
		}
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
			Mack.resetPrintLineData()
			PrintLineData.fileName := file_name
			if (!f) {
				; The file would have to be deleted after collecting filename
				OutputDebug % "Could not open file " PrintLineData.fileName	; NOTEST: Difficult to test
			} else {
				tabstops := Mack.setTabstop(f)
				last_col := 0
				while (!f.AtEOF) {
					PrintLineData.lineNumberInFile := A_Index
					line := RegExReplace(f.ReadLine(), "\t", tabstops)

					PrintLineData.text := Mack.test(line, regex_opts, found := 0)
					; parts := Mack.test(line, regex_opts, found := 0, column := 0)
					last_col := (PrintLineData.columnNumberInLine = 0
						? last_col
						: PrintLineData.columnNumberInLine)

					if (found && _log.Logs(Logger.Finest)) {
						_log.Finest("Found pattern: " line)
						_log.Finest("last_col", last_col)
						_log.Finest("parts:`n" LoggingHelper.Dump(parts))
					}

					if (found && Mack.Option.files_wo_matches) {
						; if the line matches but only files w/o matches should be listed: skip
						PrintLineData.hitNumber++
						break
					} else if (found && !Mack.Option.v) {
						; if the line matches and invert-match is disabled: output results
						PrintLineData.hitNumber++
						PrintLineData.contextBeforeHit := before_context
						PrintLineData.contextAfterHit := after_context
						cont := Mack.processOutput()
						if (cont != true) {
							break
						}
					} else if ((!found && Mack.Option.v) || Mack.Option.passthru) {
						; if the line doesn't match, but invert-match or passthru is enabled: output results
						PrintLineData.hitNumber++
						PrintLineData.contextBeforeHit := ""
						PrintLineData.contextAfterHit := ""
						PrintLineData.text := line
						cont := Mack.processOutput()
						if (cont != true) {
							break
						}
					} else {
						if (Mack.Option.A > 0 && after_context.Length() < Mack.Option.A && PrintLineData.hitNumber) {
							; if after-context is enabled and the context-buffer isn't full and we had a hit before: Add line to context-buffer (for colored or uncolored output)
							if (Mack.Option.color) {
								after_context.Push(a_line := Ansi.SetGraphic(Mack.Option.color_context) (Mack.Option.filename ? PrintLineData.fileName ":" : "") PrintLineData.lineNumberInFile ":" (last_col = 0 ? "" : " ".Repeat(StrLen(last_col)) " ") line Ansi.Reset())
							} else {
								after_context.Push(a_line := "+" (Mack.Option.filename ? PrintLineData.fileName ":" : "") PrintLineData.lineNumberInFile ":" (last_col = 0 ? "" : " ".Repeat(StrLen(last_col))) line)
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
								before_context.Push(b_line := Ansi.SetGraphic(Mack.Option.color_context) (Mack.Option.filename ? PrintLineData.fileName ":" : "") PrintLineData.lineNumberInFile ":" (last_col = 0 ? "" : " ".Repeat(StrLen(last_col)) " ") line Ansi.Reset())	
							} else {
								before_context.Push(b_line := "-" (Mack.Option.filename ? PrintLineData.fileName ":" : "") PrintLineData.lineNumberInFile ":" (last_col = 0 ? "" : " ".Repeat(StrLen(last_col))) line)	
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
			if (PrintLineData.hitNumber = 0 && Mack.Option.files_wo_matches) {
				Mack.processLine(Mack.prepareFileNameForOutput(PrintLineData.fileName))
				G_file_count++
			}
		} finally {
			if (f) {
				f.Close()
			}
			; Are there after-context-lines to print?
			if (after_context.Length() > 0) {
				loop % after_context.Length() {
					Mack.processLine(after_context.Pop())
				}
			}
			; Print hit count?
			if (Mack.Option.c && PrintLineData.hitNumber > 0) {
				if (!Mack.Option.files_w_matches) {
					if (Mack.Option.color) {
						Mack.processLine(Ansi.SetGraphic(Mack.Option.color_filename) PrintLineData.hitNumber " match(es)" Ansi.Reset())
					} else {
						Mack.processLine(PrintLineData.hitNumber " match(es)")
					}
				} else {
					Mack.processLine(Ansi.SetGraphic(Mack.Option.color_filename) PrintLineData.fileName ":" PrintLineData.hitNumber Ansi.Reset())
				}
				G_file_count++
				G_hit_count += PrintLineData.hitNumber
			}
		}

		return _log.Exit(cont)
	}

	cli() {
		op := new OptParser(["mack [options] [--] <pattern> [file | directory]..."
						   , "mack -f [options] [--] [directory]..."]
						   , OptParser.PARSER_ALLOW_DASHED_ARGS, "MACK_OPTIONS")
		op.Add(new OptParser.Group("Searching:"))
		op.Add(new OptParser.Boolean("i", "ignore-case"
			, Mack.Option, "i"
			, "Ignore case distinctions in pattern"))
		op.Add(new OptParser.Boolean("v", "invert-match"
			, Mack.Option, "v"
			, "Select non-matching lines"))
		op.Add(new OptParser.Boolean("w", "word-regexp"
			, Mack.Option, "w"
			, "Force pattern to match only whole words"))
		op.Add(new OptParser.Boolean("Q", "literal"
			, Mack.Option, "Q"
			, "Quote all metacharacters; pattern is literal"))
		op.Add(new OptParser.Group("`nSearch output:"))
		op.Add(new OptParser.Boolean("l", "files-with-matches"
			, Mack.Option, "files_w_matches"
			, "Only print filenames containing matches"))
		op.Add(new OptParser.Boolean("L", "files-without-matches"
			, Mack.Option, "files_wo_matches"
			, "Only print filenames with no matches"))
		op.Add(new OptParser.String(0, "output"
			, Mack.Option, "output"
			, "EXPR", "Output the evaluation of EXPR for each line "
			. "(turns of text highlighting)"
			, OptParser.OPT_ARG))
		op.Add(new OptParser.Boolean("o", ""
			, Mack.Option, "o"
			, "Show only the part of a line matching PATTERN. "
			. "Same as --output $0"))
		op.Add(new OptParser.Boolean(0, "passthru"
			, Mack.Option, "passthru"
			, "Print all lines, whether matching or not"))
		op.Add(new OptParser.Boolean("1", ""
			, Mack.Option, "1"
			, "Stop searching after one match of any kind"))
		op.Add(new OptParser.Boolean("c", "count"
			, Mack.Option, "c"
			, "Show number of lines matching per file"))
		op.Add(new OptParser.Boolean(0, "filename"
			, Mack.Option, "filename"
			, "Suppress prefixing filename on output (default)"
			, OptParser.OPT_NEG|OptParser.OPT_NEG_USAGE))
		op.Add(new OptParser.Boolean(0, "line"
			, Mack.Option, "line"
			, "Show the line number of the match"
			, OptParser.OPT_NEG|OptParser.OPT_NEG_USAGE, Mack.Option.line))
		op.Add(new OptParser.Boolean(0, "column"
			, Mack.Option, "column"
			, "Show the column number of the first match"
			, OptParser.OPT_NEG|OptParser.OPT_NEG_USAGE))
		op.Add(new OptParser.String("A", "after-context"
			, Mack.Option, "A"
			, "NUM", "Print NUM lines of trailing context after matching lines"
			, OptParser.OPT_ARG))
		op.Add(new OptParser.String("B", "before-context"
			, Mack.Option, "B"
			, "NUM", "Print NUM lines of leading context before matching lines"
			, OptParser.OPT_ARG))
		op.Add(new OptParser.String("C", "context"
			, Mack.Option, "context"
			, "NUM", "Print NUM (default 2) lines of output context"
			, OptParser.OPT_OPTARG, Mack.Option.context))
		op.Add(new OptParser.String(0, "tabstop"
			, Mack.Option, "tabstop"
			, "size", "Calculate tabstops with width of size (default 8)"
			,,, Mack.Option.tabstop))
		op.Add(new OptParser.String(0, "modelines"
			, Mack.Option, "modelines"
			, "lines", "Search modelines (default 5) for tabstop info. "
			. "Set to 0 to ignore modelines"
			, OptParser.OPT_OPTARG,, 5, Mack.Option.modelines))
		op.Add(new OptParser.Group("`nFile presentation:"))
		op.Add(new OptParser.Boolean(0, "pager"
			, Mack.Option, "pager"
			, "Send output through a pager (default)"
			, OptParser.OPT_NEG, Mack.Option.pager))
		op.Add(new OptParser.Boolean(0, "group"
			, Mack.Option, "group"
			, "Print a filename heading above each file's results "
			. "(default: on when used interactively)"
			, OptParser.OPT_NEG, true))
		op.Add(new OptParser.Boolean(0, "color"
			, Mack.Option, "color"
			, "Highlight the matching text (default: on)"
			, OptParser.OPT_NEG, Mack.Option.color))
		op.Add(new OptParser.String(0, "color-filename"
			, Mack.Option, "color_filename"
			, "color", ""
			, OptParser.OPT_ARG
			, Mack.Option.color_filename, Mack.Option.color_filename))
		op.Add(new OptParser.String(0, "color-match"
			, Mack.Option, "color_match"
			, "color", ""
			, OptParser.OPT_ARG
			, Mack.Option.color_match, Mack.Option.color_match))
		op.Add(new OptParser.String(0, "color-line-no"
			, Mack.Option, "color_line_no"
			, "color", "Set the color for filenames, matches, and line numbers "
			. "as ANSI color attributes (e.g. ""7;37"")"
			, OptParser.OPT_ARG
			, Mack.Option.color_line_no, Mack.Option.color_line_no))
		op.Add(new OptParser.Group("`nFile finding:"))
		op.Add(new OptParser.Boolean("f", ""
			, Mack.Option, "f"
			, "Only print the files selected, without searching. "
			. "The pattern must not be specified"))
		op.Add(new OptParser.Boolean("g", ""
			, Mack.Option, "g"
			, "Same as -f, but only select files matching pattern"))
		op.Add(new OptParser.Boolean(0, "sort-files"
			, Mack.Option, "sort_files"
			, "Sort the found files lexically"))
		op.Add(new OptParser.String(0, "files-from"
			, Mack.Option, "files_from"
			, "FILE", "Read the list of files to search from FILE"
			, OptParser.OPT_ARG)) ; TODO: Implement --files-from option
		op.Add(new OptParser.Boolean("x", ""
			, Mack.Option, "x"
			, "Read the list of files to search from STDIN")) ; TODO Implement -x option
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
		op.Add(new OptParser.Boolean("r", "recurse"
			, Mack.Option, "r"
			, "Recurse into subdirectories (default: on)"
			, OptParser.OPT_NEG, true))
		op.Add(new OptParser.Boolean("k", "known-types"
			, Mack.Option, "k"
			, "Include only files of types that are recognized"))
		op.Add(new OptParser.Callback(0, "type"
			, Mack.Option, "" ; CAVEAT: type_inex will never be set due to the callback function... that's a bit confusing!?!
			, "maintainTypeFilter", "X"
			, "Include/exclude X files"
			, OptParser.OPT_ARG | OptParser.OPT_OPTARG
			| OptParser.OPT_NEG | OptParser.OPT_NEG_USAGE))
		op.Add(new OptParser.Group("`nFile type specification:"))
		op.Add(new OptParser.Callback(0, "type-set"
			, Mack.Option, "type_set"
			, "addNewFileType", "X:FILTER[+FILTER...]"
			, "Files with given FILTER are recognized of type X. "
			. "This replaces an existing defintion."
			, OptParser.OPT_ARG))
		op.Add(new OptParser.Callback(0, "type-add"
			, Mack.Option, "type_add"
			, "addFileTypePattern", "X:FILTER[+FILTER...]"
			, "Files with given FILTER are recognized of type X"
			, OptParser.OPT_ARG))
		op.Add(new OptParser.Callback(0, "type-del"
			, Mack.Option, "type_del"
			, "removeFileType", "X"
			, "Remove all filters associated with X"
			, OptParser.OPT_ARG))
		op.Add(new OptParser.Group("`nMiscellaneous:"))
		op.Add(new OptParser.Boolean(0, "env"
			, Mack.Option, "__env_dummy"
			, "Ignore environment variable MACK_OPTIONS"
			, OptParser.OPT_NEG|OptParser.OPT_NEG_USAGE))
		op.Add(new OptParser.Boolean("h", "help"
			, Mack.Option, "h"
			, "This help"
			, OptParser.OPT_HIDDEN))
		op.Add(new OptParser.Boolean(0, "version"
			, Mack.option, "version"
			, "Display version info"))
		op.Add(new OptParser.Boolean(0, "help-types"
			, Mack.option, "ht"
			, "Display all known types"))
		op.Add(Mack.Sel_Types_Option := new OptParser.Generic(Mack.Option.types_expr
			, Mack.Option, "sel_types"
			, OptParser.OPT_MULTIPLE|OptParser.OPT_NEG))

		return op
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
				file_list := Mack.determineFilesForSearch(args)
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

	resetPrintLineData() {
		PrintLineData.fileName := ""
		PrintLineData.lineNumberInFile := 0
		PrintLineData.columnNumberInLine := 0
		PrintLineData.hitNumber := 0
		PrintLineData.contextBeforeHit := ""
		PrintLineData.contextAfterHit := ""
		PrintLineData.text := ""
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
