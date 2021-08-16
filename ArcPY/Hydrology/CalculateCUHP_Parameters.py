import arcpy
import arcpy.da
import ArcHydroTools as AHT
import os
import shutil
import sys
import time
import shutil

DELETE = False		# leave this as False until the memory issue is fixed 
BASINS_NAME = "Tribs_Subcatchments_v3"
HOME_DIRECTORY ="C:/CUHP"
#os.getcwd()
BASIN_GDB = HOME_DIRECTORY+str('/working_gdb_archive.gdb/')
PROCESS_GDB =  HOME_DIRECTORY+str('/fc_python.gdb/')      # this name comes from the mxd. AHT will create it in the folder where the mxd resides
ID_FIELD = 'name'
DEM_NAME = 'dem_proj'
if not os.path.exists(HOME_DIRECTORY+str("/Layers")):
    os.mkdir(HOME_DIRECTORY+str("/Layers"))
TEMP_FC = BASIN_GDB + 'temp_fc'
TEMP_DEM = BASIN_GDB + 'temp_dem'

# map properties
mxd = arcpy.mapping.MapDocument("CURRENT")
df = arcpy.mapping.ListDataFrames(mxd, "Layers")[0]
layers = arcpy.mapping.ListLayers(mxd)
arcpy.env.workspace = HOME_DIRECTORY
arcpy.env.overwriteOutput = True
arcpy.gp.overwriteOutput = True
arcpy.overwriteOutput = True
arcpy.AddField_management(BASINS_NAME,"Area_mi2", "Double")
arcpy.AddField_management(BASINS_NAME,"CFP_mi", "Double")
arcpy.AddField_management(BASINS_NAME,"LFP_mi", "Double")
arcpy.AddField_management(BASINS_NAME,"Slope_dec", "Double")
fc_ref=arcpy.Describe(BASINS_NAME).spatialReference
print(fc_ref.name)
dem_ref=arcpy.Describe(DEM_NAME).spatialReference
print(dem_ref.name)
if fc_ref.name != dem_ref.name:
    print("need to reproject, dem projection does not match shapefile. Aborting script")
    exit()
else:
    print(" ")
# set original basins and DEM

basins = [l for l in layers if BASINS_NAME in l.name][0]
dem =[l for l in layers if DEM_NAME in l.name.lower()][0]

# select all first so that the search cursor will work
arcpy.SelectLayerByAttribute_management(in_layer_or_view = basins, selection_type = 'SWITCH_SELECTION')

# make a list of all IDs
# select one at a time
# export that row to a geodatabase
IDs = []
with arcpy.da.SearchCursor(in_table = basins, field_names = ID_FIELD) as cur:
    for row in cur:
	    IDs.append(row[0])

# clear selection for the next step
arcpy.SelectLayerByAttribute_management(in_layer_or_view = basins, selection_type = 'CLEAR_SELECTION')

for i, id in enumerate(IDs):
	print('Processing {}...'.format(id))
    
	arcpy.env.overwriteOutput = True
	arcpy.gp.overwriteOutput = True
	arcpy.overwriteOutput = True
	
	# select an individual basin and export it as a temporary feature class to the working gdb
	clause_ID_FIELD = '"{}" = \'{}\''.format(ID_FIELD, id)
	arcpy.SelectLayerByAttribute_management(in_layer_or_view = basins, where_clause = clause_ID_FIELD)
	arcpy.CopyFeatures_management(basins, TEMP_FC)
	arcpy.SelectLayerByAttribute_management(in_layer_or_view = basins, selection_type = 'CLEAR_SELECTION')
    
	# clip the DEM to the individual basin and export it to the working gdb
	arcpy.Clip_management(in_raster = dem, rectangle = '#', out_raster = TEMP_DEM, in_template_dataset = TEMP_FC, clipping_geometry = 'ClippingGeometry')

	# 0. assign HydroID to the temp basin
	# 1. fill the sinks
	# 2. determine flow direction raster
	# 3. determine flow accumulation raster
	# stream definition
	# stream link
	# 4. determine longest flow path in catchmentarcpy.CreateTable_management(PROCESS_GDB, 'lfp_points_table_{}'.format(i))
	# 5. determine centroid in catchment
	# 6. determine centroidal flow path in catchment
	#print('Assigning HydroID')
	AHT.AssignHydroID(TEMP_FC)
	#print('Filling DEM sinks')
	#AHT.FillSinks(TEMP_DEM, 'fil_{}'.format(i))
	#print('Creating flow direction raster')
	#AHT.FlowDirection('{}/Layers/fil_{}'.format(HOME_DIRECTORY, i), 'fdr_{}'.format(i))
	#print('Creating flow accumulation raster')
	#AHT.FlowAccumulation('{}/Layers/fdr_{}'.format(HOME_DIRECTORY, i), 'fac_{}'.format(i))
	#print('Determining longest flow path')
	if not os.path.exists("C:/CUHP/LFP_dat"):
            os.mkdir("C:/CUHP/LFP_dat")
        
	arcpy.PolygonToRaster_conversion(in_features="temp_fc", value_field="name", out_rasterdataset="C:/CUHP/LFP_dat/CATCHM")
        arcpy.gp.FocalStatistics_sa("CATCHM", "C:/CUHP/LFP_dat/RANGE", "Rectangle 3 3 CELL", "RANGE", "DATA")
        arcpy.gp.RasterCalculator_sa("""Con("RANGE" == 0,"CATCHM")""", "C:/CUHP/LFP_dat/ISLANDS")
        arcpy.gp.RasterCalculator_sa("""Con( ~IsNull("ISLANDS"),"dem_proj")""", "C:/CUHP/LFP_dat/FENCED")
        arcpy.gp.Fill_sa("FENCED", "C:/CUHP/LFP_dat/FILLED", "")
        arcpy.gp.FlowDirection_sa("FILLED", "C:/CUHP/LFP_dat/FDIR", "NORMAL", "")
        arcpy.gp.FlowLength_sa("FDIR", "C:/CUHP/LFP_dat/FLEN", "DOWNSTREAM", "")
        arcpy.gp.ZonalStatistics_sa("ISLANDS", "VALUE", "FLEN", "C:/CUHP/LFP_dat/LENMAX", "MAXIMUM", "DATA")
        arcpy.gp.RasterCalculator_sa("""Con("LENMAX" == "FLEN","ISLANDS")""", "C:/CUHP/LFP_dat/MAXPNTS")
        arcpy.RasterToPoint_conversion("MAXPNTS","C:/CUHP/LFP_dat/SOURCES")
        arcpy.DeleteIdentical_management(in_dataset="SOURCES", fields="GRID_CODE", xy_tolerance="", z_tolerance="0")
        arcpy.gp.CostPath_sa("SOURCES", "FDIR", "FDIR", "C:/CUHP/LFP_dat/CPATHS", "EACH_CELL", "GRID_CODE")
        arcpy.gp.StreamToFeature_sa("CPATHS", "FDIR", "C:/CUHP/Layers/longestflowpath_{}.shp".format(i), "SIMPLIFY")
        arcpy.Delete_management('CATCHM')
        arcpy.Delete_management("FENCED")
        arcpy.Delete_management("CPATHS")
        arcpy.Delete_management("MAXPNTS")
        arcpy.Delete_management("FILLED")
        arcpy.Delete_management("FLEN")
        arcpy.Delete_management("ISLANDS")
        arcpy.Delete_management("SOURCES")
        arcpy.Delete_management("FDIR")
        arcpy.Delete_management("LENMAX")
        arcpy.Delete_management("RANGE")
        shutil.rmtree("C:/CUHP/LFP_dat")
        
        
	#AHT.LongestFlowPath(TEMP_FC, '{}/Layers/fdr_{}'.format(HOME_DIRECTORY, i), 'longestflowpath_{}'.format(i))
	print('Determining centroid')
	arcpy.FeatureToPoint_management("temp_fc", '{}/centroid_{}'.format(PROCESS_GDB,i), "CENTROID")
	
	print('Determining centroidal flow path')
	# a. find the nearest point on the line to the centroid
	# b. split the line at that point
	# c. define the upper portion as centroidal flow path
	# d. select the upper portion, export it to keep as centroidal flow path
	arcpy.analysis.GenerateNearTable('{}/centroid_{}'.format(PROCESS_GDB, i), '{}/Layers/longestflowpath_{}.shp'.format(HOME_DIRECTORY, i),out_table = "{}near_table_{}".format(PROCESS_GDB, i), location = "LOCATION")
        ref=r"C:\CUHP\CN.prj"
	arcpy.MakeXYEventLayer_management("{}near_table_{}".format(PROCESS_GDB, i), 'NEAR_X', 'NEAR_Y', 'near_xy',ref)
    
	arcpy.FeatureToPoint_management ('near_xy','{}/near_point_{}'.format(PROCESS_GDB, i))
	arcpy.SplitLineAtPoint_management('{}/Layers/longestflowpath_{}.shp'.format(HOME_DIRECTORY, i), '{}/near_point_{}'.format(PROCESS_GDB, i), '{}/lfp_split_{}'.format(PROCESS_GDB, i))
	
	temp_split_lfp = '{}/lfp_split_{}'.format(PROCESS_GDB, i)
	arcpy.MakeFeatureLayer_management(temp_split_lfp, "split_lfp_{}".format(i))
	temp_layer = arcpy.mapping.Layer( "split_lfp_{}".format(i))
	arcpy.mapping.AddLayer(df, temp_layer, "TOP")
	clause_OID = '"OBJECTID" = 2'
	arcpy.SelectLayerByAttribute_management(in_layer_or_view =  "split_lfp_{}".format(i), where_clause =clause_OID)
	arcpy.CopyFeatures_management('split_lfp_{}'.format(i), '{}/centroidal_path_{}'.format(PROCESS_GDB, i))
	arcpy.SelectLayerByAttribute_management(in_layer_or_view =  "split_lfp_{}".format(i), selection_type = 'CLEAR_SELECTION')
	arcpy.Delete_management('split_lfp_{}'.format(i))
	
	# calculate length in miles for longest/centroidal flow paths
	# add the length to basins layer
	lfp_length_mi = [f[0] for f in arcpy.da.SearchCursor('{}/Layers/longestflowpath_{}.shp'.format(HOME_DIRECTORY, i), 'SHAPE@LENGTH')][0]/5280
	print('Longest flow path [mi] = {}'.format(lfp_length_mi))
	arcpy.SelectLayerByAttribute_management(in_layer_or_view = basins, where_clause = clause_ID_FIELD)
	arcpy.CalculateField_management(in_table = basins, field = 'LFP_mi', expression = lfp_length_mi)
	
	try:
		cfp_length_mi = [f[0] for f in arcpy.da.SearchCursor('{}centroidal_path_{}'.format(PROCESS_GDB, i), 'SHAPE@LENGTH')][1]/5280
	except:
		cfp_length_mi = 9999999
	print('Centroidal flow path [mi] = {}'.format(cfp_length_mi))
	arcpy.SelectLayerByAttribute_management(in_layer_or_view = basins, where_clause = clause_ID_FIELD)
	arcpy.CalculateField_management(in_table = basins, field = 'CFP_mi', expression = cfp_length_mi)
	arcpy.SelectLayerByAttribute_management(in_layer_or_view = basins, selection_type = 'CLEAR_SELECTION')
	
	# calculate are of each catchment in mi^2
	basin_area_mi2 = [f[0] for f in arcpy.da.SearchCursor(TEMP_FC, 'SHAPE@AREA')][0]/(5280*5280)
	print('Catchment area [mi2] = {}'.format(basin_area_mi2))
	arcpy.SelectLayerByAttribute_management(in_layer_or_view = basins, where_clause = clause_ID_FIELD)
	arcpy.CalculateField_management(in_table = basins, field = 'Area_mi2', expression = basin_area_mi2)
	arcpy.SelectLayerByAttribute_management(in_layer_or_view = basins, selection_type = 'CLEAR_SELECTION')
	
	# calculate length-weighted slope
	# 1. split longest flow path at regular points along the line
	# 2. calculate slope of each split part
	# 3. use the slopes and lengths to get the length-weighted slope
	lfp_points = [f for f in arcpy.da.SearchCursor('{}\Layers\longestflowpath_{}.shp'.format(HOME_DIRECTORY, i), ['SHAPE@X', 'SHAPE@Y'], explode_to_points = True)]
	arcpy.CreateTable_management(PROCESS_GDB, 'lfp_points_table_{}'.format(i))
	arcpy.AddField_management('{}lfp_points_table_{}'.format(PROCESS_GDB, i), 'X', 'DOUBLE')
	arcpy.AddField_management('{}lfp_points_table_{}'.format(PROCESS_GDB, i), 'Y', 'DOUBLE')
	with arcpy.da.InsertCursor('{}lfp_points_table_{}'.format(PROCESS_GDB, i), ['X', 'Y']) as cur:
		for row in lfp_points:
			cur.insertRow(row)
	arcpy.MakeXYEventLayer_management('{}lfp_points_table_{}'.format(PROCESS_GDB, i), 'X', 'Y', 'lfp_points_layer')
	arcpy.FeatureToPoint_management('lfp_points_layer', '{}/lfp_points_points_{}'.format(PROCESS_GDB, i))
	arcpy.SplitLineAtPoint_management('{}/Layers/longestflowpath_{}.shp'.format(HOME_DIRECTORY, i), '{}/lfp_points_points_{}'.format(PROCESS_GDB, i), '{}/slope_lines_{}'.format(PROCESS_GDB, i), '0 feet')
	arcpy.AddSurfaceInformation_3d('{}/slope_lines_{}'.format(PROCESS_GDB, i), TEMP_DEM, 'AVG_SLOPE')
	
	slope_numerator = 0
	slope_denominator = 0
	with arcpy.da.SearchCursor('{}/slope_lines_{}'.format(PROCESS_GDB, i), ['Shape_Length', 'Avg_Slope']) as cur:
		for row in cur:
			slope_numerator += row[0]*(row[1]*0.01)**0.24
			slope_denominator += row[0]
	
	weighted_slope = (slope_numerator/slope_denominator)**4.17
	
	print('Catchment length-weighted slope [ft/ft] = {}'.format(weighted_slope))
	arcpy.SelectLayerByAttribute_management(in_layer_or_view = basins, where_clause = clause_ID_FIELD)
	arcpy.CalculateField_management(in_table = basins, field = 'Slope_dec', expression = weighted_slope)
	arcpy.SelectLayerByAttribute_management(in_layer_or_view = basins, selection_type = 'CLEAR_SELECTION')
	
	print('Writing the keys to ID_key_table.txt as {}, {}'.format(id, i))
	#with open('{}ID_key_table.txt'.format(HOME_DIRECTORY), 'a') as txt_out:
	#	id_key = '{}, {}\n'.format(id, i)
	#	txt_out.write(id_key)
	
        arcpy.Delete_management('fac_{}'.format(i))
        arcpy.Delete_management('fil_{}'.format(i))
        arcpy.Delete_management('fdr_{}'.format(i))
	print('Finished processing {}\n'.format(id))

