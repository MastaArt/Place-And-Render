/*  
[INFO] 

NAME = Cornice Pos
VERSION = 1.0.0
AUTHOR = Vasily Lukyanenko
DEV = 3DGROUND
CUSTOMER = Rehin Roman
SKYPE = romarehin
HELP = 

[1.0.0]

* First release =


[ABOUT]

Cornice position helper...=

[TEST]

[SCRIPT]
*/	

--genClassID()

plugin Helper Cornice_Pos
name: "Cornice Pos" 
classID: #(0x3c131e45, 0x6a03bda2)
category:"Standard" 
extends:dummy 
category: "Place And Render"
( 
	local oldWidth, oldPivot, oldSize, meshObj, oldSliceStart,	oldSliceEnd 

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
	)
	
	rollout params "Furn Parameters"
	(
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