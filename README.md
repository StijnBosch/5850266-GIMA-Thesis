# 5850266-GIMA-Thesis
Github repository containing all scripts and data related to GIMA M. Sc. Thesis "Impervious surface mapping using Remote Sensing and Social Media data" by Stijn Bosch (Utrecht University)

1.	Selection of case studies
The first step in the data preparation workflow is the selection of case studies based on the spatial distribution of Twitter in Europe. This has been carried out using QGIS and Excel. The data required for this step is the Twitter data, provided by ITC Faculty of Geo-Information Science and Earth Observation and the Local Administrative Units dataset, provided by the Eurostat (Eurostat, 2020). The practical steps are described below.

-	Twitter CSV file for Europe is loaded into QGIS and plotted on a map by using the ‘create points from table’ operation. Each individual Tweet record in the CSV file contains a x and y coordinate. 
-	The number of Tweets per LAU are calculated by plotting the LAU and performing the ‘count points in polygon’ operation. 
-	The resulting shapefile contains the number of Tweets per LAU. This is exported to a CSV file for further analysis
-	To calculate the number of Tweets per km2 and per 1000 inhabitants are calculated in excel. The km2 and number of inhabitants for each LAU is recorded within the Eurostat dataset. 
-	The final case study extend is created by creating a bounding box around the borders of the selected LAU in QGIS with the ‘bounding boxes’ operation.

2.	Collection of satellite imagery
After the case study areas are known, satellite imagery for these collected using the Geemap module in Python. This Python module communicates with the Google Earth Engine database. To use Geemap, registration with Google Earth Engine is required. Furthermore, the bounding boxes created for case study selection are necessary to clip the imagery to the correct extend. The notebook ‘Geemap - Image Collection.ipynb’ contains the code for this step. The practical steps are described below. 

-	For each case study area, an image collection is created. Within this image collection, the source of satellite imagery, location (a vector point from within the case study area), date and cloud cover percentage are filtered. 
-	Each image Earth Engine ID tells the sensing date for that image. Single Date Images are selected from the image collection list. 
-	For construction of the median images the .median filter is used.
-	Each Single Date and Median image is clipped on the extend of the case study bounding boxes and converted into 16 bit unsigned integer. The 16 bit conversion is necessary for export to Google Drive. One of the Sentinel 2 bands is 32 bit integer, disrupting the export of the entire image. 
-	Finally, imager are exported to Google Drive.

3.	Twitter Raster 
The construction of the Twitter Raster is performed in QGIS. The Twitter data plotted in the selection of case studies and the collected satellite imagery is used to identify the spatial extend of the Twitter Raster and identification of the pixels that contain Twitter data within their edges.  The practical steps are described below.
-	The Twitter data is loaded into QGIS as vectors and the Satellite Imagery is loaded into QGIS as raster.  
-	The Twitter data is converted to raster using the ‘Convert map to raster’ operation, containing the specification of the same spatial extend and spatial resolution as the satellite imagery. This way, the Twitter Raster and Satellite Imagery perfectly align.

4.	Validation data preparation
The three validation datasets are downloaded from their respective sources. To incorporate these dataset for accuracy assessment in the approach some pre-processing is necessary, namely clipping these maps to the extend of the case studies and convert the 30m resolution to 10m resolution to match the imagery. This pre-processing is done in QGIS. The practical steps are described below.
-	The validation dataset is loaded into QGIS and clipped on the extend of the case study area using the bounding box created in step 1 and the ´Clip raster by extent’ operation. 
-	The 30m resolution datasets and the GAIA dataset are converted to 10m resolution to match the imagery using the ‘Raster calculator’ and reshape to the extend and resolution of the case study imagery. This results in the exact same grid as the original dataset, but each 30m pixel is converted to 9 10m pixels. 

5.	Feature Extraction
Feature extraction is done in Python using Jupyter notebooks. All notebooks can be found on Github. GLCM texture features are the only features extracted using MATLAB. Due to technical issues and time consuming bug fixing for the texture features in Python, licensed software is used to construct these features in a timely manner. The input data for this step is the satellite imagery. The practical steps are described below.
-	NDVI is calculated in the ´Feature Extraction – NDVI’ notebook. The images are loaded using the ´Read_data’ function and NDVI is calculated using the Earthpy ´es.normalized_diff´ function for the NIR and Red band. The output is written to a CSV file that can be read when constructing the training data
-	NDWI is calculated in the ‘Feature Extraction – NDWI’ notebook. The images are loaded using the ‘Read_data’ function and NDWI is calculated using the NIR and Green Band. The output is written to a CSV file that can be read when constructing the training data
-	Morphological profiles are calculated in the ‘Feature Extraction – EMP’ notebook. The images are loaded using the ‘Read_data’ function. Opening and Closing operation are described in the notebook. For each image, 4 opening and closing operation are performed and the results are stored in a dictionary. The content of this dictionary is subsequently stored in an .npy file that can be read when constructing the training data
-	GLCM texture features are calculated in MATLAB. The MATLAB code is found in the notebook folder. Images are loaded using  ‘imread’ . Window sizes (Scales) are set to 5x5 and 9x9. Next, all texture features are calculated and plotted. From MATLAB, each individual texture is stored as .mat files. These files are read in the ‘Feature Extraction – Read GLCM Matlab’ notebook. For each image, all individual texture .mat files are converted to NumPy arrays  and concatenated to a stack of rasters, saved to a CSV file that can be read when constructing the training data

6.	Image classification and accuracy assessment
The image classification using Isolation Forest and Support Vector Machines is carried out in Python using Jupyter notebooks. For this last step, all datasets (satellite imagery, extracted features, twitter raster and validation datasets) are used. The practical steps are described below.
-	The IF and SVM image classification is written in the ‘Image Classification - IF & OCSVM’ notebook. 
-	First, all datasets are read, using the ‘Read_data´ function for the imagery, NumPy to load the .npy and csv files and Rasterio to open the Twitter raster and validation datasets. 
-	To perform IF and SVM, first the training dataset is constructed by concatenating the imagery and NDVI, NDWI, EMP and GLCM. 
-	Both models are fitted to the Twitter raster (Ytr). For IF, the number of decision trees is indicated by the n_estimator parameter in the IsolationForest function. For SVM, kernel and nu values are set in the OneClassSVM function. The output is set to return score_samples to obtain a raster grid with anomaly scores. The output raster is saved to a CSV file for storage. 
-	Accuracy assessment is carried out in the ‘Image Classification – Accuracy assessment’ notebook. 
-	All image classification output CSV files are read, as well as all validation dataset for each case study area. 
-	To calculate the confusion matrix, the classification output anomaly score map is converted into a binary map using the threshold value, converting everything below this value to 0 (pervious) and everything above to 1 (impervious). All validation dataset are similarly rewritten, to have 0 for pervious and 1 for impervious. 
-	Accuracy assessment statists are calculated based on the TP, TN, FP and FN values derived from the confusion matrix. These statistics are calculated for each validation dataset and divided by three to obtain the final accuracy assessment statistics. 
