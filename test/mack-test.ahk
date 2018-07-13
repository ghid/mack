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
		if (!FileExist(".\Testdata")) {
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

	@Test_RefineFilePattern() {
		SetWorkingDir %A_ScriptDir%\Testdata
		Mack.refine_file_pattern(fp := "Verkehrsdaten")
		this.AssertEquals(fp, "Verkehrsdaten\*.*")
		Mack.refine_file_pattern(fp := "Verkehrsdaten\a*.txt")
		this.AssertEquals(fp, "Verkehrsdaten\a*.txt")
		Mack.refine_file_pattern(fp := "Verkehrsdaten\a*.t*t")
		this.AssertEquals(fp, "Verkehrsdaten\a*.t*t")
	}
}
	
exitapp MackTest.RunTests()

#Include %A_ScriptDir%\..\mack.ahk
