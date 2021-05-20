from arcpy.sa import * 
import numpy as np
import arcpy
import glob 
import time
import shutil
layer="Subwatersheds_Minor"
field="FLOC"
events=[]
for i in glob.glob("Z:/Region 2/03757 Spring Creek Fire ERS/GIS/Data/AHPS Rainfall/Processed/*.tif"):
    stri=i.split("-")
    stri=stri[-1]
    events.append(stri)
	 
	 
print(events)
for j in events:
    print(j)
    arcpy.env.overwriteOutput = True
    arcpy.gp.overwriteOutput = True
    arcpy.overwriteOutput = True
    out_rast=Times(j,1000)
    out_rast = Int(out_rast)
    out_rast.save("Z:/Region 2/03757 Spring Creek Fire ERS/GIS/Data/AHPS Rainfall/out_rast.tif")
    arcpy.RasterToPolygon_conversion("Z:/Region 2/03757 Spring Creek Fire ERS/GIS/Data/AHPS Rainfall/out_rast.tif","out_poly")
    val=j.split(".")
    val=val[0]
    name = "T"+val
    print(name)
    arcpy.AddField_management(layer,name, "Double")
    IDs = []
    with arcpy.da.SearchCursor(in_table = layer, field_names = field) as cur:
        for row in cur:
            IDs.append(row[0])
			
        for i, id in enumerate(IDs):
            clause_ID_FIELD = '"{}" = \'{}\''.format(field, id)
            arcpy.SelectLayerByAttribute_management(in_layer_or_view = layer, where_clause = clause_ID_FIELD)
            arcpy.CopyFeatures_management(layer, 'temp_fc')
            arcpy.SelectLayerByAttribute_management(in_layer_or_view = layer, selection_type = 'CLEAR_SELECTION')
            arcpy.Clip_analysis("out_poly","temp_fc","rain_poly")
            arcpy.AddField_management("rain_poly","converted", "Double")
            arcpy.AddField_management("rain_poly","weighted", "Double")
            arcpy.AddField_management("rain_poly","area", "Double")
            arcpy.CalculateField_management("rain_poly",'area','!shape.area!','PYTHON')
            arcpy.CalculateField_management("rain_poly","converted","!gridcode!/1000",'PYTHON')
            arcpy.CalculateField_management("rain_poly","weighted","!area!*!converted!",'PYTHON')
            numerator=[]
            denominator=[]
            with arcpy.da.SearchCursor(in_table='rain_poly',field_names="weighted")as cur:
                for row in cur:
                    numerator.append(row[0])
            with arcpy.da.SearchCursor(in_table='rain_poly',field_names="area")as cur:
                for row in cur:
                    denominator.append(row[0])
            num=np.array(numerator)
            denom=np.array(denominator)
            num=np.sum(num)
            denom=np.sum(denom)
            area_weighted=num / denom
            print(area_weighted)
            arcpy.SelectLayerByAttribute_management(in_layer_or_view = layer, where_clause = clause_ID_FIELD)
            arcpy.CalculateField_management(in_table = layer, field = name, expression = area_weighted)
            arcpy.SelectLayerByAttribute_management(in_layer_or_view =layer, selection_type = 'CLEAR_SELECTION')
        shutil.move("Z:/Region 2/03757 Spring Creek Fire ERS/GIS/Data/AHPS Rainfall/Processed/"+"-"+j,"Z:/Region 2/03757 Spring Creek Fire ERS/GIS/Data/AHPS Rainfall/TiffCopy/")
        arcpy.Delete_management('out_rast')
        arcpy.Delete_management('rain_poly')
        arcpy.Delete_management('out_poly')