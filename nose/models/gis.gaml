/**
* Name: gis
* Based on the internal empty template. 
* Author: carol
* Tags: 
*/


model gis

global {

	
   //Shapefile for the river
   file river_shapefile <- file("../includes/rivers.shp");
   
   //Shapefile for the basins
   file basins_shapefile <- file("../includes/basins.shp");
   file reservoirs_shapefile <- file("../includes/reservoirs.shp");
   
	geometry shape <- envelope(basins_shapefile);
	float step <- 1 #h;
	
   init {
		create river from: river_shapefile ;
		create Basin from: basins_shapefile with: [id::string(read ("HYBAS_ID")), next_basin_id::string(read ("NEXT_DOWN")), order::int(read ("ORDER")),is_heather:: bool(int(read("is_heather")))];		
   		create Reservoir from: reservoirs_shapefile with: [basin_id::string(read ("basin_id"))];		
			
		// Asignar la cuenca correspondiente a cada embalse
        ask Reservoir {
        	myBasin <- one_of (Basin where (each.id = self.basin_id));        	
        }		
        
        ask Basin {
        	do init_topology;
       		//write self.id + " next basin: " + self.next_down.id;
        } 
   }
}

species Reservoir {
	string basin_id;
	Basin myBasin;
	 	
	rgb color <- #gray  ;
	
	aspect base {
		draw circle(500) color: #pink border: #black;		
	}
}

species river  {
	rgb color <- #black ;
	aspect base {
		draw shape color: color ;
	}
}

species Basin  {
	string id;
	string next_basin_id;
	bool is_heather;
	int order;
	Basin next_down;
	
	//lluvia en cada cada intevalo 
    float rainfall <- rnd(100.0);    
    float water_volume <- rnd(100.0);
    
    action init_topology {
		next_down <- one_of(Basin where (each.id = next_basin_id));    	
    }
    
    reflex set_water_volume {
    	rainfall <- rnd(100.0) ;
    	water_volume <- rainfall;
    }
    
    rgb color <- rgb(255, 255, 255 ) update: rainfall_legend( rainfall );
	
	aspect blueFlow {
		draw shape border: #white color:color;
	}	
	
	// Rainfall legend
    rgb rainfall_legend(float r) {
    	list<rgb> colors <- [rgb(130, 130, 130 ), rgb(131, 129, 142 ),rgb(97, 88, 132 ), rgb(52, 117, 142), rgb(11, 140, 136 ), rgb(53, 159, 53 ), rgb(167, 157, 81 ), rgb(159, 127, 58 ), rgb(190, 76, 7 ), rgb(207, 40, 71 ), rgb(175, 80, 136 ), rgb(212, 118, 163 ), rgb(250, 157, 190 ), rgb(220, 220, 220 )];
		list<float>thresholds <- [0, 1, 5, 10, 30, 40, 80, 120, 250, 500, 750, 1000, 1500, 5000];
        int legend_index <- 0;
        loop i from: 0 to: length(thresholds) - 2 {
        	 if ( r >= thresholds[i]         	 		
        	 			and r < thresholds[i + 1]) {
                legend_index <- i;
                break;
            }   
        }
        return colors[legend_index];
    }		
}

experiment Run type: gui {
   	parameter "Shapefile for the rivers:" var: river_shapefile category: "GIS" ;
	parameter "Shapefile for the basins:" var: basins_shapefile category: "GIS" ;
	
   output { 
   		display basic_display type:3d {
   			species Basin aspect: blueFlow ;			
			species river aspect: base ;
			species Reservoir aspect: base ;
		}
   }
}