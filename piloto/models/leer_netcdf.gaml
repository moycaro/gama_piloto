/**
* Name: leernetcdf
* Based on the internal empty template. 
* Author: carol
* Tags: 
*/


model leernetcdf

global {
	//the two grid files that we are going to use to initialize the grid
	grid_file rainfall_file <- file("/home/carol/Documents/personal/master/unir/tfm/datos/piloto/cortados/cortado.0.2020.01.tif");
	float step <- 1 #month;
    date starting_date <- date("2020-01-01");
   
	//we use the dem file to initialize the world environment
	//definiton of the file to import
	//grid_file grid_data <- grid_file("/home/carol/Documents/personal/master/unir/tfm/datos/piloto/mdt.tif");
	//field terrain <- field(grid_data) ;
	field rainfall <- field(rainfall_file);
	list<point> points <- rainfall points_in shape;
	
	//field flow <- field(terrain.columns,terrain.rows);
	
	//computation of the environment size from the geotiff file
	geometry shape <- envelope(rainfall_file);	
	
	
	float max_value;
	float min_value;
	init {
		loop pt over: points  {
			rainfall[pt] <- -9999;			
		}
	}
	
	reflex update_rainfall {
		string strYear <- string(current_date.year);
		
		string strMonth <- "";
		if ( current_date.month < 10 ) {
			strMonth <- "0" + string(current_date.month);			
		}else {
			strMonth <- string(current_date.month);
		}
		string new_file_name <- "/home/carol/Documents/personal/master/unir/tfm/datos/piloto/cortados/cortado.0." + strYear + "." + strMonth + ".tif";
		grid_file updated_rainfall_file <- file( new_file_name );
		loop pt over: points  {
			rainfall[pt] <- rainfall[pt] + 10;			
		}
		point p <- points[10];
		write "VALOR::" + string(rainfall[ p ]);  
	}
	
	
	reflex stop_simulation when: (current_date >= date("2023-01-01")) {
		do pause;
	} 
}

//we define the cell grid from the two grid files: the first file (dem_file) will be used as reference for the definition of the grid number of rows and columns and location
//the value of the files are stored in the bands built-in list attribute: each value of the list corresponds to the value in the file
//the value of the first file is also stored in thr grid_value built-in variable
//definition of the grid from the geotiff file: the width and height of the grid are directly read from the asc file. The values of the asc file are stored in the grid_value attribute of the cells.
//grid cell file: land_cover_file;

experiment show_example type: gui {
	output {
		display d type: 3d {
			//camera 'default' location: {7071.9529,10484.5136,5477.0823} target: {3450.0,3220.0,0.0};
		//	mesh terrain scale: 10 triangulation: true  color: palette([#burlywood, #saddlebrown, #darkgreen, #green]) refresh: false smooth: true;
			mesh rainfall scale: 10 triangulation: true color: palette(reverse(brewer_colors("Blues"))) transparency: 0.5 no_data:-9999 ;			
		}
		
	} 
}
