; ahk: con
#NoEnv
SetBatchLines -1
#Warn All, StdOut

#Include <testcase-libs>
#Include <FlimsyData>
#Include <Calendar>
#Include <Random>
#Include <Structure>

#Include <modules\structure\TIME_ZONE_INFORMATION>
#Include <modules\structure\DYNAMIC_TIME_ZONE_INFORMATION>
#Include <modules\structure\SYSTEMTIME>

#Include *i %A_ScriptDir%\..\.versioninfo

class MackTest extends TestCase {

	requires() {
		return [TestCase, FlimsyData, Mack]
	}

	@BeforeClass_createTestData() {
		if (!FileExist(A_Scriptdir "\Testdata")) {
			OutputDebug *** Create Testdata ***
			FileCreateDir %A_ScriptDir%\Testdata
			SetWorkingDir %A_ScriptDir%\Testdata
			fd1 := new FlimsyData.simple(1428)
			fd2 := new FlimsyData.lorem(2404)
			dir_list := []
			loop 20 {
				dir_name := ""
				loop % fd1.getInt(1, 4) {
					dir_name .= (dir_name = "" ? "" : "\")
							. fd2.getWord("PFolderName")
					dir_list.insert(dir_name)
				}
				FileCreateDir %dir_name%
			}
			loop 200 {
				dir_name := dir_list[fd1.getInt(dir_list.minIndex()+2
						, dir_list.maxIndex()-2)]
				file_name := fd2.getWord("PFileName")
						. "." fd2.getWord("PFileext")
				FileAppend % fd2.getParagraph("PLorem", fd1.getInt(1, 20))
						, %dir_name%\%file_name%
			}
		}
	}

	@BeforeClass_disablePager() {
		Pager.runInTestMode := true
		Pager.breakMessage := "--break--"
	}

	@BeforeResetLineCounter() {
		Pager.lineCounter := 0
	}

	@Before_resetOptions() {
		Mack.setDefaults()
		EnvSet MACK_OPTIONS,
	}

	@Before_redirStdOut() {
		Ansi.stdOut := FileOpen(A_Temp "\mack-test.txt", "w `n")
	}

	@After_redirStdOut() {
		Ansi.stdOut.close()
		Ansi.stdOut := Ansi.__InitStdOut()
		FileDelete %A_Temp%\mack-test.txt
	}

	@Test_checkHelpTypes() {
		preDefTypeList =
		; ahklint-ignore-begin: W001
		( LTrim RTrim0
			autohotkey *.ahk                                             
			batch      *.bat *.cmd                                       
			css        *.css                                             
			html       *.htm *.html                                      
			java       *.java *.properties                               
			js         *.js                                              
			json       *.json                                            
			log        *.log                                             
			md         *.md *.mkd *.markdown                             
			python     *.py                                              
			ruby       *.rb *.rhtml *.rjs *.rxml *.erb *.rake *.spec     
			shell      *.sh                                              
			tex        *.tex *.latex *.cls *.sty                         
			text       *.txt *.rtf *.readme                              
			vim        *.vim                                             
			xml        *.xml *.dtd *.xsl *.xslt *.ent                    
			yaml       *.yaml *.yml                                      

		)
		; ahklint-ignore-end
		this.assertTrue(IsFunc("Mack.printKnownFileTypes"))
		this.assertEquals(Mack.printKnownFileTypes(), preDefTypeList)
	}

	@Test_getVersionInfo() {
		this.assertTrue(IsFunc("Mack.getVersionInfo"))
		this.assertTrue(InStr(Mack.getVersionInfo(), " Copyright (C) "))
	}

	@Test_checkDefaultModeLineExpression() {
		this.assertTrue(IsFunc("Mack.setDefaultModelineExpression"))
		this.assertEquals(SubStr(Mack.option.modeline_expr, 1, 2), "J)")
	}

	@Test_refineFilePattern() {
		SetWorkingDir %A_ScriptDir%\Testdata
		this.assertEquals(Mack.refineFileOrPathPattern("."), ".\*.*")
		this.assertEquals(Mack.refineFileOrPathPattern("Verkehrsdaten")
				, "Verkehrsdaten\*.*")
		this.assertEquals(Mack.refineFileOrPathPattern("Verkehrsdaten\")
				, "Verkehrsdaten\*.*")
		this.assertEquals(Mack.refineFileOrPathPattern("Verkehrsdaten\*")
				, "Verkehrsdaten\*")
		this.assertEquals(Mack.refineFileOrPathPattern("Verkehrsdaten\a*.txt")
				, "Verkehrsdaten\a*.txt")
		this.assertEquals(Mack.refineFileOrPathPattern("Verkehrsdaten\*.*")
				, "Verkehrsdaten\*.*")
	}

	@Test_regexOfTypeList() {
		this.assertEquals(Mack.typeListAsRegularExpression()
				, "(autohotkey|batch|css|html|java|js|json|log|md|python|ruby|shell|tex|text|vim|xml|yaml)") ; ahklint-ignore: W002
	}

	@Test_types() {
		this.assertEquals(Mack.typeListAsRegularExpression()
				, "(autohotkey|batch|css|html|java|js|json|log|md|python|ruby|shell|tex|text|vim|xml|yaml)") ; ahklint-ignore: W002
		removeFileType("autohotkey")
		this.assertEquals(Mack.typeListAsRegularExpression()
				, "(batch|css|html|java|js|json|log|md|python|ruby|shell|tex|text|vim|xml|yaml)") ; ahklint-ignore: W002
		this.assertException("", "addFileTypePattern", "", "", "autohotkey:*.ahk+*.inc") ; ahklint-ignore: W002
		addNewFileType("autohotkey:*.ahk+*.inc")
		this.assertEquals(Mack.typeListAsRegularExpression()
				, "(autohotkey|batch|css|html|java|js|json|log|md|python|ruby|shell|tex|text|vim|xml|yaml)") ; ahklint-ignore: W002
		addFileTypePattern("autohotkey:*.ahi")
		preDefTypeList =
		; ahklint-ignore-begin: W001
		( LTrim RTrim0
			autohotkey *.ahk *.inc *.ahi                                 
			batch      *.bat *.cmd                                       
			css        *.css                                             
			html       *.htm *.html                                      
			java       *.java *.properties                               
			js         *.js                                              
			json       *.json                                            
			log        *.log                                             
			md         *.md *.mkd *.markdown                             
			python     *.py                                              
			ruby       *.rb *.rhtml *.rjs *.rxml *.erb *.rake *.spec     
			shell      *.sh                                              
			tex        *.tex *.latex *.cls *.sty                         
			text       *.txt *.rtf *.readme                              
			vim        *.vim                                             
			xml        *.xml *.dtd *.xsl *.xslt *.ent                    
			yaml       *.yaml *.yml                                      

		)
		; ahklint-ignore-end
		this.assertEquals(Mack.printKnownFileTypes(), preDefTypeList)
	}

	@Test_regexOfFileTypePattern() {
		this.assertEquals(Mack.convertFilePatternToRegularExpression("*.*")
				, ".*?\..*?")
		this.assertEquals(Mack.convertFilePatternToRegularExpression(".git")
				, "\.git")
		this.assertEquals(Mack.convertFilePatternToRegularExpression("CVS")
				, "CVS")
	}

	@Test_regexMatchList() {
		this.assertEquals(Mack
				.convertArrayToRegularExpression(["abc", "def", "ghi"])
				, "S)^(abc|def|ghi)$")
		this.assertEquals(Mack.convertArrayToRegularExpression([]), "")
		this.assertEquals(Mack.convertArrayToRegularExpression(["xyz"])
				, "S)^(xyz)$")
	}

	@Test_isEntryInList() {
		Mack.option.ignore_dirs := [ "\.git", "\.svn", "CVS" ]
		this.assertException(Mack, "positionInList", "", "", "ignore_dirs"
				, "foobar")
		this.assertEquals(Mack.positionInList("ignore_dirs", "\.svn"), 2)
	}

	@Test_addToList() {
		Mack.option.ignore_dirs := []
		this.assertEquals(Mack.option.ignore_dirs.maxIndex(), "")
		this.assertEquals(Mack.addOrReturnListEntry("ignore_dirs", ".git"), 1)
		this.assertEquals(Mack.addOrReturnListEntry("ignore_dirs", ".svn"), 2)
		this.assertEquals(Mack.addOrReturnListEntry("ignore_dirs", "CVS"), 3)
		this.assertEquals(Mack.option.ignore_dirs.maxIndex(), 3)
		this.assertEquals(Mack.option.ignore_dirs[1], "\.git")
		this.assertEquals(Mack.option.ignore_dirs[2], "\.svn")
		this.assertEquals(Mack.option.ignore_dirs[3], "CVS")

		Mack.addOrReturnListEntry("ignore_dirs", ".git")
		this.assertEquals(Mack.option.ignore_dirs.maxIndex(), 3)
		this.assertEquals(Mack.option.ignore_dirs[1], "\.git")
		this.assertEquals(Mack.option.ignore_dirs[2], "\.svn")
		this.assertEquals(Mack.option.ignore_dirs[3], "CVS")

		Mack.addOrReturnListEntry("type", "*.ahk")
		this.assertEquals(Mack.option.type.maxIndex(), 1)
		this.assertEquals(Mack.option.type[1], ".*?\.ahk")
	}

	@Test_removeFromList() {
		Mack.option.ignore_dirs := [ "\.git", "\.svn", "CVS" ]
		this.assertException(Mack, "removeListEntry", "", "", "ignore_dirs"
				, "foobar")
		x := Mack.option.ignore_dirs.maxIndex()
		this.assertEquals(Mack.removeListEntry("ignore_dirs", ".svn"), "\.svn")
		this.assertTrue(Mack.option.ignore_dirs.maxIndex() = x - 1)
	}

	@Test_deleteType() {
		this.assertException("", "removeFileType", "", "", "foo")
		this.assertTrue(Mack.option.types.hasKey("text"))
		this.assertEquals(removeFileType("text"), "*.txt *.rtf *.readme")
		this.assertFalse(Mack.option.types.hasKey("text"))
	}

	@Test_addFileTypePattern() {
		this.assertException("", "addFileTypePattern", "", ""
				, "foo:*.bar+*.buzz")
		this.assertException("", "addFileTypePattern", "", "", "foo")
		this.assertTrue(Mack.option.types.hasKey("text"))
		addFileTypePattern("text:*.doc")
		this.assertEquals(Mack.option.types["text"]
				, "*.txt *.rtf *.readme *.doc")
	}

	@Test_addNewFileType() {
		this.assertException("", "addNewFileType", "", "", "text:*.txt+*.doc")
		this.assertException("", "addNewFileType", "", "", "foo")
		this.assertFalse(Mack.option.types.hasKey("foo"))
		addNewFileType("foo:*.bar")
		this.assertEquals(Mack.option.types["foo"], "*.bar")
	}

	@Test_typeFilter() {
		this.assertException("", "maintainTypeFilter", "", "", "foo")
		this.assertException("", "maintainTypeFilter", "", "", "foo", "no")
		this.assertEquals(maintainTypeFilter("yaml"), 1)
		this.assertEquals(maintainTypeFilter("python"), 2)
		this.assertEquals(maintainTypeFilter("batch", "no"), 1)
		this.assertEquals(Mack.option.type.maxIndex(), 2)
		this.assertEquals(Mack.option.type[1], "(.*?\.yaml|.*?\.yml)")
		this.assertEquals(Mack.option.type[2], ".*?\.py")
		this.assertEquals(Mack.option.type_ignore.maxIndex(), 1)
		this.assertEquals(Mack.option.type_ignore[1], "(.*?\.bat|.*?\.cmd)")
	}

	@Test_setDefaultIgnoreDirs() {
		this.assertEquals(Mack.option.ignore_dirs.maxIndex(), 3)
		this.assertEquals(Mack.option.ignore_dirs[1], "\.svn")
		this.assertEquals(Mack.option.ignore_dirs[2], "\.git")
		this.assertEquals(Mack.option.ignore_dirs[3], "CVS")
	}

	@Test_setDefaultIgnoreFiles() {
		this.assertEquals(Mack.option.ignore_files.maxIndex(), 7)
		this.assertEquals(Mack.option.ignore_files[1], "#.*?#")
		this.assertEquals(Mack.option.ignore_files[2], ".*?~")
		this.assertEquals(Mack.option.ignore_files[3], ".*?\.bak")
		this.assertEquals(Mack.option.ignore_files[4], ".*?\.swp")
		this.assertEquals(Mack.option.ignore_files[5], ".*?\.exe")
		this.assertEquals(Mack.option.ignore_files[6], ".*?\.dll")
		this.assertEquals(Mack.option.ignore_files[7], "Thumbs\.db")
	}

	@Test_arrayToString() {
		this.assertEquals(Mack.arrayOrStringToString("foo"), "foo")
		this.assertEquals(Mack.arrayOrStringToString(["foo", "bar", "buzz"])
				, "foobarbuzz")
	}

	@Test_ignoreDir() {
		x := Mack.option.ignore_dirs.maxIndex()
		maintainDirectoriesToIgnore("foo")
		this.assertEquals(Mack.option.ignore_dirs[x+1], "foo")
		maintainDirectoriesToIgnore("foo", "no")
		this.assertEquals(Mack.option.ignore_dirs.maxIndex(), x)
	}

	@Test_ignoreFile() {
		x := Mack.option.ignore_files.maxIndex()
		this.assertEquals(maintainFilesToIgnore("*.foo"), x+1)
		this.assertEquals(Mack.option.ignore_files[x+1], ".*?\.foo")
		this.assertEquals(maintainFilesToIgnore("*.foo", "no"), ".*?\.foo")
		this.assertEquals(Mack.option.ignore_files.maxIndex(), x)
	}

	@Test_determineFiles() {
		SetWorkingDir %A_ScriptDir%\Testdata
		Mack.option.sort_files := true
		list := Mack.determineFilesForSearch(["Plan", "Ammenmaerchen"])
		this.assertEquals(list.maxIndex(), 45)
		; ahklint-ignore-begin: W002
		this.assertEquals(list[1], "Ammenmaerchen\Adelsdiplom.mp3")
		this.assertEquals(list[2], "Ammenmaerchen\Anlage.pdf")
		this.assertEquals(list[3], "Ammenmaerchen\Auskunftsschalter\Aktienurkunde.rtf")
		this.assertEquals(list[4], "Ammenmaerchen\Auskunftsschalter\Arztbrief.html")
		this.assertEquals(list[5], "Ammenmaerchen\Auskunftsschalter\Rundschreiben.pdf")
		this.assertEquals(list[6], "Ammenmaerchen\Auskunftsschalter\Schema\Anfuegung.html")
		this.assertEquals(list[7], "Ammenmaerchen\Auskunftsschalter\Schema\Bericht.pdf")
		this.assertEquals(list[8], "Ammenmaerchen\Auskunftsschalter\Schema\Bescheid.txt")
		this.assertEquals(list[9], "Ammenmaerchen\Auskunftsschalter\Schema\Geograph.md")
		this.assertEquals(list[10], "Ammenmaerchen\Auskunftsschalter\Schema\Geograph.mp3")
		this.assertEquals(list[11], "Ammenmaerchen\Auskunftsschalter\Schema\Geschichte.md")
		this.assertEquals(list[12], "Ammenmaerchen\Auskunftsschalter\Schema\Schlussformel.rtf")
		this.assertEquals(list[13], "Ammenmaerchen\Auskunftsschalter\Schema\Wertpapier.jpeg")
		this.assertEquals(list[14], "Ammenmaerchen\Auskunftsschalter\unbelebtes.pdf")
		this.assertEquals(list[15], "Ammenmaerchen\Befundbericht.pdf")
		this.assertEquals(list[16], "Ammenmaerchen\Buchung.md")
		this.assertEquals(list[17], "Ammenmaerchen\L-Schein.txt")
		this.assertEquals(list[18], "Ammenmaerchen\Nachlassdokument.exe")
		this.assertEquals(list[19], "Ammenmaerchen\Strafzettel.html")
		this.assertEquals(list[20], "Ammenmaerchen\Wertpapier.doc")
		this.assertEquals(list[21], "Ammenmaerchen\nicht.doc")
		this.assertEquals(list[22], "Plan\Autograph.png")
		this.assertEquals(list[23], "Plan\Bekanntmachung\Adelsdiplom.png")
		this.assertEquals(list[24], "Plan\Bekanntmachung\Anfuegung.rtf")
		this.assertEquals(list[25], "Plan\Bekanntmachung\Archivale.mp3")
		this.assertEquals(list[26], "Plan\Bekanntmachung\Ueberweisungsschein.ahk")
		this.assertEquals(list[27], "Plan\Bekanntmachung\Waffenpass.html")
		this.assertEquals(list[28], "Plan\Bericht.pdf")
		this.assertEquals(list[29], "Plan\Bericht\Anlage.mp3")
		this.assertEquals(list[30], "Plan\Bericht\Aussendung.png")
		this.assertEquals(list[31], "Plan\Bericht\Fakten\Bemerkung.html")
		this.assertEquals(list[32], "Plan\Bericht\Fakten\Communiquee.pdf")
		this.assertEquals(list[33], "Plan\Bericht\Fakten\Konnossement.mp3")
		this.assertEquals(list[34], "Plan\Bericht\Fakten\Kurrende.ahk")
		this.assertEquals(list[35], "Plan\Bericht\Fakten\Rundbrief.rtf")
		this.assertEquals(list[36], "Plan\Bericht\Fakten\Schlussformel.exe")
		this.assertEquals(list[37], "Plan\Bericht\Fakten\Schriftstueck.ahk")
		this.assertEquals(list[38], "Plan\Bericht\Letzter_Wille.rtf")
		this.assertEquals(list[39], "Plan\Bericht\Nichtveranlagungsbescheinigung.jpeg")
		this.assertEquals(list[40], "Plan\Bulletin.ahk")
		this.assertEquals(list[41], "Plan\Communiquee.mp3")
		this.assertEquals(list[42], "Plan\L-Schein.pdf")
		this.assertEquals(list[43], "Plan\Nachlassdokument.rtf")
		this.assertEquals(list[44], "Plan\Presseerklaerung.ahk")
		this.assertEquals(list[45], "Plan\Presseerklaerung.txt")
		; ahklint-ignore-end

		SetWorkingDir %A_ScriptDir%\Testdata\Schema\Fakten\Verkehrsdaten
		list := Mack.determineFilesForSearch([])
		this.assertEquals(list.maxIndex(), 3)
	}

	@Test_collectFileNames() {
		SetWorkingDir %A_ScriptDir%\Testdata
		Mack.option.r := false
		list := Mack.collectFileNames("Plan")
		this.assertEquals(list.maxIndex(), 8)
		this.assertEquals(list[1], "Plan\Autograph.png")
		this.assertEquals(list[2], "Plan\Bericht.pdf")
		this.assertEquals(list[3], "Plan\Bulletin.ahk")
		this.assertEquals(list[4], "Plan\Communiquee.mp3")
		this.assertEquals(list[5], "Plan\L-Schein.pdf")
		this.assertEquals(list[6], "Plan\Nachlassdokument.rtf")
		this.assertEquals(list[7], "Plan\Presseerklaerung.ahk")
		this.assertEquals(list[8], "Plan\Presseerklaerung.txt")

		Mack.option.r := true
		list := Mack.collectFileNames("Plan")
		this.assertEquals(list.maxIndex(), 24)
		; ahklint-ignore-begin: W002
		this.assertEquals(list[1],	"Plan\Autograph.png")
		this.assertEquals(list[2], "Plan\Bekanntmachung\Adelsdiplom.png")
		this.assertEquals(list[3], "Plan\Bekanntmachung\Anfuegung.rtf")
		this.assertEquals(list[4], "Plan\Bekanntmachung\Archivale.mp3")
		this.assertEquals(list[5], "Plan\Bekanntmachung\Ueberweisungsschein.ahk")
		this.assertEquals(list[6], "Plan\Bekanntmachung\Waffenpass.html")
		this.assertEquals(list[7], "Plan\Bericht\Anlage.mp3")
		this.assertEquals(list[8], "Plan\Bericht\Aussendung.png")
		this.assertEquals(list[9], "Plan\Bericht\Fakten\Bemerkung.html")
		this.assertEquals(list[10], "Plan\Bericht\Fakten\Communiquee.pdf")
		this.assertEquals(list[11], "Plan\Bericht\Fakten\Konnossement.mp3")
		this.assertEquals(list[12], "Plan\Bericht\Fakten\Kurrende.ahk")
		this.assertEquals(list[13], "Plan\Bericht\Fakten\Rundbrief.rtf")
		this.assertEquals(list[14], "Plan\Bericht\Fakten\Schlussformel.exe")
		this.assertEquals(list[15], "Plan\Bericht\Fakten\Schriftstueck.ahk")
		this.assertEquals(list[16], "Plan\Bericht\Letzter_Wille.rtf")
		this.assertEquals(list[17], "Plan\Bericht\Nichtveranlagungsbescheinigung.jpeg")
		this.assertEquals(list[18], "Plan\Bericht.pdf")
		this.assertEquals(list[19], "Plan\Bulletin.ahk")
		this.assertEquals(list[20], "Plan\Communiquee.mp3")
		this.assertEquals(list[21], "Plan\L-Schein.pdf")
		this.assertEquals(list[22], "Plan\Nachlassdokument.rtf")
		this.assertEquals(list[23], "Plan\Presseerklaerung.ahk")
		this.assertEquals(list[24], "Plan\Presseerklaerung.txt")
		; ahklint-ignore-end
	}

	@Test_processLine() {
		fd1 := new FlimsyData.simple(1517)
		Mack.option.A := 3
		Mack.option.B := 3
		lineNr := 1
		loop 50 {
			lineNr += fd1.getInt(1, 3)
			Mack.processLine(lineNr " Test " A_Index)
		}
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\mack-test.txt")
				, TestCase.fileContent(A_ScriptDir "\Figures\ProcessLines.txt"))
	}

	@Test_modeline1() {
		SetWorkingDir %A_ScriptDir%\Testdata
		if (FileExist("modeline_test.txt")) {
			FileDelete modeline_test.txt
		}
		FileAppend `; `tvim:ts=07, modeline_test.txt
		this.assertEquals(Mack.run([".", "modeline_test.txt"]), "")
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\mack-test.txt")
				, TestCase.fileContent(A_ScriptDir "\Figures\Modeline.txt"))
		FileDelete modeline_test.txt
	}

	@Test_Modeline2() {
		SetWorkingDir %A_ScriptDir%\Testdata
		if (FileExist("modeline_test.txt")) {
			FileDelete modeline_test.txt
		}
		FileAppend `n`n`n`n`n`n; `tvim:ts=03, modeline_test.txt
		this.assertEquals(Mack.run([".", "modeline_test.txt"]), "")
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\mack-test.txt")
				, TestCase.fileContent(A_ScriptDir "\Figures\Modeline2.txt"))
		FileDelete modeline_test.txt
	}

	@Test_VersionInfo() {
		this.assertEquals(Mack.run(["--version"]), "")
		Ansi.flush()
		this.assertTrue(RegExMatch(TestCase.fileContent(A_Temp "\mack-test.txt")
				, ".+"))
	}

	@Test_helpTypes() {
		this.assertEquals(Mack.run(["--help-types"]), "")
		Ansi.flush()
		this.assertTrue(RegExMatch(TestCase.fileContent(A_Temp "\mack-test.txt")
				, ".+"))
	}

	@Test_usage() {
		this.assertEquals(Mack.run(["-h"]), "")
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\mack-test.txt")
				, TestCase.fileContent(A_ScriptDir "\Figures\Usage.txt"))
	}

	@Test_badUsage() {
		this.assertEquals(Mack.run(["--foo"]), "")
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\mack-test.txt")
				, TestCase.fileContent(A_ScriptDir "\Figures\BadUsage.txt")
				. TestCase.fileContent(A_ScriptDir "\Figures\usage.txt"))
	}

	@Test_fileList() {
		SetWorkingDir %A_ScriptDir%\Testdata
		this.assertEquals(Mack.run(["-f"]), "")
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\mack-test.txt")
				, TestCase.fileContent(A_ScriptDir "\Figures\Filelist.txt"))
	}

	@Test_patternFilelist() {
		SetWorkingDir %A_ScriptDir%\Testdata
		this.assertEquals(Mack.run(["--nopager", "--sort-files", "-g"
				, "i)^[abcklmstu].*\.txt$"]), "")
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\mack-test.txt")
				, TestCase.fileContent(A_ScriptDir
				. "\Figures\Pattern-Filelist.txt"))
	}

	@Test_FilteredFilelist() {
		SetWorkingDir %A_ScriptDir%\Testdata
		this.assertEquals(Mack.run(["--nopager", "--type", "autohotkey", "-ilc"
				, "est lorem ipsum dolor sit amet\."]), "")
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\mack-test.txt")
				, TestCase.fileContent(A_ScriptDir
				. "\Figures\Filtered-Filelist.txt"))
	}

	@Test_FilteredTypenameFilelist() {
		SetWorkingDir %A_ScriptDir%\Testdata
		this.assertEquals(Mack.run(["--nopager", "--autohotkey", "-ilc"
				, "est lorem ipsum dolor sit amet\."]), "")
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\mack-test.txt")
				, TestCase.fileContent(A_ScriptDir
				. "\Figures\Filtered-Filelist.txt"))
	}

	@Test_FilesWithMatches1() {
		SetWorkingDir %A_ScriptDir%\Testdata
		this.assertEquals(Mack.run(["--nopager", "--type", "autohotkey", "-Qw"
				, "--files-with-matches", "ut", "Verkehrsdaten\"]), "")
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\mack-test.txt")
				, TestCase.fileContent(A_ScriptDir
				. "\Figures\FilesWithMatches1.txt"))
	}

	@Test_FilesWithMatches2() {
		SetWorkingDir %A_ScriptDir%\Testdata
		this.assertEquals(Mack.run(["--nopager", "--type", "autohotkey"
				, "--nocolor", "-Qw", "--files-with-matches", "ut"
				, "Verkehrsdaten\"])
				, "")
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\mack-test.txt")
				, TestCase.fileContent(A_ScriptDir
				. "\Figures\FilesWithMatches2.txt"))
	}

	@Test_FilesWithoutMatches1() {
		SetWorkingDir %A_ScriptDir%\Testdata
			this.assertEquals(Mack.run(["--nopager", "--type", "autohotkey"
					, "--nocolor", "-L", "foo", "Verkehrsdaten\"]), "")
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\mack-test.txt")
				, TestCase.fileContent(A_ScriptDir
				. "\Figures\FilesWithoutMatches1.txt"))
	}

	@Test_FilesWithoutMatches2() {
		SetWorkingDir %A_ScriptDir%\Testdata
			this.assertEquals(Mack.run(["--nopager", "--type", "autohotkey"
					, "-L", "foo", "Verkehrsdaten\"]), "")
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\mack-test.txt")
				, TestCase.fileContent(A_ScriptDir
				. "\Figures\FilesWithoutMatches2.txt"))
	}

	@Test_Search1() {
		SetWorkingDir %A_ScriptDir%\Testdata
		this.assertEquals(Mack.run(["--type", "autohotkey", "--column"
				, "Lorem ipsum dolor sit amet,", "Verkehrsdaten\"]), "")
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\mack-test.txt")
				, TestCase.fileContent(A_ScriptDir "\Figures\Search1.txt"))
	}

	@Test_Search2() {
		SetWorkingDir %A_ScriptDir%\Testdata
		this.assertEquals(Mack.run(["--type", "autohotkey", "--nocolor"
				, "-v", "Lorem ipsum dolor sit amet,", "Verkehrsdaten\"]), "")
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\mack-test.txt")
				, TestCase.fileContent(A_ScriptDir "\Figures\Search2.txt"))
	}

	@Test_Search3() {
		SetWorkingDir %A_ScriptDir%\Testdata
		this.assertEquals(Mack.run(["--type", "autohotkey", "-C", "3"
				, "Lorem ipsum dolor sit amet,", "Verkehrsdaten\"]), "")
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\mack-test.txt")
				, TestCase.fileContent(A_ScriptDir "\Figures\Search3.txt"))
	}

	@Test_Search4() {
		SetWorkingDir %A_ScriptDir%\Testdata
		this.assertEquals(Mack.run(["--autohotkey", "--nocolor", "-C"
				, "2", "Lorem ipsum dolor sit amet,", "Verkehrsdaten\"]), "")
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\mack-test.txt")
				, TestCase.fileContent(A_ScriptDir "\Figures\Search4.txt"))
	}

	@Test_Search5() {
		SetWorkingDir %A_ScriptDir%\Testdata
		this.assertEquals(Mack.run(["--nopager", "--autohotkey", "--output"
				, "$1", "Lorem ipsum dolor sit amet(.)", "Verkehrsdaten\"]), "")
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\mack-test.txt")
				, TestCase.fileContent(A_ScriptDir "\Figures\Search5.txt"))
	}

	@Test_Search6() {
		SetWorkingDir %A_ScriptDir%\Testdata
		this.assertEquals(Mack.run(["--nopager", "--autohotkey", "--output"
				, "$0", "Lorem ipsum dolor sit amet(.)", "Verkehrsdaten\"]), "")
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\mack-test.txt")
				, TestCase.fileContent(A_ScriptDir "\Figures\Search6.txt"))
	}

	@Test_Search7() {
		SetWorkingDir %A_ScriptDir%\Testdata
		this.assertEquals(Mack.run(["--autohotkey", "-c"
				, "Lorem ipsum dolor sit amet,", "Verkehrsdaten\"]), "")
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\mack-test.txt")
				, TestCase.fileContent(A_ScriptDir "\Figures\Search7.txt"))
	}

	@Test_Search8() {
		SetWorkingDir %A_ScriptDir%\Testdata
		this.assertEquals(Mack.run(["--nopager", "--autohotkey", "-cQ"
				, "--nocolor", "Lorem ipsum dolor sit amet.", "Verkehrsdaten\"])
				, "")
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\mack-test.txt")
				, TestCase.fileContent(A_ScriptDir "\Figures\Search8.txt"))
	}

	@Test_Search9() {
		SetWorkingDir %A_ScriptDir%\Testdata
		this.assertEquals(Mack.run(["--nopager", "--autohotkey", "-C"
				, "2", "eleifend", "Verkehrsdaten\"]), "")
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\mack-test.txt")
				, TestCase.fileContent(A_ScriptDir "\Figures\Search9.txt"))
	}

	@Test_Search10() {
		SetWorkingDir %A_ScriptDir%\Testdata
		this.assertEquals(Mack.run(["--autohotkey", "-A", "2", "^Duis\s"
				, "Verkehrsdaten\"]), "")
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\mack-test.txt")
				, TestCase.fileContent(A_ScriptDir "\Figures\Search10.txt"))
	}

	@Test_Search11() {
		SetWorkingDir %A_ScriptDir%\Testdata
		f := FileOpen("Verkehrsdaten\Adelsdiplom.ahk", "r-rwd")
		this.assertEquals(Mack.run(["--nopager", "--autohotkey", "-A", "2"
				, "^Duis\s", "Verkehrsdaten\"]), "")
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\mack-test.txt")
				, TestCase.fileContent(A_ScriptDir "\Figures\Search11.txt")
				. TestCase.fileContent(A_ScriptDir "\Figures\usage.txt"))
		f.close()
	}

	@Test_noSearchPattern() {
		SetWorkingDir %A_ScriptDir%\Testdata
		this.assertEquals(Mack.run(["--nopager", "--autohotkey"]), "")
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\mack-test.txt")
				, TestCase.fileContent(A_ScriptDir
				. "\Figures\NoSearchPattern.txt")
				. TestCase.fileContent(A_ScriptDir "\Figures\usage.txt"))
	}

	@Test_SearchNoHits() {
		SetWorkingDir %A_ScriptDir%\Testdata
		this.assertEquals(Mack.run(["--nopager", "--autohotkey", "--no-html"
				, "-L", "^Duis ", "Verkehrsdaten\"]), "")
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\mack-test.txt"), "")
	}

	@Test_Search13() {
		SetWorkingDir %A_ScriptDir%\Testdata
		this.assertEquals(Mack.run(["--nopager", "-k", "^Duis "
				, "Verkehrsdaten\"]), "")
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\mack-test.txt")
				, TestCase.fileContent(A_ScriptDir "\Figures\Search13.txt"))
	}

	@Test_Search14() {
		SetWorkingDir %A_ScriptDir%\Testdata
		this.assertEquals(Mack.run(["--nopager", "--column", "-o", "^Duis "
				, "Verkehrsdaten\"]), "")
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\mack-test.txt")
				, TestCase.fileContent(A_ScriptDir "\Figures\Search14.txt"))
	}

	@Test_Search15() {
		SetWorkingDir %A_ScriptDir%\Testdata
		this.assertEquals(Mack.run(["--nopager", "--autohotkey"
				, "--nocolor", "-C", "2", "eleifend", "Verkehrsdaten\"]), "")
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\mack-test.txt")
				, TestCase.fileContent(A_ScriptDir "\Figures\Search15.txt"))
	}

	@Test_Search16() {
		SetWorkingDir %A_ScriptDir%\Testdata
		this.assertEquals(Mack.run(["--nopager", "--autohotkey", "-1"
				, "eleifend", "Verkehrsdaten\"]), "")
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\mack-test.txt")
				, TestCase.fileContent(A_ScriptDir "\Figures\Search16.txt"))
	}

	@Test_Search17() {
		SetWorkingDir %A_ScriptDir%\Testdata
		this.assertEquals(Mack.run(["--nopager", "--autohotkey", "--nocolor"
				, "-1", "eleifend", "Verkehrsdaten\"]), "")
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\mack-test.txt")
				, TestCase.fileContent(A_ScriptDir "\Figures\Search17.txt"))
	}

	@Test_Search18() {
		SetWorkingDir %A_ScriptDir%\Testdata
		this.assertEquals(Mack.run(["--nopager", "--autohotkey", "--nocolor"
				, "-1v", "eleifend", "Verkehrsdaten\"]), "")
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\mack-test.txt")
				, TestCase.fileContent(A_ScriptDir "\Figures\Search18.txt"))
	}

	@Test_Search19() {
		SetWorkingDir %A_ScriptDir%\Testdata
		this.assertEquals(Mack.run(["--nopager", "--type", "autohotkey"
				, "--nocolor", "--column", "Lorem ipsum dolor sit amet,"
				, "Verkehrsdaten\"]), "")
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\mack-test.txt")
				, TestCase.fileContent(A_ScriptDir "\Figures\Search19.txt"))
	}

	@Test_search20() {
		if (FileExist("fizzbuzz_test.txt")) {
			FileDelete fizzbuzz_test.txt
		}
		loop 100 {
			FileAppend % (mod(A_Index, 15) == 0 ? "FizzBuzz"
					: mod(A_Index, 3) == 0 ? "Fizz"
					: mod(A_Index, 5) == 0 ? "Buzz"
					: A_Index) "`n", fizzbuzz_test.txt
		}
		this.assertEquals(Mack.run(["--nopager",  "-C", "--nocolor", "\d2"
				, "fizzbuzz_test.txt"]), "")
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\mack-test.txt")
				, TestCase.fileContent(A_ScriptDir "\Figures\Search20.txt"))
		FileDelete fizzbuzz_test.txt
	}

	@Test_search20With_mackrc() {
		if (FileExist("fizzbuzz_test.txt")) {
			FileDelete fizzbuzz_test.txt
		}
		if (FileExist("_mymackrc")) {
			FileDelete _mymackrc
		}
		loop 100 {
			FileAppend % (mod(A_Index, 15) == 0 ? "FizzBuzz"
					: mod(A_Index, 3) == 0 ? "Fizz"
					: mod(A_Index, 5) == 0 ? "Buzz"
					: A_Index) "`n", fizzbuzz_test.txt
		}
		FileAppend,
		( LTrim ; ahklint-ignore-begin: I001,W003
			--nopager
			-C
			--nocolor
		), _mymackrc
		; ahklint-ignore-end
		this.assertEquals(Mack.run(["--mackrc", "_mymackrc", "\d2"
				, "fizzbuzz_test.txt"]), "")
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\mack-test.txt")
				, TestCase.fileContent(A_ScriptDir "\Figures\Search20.txt"))
		FileDelete fizzbuzz_test.txt
		FileDelete _mymackrc
	}

	@Test_filesFromFile() {
		SetWorkingDir %A_ScriptDir%\Testdata
		if (FileExist(A_ScriptDir "\input_files.txt")) {
			FileDelete %A_ScriptDir%\input_files.txt
		}
		FileAppend,
		( LTrim ; ahklint-ignore-begin: W002,W003
			.\Ammenmaerchen\Anlage.pdf
			.\Ammenmaerchen\Auskunftsschalter\Aktienurkunde.rtf
			.\Bekanntmachung\Informationsuebertragung\Basisinformationen\Anlage.mp3
			.\Buecherei\Wissen\Archivale.rtf
			.\Datenansammlung\Anlage.jpeg
			.\Datenansammlung\Anlage.txt
			.\Metainformationen\Archivale.md
			.\Metainformationen\Archivale.pdf
			.\Plan\Bekanntmachung\Archivale.mp3
			.\Plan\Bericht\Anlage.mp3
			.\Verkehrsdaten\Abstraktion\Archivale.rtf
			.\Verkehrsdaten\Botschaft\Nachrichteninhalt\Datenuebertragung\Aktienurkunde.pdf
		), %A_ScriptDir%\input_files.txt
		; ahklint-ignore-end
		this.assertEquals(Mack.run(["--files-from"
				, A_ScriptDir "\input_files.txt", "-lc", "^Duis"]))
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\mack-test.txt")
				, TestCase.fileContent(A_ScriptDir
				. "\Figures\FilesFromFile.txt"))
		FileDelete %A_ScriptDir%\input_files.txt
	}
}

exitapp MackTest.runTests()

#Include %A_ScriptDir%\..\mack.ahk
