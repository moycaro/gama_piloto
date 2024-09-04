/**
* Name: congrid
* Based on the internal empty template. 
* Author: carol
* Tags: 
*/


model congrid

global {
	float step <- 1 #month;
    date starting_date <- date("2020-01-01");
    
	 grid_file rainfall_file <- file("../datos/cortados/cortado.0.2020.01.tif");
  	 //Shape of the environment using the dem file
  	 geometry shape <- envelope(rainfall_file);
	
	
	init {
		do init_cells;
		ask rainfall_grid {
			do update_color;
		}
	}	
	
   //Action to initialize the altitude value of the cell according to the dem file
   action init_cells {
      ask rainfall_grid {
         rainfall <- grid_value;
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
		string new_file_name <- "../datos/cortados/cortado.0." + strYear + "." + strMonth + ".tif";
		grid_file updated_rainfall_file <- file( new_file_name );
		
  			//create building_from_shapefile from: buildings_simple0_shape_file with: [building_nature::string(read("NATURE"))];
  	create grid from: updated_rainfall_file;
  	
loop el over: rainfall_grid {	
	//write el get "grid_value";
    write "my row index is:" + string( el.grid_y );
}		

		ask rainfall_grid {
            let newValue <- rnd(100);
            rainfall <- newValue;
            do update_color;
        }
	}
	
	
	reflex stop_simulation when: (current_date >= date("2022-12-12")) {
		do pause;
	} 
}

species building_from_grid {
	grid my_grid;
	date related_date;
}

grid rainfall_grid file: rainfall_file neighbors: 8 frequency: 0  use_regular_agents: false use_individual_shapes: false use_neighbors_cache: false {
	float rainfall;

      //Update the color of the cell
      action update_color { 
         if (rainfall > 100) {
         	color <- #green;
         } else if (rainfall >= 0) {
         	color <- #blue;
         } else {
         	color <- #white;
         }
         
//         grid_value <- water_height + altitude;
      }
}


experiment hydro type: gui {
	output {
		display d type:2d antialias:false{
			grid rainfall_grid border: #black;
			//species river;
		}
	}
}
