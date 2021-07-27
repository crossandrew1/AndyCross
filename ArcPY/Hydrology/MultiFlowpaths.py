import arcpy
       
mxd = arcpy.mapping.MapDocument("CURRENT")

#Change root_dir_SavePath to where you want files to be saved, you can make a new folder and point this script to that, when copying path from windows
#change the "\" to "/" or python wont be able to read the path and you will get an error

root_dir_SavePath="C:/CUHP/LFP_dat/"

#Update these to the names of your basins and the dem being used in the analysis
BASINS_NAME = "SodaCreekEdit"
basins =BASINS_NAME
dem="SodaCreekDemFT_proj.tif"

#How many points do you want the script to calculate? Add more for better subcatchment delineation
n_points=300

#This is the attribute that the script indexes through- it must be a string (text) field and be called Name- this can be changed to what ever is needed
ID_FIELD = 'Name'
arcpy.SelectLayerByAttribute_management(in_layer_or_view = basins, selection_type = 'SWITCH_SELECTION')


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
	clause_ID_FIELD = '"{}" = \'{}\''.format(ID_FIELD, id)
	arcpy.SelectLayerByAttribute_management(in_layer_or_view = basins, where_clause = clause_ID_FIELD)
	arcpy.CopyFeatures_management(basins, 'temp_fc')
	arcpy.SelectLayerByAttribute_management(in_layer_or_view = basins, selection_type = 'CLEAR_SELECTION')
        arcpy.PolygonToRaster_conversion(in_features="temp_fc", value_field="name", out_rasterdataset=root_dir_SavePath+"CATCHM")
        arcpy.gp.FocalStatistics_sa("CATCHM", root_dir_SavePath+"RANGE", "Rectangle 3 3 CELL", "RANGE", "DATA")
        arcpy.gp.RasterCalculator_sa("""Con("RANGE" == 0,"CATCHM")""", root_dir_SavePath+"ISLANDS")
        arcpy.gp.RasterCalculator_sa("""Con( ~IsNull("ISLANDS"),dem)""", root_dir_SavePath+"FENCED")
        arcpy.gp.Fill_sa("FENCED", root_dir_SavePath+"FILLED_{}".format(i), "")
        arcpy.gp.FlowDirection_sa("FILLED_{}".format(i), root_dir_SavePath+"FDIR_{}".format(i), "NORMAL", "")
        arcpy.CreateRandomPoints_management(out_name= 'points_layer_{}'.format(i),constraining_feature_class= "temp_fc",number_of_points_or_field= n_points,minimum_allowed_distance=20)
   
        arcpy.AddField_management('points_layer_{}'.format(i),"id", "text")
        arcpy.AddField_management('points_layer_{}'.format(i),"GRID_CODE", "integer")
        arcpy.CalculateField_management(in_table = 'points_layer_{}'.format(i), field = 'GRID_CODE', expression = 0)
        arcpy.CalculateField_management(in_table='points_layer_{}'.format(i), field='id', expression=1)
 
        clause_ID_FIELD_point = '"{}" = \'{}\''.format('id', 1)
        arcpy.SelectLayerByAttribute_management(in_layer_or_view = 'points_layer_{}'.format(i), where_clause = clause_ID_FIELD_point)
        arcpy.CopyFeatures_management('points_layer_{}'.format(i), 'temp_pt')
        arcpy.SelectLayerByAttribute_management(in_layer_or_view = 'points_layer_{}'.format(i), selection_type = 'CLEAR_SELECTION')
        arcpy.gp.CostPath_sa("temp_pt", "FDIR_{}".format(i), "FDIR_{}".format(i), root_dir_SavePath+"CPATHS_{}".format(i), "EACH_CELL", "GRID_CODE")
        arcpy.gp.StreamToFeature_sa("CPATHS_{}".format(i), "FDIR_{}".format(i), root_dir_SavePath+"flowpaths_combined_{}.shp".format(i), "SIMPLIFY")
