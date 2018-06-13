/*  
[INFO] 

NAME = HomeLook Plinth
VERSION = 1.0.3
AUTHOR = Vasily Lukyanenko
DEV = 3DGROUND
CUSTOMER = Rehin Roman
SKYPE = romarehin
HELP = 

[1.0.0]

* First release =

[1.0.2]

+Added: Name Type =

[1.0.3]

-BugFix: 3Ds Max  Fatal Error=


[ABOUT]

Load plinth from file in to position.=

[TEST]

[SCRIPT]
*/	


--genClassID()

plugin Helper PlinthPlacer
name: "Plinth Placer" 
classID: #(0x723676de, 0x1e57dcd7)
category:"Standard" 
extends:dummy 
category: "HomeLook Placer"
(
	local oldWidth, oldPivot, oldSize, meshObj, oldSliceStart,	oldSliceEnd 
	local iniSetting = getFileNamePath (getThisScriptFileName()) + "HomeLookPlinthPlacer.ini"
	local lastMdl = ""

	
	fn getDefaultNameType = (
		v = getIniSetting iniSetting "FURNPLACER" "NAME"
		return v		
	)	
			
	parameters main rollout: params
	(	
		width type:#worldUnits ui: spnWidth default: 1
		startPoint type:#point3 default: [0,0,0]
		endPoint type:#point3  default: [0,0,0]
		size type: #worldUnits ui: spnSize default: (units.decodeValue "4.0cm") 
		defTM type:#matrix3  default: (matrix3 1)
		trans type:#matrix3  default: (matrix3 1)
		pivotAligment type:#integer ui: rdoPivotAligment default: 1
		
		startSlice type: #integer ui: ddlStartSlice default: 1
		endSlice type: #integer ui: ddlEndSlice default: 2	
		
		nameType type: #string ui: edtNameType default: "SET NAME TYPE!"
		/*		
		on nameType get v do
		(
			if(v == "" or v == "SET NAME TYPE!") then getDefaultNameType() else v
		)*/
	)
	
	rollout params "Furn Parameters"
	(
		label lblNameType "Name Type:" align: #left
		edittext edtNameType ""
		button btnSelectSame "Select Same"
		
		label sep1 ""
		spinner spnWidth "Width:" range:[0, 1e9, 1]
		spinner spnSize "Gizmo Size:" range:[0, 1e9, (units.decodeValue "4.0cm")]
		label lblStartSlice "Start Slice: " across: 2 align: #right offset: [0, 4]
		dropdownlist ddlStartSlice "" items: #("45", "-45", "none")
			
		label lblEndSlice "End Slice: " across: 2 align: #right offset: [0, 4]
		dropdownlist ddlEndSlice "" items: #("45", "-45", "none")
		
		
				
		group "Pivot Aligment:"
		(
			radiobuttons rdoPivotAligment "" labels:#("", "", "", "", "", "", "", "", "") columns:3 default: 5
		)
		
		group "Load And Place Model:"
		(
			button btnLoadModel "Open" width: 133 height: 35
		)
			
		fn getNodesByName n cls: undefined = 
		(	
			nl = for o in objects where (matchPattern o.name pattern: n) collect o
			if(cls == undefined) do return nl
			
			return for o in nl where classOf o == cls collect o
		)
		
		fn getObjectHead s =
		(
			g = for i in s where (isGroupHead i) and (not (isGroupMember i)) collect i
			if(g[1] != undefined) do return g[1]	
			if(s.count == 1 and s[1] != undefined) do return s[1]
			return undefined
		)
		
		fn getSliceType i =
		(
			return case i of
			(
				2: -45
				3: 0
				default: 45			
			)
		)
			
		fn addSlice g h t a = 
		(
			sliceAngle = case a of 
			(	
				#end: getSliceType h.endSlice
				default: getSliceType h.startSlice
			)
			
			slicePos = case a of 
			(	
				#end: h.endPoint
				default: h.startPoint
			)
			
			m = sliceModifier() 
			addModifier g m

			objTM = g.objectTransform
			modTM = getModContextTM g m
			
			rp = matrix3 1
			preRotateY rp 90
			preRotateZ rp -sliceAngle
			
			m.slice_plane.rotation = rp.rotationPart	
			m.slice_plane.pos = slicePos * modTM * (inverse objTM)
				
			m.slice_type = t
		)
		
		fn placeCornisePos m h =	
		(
			start = h.startPoint
			end = h.endPoint
			w = h.width
			
			g = snapshot m
			m.isHidden = true
						
			g = convertToMesh g
			g.isHidden = false

			g.rotation.x = 0
			g.rotation.y = 0
			g.rotation.z = 0

			g.pivot = g.center
			g.pivot.x = g.min.x
			
			print  ( h.pivotAligment )
			case h.pivotAligment of
			(
				default: (
					g.pivot.y = g.max.y
					g.pivot.z = g.max.z
				)
				2: (
					g.pivot.z = g.max.z
				)
				3: (
					g.pivot.y = g.min.y
					g.pivot.z = g.max.z
				)
				4: (
					g.pivot.y = g.max.y
				)	
				5: (
					g.pivot = g.center
					g.pivot.x = g.min.x
				)				
				6: (
					g.pivot.y = g.min.y
				)
				7: (
					g.pivot.y = g.max.y
					g.pivot.z = g.min.z
				)
				8: (
					g.pivot.z = g.min.z
				)
				9: (
					g.pivot.y = g.min.y
					g.pivot.z = g.min.z
				)
			)
			
			gWidth = abs (g.max.x - g.min.x)

			gBBox = #(abs(g.max.z - g.min.z),  abs (g.max.y - g.min.y))

			gLength = abs(g.max.y - g.min.y)

			try(update g)catch()
				
			tmm = h.trans
				
			preRotateY tmm -90
			preRotateX tmm 90
			preScale tmm  [1,-1,1]
			preScale tmm  [1,1,-1]
				
			g.rotation = inverse tmm.rotationPart
			g.pos = start

			in coordsys g move g [-gLength,0,0]

			k = (ceil ((w + gLength * 2) / gWidth)) as integer
			
			if(k > 1) do
			(
				attachList = #()
				for i in 1 to k-1 do
				(
					ng = copy g
					in coordsys g move ng [i * gWidth, 0,0]
					
					append attachList ng		
				)
				
				for i in attachList do meshop.attach g i 
			)

			addSlice g h 2 #start
			addSlice g h 3 #end

			addModifier g (Cap_Holes())
				
			return g
		)
		
		fn self = refs.dependentNodes this firstOnly: true
		
		fn getSameHelpers = (
			for i in objects where classOf i == PlinthPlacer and i.nameType == edtNameType.text collect i		
		)
		
		fn setSettingsByNameType = 
		(
			for i in getSameHelpers() do 
			(	
				i.pivotAligment = this.pivotAligment
			)
		)
		
		fn selectSameHelpers = 
		(
			clearSelection()
			s = getSameHelpers()
			print s
			if(s.count == 0) do return false
			select s
		)
					
		on btnSelectSame pressed do selectSameHelpers()
				
		on btnLoadModel pressed do
		(
			if(edtNameType.text == "" or edtNameType.text == "SET NAME TYPE!") do return messageBox "Please set name type!" title: "Warning!"
			
			local s = self()
			lastMdl = getIniSetting iniSetting "FURNPLACER" "LASTMDL"
			if(classOf s != PlinthPlacer) do return false 
			
			local f = getOpenFileName caption: "Select Model" types:"3ds Max (*.max)|*.max|" filename: lastMdl

			if(f == undefined) do return false
			
			setIniSetting iniSetting "FURNPLACER" "LASTMDL" f
			lastMdl = f
			
			clearSelection()
			mergeMAXFile f #select 
			
			m = selection
			
			if(m.count > 1 or superClassOf m[1] != GeometryClass) do return messageBox "Imported mesh not as one object!" title: "Error!"
			
			--placerList = getNodesByName s.name cls: PlinthPlacer
			
			placerList = getSameHelpers()
						
			o = getObjectHead m
			outList = #()
			for hh in placerList do (
				no = placeCornisePos o hh
				
				append outList no
			)	
			
			try(delete o) catch()
			
			group outList name: s.nameType
		)
		
		on edtNameType changed v do
		(
			setIniSetting iniSetting "FURNPLACER" "NAME" (edtNameType.text)
		)
		
		on rdoPivotAligment changed v do
		(
			setSettingsByNameType()
		)
		
		on params open do
		(
			v = getIniSetting iniSetting "FURNPLACER" "NAME"
			if(edtNameType.text == "" or edtNameType.text == "SET NAME TYPE!") do (
				edtNameType.text = v	
				this.nameType = v
			)
		)
	)
	
	fn getSlice type: #start =
	(
		i = startSlice
		if(type == #end) do i = endSlice
		
		return case i of
		(
			2: -45
			3: 0
			default: 45			
		)
	)
	
	fn transformMesh m tm =
	(
		for v in 1 to m.numverts do setVert m v ((getVert m v) * tm)
		return m
	)		
	
	fn arrow =
	(
		l = width	
		l = l / 20
		
		a = createInstance plane length: l width: 0 mapCoords:false lengthsegs: 1 widthsegs: 1 
		m = a.mesh		
		
		for v in #(1,2,3,4) do setVert m v ((getVert m v) - 1)
				
		return m
	)
	
	fn pPoint angle: 45 type: #start =
	(
		l = size * 5
						
		a = createInstance box length: l width: l height: l mapCoords:false lengthsegs: 1 widthsegs: 1 heightsegs: 1 wirecolor: green isSelected: false
		m = a.mesh
			
		tm = matrix3 1
		if(type == #start) do tm = rotateY tm 180
		tm = preRotateY tm angle
		tm.row4 = [0,0,0]
		if(type == #end) do tm.row4 = [0,0, width]
								
		m = transformMesh m tm
			
		return m
	)
		
	
	fn lookAtByZ t target = 
	(
		if(t == undefined) do return undefined
		
		v = target - t.row4
		tm = arbAxis v		
		tm.row4 = [0,0,0]
			
		return tm				
	)
	
	on getDisplayMesh do
	(
		if(oldWidth == width and \
			size == oldSize and  \
			oldPivot == pivotAligment and \
			oldSliceStart == startSlice and \
			oldSliceEnd == endSlice and \
			meshObj != undefined 			
		) do return meshObj
		
		p = createInstance box length: (size) width: (size) height: width mapCoords:false lengthsegs: 1 widthsegs: 1 heightsegs: 1 wirecolor: green isSelected: false
			
		meshObj = p.mesh
						
		tm = lookAtByZ defTM endPoint
		
		hs = size / 2
		tm2 = matrix3 1
		case pivotAligment of
		(
			1: tm2.row4 = [-hs, -hs, 0]
			2: tm2.row4 = [0, -hs, 0]
			3: tm2.row4 = [hs, -hs, 0]
			4: tm2.row4 = [-hs, 0, 0]
			6: tm2.row4 = [hs, 0, 0]
			7: tm2.row4 = [-hs, hs, 0]
			8: tm2.row4 = [0, hs, 0]
			9: tm2.row4 = [hs, hs, 0]
			
			default: tm2.row4 = [0,0,0]
		)
		
		meshObj = transformMesh meshObj tm2
				
		if(tm != undefined) do 
		(				
			-- increase size
			for v in #(1,2,3,4) do setVert meshObj v ((getVert meshObj v) + [0,0,-size])
			for v in #(5,6,7,8) do setVert meshObj v ((getVert meshObj v) + [0,0,size])
			
			-- get slice angle
			r1 = getSlice type: #start
			r2 = getSlice type: #end
			
			trans = tm
			
			meshObj = transformMesh meshObj tm	
			meshObj -= transformMesh (pPoint angle: r1) tm
			meshObj -= transformMesh (pPoint angle: r2 type: #end) tm
		)
								
		oldWidth = width
		oldSize = size
		oldPivot = pivotAligment
		oldSliceStart = startSlice
		oldSliceEnd = endSlice
		
		
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
				1: (
					nodeTM.translation = gridPoint
					defTM = nodeTM						
					startPoint = gridPoint
				)
				2: #stop 
			)
		)

		on mouseMove click do
		(
			endPoint = gridPoint
									
			case click of
			(
				2: (				
					width = abs(distance startPoint endPoint) 					
				)
			)
		)
	) 	
)