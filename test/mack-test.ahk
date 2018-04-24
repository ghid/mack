; ahk: con
#NoEnv
SetBatchLines -1
#Warn All, OutputDebug

#Include <logging>
#Include <testcase>

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

}
	
exitapp MackTest.RunTests()

#Include %A_ScriptDir%\..\mack.ahk
