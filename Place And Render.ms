/*  
[INFO] 

NAME = Place And Render
VERSION = 1.0.0
AUTHOR = Vasily Lukyanenko
DEV = 3DGROUND
CUSTOMER = Rehin Roman
SKYPE = romarehin
HELP = 

[INSTALL]

MACRO=PlaceAndRender
CAT=3DGROUND
TEXT=Place And Render
ICON=#("PhysX_Main", 30)

[1.0.0]

* First release =

[ABOUT]

Batch render models in scene...=

[TEST]

[SCRIPT]
*/	



try(closeRolloutFloater fPlaceAndRender)catch()
global fPlaceAndRender = newRolloutFloater "Place And Render" 280 300

global _EXT = ".exr"

fn getScriptInfo s releaseInfo: "" =
(		
	if(releaseInfo != "") do
	(
		r = getINISetting s releaseInfo
		return r
	)
	
	v = getINISetting s "INFO" "VERSION"
	a = getINISetting s "INFO" "AUTHOR"
	n = getINISetting s "INFO" "NAME"
	o = getINISetting s "ABOUT"
	c = getINISetting s "INFO" "DEV"
	h = getINISetting s "INFO" "HELP"
	
	r = for i in (getINISetting s) where i != "ABOUT" and i != "SCRIPT" and i != "COPY" collect i
	
	return #(n, a, v, o, r, c, h)
)

fn getMaxVersion = 
(
	v = maxVersion()
	v = 2000 + ((v[1] / 1000) - 2)
	
	return v as string
)

fn useSettings k p w =
(		
	u = sysInfo.username
	d = getFilenamePath  (getThisScriptFilename())
	n = filenameFromPath (getThisScriptFilename())			
	settingsFile = d + u + "_" + n + ".ini"
	
	t = getMaxVersion()
		
	case w of
	(
		"r":
		(
			s = getINISetting settingsFile t k
			case p of
			(
				"int": return s as integer
				"float": return s as float
				"bool": if s == "true" or s.count < 1 then true else false
				"bool_not": if s == "true" then true else false
				
				default: return s
			)
		)
		default: return setINISetting settingsFile t k (p as string)
	)
)

fn getRender =
(
	r = renderers.current as string

	if matchpattern r pattern:"*Corona*" do return #Corona
	if matchpattern r pattern:"*V_Ray_Adv*" do return #VRay
	return #unknown
)

fn resolvePaths f =
(
	mapPaths.add (getFileNamePath f)
	
	ATSOps.Visible = false
	ATSOps.Visible = true
	
	ATSOps.ExcludeOutputFiles = true
	actionMan.executeAction -841213575 "2"  
	actionMan.executeAction -841213575 "16" 
	actionMan.executeAction -841213575 "2"  
	actionMan.executeAction -841213575 "17" 
	ATSOps.ClearSelection() 
	ATSOps.refresh()
	gc()
	
	ATSOps.Visible = false	
)

fn toggleUI r enabled: false skip: 4 =
(
	for i in 1 to r.controls.count do 
	(	
		if(i <= skip) then
		(
			r.controls[i].enabled = true
		) else (
			r.controls[i].enabled = enabled
		)		
	)
)

rollout _STEP1 "Settings"
(
	global SKIP_1 = 4
	global SKIP_2 = 8
	global SKIP_3 = 12
	
	group "Main Scene File"
	(
		edittext edtMainSceneFile "" height: 25 readOnly: true
		button btnSelectScene "Select Scene"
	)
	
	group "Server Models Config"
	(
		edittext edtServerModelsConfig "" height: 25 readOnly: true
		button btnSelectConfig "Select Config"
	)
	
	button btnStartRender "Start Render" width: 260 height: 35
	
	fn loadMainSceneFile load: #no=
	(
		f = useSettings "MAIN_SCENE_FILE" "string" "r"
		if(not doesFileExist f) do return false		
		edtMainSceneFile.text = f
		if(load == #yes) do loadMaxFile f useFileUnits: true quiet: true
		return true
	)
	
	fn loadServerModelsConfig =
	(
		f = useSettings "SMC_FILE" "string" "r"
		if(not doesFileExist f) do return undefined	
		edtServerModelsConfig.text = f	
		return f
	)
	
	fn onOpen =
	(
		toggleUI _STEP1 skip: SKIP_1 
		
		if(loadMainSceneFile()) do 
		(
			toggleUI _STEP1 skip: SKIP_2
			if(loadServerModelsConfig() != undefined) do toggleUI _STEP1 skip: SKIP_3
		)
	)
	
	fn startBatchRender ini =
	(
		articuls = getIniSetting ini
		errors = #()
		
		progressStart "Rendering..."
		escapeEnable
		
		for i in 1 to articuls.count do
		(
			CoronaRenderer.CoronaFp.stopRender()
			
			_NAME = articuls[i]
			_FILE = getIniSetting ini _NAME "FILE"
			_POS = getIniSetting ini _NAME "POS"
			_TEXT = getIniSetting ini _NAME "TEXT"
			_OUT = getIniSetting ini _NAME "OUT"
						
			progressUpdate (100.0 * i / articuls.count)						
			if(getProgressCancel() == true) do exit	
			
			if(not doesFileExist _FILE) do 
			(
				append errors _FILE
				continue
			)
						
			print _NAME
			print _FILE
			print _POS
			print _TEXT
			print _OUT
			print _EXT
			print "----"
			
			clearSelection()
			mergeMAXFile _FILE  #select #autoRenameDups #renameMtlDups quiet: true 
						
			resolvePaths(_FILE)
			
			model = selection
			
			fopenexr.setAutoAddRenderElements true
			rendSaveFile = true
			rendOutputFilename = _OUT + _NAME + _TEXT + _EXT
					
			c = cameras[1]
			
			if(c != undefined) then viewport.setCamera c
						
			max quick render
						
			try(hide model)catch()
		)
		
		progressEnd()	
	)
	
	on _STEP1 open do
	(
		onOpen()
	)
	
	on btnSelectScene pressed do
	(
		i = getFilenamePath (useSettings "MAIN_SCENE_FILE" "string" "r")
		f = getOpenFileName caption: "Open File" types: "3ds Max (*.max)|*.max" initialDir: i
		if(f == undefined) do return false
		
		useSettings "MAIN_SCENE_FILE" f "w"	
		
		onOpen()
	)
	
	on btnSelectConfig pressed do
	(
		i = getFilenamePath (useSettings "SMC_FILE" "string" "r")
		f = getOpenFileName caption: "Open Server Models Config" types: "(*.smc)|*.smc" initialDir: i
		if(f == undefined) do return false
		
		useSettings "SMC_FILE" f "w"	
		
		onOpen()
	)
	
	on btnStartRender pressed do
	(
		q = queryBox "Do you really want to start render?\n\nFor cancel hold button \"Esc\" and stop the render." title: "Confirm!"
		if(not q) do return false
		
		if(not (loadMainSceneFile load: #yes)) do return messageBox "Can't load Main Scene File!" title: "Error!"
		if(loadServerModelsConfig() == undefined) do return messageBox "Can't load Server Models Config File!" title: "Error!"
		if(getRender() != #Corona) do return messageBox "Scene not used Corona Renderer" title: "Error!"
						
		ini = loadServerModelsConfig()			
		startBatchRender ini
	)
)

rollout _rAbout "About" 
(
	label lblName "" 
	label lblVer "" 
	
	label lblAuthor "" height: 30
	label lblCopy ""  height: 30
	
	local c = color 200 200 200 
	hyperLink href1 "http://3dground.net/" address: "http://3dground.net/" align: #center hoverColor: c visitedColor: c offset: [0, 20]
	
	on _rAbout open do
	(		
		i = getScriptInfo (getThisScriptFilename())
			
		lblName.caption = i[1]
		lblAuthor.caption = i[2]
		lblVer.caption = i[3]
		lblCopy.caption = i[6]
	)
)

addRollout _STEP1 fPlaceAndRender 
addRollout _rAbout fPlaceAndRender rolledUp:true
