; ahk: con
#NoEnv
SetBatchLines -1
#Warn All, OutputDebug

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

	@Test_GetVersionInfo() {
		this.AssertTrue(IsFunc("Mack.get_version_info"))
		this.AssertTrue(InStr(Mack.get_version_info(), " Copyright (C) "))
	}

	@Test_HelpTypes() {
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
        this.AssertEquals(list[4], "Plan\Communiqué.mp3")
        this.AssertEquals(list[5], "Plan\L-Schein.pdf")
        this.AssertEquals(list[6], "Plan\Nachlassdokument.rtf")
        this.AssertEquals(list[7], "Plan\Presseerklärung.ahk")
        this.AssertEquals(list[8], "Plan\Presseerklärung.txt")

        Mack.Option.r := true
        list := Mack.collect_filenames("Plan")
        this.AssertEquals(list.MaxIndex(), 24)
        this.AssertEquals(list[1],  "Plan\Autograph.png")
        this.AssertEquals(list[2], "Plan\Bekanntmachung\Adelsdiplom.png")
        this.AssertEquals(list[3], "Plan\Bekanntmachung\Anfügung.rtf")
        this.AssertEquals(list[4], "Plan\Bekanntmachung\Archivale.mp3")
        this.AssertEquals(list[5], "Plan\Bekanntmachung\Waffenpass.html")
        this.AssertEquals(list[6], "Plan\Bekanntmachung\Überweisungsschein.ahk")
        this.AssertEquals(list[7], "Plan\Bericht\Anlage.mp3")
        this.AssertEquals(list[8], "Plan\Bericht\Aussendung.png")
        this.AssertEquals(list[9], "Plan\Bericht\Fakten\Bemerkung.html")
        this.AssertEquals(list[10], "Plan\Bericht\Fakten\Communiqué.pdf")
        this.AssertEquals(list[11], "Plan\Bericht\Fakten\Konnossement.mp3")
        this.AssertEquals(list[12], "Plan\Bericht\Fakten\Kurrende.ahk")
        this.AssertEquals(list[13], "Plan\Bericht\Fakten\Rundbrief.rtf")
        this.AssertEquals(list[14], "Plan\Bericht\Fakten\Schlussformel.exe")
        this.AssertEquals(list[15], "Plan\Bericht\Fakten\Schriftstück.ahk")
        this.AssertEquals(list[16], "Plan\Bericht\Nichtveranlagungsbescheinigung.jpeg")
        this.AssertEquals(list[17], "Plan\Bericht\Wille.rtf")
        this.AssertEquals(list[18], "Plan\Bericht.pdf")
        this.AssertEquals(list[19], "Plan\Bulletin.ahk")
        this.AssertEquals(list[20], "Plan\Communiqué.mp3")
        this.AssertEquals(list[21], "Plan\L-Schein.pdf")
        this.AssertEquals(list[22], "Plan\Nachlassdokument.rtf")
        this.AssertEquals(list[23], "Plan\Presseerklärung.ahk")
        this.AssertEquals(list[24], "Plan\Presseerklärung.txt")
    }

    @Test_Determine_Files() {
        SetWorkingDir %A_ScriptDir%\Testdata
        Mack.Option.sort_files := true
        list := Mack.determine_files(["Plan", "Ammenmärchen"])
        this.AssertEquals(list.MaxIndex(), 45)
        this.AssertEquals(list[1], "Ammenmärchen\Adelsdiplom.mp3")
        this.AssertEquals(list[2], "Ammenmärchen\Anlage.pdf")
        this.AssertEquals(list[3], "Ammenmärchen\Auskunftsschalter\Aktienurkunde.rtf")
        this.AssertEquals(list[4], "Ammenmärchen\Auskunftsschalter\Arztbrief.html")
        this.AssertEquals(list[5], "Ammenmärchen\Auskunftsschalter\Rundschreiben.pdf")
        this.AssertEquals(list[6], "Ammenmärchen\Auskunftsschalter\Schema\Anfügung.html")
        this.AssertEquals(list[7], "Ammenmärchen\Auskunftsschalter\Schema\Bericht.pdf")
        this.AssertEquals(list[8], "Ammenmärchen\Auskunftsschalter\Schema\Bescheid.txt")
        this.AssertEquals(list[9], "Ammenmärchen\Auskunftsschalter\Schema\Geograph.md")
        this.AssertEquals(list[10], "Ammenmärchen\Auskunftsschalter\Schema\Geograph.mp3")
        this.AssertEquals(list[11], "Ammenmärchen\Auskunftsschalter\Schema\Geschichte.md")
        this.AssertEquals(list[12], "Ammenmärchen\Auskunftsschalter\Schema\Schlussformel.rtf")
        this.AssertEquals(list[13], "Ammenmärchen\Auskunftsschalter\Schema\Wertpapier.jpeg")
        this.AssertEquals(list[14], "Ammenmärchen\Auskunftsschalter\unbelebtes.pdf")
        this.AssertEquals(list[15], "Ammenmärchen\Befundbericht.pdf")
        this.AssertEquals(list[16], "Ammenmärchen\Buchung.md")
        this.AssertEquals(list[17], "Ammenmärchen\L-Schein.txt")
        this.AssertEquals(list[18], "Ammenmärchen\Nachlassdokument.exe")
        this.AssertEquals(list[19], "Ammenmärchen\Strafzettel.html")
        this.AssertEquals(list[20], "Ammenmärchen\Wertpapier.doc")
        this.AssertEquals(list[21], "Ammenmärchen\nicht.doc")
        this.AssertEquals(list[22], "Plan\Autograph.png")
        this.AssertEquals(list[23], "Plan\Bekanntmachung\Adelsdiplom.png")
        this.AssertEquals(list[24], "Plan\Bekanntmachung\Anfügung.rtf")
        this.AssertEquals(list[25], "Plan\Bekanntmachung\Archivale.mp3")
        this.AssertEquals(list[26], "Plan\Bekanntmachung\Waffenpass.html")
        this.AssertEquals(list[27], "Plan\Bekanntmachung\Überweisungsschein.ahk")
        this.AssertEquals(list[28], "Plan\Bericht.pdf")
        this.AssertEquals(list[29], "Plan\Bericht\Anlage.mp3")
        this.AssertEquals(list[30], "Plan\Bericht\Aussendung.png")
        this.AssertEquals(list[31], "Plan\Bericht\Fakten\Bemerkung.html")
        this.AssertEquals(list[32], "Plan\Bericht\Fakten\Communiqué.pdf")
        this.AssertEquals(list[33], "Plan\Bericht\Fakten\Konnossement.mp3")
        this.AssertEquals(list[34], "Plan\Bericht\Fakten\Kurrende.ahk")
        this.AssertEquals(list[35], "Plan\Bericht\Fakten\Rundbrief.rtf")
        this.AssertEquals(list[36], "Plan\Bericht\Fakten\Schlussformel.exe")
        this.AssertEquals(list[37], "Plan\Bericht\Fakten\Schriftstück.ahk")
        this.AssertEquals(list[38], "Plan\Bericht\Nichtveranlagungsbescheinigung.jpeg")
        this.AssertEquals(list[39], "Plan\Bericht\Wille.rtf")
        this.AssertEquals(list[40], "Plan\Bulletin.ahk")
        this.AssertEquals(list[41], "Plan\Communiqué.mp3")
        this.AssertEquals(list[42], "Plan\L-Schein.pdf")
        this.AssertEquals(list[43], "Plan\Nachlassdokument.rtf")
        this.AssertEquals(list[44], "Plan\Presseerklärung.ahk")
        this.AssertEquals(list[45], "Plan\Presseerklärung.txt")
    }
}
	
exitapp MackTest.RunTests()

#Include %A_ScriptDir%\..\mack.ahk
