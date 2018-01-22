/*  
[INFO] 

NAME = HomeLook Placer
VERSION = 1.0.0
AUTHOR = Vasily Lukyanenko
DEV = 3DGROUND
CUSTOMER = Rehin Roman
SKYPE = romarehin
HELP = 

[1.0.0]

* First release =


[ABOUT]

Load objects from file in to position.=

[TEST]

[SCRIPT]
*/	


--genClassID()

plugin Helper FurniturePlacer
name: "Furn Placer" 
classID: #(0x6b56e181, 0x5bc600cf)
category:"Standard" 
extends:dummy 
category: "HomeLook Placer"
(
	local oldLenght, oldWidth, oldPivot, meshObj
	local iniSetting = getFileNamePath (getThisScriptFileName()) + "HomeLookPlacer.ini"
	local lastMdl = ""

	parameters main rollout: params
	(
		width type:#worldUnits ui: spnWidth default: 1
		length type:#worldUnits ui: spnLength  default: 1
		pivotAligment type:#integer ui: rdoPivotAligment default: 5				
	)
	
	fn placeFurnPos m h =
	(
		hw = h.width/2
		hl = h.length/2	
		a = h.pivotAligment
		
		bBox = nodeGetBoundingBox m m.transform
		mSize =(bBox[2] - bBox[1])/2
		
		newPos = [0,0,0]
		
		case a of
		(
			1: (
				newPos.x = (hw - mSize.x)
				newPos.y = -(hl - mSize.y)
			)
			2: (
				newPos.x = 0
				newPos.y = -(hl - mSize.y)
			)
			3: (
				newPos.x = -(hw - mSize.x)
				newPos.y = -(hl - mSize.y)
			)		
			4: (
				newPos.x = (hw - mSize.x)
				newPos.y = 0
			)
			6: (
				newPos.x = -(hw - mSize.x)
				newPos.y = 0
			)	
			7: (
				newPos.x = (hw - mSize.x)
				newPos.y = (hl - mSize.y)
			)
			8: (
				newPos.x = 0
				newPos.y = (hl - mSize.y)
			)
			9: (
				newPos.x = -(hw - mSize.x)
				newPos.y = (hl - mSize.y)
			)	
			default: (
				newPos.x = 0
				newPos.y = 0
			)
		)
				
		m.transform = h.transform 		
		in coordsys m.transform move m newPos		
	)
		
	rollout params "Furn Parameters"
	(
		spinner spnWidth "Width:" range:[0, 1e9, 1]
		spinner spnLength "Length:" range:[0, 1e9, 1]
				
		group "Pivot Aligment:"
		(			
			radiobuttons rdoPivotAligment "" labels:#("", "", "", "", "", "", "", "", "") columns:3 default: 5
		)
		
		group "Load And Place Model:"
		(
			button btnLoadModel "Open" width: 133 height: 35
		)
		
		fn getObjectHead s =
		(
			g = for i in s where (isGroupHead i) and (not (isGroupMember i)) collect i
			if(g[1] != undefined) do return g[1]	
			if(s.count == 1 and s[1] != undefined) do return s[1]
			return undefined
		)
		
		on btnLoadModel pressed do
		(
			local s = selection[1]
			
			if(classOf s != FurniturePlacer) do return false 
				
			
			local f = getOpenFileName caption: "Select Model" types:"3ds Max (*.max)|*.max|" filename: lastMdl

			if(f == undefined) do return false
			
			setIniSetting iniSetting "FURNPLACER" "LASTMDL" f
			lastMdl = f
			
			clearSelection()
			mergeMAXFile f #select 
			
			local h = getObjectHead selection
			
			if(h == undefined) do return false
			
			
			placeFurnPos h s			
		)
		
		on params open do
		(
			lastMdl = getIniSetting iniSetting "FURNPLACER" "LASTMDL"
		)
	)
	
	fn transformMesh m tm =
	(
		for v in 1 to m.numverts do setVert m v ((getVert m v) * tm)
		return m
	)		
	
	fn arrow =
	(
		l = amin #(width, length)		
		l = l / 20
		
		a = createInstance plane length: l width: (width/10) mapCoords:false lengthsegs: 1 widthsegs: 1 
		m = a.mesh		
		
		setVert m 1 ((getVert m 1) + [a.width/2,0,0])
		setVert m 2 ((getVert m 2) + [-a.width/2,0,0])
		
		return m
	)
	
	fn pPoint =
	(
		l = amin #(width, length)		
		l = l / 20
		
		a = createInstance cylinder radius: l height: 0
		
		m = a.mesh
		
		return m
	)
	
	on getDisplayMesh do 
	(			
		if(oldLenght == length and oldWidth == width and  oldPivot == pivotAligment and meshObj != undefined) do return meshObj
		
		p = createInstance plane length: length width: width mapCoords:false lengthsegs: 2 widthsegs: 2 wirecolor: green
				
		oldLenght = p.length = length
		oldWidth = p.width = width
		oldPivot = pivotAligment
		meshObj = p.mesh
		
		hw = width/2
		hl = length/2
		
		tm = matrix3 1
		tm.row4 = [0, -length/2-(length/8), 0]
	
		tmPivot = matrix3 1
		case pivotAligment of
		(
			1: tmPivot.row4 = [hw, -hl, 0]
			2: tmPivot.row4 = [0, -hl, 0]
			3: tmPivot.row4 = [-hw, -hl, 0]
			4: tmPivot.row4 = [hw, 0, 0]
			6: tmPivot.row4 = [-hw, 0, 0]
			7: tmPivot.row4 = [hw, hl, 0]
			8: tmPivot.row4 = [0, hl, 0]
			9: tmPivot.row4 = [-hw, hl, 0]
			default: tmPivot.row4 = [0,0,0]
		)
		
		
		meshObj += transformMesh (arrow()) tm
		meshObj += transformMesh (pPoint()) tmPivot
		
		
		return meshObj
	)
	
	on useWireColor do
	(
		return false
	)
 
	tool create 
	( 
		on mousePoint click do 
		(
			case click of
			(
				1: nodeTM.translation = gridPoint
				2: #stop 
			)
		)

		on mouseMove click do
		(
			case click of
			(
				2: (width = abs gridDist.x * 2; length = abs gridDist.y * 2)
			)
		)
	) 	
)