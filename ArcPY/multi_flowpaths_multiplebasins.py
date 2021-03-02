'''
cent=[]
for i in range(0,145):
    cent.append('centroidal_path_{}'.format(i))
arcpy.Merge_management(cent,'cfp_merged')
'''
import arcpy
"""
home_dir='C:/rain_on_grid/'
points=home_dir+str("rainfall_points")
paths=home_dir+str("paths")
extras=home_dir+str("LFP_dat")
if not os.path.exists(points):
        os.mkdir(home_dir+points)
if not os.path.exists(home_dir+paths):
        os.mkdir(home_dir+paths)
"""        
mxd = arcpy.mapping.MapDocument("CURRENT")
#df = arcpy.mapping.ListDataFrames(mxd, "Layers")[0]
BASINS_NAME = "bnt"
basins =BASINS_NAME
#[l for l in layers if BASINS_NAME in l.name][0]
arcpy.SelectLayerByAttribute_management(in_layer_or_view = basins, selection_type = 'SWITCH_SELECTION')
ID_FIELD = 'name'

IDs = []
with arcpy.da.SearchCursor(in_table = basins, field_names = ID_FIELD) as cur:
    for row in cur:
	    IDs.append(row[0])

# clear selection for the next step
arcpy.SelectLayerByAttribute_management(in_layer_or_view = basins, selection_type = 'CLEAR_SELECTION')
n_points=300
for i, id in enumerate(IDs):
	print('Processing {}...'.format(id))
    
	arcpy.env.overwriteOutput = True
	arcpy.gp.overwriteOutput = True
	arcpy.overwriteOutput = True
	clause_ID_FIELD = '"{}" = \'{}\''.format(ID_FIELD, id)
	arcpy.SelectLayerByAttribute_management(in_layer_or_view = basins, where_clause = clause_ID_FIELD)
	arcpy.CopyFeatures_management(basins, 'temp_fc')
	arcpy.SelectLayerByAttribute_management(in_layer_or_view = basins, selection_type = 'CLEAR_SELECTION')
        arcpy.PolygonToRaster_conversion(in_features="temp_fc", value_field="name", out_rasterdataset="C:/CUHP/LFP_dat/CATCHM")
        arcpy.gp.FocalStatistics_sa("CATCHM", "C:/CUHP/LFP_dat/RANGE", "Rectangle 3 3 CELL", "RANGE", "DATA")
        arcpy.gp.RasterCalculator_sa("""Con("RANGE" == 0,"CATCHM")""", "C:/CUHP/LFP_dat/ISLANDS")
        arcpy.gp.RasterCalculator_sa("""Con( ~IsNull("ISLANDS"),"dem_proj")""", "C:/CUHP/LFP_dat/FENCED")
        arcpy.gp.Fill_sa("FENCED", "C:/CUHP/LFP_dat/FILLED_{}".format(i), "")
        arcpy.gp.FlowDirection_sa("FILLED_{}".format(i), "C:/CUHP/LFP_dat/FDIR_{}".format(i), "NORMAL", "")
        arcpy.CreateRandomPoints_management(out_name= 'points_layer_{}'.format(i),constraining_feature_class= "temp_fc",number_of_points_or_field= n_points,minimum_allowed_distance=20)
   
        arcpy.AddField_management('points_layer_{}'.format(i),"id", "text")
        arcpy.AddField_management('points_layer_{}'.format(i),"GRID_CODE", "integer")
        arcpy.CalculateField_management(in_table = 'points_layer_{}'.format(i), field = 'GRID_CODE', expression = 0)
        arcpy.CalculateField_management(in_table='points_layer_{}'.format(i), field='id', expression=1)
 
        clause_ID_FIELD_point = '"{}" = \'{}\''.format('id', 1)
        arcpy.SelectLayerByAttribute_management(in_layer_or_view = 'points_layer_{}'.format(i), where_clause = clause_ID_FIELD_point)
        arcpy.CopyFeatures_management('points_layer_{}'.format(i), 'temp_pt')
        arcpy.SelectLayerByAttribute_management(in_layer_or_view = 'points_layer_{}'.format(i), selection_type = 'CLEAR_SELECTION')
        arcpy.gp.CostPath_sa("temp_pt", "FDIR_{}".format(i), "FDIR_{}".format(i), "C:/CUHP/LFP_dat/CPATHS_{}".format(i), "EACH_CELL", "GRID_CODE")
        arcpy.gp.StreamToFeature_sa("CPATHS_{}".format(i), "FDIR_{}".format(i), "C:/CUHP/LFP_dat/flowpaths_combined_{}.shp".format(i), "SIMPLIFY")
cent=[]
for i in range(0,len(IDs)):
    cent.append('points_layer_{}'.format(i))
arcpy.Merge_management(cent,'cfp_merged') 
lfp=[]
for i in range(0,len(IDs)):
    lfp.append("flowpaths_combined_{}".format(i))
arcpy.Merge_management(lfp,'lfp_merged')

