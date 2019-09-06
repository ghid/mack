; ahk: console
ListLines Off
SetBatchLines -1

#Include %A_LineFile%\..\modules
#Include PrintLineData.ahk

class Mack {

	requires() {
		return [Ansi, String, Datatable, Arrays, Queue, Pager, Optparser]
	}

	static option
	static Sel_Types_Option
	static firstCall

	setDefaults() {
		Mack.firstCall := true
		Mack.sel_Types_Option := ""
		; ahklint-ignore-begin: W002,W003
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
				, mackrc                : ""
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
				, types_expr			: ""
				, type					: []
				, type_ignore			: []
				, v				  		: false
				, version		  		: false
				, w				  		: false
				, x				  		: false
				, 1				  		: false }
		; ahklint-ignore-end

		Mack.option := dv
		Mack.option.types_expr := Mack.typeListAsRegularExpression()
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
				. "-" G_VERSION_INFO.BUILD
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
		if (Mack.option.x || Mack.option.files_from == "-") {
			filesToSearch := Mack.getFilesToSearchFromStdIn()
		} else if (Mack.option.files_from != "") {
			filesToSearch := Mack.getFilesToSearchFromFile()
		} else {
			filesToSearch := Mack.getFilesToSearchFromFileStructure(args)
		}
		return filesToSearch
	}

	getFilesToSearchFromStdIn() {
		fileList := []
		loop {
			fileName := Ansi.readLine()
			if (fileName != "") {
				fileList.push(fileName)
			}
		} until (fileName == "")
		return fileList
	}

	getFilesToSearchFromFile() {
		fileList := []
		try {
			fileWithFileList := FileOpen(Mack.option.files_from, "r `n")
			while (!fileWithFileList.atEOF) {
				fileName := RTrim(fileWithFileList.readLine(), "`n")
				if (fileName != "") {
					fileList.push(fileName)
				}
			}
			return fileList
		} finally {
			if (fileWithFileList) {
				fileWithFileList.close()
			}
		}
	}

	getFilesToSearchFromFileStructure(args) {
		if (args.maxIndex() == "") {
			fileList := Mack.collectFileNames(".\*.*")
		} else {
			loop % args.maxIndex() {
				filePattern := Mack.refineFileOrPathPattern(args[A_Index])
				fileList := Mack.collectFileNames(filePattern
						, (A_Index > 1 ? fileList : ""))
			}
		}
		if (Mack.option.sort_files && fileList.maxIndex() != "") {
			fileList := Mack.sortFileList(fileList)
		}
		return fileList
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
			if (!hasMatchingBackslash) {
				refinedPathPattern .= "\"
			}
			if (!hasMatchingWildcard) {
				refinedPathPattern .= "*.*"
			}
		}
		return refinedPathPattern
	}

	collectFileNames(directoryName, listOfFileNames="") {
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
		pattern := Mack.convertFilePatternToRegularExpression(entryToAdd)
		try {
			return Mack.positionInList(listName, pattern)
		} catch {
			return Mack.option[listName].push(pattern)
		}
	}

	removeListEntry(listName, entryToRemove) {
		pattern := Mack.convertFilePatternToRegularExpression(entryToRemove)
		return Mack.option[listName].removeAt(Mack.positionInList(listName
				, pattern))
	}

	positionInList(listName, lookForEntry) {
		for listIndex, listContent in Mack.option[listName] {
			if (listContent == lookForEntry) {
				return listIndex
			}
		}
		throw Exception("EntryNotInList:" listName "[" lookForEntry "]"
				, A_ThisFunc)
	}

	typeListAsRegularExpression() {
		typeListAsRegularExpression := "("
		for fileType, filePattern in Mack.option.types {
			typeListAsRegularExpression .= (A_Index = 1 ? "" : "|") fileType
		}
		typeListAsRegularExpression .= ")"
		return typeListAsRegularExpression
	}

	convertFilePatternToRegularExpression(filePattern) {
		convertedEscapeChars := RegExReplace(filePattern, "[+.\\\[\]\{\}\(\)]"
				, "\$0")
		convertedQuestionMarks := StrReplace(convertedEscapeChars, "?", ".")
		convertedAsterisks := StrReplace(convertedQuestionMarks, "*", ".*?")
		if (InStr(convertedAsterisks, " ")) {
			convertedAsterisks := "(" RegExReplace(convertedAsterisks, "\s+"
					, "|") ")"
		}
		return convertedAsterisks
	}

	convertArrayToRegularExpression(inputArray) {
		regularExpression := ""
		for i, item in inputArray {
			regularExpression .= (i > 1 ? "|" : "") item
		}
		if (regularExpression != "") {
			regularExpression := "S)^(" regularExpression ")$"
		}
		return regularExpression
	}

	setTabStopsForFile(fileObject) {
		tabstop := 0
		if (Mack.option.modelines) {
			tabstop := Mack.fromModelineAtTopOfFile(fileObject)
			 if (!tabstop) {
				tabstop := Mack.fromModelineAtBottomOfFile(fileObject)
			 }
			fileObject.seek(0)
		}
		return " ".repeat(tabstop ? tabstop : Mack.option.tabstop)
	}

	fromModelineAtTopOfFile(fileObject) {
		tabstop := 0
		while (tabstop == 0 && A_Index <= Mack.option.modelines) {
			try {
				line := fileObject.readLine()
				if (RegExMatch(line, Mack.option.modeline_expr, $)) {
					tabstop := $tabstop
				}
			} catch ex {
				OutputDebug % ex.what ": " ex.message							; NOTEST: Will not be tested, because the pattern is hardcoded.
				throw ex														; NOTEST
			}
		}
		return tabstop
	}

	fromModelineAtBottomOfFile(fileObject) {
		tabstop := 0
		readAt := fileObject.length
		while (tabstop == 0 && A_Index <= Mack.option.modelines) {
			try {
				line := Mack.readLineFromBottomOfFile(fileObject, readAt)
				if (RegExMatch(line, Mack.option.modeline_expr, $)) {
					tabstop := $tabstop
				} else {
					readAt -= StrLen(line)
				}
			} catch ex {
				if (ex.message != "EndOfFile") {
					throw ex
				}
			}
		}
		return tabstop
	}

	readLineFromBottomOfFile(fileObject, readAt) {
		line := ""
		while (readAt >= 0)	{
			fileObject.seek(readAt)
			charAt := fileObject.read(1)
			line := charAt . line
			if (charAt == "`n") {
				return line
			}
			readAt--
		}
		throw Exception("EndOfFile", A_ThisFunc)
	}

	searchPatternInText(text) {
		searchAt := 1
		matchesFound := 0
		PrintLineData.text := []
		loop {
			patternFoundAt := RegExMatch(text
					, (Mack.option.i ? "i" : "") "OS)" Mack.option.pattern
					, group, searchAt)
			if (patternFoundAt) {
				if (A_Index == 1 && Mack.option.column) {
					Mack.saveColumnOfFirstHitInLine(patternFoundAt)
				}
				if (Mack.option.output) {
					PrintLineData.text.push(Mack.substitueBackReferences(group))
					matchesFound := 1
					break
				} else {
					matchesFound++
					if (patternFoundAt > 1) {
						PrintLineData.text.push(Mack.textInFrontOfHit(text
								, searchAt, patternFoundAt))
					}
					PrintLineData.text.push(Mack.prepareHit(group))
					searchAt := patternFoundAt + StrLen(group.value)
				}
			} else if (matchesFound) {
				PrintLineData.text.push(Mack.noMoreMatchesButTextAfterHit(text
						, searchAt))
			} else {
				PrintLineData.text.push(Mack.lineHasNoHit(text))
			}
		} until (patternFoundAt = 0)
		return matchesFound
	}

	substitueBackReferences(group) {
		pattern := Mack.option.output
		while (RegExMatch(pattern, "\$(\d+)", argNo)) {
			pattern := RegExReplace(pattern, "\Q" argNo "\E", group[argNo1])
		}
		return pattern
	}

	saveColumnOfFirstHitInLine(columnNumber) {
		PrintLineData.columnNumberInLine := columnNumber
	}

	textInFrontOfHit(text, from, foundAt) {
		return SubStr(text, from, foundAt - from)
	}

	noMoreMatchesButTextAfterHit(text, at) {
		return SubStr(text, at)
	}

	lineHasNoHit(text) {
		return text
	}

	prepareHit(group) {
		if (Mack.option.color) {
			hit := Ansi.setGraphic(Mack.option.color_match) group.value
					. Ansi.reset()
		} else {
			hit := group.value
		}
		return hit
	}

	processOutput() {
		if (PrintLineData.hitNumber == 1
				&& (Mack.option.g || Mack.option.files_w_matches)) {
			if (!Mack.option.c) {
				Mack.processLine(Mack.prepareFileNameForOutput(PrintLineData
						.fileName))
				return false
			}
		} else {
			if (PrintLineData.hitNumber == 1 && Mack.option.group) {
				if (!Mack.firstCall) {
					Mack.processLine(" ")
				} else {
					Mack.firstCall := false
				}
				Mack.processLine(Mack.prepareFileNameForOutput(PrintLineData
						.fileName))
			}
			Mack.printContextIfNecessary()
			if (!Mack.option.files_w_matches) {
				Mack.printMatchLine(Mack.prepareFileNameForOutput(PrintLineData
						.fileName ":"))
			}
		}
		if (Mack.option.1) {
			Ansi.flush()
			Ansi.flushInput()
			return -1
		}
		return true
	}

	prepareFileNameForOutput(fileName) {
		if (Mack.option.color) {
			printFileName := Ansi.setGraphic(Mack.option.color_filename)
					. fileName
					. Ansi.reset()
		} else {
			printFileName := fileName
		}
		return printFileName
	}

	printMatchLine(lineFileName) {
		lineNumber := PrintLineData.lineNumberInFile
		columnNumber := PrintLineData.columnNumberInLine
		if (Mack.option.color) {
			coloredLineNumber := Ansi.setGraphic(Mack.option.color_line_no)
					. lineNumber Ansi.reset()
			coloredColumnNumber := Ansi.setGraphic(Mack.option.color_line_no)
					. columnNumber Ansi.reset()
			Mack.processLine((Mack.option.filename ? lineFileName : "")
					. (Mack.option.line ? coloredLineNumber ":"  : "")
					. (columnNumber ? coloredColumnNumber ":" : "")
					. Mack.arrayOrStringToString(PrintLineData.text)
					. Ansi.reset() Ansi.eraseLine())
		} else {
			Mack.processLine((Mack.option.filename ? lineFileName : "")
					. (Mack.option.line ? lineNumber ":" : "")
					. (columnNumber ? columnNumber ":" : "")
					. Mack.arrayOrStringToString(PrintLineData.text))
		}
	}

	printContextIfNecessary() {
		if (PrintLineData.contextAfterHit.length() > 0) {
			loop % PrintLineData.contextAfterHit.length() {
				Mack.processLine(PrintLineData.contextAfterHit.pop())
			}
		}
		if (PrintLineData.contextBeforeHit.length() > 0) {
			loop % PrintLineData.contextBeforeHit.length() {
				Mack.processLine(PrintLineData.contextBeforeHit.pop())
			}
		}
	}

	processLine(line) {
		Mack.printContextSeparatorIfNecessary(line)
		return Pager.writeHardWrapped(Ansi.readable(line, Mack.option.color))
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
			return Arrays.toString(inputValue, "")
		}
		return inputValue
	}

	searchInFileForPattern(fileName) {
		fileObject := {}
		try {
			fileObject := FileOpen(fileName, "r `n")
			Mack.resetPrintLineData(fileName)
			if (!fileObject) {
				OutputDebug % "Could not open file " PrintLineData.fileName		; NOTEST: Difficult to test
			} else {
				result := Mack.processFile(fileObject)
			}
			if (PrintLineData.hitNumber == 0 && Mack.option.files_wo_matches) {
				Mack.processLine(Mack.prepareFileNameForOutput(PrintLineData
						.fileName))
			}
		} catch ex {
			ex.message .= " File name: " fileName
			throw ex
		} finally {
			if (fileObject) {
				fileObject.close()
			}
			Mack.printHitCountIfNecessary()
		}
		return result
	}

	; TODO: Refactor?
	processFile(fileObject) {
		tabStops := Mack.setTabStopsForFile(fileObject)
		continueProcessing := true
		while (continueProcessing > 0 && !fileObject.atEOF) {
			PrintLineData.lineNumberInFile := A_Index
			lineWithSubstitutedTabs := RegExReplace(fileObject.readLine()
					, "\t", tabStops)
			lineWithoutNewLineAtEnd := RegExReplace(lineWithSubstitutedTabs
					, "`n$", "", 1)
			matchesFound := Mack.searchPatternInText(lineWithoutNewLineAtEnd)
			if (matchesFound && Mack.option.files_wo_matches) {
				PrintLineData.hitNumber++
				continueProcessing := false
			} else if (Mack.option.passthru
					|| ( matchesFound && !Mack.option.v)
					|| (!matchesFound &&  Mack.option.v)) {
				PrintLineData.hitNumber++
				continueProcessing := Mack.processOutput()
			} else {
				if (Mack.option.A > 0
						&& PrintLineData.contextAfterHit.length()
						< Mack.option.A
						&& PrintLineData.hitNumber) {
					Mack.storeAfterContextDataInQueue(PrintLineData
							.contextAfterHit)
				} else if (Mack.option.B > 0) {
					Mack.storeBeforeContextDataInQueue(PrintLineData
							.contextBeforeHit)
				}
			}
		}
		loop % PrintLineData.contextAfterHit.length() {
			Mack.processLine(PrintLineData.contextAfterHit.pop())
		}
		return continueProcessing
	}

	storeBeforeContextDataInQueue(contextQueue) {
		Mack.storeContextDataInQueue(contextQueue, "-")
	}

	storeAfterContextDataInQueue(contextQueue) {
		Mack.storeContextDataInQueue(contextQueue, "+")
	}

	storeContextDataInQueue(contextQueue, charForNotColoredOutput) {
		if (Mack.option.color) {
			contextQueue.push(Ansi.setGraphic(Mack.option.color_context)
					. (Mack.option.filename ? PrintLineData.fileName ":" : "")
					. PrintLineData.lineNumberInFile ":"
					. (PrintLineData.columnNumberInLine = 0
					? ""
					: " ".repeat(StrLen(PrintLineData.columnNumberInLine)) " ")
					. Mack.arrayOrStringToString(PrintLineData.text)
					. Ansi.reset())
		} else {
			contextQueue.push(charForNotColoredOutput
					. (Mack.option.filename ? PrintLineData.fileName ":" : "")
					. PrintLineData.lineNumberInFile ":"
					. (PrintLineData.columnNumberInLine = 0
					? ""
					: " ".repeat(StrLen(PrintLineData.columnNumberInLine)))
					. Mack.arrayOrStringToString(PrintLineData.text))
		}
	}

	printHitCountIfNecessary() {
		if (Mack.option.c && PrintLineData.hitNumber > 0) {
			if (!Mack.option.files_w_matches) {
				if (Mack.option.color) {
					Mack.processLine(Ansi.setGraphic(Mack.option.color_filename)
							. PrintLineData.hitNumber " match(es)" Ansi.reset())
				} else {
					Mack.processLine(PrintLineData.hitNumber " match(es)")
				}
			} else {
				Mack.processLine(Ansi.setGraphic(Mack.option.color_filename)
						. PrintLineData.fileName ":" PrintLineData.hitNumber
						. Ansi.reset())
			}
		}
	}

	resetPrintLineData(fileName) {
		PrintLineData.fileName := fileName
		PrintLineData.lineNumberInFile := 0
		PrintLineData.columnNumberInLine := 0
		PrintLineData.hitNumber := 0
		PrintLineData.contextBeforeHit := new Queue(Mack.option.b)
		PrintLineData.contextAfterHit := new Queue(Mack.option.a)
		PrintLineData.text := []
	}

	cli() {
		op := new OptParser(["mack [options] [--] <pattern> "
				. "[file | directory]..."
				, "mack -f [options] [--] [directory]..."]
				, OptParser.PARSER_ALLOW_DASHED_ARGS, "MACK_OPTIONS"
				, ".mackrc")
		Mack.addSearchingOptionsToParser(op)
		Mack.addSearchOutputOptionsToParser(op)
		Mack.addFilePresentationOptionsToParser(op)
		Mack.addFileFindingOptionsToParser(op)
		Mack.addFileInclusionAndExclusionOptionsToParser(op)
		Mack.addFileTypeSecificationOptionsToParser(op)
		Mack.addMiscOptionsToParser(op)
		return op
	}

	addSearchingOptionsToParser(op) {
		op.add(new OptParser.Group("Searching:"))
		op.add(new OptParser.Boolean("i", "ignore-case"
				, Mack.option, "i"
				, "Ignore case distinctions in pattern"))
		op.add(new OptParser.Boolean("v", "invert-match"
				, Mack.option, "v"
				, "Select non-matching lines"))
		op.add(new OptParser.Boolean("w", "word-regexp"
				, Mack.option, "w"
				, "Force pattern to match only whole words"))
		op.add(new OptParser.Boolean("Q", "literal"
				, Mack.option, "Q"
				, "Quote all metacharacters; pattern is literal"))
	}

	addSearchOutputOptionsToParser(op) {
		op.add(new OptParser.Group("`nSearch output:"))
		op.add(new OptParser.Boolean("l", "files-with-matches"
				, Mack.option, "files_w_matches"
				, "Only print filenames containing matches"))
		op.add(new OptParser.Boolean("L", "files-without-matches"
				, Mack.option, "files_wo_matches"
				, "Only print filenames with no matches"))
		op.add(new OptParser.String(0, "output"
				, Mack.option, "output"
				, "EXPR", "Output the evaluation of EXPR for each line "
				. "(turns of text highlighting)"
				, OptParser.OPT_ARG))
		op.add(new OptParser.Boolean("o", ""
				, Mack.option, "o"
				, "Show only the part of a line matching PATTERN. "
				. "Same as --output $0"))
		op.add(new OptParser.Boolean(0, "passthru"
				, Mack.option, "passthru"
				, "Print all lines, whether matching or not"))
		op.add(new OptParser.Boolean("1", ""
				, Mack.option, "1"
				, "Stop searching after one match of any kind"))
		op.add(new OptParser.Boolean("c", "count"
				, Mack.option, "c"
				, "Show number of lines matching per file"))
		op.add(new OptParser.Boolean(0, "filename"
				, Mack.option, "filename"
				, "Suppress prefixing filename on output (default)"
				, OptParser.OPT_NEG|OptParser.OPT_NEG_USAGE))
		op.add(new OptParser.Boolean(0, "line"
				, Mack.option, "line"
				, "Show the line number of the match"
				, OptParser.OPT_NEG|OptParser.OPT_NEG_USAGE, Mack.option.line))
		op.add(new OptParser.Boolean(0, "column"
				, Mack.option, "column"
				, "Show the column number of the first match"
				, OptParser.OPT_NEG|OptParser.OPT_NEG_USAGE))
		op.add(new OptParser.String("A", "after-context"
				, Mack.option, "A"
				, "NUM"
				, "Print NUM lines of trailing context after matching lines"
				, OptParser.OPT_ARG))
		op.add(new OptParser.String("B", "before-context"
				, Mack.option, "B"
				, "NUM"
				, "Print NUM lines of leading context before matching lines"
				, OptParser.OPT_ARG))
		op.add(new OptParser.String("C", "context"
				, Mack.option, "context"
				, "NUM", "Print NUM (default 2) lines of output context"
				, OptParser.OPT_OPTARG, Mack.option.context))
		op.add(new OptParser.String(0, "tabstop"
				, Mack.option, "tabstop"
				, "size", "Calculate tabstops with width of size (default 8)"
				,,, Mack.option.tabstop))
		op.add(new OptParser.String(0, "modelines"
				, Mack.option, "modelines"
				, "lines", "Search modelines (default 5) for tabstop info. "
				. "Set to 0 to ignore modelines"
				, OptParser.OPT_OPTARG,, 5, Mack.option.modelines))
	}

	addFilePresentationOptionsToParser(op) {
		op.add(new OptParser.Group("`nFile presentation:"))
		op.add(new OptParser.Boolean(0, "pager"
				, Mack.option, "pager"
				, "Send output through a pager (default)"
				, OptParser.OPT_NEG, Mack.option.pager))
		op.add(new OptParser.Boolean(0, "group"
				, Mack.option, "group"
				, "Print a filename heading above each file's results "
				. "(default: on when used interactively)"
				, OptParser.OPT_NEG, true))
		op.add(new OptParser.Boolean(0, "color"
				, Mack.option, "color"
				, "Highlight the matching text (default: on)"
				, OptParser.OPT_NEG, Mack.option.color))
		op.add(new OptParser.String(0, "color-filename"
				, Mack.option, "color_filename"
				, "color", ""
				, OptParser.OPT_ARG
				, Mack.option.color_filename, Mack.option.color_filename))
		op.add(new OptParser.String(0, "color-match"
				, Mack.option, "color_match"
				, "color", ""
				, OptParser.OPT_ARG
				, Mack.option.color_match, Mack.option.color_match))
		op.add(new OptParser.String(0, "color-line-no"
				, Mack.option, "color_line_no"
				, "color"
				, "Set the color for filenames, matches, and line numbers "
				. "as ANSI color attributes (e.g. ""7;37"")"
				, OptParser.OPT_ARG
				, Mack.option.color_line_no, Mack.option.color_line_no))
	}

	addFileFindingOptionsToParser(op) {
		op.add(new OptParser.Group("`nFile finding:"))
		op.add(new OptParser.Boolean("f", ""
				, Mack.option, "f"
				, "Only print the files selected, without searching. "
				. "The pattern must not be specified"))
		op.add(new OptParser.Boolean("g", ""
				, Mack.option, "g"
				, "Same as -f, but only select files matching pattern"))
		op.add(new OptParser.Boolean(0, "sort-files"
				, Mack.option, "sort_files"
				, "Sort the found files lexically"))
		op.add(new OptParser.String(0, "files-from"
				, Mack.option, "files_from"
				, "FILE", "Read the list of files to search from FILE"
				, OptParser.OPT_ARG))
		op.add(new OptParser.Boolean("x", ""
				, Mack.option, "x"
				, "Read the list of files to search from STDIN"))
	}

	addFileInclusionAndExclusionOptionsToParser(op) {
		op.add(new OptParser.Group("`nFile inclusion/exclusion:"))
		op.add(new OptParser.Callback(0, "ignore-dir"
				, Mack.option, "ignore_dir"
				, "maintainDirectoriesToIgnore", "name"
				, "Add/remove directory from list of ignored dirs"
				, OptParser.OPT_ARG | OptParser.OPT_NEG))
		op.add(new OptParser.Callback(0, "ignore-file"
				, Mack.option, "ignore_file"
				, "maintainFilesToIgnore", "filter"
				, "Add filter for ignoring files"
				, OptParser.OPT_ARG | OptParser.OPT_NEG))
		op.add(new OptParser.Boolean("r", "recurse"
				, Mack.option, "r"
				, "Recurse into subdirectories (default: on)"
				, OptParser.OPT_NEG, true))
		op.add(new OptParser.Boolean("k", "known-types"
				, Mack.option, "k"
				, "Include only files of types that are recognized"))
		op.add(new OptParser.Callback(0, "type"
				, Mack.option, ""
				, "maintainTypeFilter", "X"
				, "Include/exclude X files"
				, OptParser.OPT_ARG | OptParser.OPT_OPTARG
				| OptParser.OPT_NEG | OptParser.OPT_NEG_USAGE))
	}

	addFileTypeSecificationOptionsToParser(op) {
		op.add(new OptParser.Group("`nFile type specification:"))
		op.add(new OptParser.Callback(0, "type-set"
				, Mack.option, "type_set"
				, "addNewFileType", "X:FILTER[+FILTER...]"
				, "Files with given FILTER are recognized of type X. "
				. "This replaces an existing defintion."
				, OptParser.OPT_ARG))
		op.add(new OptParser.Callback(0, "type-add"
				, Mack.option, "type_add"
				, "addFileTypePattern", "X:FILTER[+FILTER...]"
				, "Files with given FILTER are recognized of type X"
				, OptParser.OPT_ARG))
		op.add(new OptParser.Callback(0, "type-del"
				, Mack.option, "type_del"
				, "removeFileType", "X"
				, "Remove all filters associated with X"
				, OptParser.OPT_ARG))
	}

	addMiscOptionsToParser(op) {
		op.add(new OptParser.Group("`nMiscellaneous:"))
		op.add(new OptParser.Boolean(0, "env"
				, Mack.option, "__env_dummy"
				, "Ignore environment variable MACK_OPTIONS"
				, OptParser.OPT_NEG|OptParser.OPT_NEG_USAGE))
		op.add(new OptParser.RcFile(0, "mackrc"
				, Mack.option, "mackrc"
				, "FILE", "Specifies a mackrc file to load after all others"))
		op.add(new OptParser.Boolean("h", "help"
				, Mack.option, "h"
				, "This help"
				, OptParser.OPT_HIDDEN))
		op.add(new OptParser.Boolean(0, "version"
				, Mack.option, "version"
				, "Display version info"))
		op.add(new OptParser.Boolean(0, "help-types"
				, Mack.option, "ht"
				, "Display all known types"))
		op.add(Mack.sel_Types_Option
				:= new OptParser.Generic(Mack.option.types_expr
				, Mack.option, "sel_types"
				, OptParser.OPT_MULTIPLE|OptParser.OPT_NEG))
	}

	run(cmdLineArgs) {
		Mack.setDefaults()
		result := ""
		try {
			op := Mack.cli()
			remainingArgs := op.parse(cmdLineArgs)
			Pager.enablePager := Mack.option.pager
			Mack.useKnownFileTypesIfNecessary()
			Mack.useSelectedFileTypesIfNecessary()
			Mack.setDirectoriesFilesAndFileTypesToUseOrToIgnore()
			Mack.setupContextOptions()
			Mack.setupEvaluatedOutput()
			if (Mack.option.version) {
				Ansi.writeLine(Mack.getVersionInfo())
			} else if (Mack.option.h) {
				Ansi.writeLine(op.usage())
			} else if (Mack.option.ht) {
				Ansi.write(Mack.printKnownFileTypes())
			} else {
				Mack.setupSearchPatternIfNecessary(remainingArgs)
				fileList := Mack.determineFilesForSearch(remainingArgs)
				Mack.processFileList(fileList)
			}
		} catch ex {
			OutputDebug % ex.file ":" ex.line
			Ansi.writeLine(ex.message)
			Ansi.writeLine(op.usage())
			result := ex.extra
		}
		return result
	}

	useKnownFileTypesIfNecessary() {
		if (Mack.option.k) {
			for filetype, filter in Mack.option.types {
				maintainTypeFilter(filetype)
			}
		}
	}

	useSelectedFileTypesIfNecessary() {
		if (Mack.option.sel_types) {
			for i, filetype in Mack.option.sel_types {
				if (SubStr(filetype, 1, 1) == "!") {
					maintainTypeFilter(SubStr(filetype, 2), true)
				} else {
					maintainTypeFilter(filetype)
				}
			}
		}
	}

	setDirectoriesFilesAndFileTypesToUseOrToIgnore() {
		Mack.option.match_ignore_dirs := Mack
				.convertArrayToRegularExpression(Mack.option.ignore_dirs)
		Mack.option.match_ignore_files := Mack
				.convertArrayToRegularExpression(Mack.option.ignore_files)
		Mack.option.match_type := Mack
				.convertArrayToRegularExpression(Mack.option.type)
		Mack.option.match_type_ignore := Mack
				.convertArrayToRegularExpression(Mack.option.type_ignore)
	}

	setupContextOptions() {
		if (Mack.option.A == "") {
			Mack.option.A := 0
		}
		if (Mack.option.B == "") {
			Mack.option.B := 0
		}
		if (Mack.option.context > 0 && Mack.option.A == 0) {
			Mack.option.A := Mack.option.context
		}
		if (Mack.option.context > 0 && Mack.option.B == 0) {
			Mack.option.B := Mack.option.context
		}
	}

	setupEvaluatedOutput() {
		if (Mack.option.o) {
			Mack.option.color_match := Ansi.reset()
			Mack.option.output := "$0"
		}
	}

	setupSearchPatternIfNecessary(args) {
		if (!Mack.option.f) {
			Mack.option.pattern := Arrays.shift(args)
			if (Mack.option.pattern == "") {
				throw Exception("Provide a search pattern")
			}
			if (Mack.option.Q) {
				Mack.option.pattern := "\Q" Mack.option.pattern "\E"
			}
			if (Mack.option.w) {
				Mack.option.pattern := "\b" Mack.option.pattern "\b"
			}
			if (Mack.option.g) {
				Mack.option.file_pattern := Mack.option.pattern
			}
		}
	}

	processFileList(fileList) {
		if (Mack.option.f || Mack.option.g) {
			loop % fileList.maxIndex() {
				Pager.writeHardWrapped(fileList[A_Index])
			}
		} else {
			Console.refreshBufferInfo()
			loop % fileList.maxIndex() {
				if (Mack.searchInFileForPattern(fileList[A_Index]) == -1) {
					return
				}
			}
		}
	}
}

#NoEnv						; NOTEST-BEGIN
#NoTrayIcon
#SingleInstance off
SetBatchLines -1

#Include <ansi\ansi>
#Include <string\string>
#Include <datatable\datatable>
#Include <arrays\arrays>
#Include <queue\queue>
#include <pager\pager>
#Include <optparser\optparser>
#Include *i %A_ScriptDir%\.versioninfo

main:
	global G_wt
	WinGetTitle G_wt, A
	Ansi.NO_BUFFER := true
	returnCode := Mack.run(A_Args)
	Ansi.flushInput()
exitapp returnCode				; NOTEST-END

maintainDirectoriesToIgnore(directoryName, noOptGiven="") {
	if (noOptGiven) {
		Mack.removeListEntry("ignore_dirs", directoryName)
	} else {
		Mack.addOrReturnListEntry("ignore_dirs", directoryName)
	}
}

maintainFilesToIgnore(fileName, noOptGiven="") {
	if (noOptGiven) {
		index := Mack.removeListEntry("ignore_files", fileName)
	} else {
		index := Mack.addOrReturnListEntry("ignore_files", fileName)
	}
	return index
}

removeFileType(fileType) {
	currentValue := Mack.option.types.delete(fileType)
	if (currentValue == "") {
		throw Exception("InvalidFiletype:" fileType)
	}
	Mack.option.regex_of_types := Mack.typeListAsRegularExpression()
	Mack.sel_Types_Option.stExpr := Mack.option.regex_of_types
	return currentValue
}

addFileTypePattern(fileTypeFilter) {
	if (!RegExMatch(fileTypeFilter, "([a-z]+):(.+)", $)) {
		throw Exception("InvalidFiletypeFilter:" fileTypeFilter)
	}
	if (Mack.option.types[$1] == "") {
		throw Exception("UnknownFiletype:" $1)
	}
	Mack.option.types[$1] .= " " StrReplace($2, "+", " ")
}

addNewFileType(fileTypeFilter) {
	if (!RegExMatch(fileTypeFilter, "([a-z]+):(.+)", $)) {
		throw Exception("InvalidFiletypeFilter:" fileTypeFilter)
	}
	if (Mack.option.types[$1] != "") {
		throw Exception("FiletypeAlreadyDefined:" $1)
	}
	Mack.option.types[$1] := StrReplace($2, "+", " ")
	Mack.option.regex_of_types := Mack.typeListAsRegularExpression()
	Mack.sel_Types_Option.stExpr := Mack.option.regex_of_types
}

maintainTypeFilter(filetype, noOptGiven="") {
	if (Mack.option.types[filetype] == "") {
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
