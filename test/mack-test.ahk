; ahk: con
#NoEnv
SetBatchLines -1
; #Warn All, OutputDebug

#Include <logging>
#Include <testcase>
#Include <flimsydata>

#Include <system>
#Include <string>
#Include <datatable>
#Include <arrays>
#Include <queue>

class MackTest extends TestCase {
	
	; @BeforeClass_...
	; @AfterClass_...
	; @Test_...
	; @Depend_@Test_...

	@BeforeClass_Setup() {
		if (!FileExist(A_Scriptdir "\Testdata")) {
            OutputDebug *** Create Testdata ***
			FileCreateDir %A_ScriptDir%\Testdata
			SetWorkingDir %A_ScriptDir%\Testdata
			fd1 := new FlimsyData.Simple(1428)
			fd2 := new FlimsyData.Lorem(2404)
			; Create test folders & files
			dir_list := []
			loop 20 {
				dir_name := ""
				loop % fd1.GetInt(1, 4) {
					dir_name .= (dir_name = "" ? "" : "\") fd2.GetWord("PFolderName")
					dir_list.Insert(dir_name)
				}
				FileCreateDir %dir_name%
			}
			loop 200 {
				dir_name := dir_list[fd1.GetInt(dir_list.MinIndex()+2, dir_list.MaxIndex()-2)]
				file_name := fd2.GetWord("PFileName") "." fd2.GetWord("PFileext")
				FileAppend % fd2.GetParagraph("PLorem", fd1.GetInt(1, 20)), %dir_name%\%file_name%
			}
		}
	}

    @Before_ResetOptions() {
        ; Reset options to default values before running any testcase
        Mack.set_defaults()
    }

	@BeforeRedirStdOut() {
		Ansi.StdOut := FileOpen(A_Temp "\mack-test.txt", "w `n")
	}

	@AfterRedirStdOut() {
		Ansi.StdOut.Close()
		Ansi.StdOut := Ansi.__InitStdOut()
		FileDelete %A_Temp%\mack-test.txt
	}

	@Test_GetVersionInfo() {
		this.AssertTrue(IsFunc("Mack.get_version_info"))
		this.AssertTrue(InStr(Mack.get_version_info(), " Copyright (C) "))
	}

	@Test_CheckHelpTypes() {
		pre_def_type_list = 
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
		this.AssertTrue(IsFunc("Mack.help_types"))
		this.AssertEquals(Mack.help_types(), pre_def_type_list)
	}

	@Test_Refine_File_Pattern() {
		SetWorkingDir %A_ScriptDir%\Testdata
		Mack.refine_file_pattern(fp := "Verkehrsdaten")
		this.AssertEquals(fp, "Verkehrsdaten\*.*")
		Mack.refine_file_pattern(fp := "Verkehrsdaten\")
		this.AssertEquals(fp, "Verkehrsdaten\*.*")
		Mack.refine_file_pattern(fp := "Verkehrsdaten\a*.txt")
		this.AssertEquals(fp, "Verkehrsdaten\a*.txt")
		Mack.refine_file_pattern(fp := "Verkehrsdaten\*.*")
		this.AssertEquals(fp, "Verkehrsdaten\*.*")
	}

	@Test_Types() {
		this.AssertEquals(Mack.regex_of_types(),"(autohotkey|batch|css|html|java|js|json|log|md|python|ruby|shell|tex|text|vim|xml|yaml)")
		del_type("autohotkey")
		this.AssertEquals(Mack.regex_of_types(),"(batch|css|html|java|js|json|log|md|python|ruby|shell|tex|text|vim|xml|yaml)")
		this.AssertException("", "add_type", "", "", "autohotkey:*.ahk+*.inc")
		set_type("autohotkey:*.ahk+*.inc")
		this.AssertEquals(Mack.regex_of_types(),"(autohotkey|batch|css|html|java|js|json|log|md|python|ruby|shell|tex|text|vim|xml|yaml)")
		add_type("autohotkey:*.ahi")
		pre_def_type_list = 
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
		this.AssertEquals(Mack.help_types(), pre_def_type_list)
	}

    @Test_Regex_Of_File_Pattern() {
        this.AssertEquals(Mack.regex_of_file_pattern("*.*"), ".*?\..*?")
        this.AssertEquals(Mack.regex_of_file_pattern(".git"), "\.git")
        this.AssertEquals(Mack.regex_of_file_pattern("CVS"), "CVS")
    }

    @Test_Regex_Match_List() {
        this.AssertEquals(Mack.regex_match_list(["abc", "def", "ghi"]), "S)^(abc|def|ghi)$")
        this.AssertEquals(Mack.regex_match_list([]), "")
        this.AssertEquals(Mack.regex_match_list(["xyz"]), "S)^(xyz)$")
    }

    @Test_Regex_Of_Types() {
        this.AssertEquals(Mack.regex_of_types(), "(autohotkey|batch|css|html|java|js|json|log|md|python|ruby|shell|tex|text|vim|xml|yaml)")
    }

    @Depend_@Test_Add_To_List() {
        return "@Test_Regex_Of_File_Pattern"
    }
    @Test_Add_To_List() {
        Mack.Option.ignore_dirs := []
        this.AssertEquals(Mack.Option.ignore_dirs.MaxIndex(), "")
        Mack.add_to_list("ignore_dirs", ".git")
        Mack.add_to_list("ignore_dirs", ".svn")
        Mack.add_to_list("ignore_dirs", "CVS")
        this.AssertEquals(Mack.Option.ignore_dirs.MaxIndex(), 3)
        this.AssertEquals(Mack.Option.ignore_dirs[1], "\.git")
        this.AssertEquals(Mack.Option.ignore_dirs[2], "\.svn")
        this.AssertEquals(Mack.Option.ignore_dirs[3], "CVS")

        Mack.add_to_list("ignore_dirs", ".git")
        this.AssertEquals(Mack.Option.ignore_dirs.MaxIndex(), 3)
        this.AssertEquals(Mack.Option.ignore_dirs[1], "\.git")
        this.AssertEquals(Mack.Option.ignore_dirs[2], "\.svn")
        this.AssertEquals(Mack.Option.ignore_dirs[3], "CVS")

        Mack.add_to_list("type", "*.ahk")
        this.AssertEquals(Mack.Option.type.MaxIndex(), 1)
        this.AssertEquals(Mack.Option.type[1], ".*?\.ahk")
    }

    @Test_Remove_From_List() {
        x := Mack.Option.ignore_dirs.MaxIndex()
        Mack.remove_from_list("ignore_dirs", ".svn")
        this.AssertTrue(Mack.Option.ignore_dirs.MaxIndex() = x - 1)
    }

    @Test_Del_Type() {
        this.AssertException("", "del_type", "", "", "foo")
        this.AssertTrue(Mack.Option.types.HasKey("text"))
        del_type("text")
        this.AssertFalse(Mack.Option.types.HasKey("text"))
    }

    @Test_Add_Type() {
        this.AssertException("", "add_type", "", "", "foo:*.bar+*.buzz")
        this.AssertException("", "add_type", "", "", "foo")
        this.AssertTrue(Mack.Option.types.HasKey("text"))
        add_type("text:*.doc")
        this.AssertEquals(Mack.Option.types["text"], "*.txt *.rtf *.readme *.doc")
    }

    @Test_Set_Type() {
        this.AssertException("", "set_type", "", "", "text:*.txt+*.doc")
        this.AssertException("", "set_type", "", "", "foo")
        this.AssertFalse(Mack.Option.types.HasKey("foo"))
        set_type("foo:*.bar")
        this.AssertEquals(Mack.Option.types["foo"], "*.bar")
    }

    @Test_Type_Filter() {
        this.AssertException("", "type_filter", "", "", "foo")
        this.AssertException("", "type_filter", "", "", "foo", "no")
        type_filter("yaml")
        type_filter("python")
        type_filter("batch", "no")
        this.AssertEquals(Mack.Option.type.MaxIndex(), 2)
        this.AssertEquals(Mack.Option.type[1], "(.*?\.yaml|.*?\.yml)")
        this.AssertEquals(Mack.Option.type[2], ".*?\.py")
        this.AssertEquals(Mack.Option.type_ignore.MaxIndex(), 1)
        this.AssertEquals(Mack.Option.type_ignore[1], "(.*?\.bat|.*?\.cmd)")
    }

    @Test_Set_Default_Ignore_Dirs() {
        this.AssertEquals(Mack.Option.ignore_dirs.MaxIndex(), 3)
        this.AssertEquals(Mack.Option.ignore_dirs[1], "\.svn")
        this.AssertEquals(Mack.Option.ignore_dirs[2], "\.git")
        this.AssertEquals(Mack.Option.ignore_dirs[3], "CVS")
    }

    @Test_Set_Default_Ignore_Files() {
        this.AssertEquals(Mack.Option.ignore_files.MaxIndex(), 7)
        this.AssertEquals(Mack.Option.ignore_files[1], "#.*?#")
        this.AssertEquals(Mack.Option.ignore_files[2], ".*?~")
        this.AssertEquals(Mack.Option.ignore_files[3], ".*?\.bak")
        this.AssertEquals(Mack.Option.ignore_files[4], ".*?\.swp")
        this.AssertEquals(Mack.Option.ignore_files[5], ".*?\.exe")
        this.AssertEquals(Mack.Option.ignore_files[6], ".*?\.dll")
        this.AssertEquals(Mack.Option.ignore_files[7], "Thumbs\.db")
    }

    @Test_Array_To_String() {
        this.AssertEquals(Mack.array_to_string("foo"), "foo")
        this.AssertEquals(Mack.array_to_string(["foo", "bar", "buzz"]), "foobarbuzz")
    }

    @Test_Ignore_Dir() {
        x := Mack.Option.ignore_dirs.MaxIndex()
        ignore_dir("foo")
        this.AssertEquals(Mack.Option.ignore_dirs[x+1], "foo")
        ignore_dir("foo", "no")
        this.AssertEquals(Mack.Option.ignore_dirs.MaxIndex(), x)
    }

    @Test_Ignore_File() {
        x := Mack.Option.ignore_files.MaxIndex()
        ignore_file("*.foo")
        this.AssertEquals(Mack.Option.ignore_files[x+1], ".*?\.foo")
        ignore_file("*.foo", "no")
        this.AssertEquals(Mack.Option.ignore_files.MaxIndex(), x)
    }

    @Test_Collect_Filenames() {
        SetWorkingDir %A_ScriptDir%\Testdata
        Mack.Option.r := false
        list := Mack.collect_filenames("Plan")
        this.AssertEquals(list.MaxIndex(), 8)
        this.AssertEquals(list[1], "Plan\Autograph.png")
        this.AssertEquals(list[2], "Plan\Bericht.pdf")
        this.AssertEquals(list[3], "Plan\Bulletin.ahk")
        this.AssertEquals(list[4], "Plan\Communiquee.mp3")
        this.AssertEquals(list[5], "Plan\L-Schein.pdf")
        this.AssertEquals(list[6], "Plan\Nachlassdokument.rtf")
        this.AssertEquals(list[7], "Plan\Presseerklaerung.ahk")
        this.AssertEquals(list[8], "Plan\Presseerklaerung.txt")

        Mack.Option.r := true
        list := Mack.collect_filenames("Plan")
        this.AssertEquals(list.MaxIndex(), 24)
        this.AssertEquals(list[1],  "Plan\Autograph.png")
        this.AssertEquals(list[2], "Plan\Bekanntmachung\Adelsdiplom.png")
        this.AssertEquals(list[3], "Plan\Bekanntmachung\Anfuegung.rtf")
        this.AssertEquals(list[4], "Plan\Bekanntmachung\Archivale.mp3")
        this.AssertEquals(list[5], "Plan\Bekanntmachung\Ueberweisungsschein.ahk")
        this.AssertEquals(list[6], "Plan\Bekanntmachung\Waffenpass.html")
        this.AssertEquals(list[7], "Plan\Bericht\Anlage.mp3")
        this.AssertEquals(list[8], "Plan\Bericht\Aussendung.png")
        this.AssertEquals(list[9], "Plan\Bericht\Fakten\Bemerkung.html")
        this.AssertEquals(list[10], "Plan\Bericht\Fakten\Communiquee.pdf")
        this.AssertEquals(list[11], "Plan\Bericht\Fakten\Konnossement.mp3")
        this.AssertEquals(list[12], "Plan\Bericht\Fakten\Kurrende.ahk")
        this.AssertEquals(list[13], "Plan\Bericht\Fakten\Rundbrief.rtf")
        this.AssertEquals(list[14], "Plan\Bericht\Fakten\Schlussformel.exe")
        this.AssertEquals(list[15], "Plan\Bericht\Fakten\Schriftstueck.ahk")
        this.AssertEquals(list[16], "Plan\Bericht\Letzter_Wille.rtf")
        this.AssertEquals(list[17], "Plan\Bericht\Nichtveranlagungsbescheinigung.jpeg")
        this.AssertEquals(list[18], "Plan\Bericht.pdf")
        this.AssertEquals(list[19], "Plan\Bulletin.ahk")
        this.AssertEquals(list[20], "Plan\Communiquee.mp3")
        this.AssertEquals(list[21], "Plan\L-Schein.pdf")
        this.AssertEquals(list[22], "Plan\Nachlassdokument.rtf")
        this.AssertEquals(list[23], "Plan\Presseerklaerung.ahk")
        this.AssertEquals(list[24], "Plan\Presseerklaerung.txt")
    }

    @Test_Determine_Files() {
        SetWorkingDir %A_ScriptDir%\Testdata
        Mack.Option.sort_files := true
        list := Mack.determine_files(["Plan", "Ammenmaerchen"])
        this.AssertEquals(list.MaxIndex(), 45)
        this.AssertEquals(list[1], "Ammenmaerchen\Adelsdiplom.mp3")
        this.AssertEquals(list[2], "Ammenmaerchen\Anlage.pdf")
        this.AssertEquals(list[3], "Ammenmaerchen\Auskunftsschalter\Aktienurkunde.rtf")
        this.AssertEquals(list[4], "Ammenmaerchen\Auskunftsschalter\Arztbrief.html")
        this.AssertEquals(list[5], "Ammenmaerchen\Auskunftsschalter\Rundschreiben.pdf")
        this.AssertEquals(list[6], "Ammenmaerchen\Auskunftsschalter\Schema\Anfuegung.html")
        this.AssertEquals(list[7], "Ammenmaerchen\Auskunftsschalter\Schema\Bericht.pdf")
        this.AssertEquals(list[8], "Ammenmaerchen\Auskunftsschalter\Schema\Bescheid.txt")
        this.AssertEquals(list[9], "Ammenmaerchen\Auskunftsschalter\Schema\Geograph.md")
        this.AssertEquals(list[10], "Ammenmaerchen\Auskunftsschalter\Schema\Geograph.mp3")
        this.AssertEquals(list[11], "Ammenmaerchen\Auskunftsschalter\Schema\Geschichte.md")
        this.AssertEquals(list[12], "Ammenmaerchen\Auskunftsschalter\Schema\Schlussformel.rtf")
        this.AssertEquals(list[13], "Ammenmaerchen\Auskunftsschalter\Schema\Wertpapier.jpeg")
        this.AssertEquals(list[14], "Ammenmaerchen\Auskunftsschalter\unbelebtes.pdf")
        this.AssertEquals(list[15], "Ammenmaerchen\Befundbericht.pdf")
        this.AssertEquals(list[16], "Ammenmaerchen\Buchung.md")
        this.AssertEquals(list[17], "Ammenmaerchen\L-Schein.txt")
        this.AssertEquals(list[18], "Ammenmaerchen\Nachlassdokument.exe")
        this.AssertEquals(list[19], "Ammenmaerchen\Strafzettel.html")
        this.AssertEquals(list[20], "Ammenmaerchen\Wertpapier.doc")
        this.AssertEquals(list[21], "Ammenmaerchen\nicht.doc")
        this.AssertEquals(list[22], "Plan\Autograph.png")
        this.AssertEquals(list[23], "Plan\Bekanntmachung\Adelsdiplom.png")
        this.AssertEquals(list[24], "Plan\Bekanntmachung\Anfuegung.rtf")
        this.AssertEquals(list[25], "Plan\Bekanntmachung\Archivale.mp3")
        this.AssertEquals(list[26], "Plan\Bekanntmachung\Ueberweisungsschein.ahk")
        this.AssertEquals(list[27], "Plan\Bekanntmachung\Waffenpass.html")
        this.AssertEquals(list[28], "Plan\Bericht.pdf")
        this.AssertEquals(list[29], "Plan\Bericht\Anlage.mp3")
        this.AssertEquals(list[30], "Plan\Bericht\Aussendung.png")
        this.AssertEquals(list[31], "Plan\Bericht\Fakten\Bemerkung.html")
        this.AssertEquals(list[32], "Plan\Bericht\Fakten\Communiquee.pdf")
        this.AssertEquals(list[33], "Plan\Bericht\Fakten\Konnossement.mp3")
        this.AssertEquals(list[34], "Plan\Bericht\Fakten\Kurrende.ahk")
        this.AssertEquals(list[35], "Plan\Bericht\Fakten\Rundbrief.rtf")
        this.AssertEquals(list[36], "Plan\Bericht\Fakten\Schlussformel.exe")
        this.AssertEquals(list[37], "Plan\Bericht\Fakten\Schriftstueck.ahk")
        this.AssertEquals(list[38], "Plan\Bericht\Letzter_Wille.rtf")
        this.AssertEquals(list[39], "Plan\Bericht\Nichtveranlagungsbescheinigung.jpeg")
        this.AssertEquals(list[40], "Plan\Bulletin.ahk")
        this.AssertEquals(list[41], "Plan\Communiquee.mp3")
        this.AssertEquals(list[42], "Plan\L-Schein.pdf")
        this.AssertEquals(list[43], "Plan\Nachlassdokument.rtf")
        this.AssertEquals(list[44], "Plan\Presseerklaerung.ahk")
        this.AssertEquals(list[45], "Plan\Presseerklaerung.txt")

        SetWorkingDir %A_ScriptDir%\Testdata\Schema\Fakten\Verkehrsdaten
        list := Mack.determine_files([])
        this.AssertEquals(list.MaxIndex(), 3)
    }

    @Test_Modeline1() {
        SetWorkingDir %A_ScriptDir%\Testdata
        if (FileExist("modeline_test.txt")) {
            FileDelete modeline_test.txt
        }
        FileAppend `; vim:ts=03, modeline_test.txt
        this.AssertEquals(Mack.run([".", "modeline_test.txt"]), "")
		this.AssertEquals(TestCase.FileContent(A_Temp "\mack-test.txt"), TestCase.FileContent(A_ScriptDir "\Figures\Modeline.txt"))
        FileDelete modeline_test.txt
    }

    @Test_Modeline2() {
        SetWorkingDir %A_ScriptDir%\Testdata
        if (FileExist("modeline_test.txt")) {
            FileDelete modeline_test.txt
        }
        FileAppend `n`n`n`n`n`n; vim:ts=03, modeline_test.txt
        this.AssertEquals(Mack.run([".", "modeline_test.txt"]), "")
		this.AssertEquals(TestCase.FileContent(A_Temp "\mack-test.txt"), TestCase.FileContent(A_ScriptDir "\Figures\Modeline2.txt"))
        FileDelete modeline_test.txt
    }

    @Test_VersionInfo() {
        this.AssertEquals(Mack.Run(["--version"]), "")
        Ansi.Flush()
        this.AssertTrue(RegExMatch(TestCase.FileContent(A_Temp "\mack-test.txt"), ".+"))
    }

    @Test_HelpTypes() {
        this.AssertEquals(Mack.Run(["--help-types"]), "")
        Ansi.Flush()
        this.AssertTrue(RegExMatch(TestCase.FileContent(A_Temp "\mack-test.txt"), ".+"))
    }

    @Test_Usage() {
		this.AssertEquals(Mack.Run(["-h"]), "")
		Ansi.Flush()
		this.AssertEquals(TestCase.FileContent(A_Temp "\mack-test.txt"), TestCase.FileContent(A_ScriptDir "\Figures\Usage.txt"))
    }

    @Test_BadUsage() {
		this.AssertEquals(Mack.Run(["--foo"]), "")
		Ansi.Flush()
		this.AssertEquals(TestCase.FileContent(A_Temp "\mack-test.txt"), TestCase.FileContent(A_ScriptDir "\Figures\BadUsage.txt"))
    }

    @Test_Filelist() {
        SetWorkingDir %A_ScriptDir%\Testdata
        this.AssertEquals(Mack.Run(["--nopager", "-f"]), "")
        Ansi.Flush()
		this.AssertEquals(TestCase.FileContent(A_Temp "\mack-test.txt"), TestCase.FileContent(A_ScriptDir "\Figures\Filelist.txt"))
    }

    @Test_PatternFilelist() {
        SetWorkingDir %A_ScriptDir%\Testdata
        this.AssertEquals(Mack.Run(["--nopager", "--sort-files", "-g", "i)^[abcklmstu].*\.txt$"]), "")
        Ansi.Flush()
		this.AssertEquals(TestCase.FileContent(A_Temp "\mack-test.txt"), TestCase.FileContent(A_ScriptDir "\Figures\Pattern-Filelist.txt"))
    }

    @Test_FilteredFilelist() {
        SetWorkingDir %A_ScriptDir%\Testdata
        this.AssertEquals(Mack.Run(["--nopager", "--type", "autohotkey", "-ilc", "est lorem ipsum dolor sit amet\."]), "")
        Ansi.Flush()
		this.AssertEquals(TestCase.FileContent(A_Temp "\mack-test.txt"), TestCase.FileContent(A_ScriptDir "\Figures\Filtered-Filelist.txt"))
    }

    @Test_FilteredTypenameFilelist() { 
        SetWorkingDir %A_ScriptDir%\Testdata
        this.AssertEquals(Mack.Run(["--nopager", "--autohotkey", "-ilc", "est lorem ipsum dolor sit amet\."]), "")
        Ansi.Flush()
		this.AssertEquals(TestCase.FileContent(A_Temp "\mack-test.txt"), TestCase.FileContent(A_ScriptDir "\Figures\Filtered-Filelist.txt"))
    }

    @Test_FilesWithMatches1() {
        SetWorkingDir %A_ScriptDir%\Testdata
        this.AssertEquals(Mack.Run(["--nopager", "--type", "autohotkey", "-Qw", "--files-with-matches", "ut", "Verkehrsdaten\"]), "")
        Ansi.Flush()
		this.AssertEquals(TestCase.FileContent(A_Temp "\mack-test.txt"), TestCase.FileContent(A_ScriptDir "\Figures\FilesWithMatches1.txt"))
    }

    @Test_FilesWithMatches2() {
        SetWorkingDir %A_ScriptDir%\Testdata
        this.AssertEquals(Mack.Run(["--nopager", "--type", "autohotkey", "--nocolor", "-Qw", "--files-with-matches", "ut", "Verkehrsdaten\"]), "")
        Ansi.Flush()
		this.AssertEquals(TestCase.FileContent(A_Temp "\mack-test.txt"), TestCase.FileContent(A_ScriptDir "\Figures\FilesWithMatches2.txt"))
    }

    @Test_FilesWithoutMatches1() {
        SetWorkingDir %A_ScriptDir%\Testdata
            this.AssertEquals(Mack.Run(["--nopager", "--type", "autohotkey", "--nocolor", "-L", "foo", "Verkehrsdaten\"]), "")
        Ansi.Flush()
		this.AssertEquals(TestCase.FileContent(A_Temp "\mack-test.txt"), TestCase.FileContent(A_ScriptDir "\Figures\FilesWithoutMatches1.txt"))
    }

    @Test_FilesWithoutMatches2() {
        SetWorkingDir %A_ScriptDir%\Testdata
            this.AssertEquals(Mack.Run(["--nopager", "--type", "autohotkey", "-L", "foo", "Verkehrsdaten\"]), "")
        Ansi.Flush()
		this.AssertEquals(TestCase.FileContent(A_Temp "\mack-test.txt"), TestCase.FileContent(A_ScriptDir "\Figures\FilesWithoutMatches2.txt"))
    }

    @Test_Search1() {
        SetWorkingDir %A_ScriptDir%\Testdata
        this.AssertEquals(Mack.Run(["--nopager", "--type", "autohotkey", "--column", "Lorem ipsum dolor sit amet,", "Verkehrsdaten\"]), "")
        Ansi.Flush()
		this.AssertEquals(TestCase.FileContent(A_Temp "\mack-test.txt"), TestCase.FileContent(A_ScriptDir "\Figures\Search1.txt"))
    }

    @Test_Search2() {
        SetWorkingDir %A_ScriptDir%\Testdata
        this.AssertEquals(Mack.Run(["--nopager", "--type", "autohotkey", "--nocolor", "-v", "Lorem ipsum dolor sit amet,", "Verkehrsdaten\"]), "")
        Ansi.Flush()
		this.AssertEquals(TestCase.FileContent(A_Temp "\mack-test.txt"), TestCase.FileContent(A_ScriptDir "\Figures\Search2.txt"))
    }

    @Test_Search3() {
        SetWorkingDir %A_ScriptDir%\Testdata
        this.AssertEquals(Mack.Run(["--nopager", "--type", "autohotkey", "-C", "3", "Lorem ipsum dolor sit amet,", "Verkehrsdaten\"]), "")
        Ansi.Flush()
		this.AssertEquals(TestCase.FileContent(A_Temp "\mack-test.txt"), TestCase.FileContent(A_ScriptDir "\Figures\Search3.txt"))
    }

    @Test_Search4() {
        SetWorkingDir %A_ScriptDir%\Testdata
        this.AssertEquals(Mack.Run(["--nopager", "--autohotkey", "--nocolor", "-C", "2", "Lorem ipsum dolor sit amet,", "Verkehrsdaten\"]), "")
        Ansi.Flush()
		this.AssertEquals(TestCase.FileContent(A_Temp "\mack-test.txt"), TestCase.FileContent(A_ScriptDir "\Figures\Search4.txt"))
    }

    @Test_Search5() {
        SetWorkingDir %A_ScriptDir%\Testdata
        this.AssertEquals(Mack.Run(["--nopager", "--autohotkey", "--output", "$1", "Lorem ipsum dolor sit amet(.)", "Verkehrsdaten\"]), "")
        Ansi.Flush()
		this.AssertEquals(TestCase.FileContent(A_Temp "\mack-test.txt"), TestCase.FileContent(A_ScriptDir "\Figures\Search5.txt"))
    }

    @Test_Search6() {
        SetWorkingDir %A_ScriptDir%\Testdata
        this.AssertEquals(Mack.Run(["--nopager", "--autohotkey", "--output", "$0", "Lorem ipsum dolor sit amet(.)", "Verkehrsdaten\"]), "")
        Ansi.Flush()
		this.AssertEquals(TestCase.FileContent(A_Temp "\mack-test.txt"), TestCase.FileContent(A_ScriptDir "\Figures\Search6.txt"))
    }

    @Test_Search7() {
        SetWorkingDir %A_ScriptDir%\Testdata
        this.AssertEquals(Mack.Run(["--nopager", "--autohotkey", "-c", "Lorem ipsum dolor sit amet,", "Verkehrsdaten\"]), "")
        Ansi.Flush()
		this.AssertEquals(TestCase.FileContent(A_Temp "\mack-test.txt"), TestCase.FileContent(A_ScriptDir "\Figures\Search7.txt"))
    }

    @Test_Search8() {
        SetWorkingDir %A_ScriptDir%\Testdata
        this.AssertEquals(Mack.Run(["--nopager", "--autohotkey", "-cQ", "--nocolor", "Lorem ipsum dolor sit amet.", "Verkehrsdaten\"]), "")
        Ansi.Flush()
		this.AssertEquals(TestCase.FileContent(A_Temp "\mack-test.txt"), TestCase.FileContent(A_ScriptDir "\Figures\Search8.txt"))
    }

    @Test_Search9() {
        SetWorkingDir %A_ScriptDir%\Testdata
        this.AssertEquals(Mack.Run(["--nopager", "--autohotkey", "-C", "2", "eleifend", "Verkehrsdaten\"]), "")
        Ansi.Flush()
		this.AssertEquals(TestCase.FileContent(A_Temp "\mack-test.txt"), TestCase.FileContent(A_ScriptDir "\Figures\Search9.txt"))
    }

    @Test_Search10() {
        SetWorkingDir %A_ScriptDir%\Testdata
        this.AssertEquals(Mack.Run(["--nopager", "--autohotkey", "-A", "2", "^Duis ", "Verkehrsdaten\"]), "")
        Ansi.Flush()
		this.AssertEquals(TestCase.FileContent(A_Temp "\mack-test.txt"), TestCase.FileContent(A_ScriptDir "\Figures\Search10.txt"))
    }

    @Test_Search11() {
        SetWorkingDir %A_ScriptDir%\Testdata
        f := FileOpen("Verkehrsdaten\Adelsdiplom.ahk", "r-rwd")
        this.AssertEquals(Mack.Run(["--nopager", "--autohotkey", "-A", "2", "^Duis ", "Verkehrsdaten\"]), "")
        Ansi.Flush()
		this.AssertEquals(TestCase.FileContent(A_Temp "\mack-test.txt"), TestCase.FileContent(A_ScriptDir "\Figures\Search11.txt"))
        f.close()
    }

    @Test_SearchNoPattern() {
        SetWorkingDir %A_ScriptDir%\Testdata
        this.AssertEquals(Mack.Run(["--nopager", "--autohotkey"]), "")
        Ansi.Flush()
		this.AssertEquals(TestCase.FileContent(A_Temp "\mack-test.txt"), TestCase.FileContent(A_ScriptDir "\Figures\NoSearchPattern.txt"))
    }

    @Test_SearchNoHits() {
        SetWorkingDir %A_ScriptDir%\Testdata
        this.AssertEquals(Mack.Run(["--nopager", "--autohotkey", "--no-html", "-L", "^Duis ", "Verkehrsdaten\"]), "")
        Ansi.Flush()
		this.AssertEquals(TestCase.FileContent(A_Temp "\mack-test.txt"), "")
    }

    @Test_Search13() {
        SetWorkingDir %A_ScriptDir%\Testdata
        this.AssertEquals(Mack.Run(["--nopager", "-k", "^Duis ", "Verkehrsdaten\"]), "")
        Ansi.Flush()
		this.AssertEquals(TestCase.FileContent(A_Temp "\mack-test.txt"), TestCase.FileContent(A_ScriptDir "\Figures\Search13.txt"))
    }

    @Test_Search14() {
        SetWorkingDir %A_ScriptDir%\Testdata
        this.AssertEquals(Mack.Run(["--nopager", "--column", "-o", "^Duis ", "Verkehrsdaten\"]), "")
        Ansi.Flush()
		this.AssertEquals(TestCase.FileContent(A_Temp "\mack-test.txt"), TestCase.FileContent(A_ScriptDir "\Figures\Search14.txt"))
    }

    @Test_Search15() {
        SetWorkingDir %A_ScriptDir%\Testdata
        this.AssertEquals(Mack.Run(["--nopager", "--autohotkey", "--nocolor", "-C", "2", "eleifend", "Verkehrsdaten\"]), "")
        Ansi.Flush()
		this.AssertEquals(TestCase.FileContent(A_Temp "\mack-test.txt"), TestCase.FileContent(A_ScriptDir "\Figures\Search15.txt"))
    }

    @Test_Search16() {
        SetWorkingDir %A_ScriptDir%\Testdata
        this.AssertEquals(Mack.Run(["--nopager", "--autohotkey", "-1", "eleifend", "Verkehrsdaten\"]), "")
        Ansi.Flush()
		this.AssertEquals(TestCase.FileContent(A_Temp "\mack-test.txt"), TestCase.FileContent(A_ScriptDir "\Figures\Search16.txt"))
    }

    @Test_Search17() {
        SetWorkingDir %A_ScriptDir%\Testdata
        this.AssertEquals(Mack.Run(["--nopager", "--autohotkey", "--nocolor", "-1", "eleifend", "Verkehrsdaten\"]), "")
        Ansi.Flush()
		this.AssertEquals(TestCase.FileContent(A_Temp "\mack-test.txt"), TestCase.FileContent(A_ScriptDir "\Figures\Search17.txt"))
    }

    @Test_Search18() {
        SetWorkingDir %A_ScriptDir%\Testdata
        this.AssertEquals(Mack.Run(["--nopager", "--autohotkey", "--nocolor", "-1v", "eleifend", "Verkehrsdaten\"]), "")
        Ansi.Flush()
		this.AssertEquals(TestCase.FileContent(A_Temp "\mack-test.txt"), TestCase.FileContent(A_ScriptDir "\Figures\Search18.txt"))
    }

    @Test_Search19() {
        SetWorkingDir %A_ScriptDir%\Testdata
        this.AssertEquals(Mack.Run(["--nopager", "--type", "autohotkey", "--nocolor", "--column", "Lorem ipsum dolor sit amet,", "Verkehrsdaten\"]), "")
        Ansi.Flush()
		this.AssertEquals(TestCase.FileContent(A_Temp "\mack-test.txt"), TestCase.FileContent(A_ScriptDir "\Figures\Search19.txt"))
    }
}
	
exitapp MackTest.RunTests()

#Include %A_ScriptDir%\..\mack.ahk
