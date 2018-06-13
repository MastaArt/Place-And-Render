try(destroyDialog _rUpdater)catch()
rollout _rUpdater "Install And Update" width: 300 height: 300
(
	dotNetControl lblTask "System.Windows.Forms.Label" height: 20
	
	button btnUpdate "Install/Update To Latest Version" enabled: true height: 30 offset: [0, 10]
	dotNetControl edtNotes "System.Windows.Forms.Textbox" width: 298 height: 212 align:#center offset: [0, 10]
	
	fn getColor r g b = (dotnetclass "System.Drawing.Color").FromArgb r g b
	
	timer tmrCheckUpdates "" active: false interval: 500

	fn getBgColor = 
	(
		b = (colorman.getcolor #background) * 255
		c = getColor b[1] b[2] b[3]
		return c
	)

	fn getTextColor =
	(
		t = (colorMan.getColor #text) * 255
		c = getColor t[1] t[2] t[3]
		return c
	)
	
	fn setTask msg:"" type: #grey =
	(
		t = #(67,67,67)
		b = #(183,183,183)
		
		if(type == #red) do 
		(
			t = #(153,0,0)
			b = #(224,102,102)
		)
		if(type == #green) do 
		(
			t = #(56,118,79)
			b = #(147,196,125)
		)
		if(type == #yellow) do 
		(
			t = #(205,144,0)
			b = #(255,229,153)
		)
				
		lblTask.BackColor = getColor b[1] b[2] b[3]
		lblTask.ForeColor = getColor t[1] t[2] t[3]
		
		lblTask.Font = dotNetObject "System.Drawing.Font" "Tahoma" 10 ((dotNetClass "System.Drawing.FontStyle").Bold)
		lblTask.TextAlign = lblTask.TextAlign.MiddleCenter
		lblTask.text = msg
	)
	
	fn initDotnet =
	(
		edtNotes.Font = dotNetObject "System.Drawing.Font" "MS Sans Serif" 8 ((dotNetClass "System.Drawing.FontStyle").Regular)
		edtNotes.BorderStyle = (dotNetClass "System.Windows.Forms.BorderStyle").FixedSingle
		edtNotes.BackColor = getBgColor()
		edtNotes.ForeColor = getTextColor()
		edtNotes.MultiLine = true
		edtNotes.WordWrap = true
		edtNotes.ScrollBars = (dotNetClass "System.Windows.Forms.ScrollBars").Vertical
		edtNotes.ReadOnly = true
		setTask msg: "Check for updates..."
	)
	
	fn createMacro MACRO CAT TXT FULLNAME =
	(
		m = ""
		m += "\nmacroScript " + MACRO 
		m += "\ncategory:\"[" + CAT + "]\"" 
		m += "\ntoolTip:\"" + TXT + "\""
		m += "\nbuttontext:\"" + TXT + "\""
		
		m += "\n("
		m += "\n\ton execute do"
		m += "\n\t("
			m += "\n\t\tszScript =  getDir(#temp) + \"\\" + MACRO + @"\" + FULLNAME + "\""
			m += "\n\t\ttry(fileIn(szScript)) catch(messageBox \"Script not found! Please reinstall " + TXT + "!\" title: \"Warning!\")"
		m += "\n\t)"
		m += "\n)"
			
		execute(m)
	)
	
	fn addQuadMenuButton macro cat txt remove: false =
	(
		quadMenu = menuMan.getViewportRightClickMenu #nonePressed
		theMenu = quadMenu.getMenu 1

		fn findMenuItem theMenu menuName =
		(
			for i in 1 to theMenu.numItems() where (theMenu.getItem i).getTitle() == menuName do return i
			return 0
		)

		fn unregisterMenuItem theMenu menuName =
		(	
			try
			(
				for i in 1 to theMenu.numItems() do
				(
					if((theMenu.getItem i).getTitle() == menuName) do
					(
						theMenu.removeItemByPosition i 	

						if((theMenu.getItem (i - 1)).getIsSeparator()) do theMenu.removeItemByPosition (i - 1)
					)
				)
			)catch()
		)

		item = try(findMenuItem theMenu "Select &Similar")catch(6)

		unregisterMenuItem theMenu txt
		
		if(not remove) do
		(
			quadItem = menuMan.createActionItem macro ("[" + cat + "]")
			
			theMenu.addItem quadItem (item += 1)
		)
			
		menuMan.updateMenuBar()
	)
	
	struct updateClient (
		updFile = "",
		updPath = "",
		installFile = "",
		checkUrl = "",
		currVer = "",
		currScript = "",
		checkUpdMsg = #red,
		releaseNotes = "",
		mzpPackage = "",
		currPath = "",
		updTmpFile = "",
				
		fn info v =
		(
			getIniSetting updFile "INFO" v
		),
		
		fn getNotes =
		(
			n = getIniSetting updTmpFile "NOTES"
			t = getIniSetting updTmpFile "INSTALL" "TXT"
			v = getIniSetting updTmpFile "UPDATE" "CURR_VER"
			s = getIniSetting updTmpFile "INSTALL" "MACRO"
			
			releaseNotes = "Release Notes \"" + t + " " + v + "\": \r\n\r\n"
			
			for note in n do releaseNotes += note + "\r\n"
		),
		
		fn downloadFile url dl=
		(
			try(setFileAttribute dl #readOnly false) catch()
			deleteFile dl
			
			w = dotNetObject "System.Net.WebClient"
			uri = url + "?time=" + timestamp() as string
			uri = substituteString uri " " "%20"
						
			try(				
				w.DownloadFile uri dl				
				print ("Downloaded: " + uri)
				
				return dl
			) catch(
				print ("Error download: " + uri + " | " + dl)
				
				return #red
			)
		),
		
		fn downloadPackage =
		(						
			files = getIniSetting updTmpFile "FILES"
			m = getIniSetting updTmpFile "INSTALL" "MACRO"
			c = getIniSetting updTmpFile "INSTALL" "CAT"
			t = getIniSetting updTmpFile "INSTALL" "TXT"
			
				
			destFolder = getDir(#temp) + @"\" + m + @"\"
			destStarturp = getDir(#userStartupScripts) + @"\"
			makeDir destFolder
			
			errorDownload = false
			
			for f in files do
			(
				v = getIniSetting updTmpFile "FILES" f
				
				setTask	msg: ("Download: " + f)
				print ("Download: " + f)
				
				j = true
				
				case v of 
				(
					"STARTUP": 
					(
						j = downloadFile (checkUrl + f) (destStarturp + f)
						--try(fileIn (destStarturp + f))catch()
					)
					default: j = downloadFile (checkUrl + f) (destFolder + f)
				)	
				
				if(v == "MAIN") do
				(
					createMacro m c t f
					addQuadMenuButton m c t
				)

				if(j == #red) do errorDownload = true
			)

			return errorDownload
		),
		
		fn init = 
		(									
			currPath = getFilenamePath (getThisScriptFileName())
			updTmpFile =  currPath + "tmp_upd_" + (timestamp() as string) + ".ini"
			updFile =  currPath + "update.ini"
				
			for f in getFiles (currPath + "tmp_upd_*.ini") do deleteFile f
				
			checkUrl = getIniSetting updFile "UPDATE" "CHECK_URL"
			currVer = getIniSetting updFile "UPDATE" "CURR_VER"
			currScript = getIniSetting updFile "INSTALL" "MACRO"	
					
			if(checkUrl == "") do return updFile = #red
				
			r = downloadFile (checkUrl + "update.ini") updTmpFile
			if(r == #red) do return updTmpFile = r
						
			v = getIniSetting updTmpFile "UPDATE" "CURR_VER"
			s = getIniSetting updTmpFile "INSTALL" "MACRO"
					
			if(s != currScript or s == "" or v == "") do return updFile = #red
		), 
				
		fn checkNewVersion = (
			if(updTmpFile == #red) do 
			(
				checkUpdMsg = "Can't connect to server :("
				return #red
			)
			v = getIniSetting updTmpFile "UPDATE" "CURR_VER"
					
			if(v > currVer) do 
			(
				checkUpdMsg = "Available new version: " + v
				getNotes()
				return #green
			)
			
			checkUpdMsg = "You are using the latest version!"
			return #yellow
		)
	)
	
	fn checkUpdates =
	(			
		upd = updateClient()
		upd.init()		
		isUpdate = upd.checkNewVersion()
					
		setTask	msg: upd.checkUpdMsg type: isUpdate
			
		if(isUpdate == #green) do
		(
			_rUpdater.height = 300
			btnUpdate.enabled = true
			edtNotes.text = upd.releaseNotes
		)
	)
	
	fn downloadAndInstallUpdates = 
	(
		btnUpdate.enabled = false
		
		setTask	msg: "Downloading ..."
		
		upd = updateClient()
		upd.init()
		p = upd.downloadPackage()
		print p		
	
		
		if(p == false) then (
			setTask	msg: "Updates have been installed!" type: #green
			
			m = "Updates have been installed!"
			m += "\n\nPlease restart the 3Ds Max!"
			messageBox m title: "Success!" beep: false
		) else (
			setTask	msg: "An error has occurred!" type: #red
		)
		
		btnUpdate.enabled = true
	)
	
	on btnUpdate pressed do
	(			
		downloadAndInstallUpdates()			
	)
	
	on _rUpdater open do
	(	
		initDotnet()		
		tmrCheckUpdates.active = true
		
		_rUpdater.height = 80
	)
		
	
	on tmrCheckUpdates tick do
	(
		checkUpdates()
		tmrCheckUpdates.active = false;
	)
)

createDialog _rUpdater