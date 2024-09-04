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
   
   float step <- 1 #minutes;
   
   //Shapefile for the basins
   file basins_shapefile <- file("../includes/basins.shp");
   file reservoirs_shapefile <- file("../includes/reservoirs.shp");
   
 //	int nb_gauges_affected <- 0 update: (people + list_people_in_buildings) count (each.is_infected);
//	int nb_gauges_not_affected <- nb_gauges update: nb_gauges - nb_gauges_affected;
	geometry shape <- envelope(basins_shapefile) + 500;
  	field water_field <- field(200, 200, 0);  
	  
   init {
		create River from: river_shapefile with: [basin_id::string(read ("basin_id"))];
		create Basin from: basins_shapefile with: [id::string(read ("HYBAS_ID")), is_heather:: bool(int(read("is_heather")))];		
   		create Reservoir from: reservoirs_shapefile with: [basin_id::string(read ("basin_id"))];		
			
		// Asignar la cuenca correspondiente a cada embalse
        ask Reservoir {
        	myBasin <- one_of (Basin where (each.id = self.basin_id));        	
        }
        ask River {
        	myBasin <- one_of (Basin where (each.id = self.basin_id));        	
        }	
        
        do init_river_cells;
   }
   
   action init_river_cells {
     ask River {
		water_field[ location ] <- 1.0;					
	 }	
   }   
   
   reflex update_cell_value {
   		let aleatorio <- rnd(20);
		//ask all cells to decrease their level of pollution
		ask cell {
			water_volume <- water_volume * aleatorio;	
		}		
		
		water_field <- water_field * aleatorio;
   }   
}

 grid cell height:200 width:200 neighbors: 8 frequency: 0  use_regular_agents: false use_individual_shapes: false use_neighbors_cache: true {
	bool is_river;
	float water_volume;
}

species Reservoir {
	string basin_id;
	Basin myBasin;
	 	
	rgb color <- #gray  ;
	
	aspect base {
		draw circle(500) color: #pink border: #black;		
	}
}

species River  {
	string basin_id;
	Basin myBasin;
	
	rgb color <- #black ;
	aspect base {
		draw shape color: color ;
	}
}

species Basin  {
	string id;
	bool is_heather;
	
	//lluvia en cada cada intevalo 
    float rainfall <- rnd(100.0);    
    float water_volume <- rnd(100.0);
    
    reflex set_water_volume {
    	rainfall <- rnd(100.0) ;
    	water_volume <- rainfall;
    }
    
    reflex set_basin_color {
    	color <- rainfall_legend( rainfall ); 
    }
    
    rgb color <- rgb(255, 255, 255 );
	
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
   		monitor "Current hour" value: current_date;
		
   		display basic_display type:3d {
   			species Basin aspect: blueFlow ;			
			species River aspect: base ;
			species Reservoir aspect: base ;
			grid cell;
		}
		
		display chart refresh: every(10 #cycles)  type: 2d {
			chart "Water volume" type: series {
				//data "not_affected" value: nb_gauges_not_affected color: #green marker: false;
			}
		}
	}
}


experiment bonito type: gui //autorun: true
{
	//parameter "Shapefile for the rivers:" var: river_shapefile category: "GIS" ;
	parameter "Shapefile for the basins:" var: basins_shapefile category: "GIS" ;
	
	float minimum_cycle_duration <- 0.01;
	list<rgb> pal <- palette([ #black, #green, #yellow, #orange, #orange, #red, #red, #red]);
	
	map<rgb,float> rainfall_scale <- [rgb(0, 0, 0 )::0, rgb(131, 129, 142 )::1,rgb(97, 88, 132 )::5,rgb(52, 117, 142)::10
		,rgb(11, 140, 136)::30,rgb(53, 159, 53)::40,rgb(167, 157, 81)::80,rgb(159, 127, 58)::120
		,rgb(190, 76, 7)::250,rgb(207, 40, 71)::500,rgb(175, 80, 136 )::750,rgb(212, 118, 163)::1000
		,rgb(250, 157, 190)::1500,rgb(220, 220, 220)::5000
	];
	
	font text <- font("Arial", 14, #bold);
	font title <- font("Arial", 18, #bold);
	
	output synchronized: true{
		//display carte type: 3d axes: false background: rgb(50,50,50) fullscreen: true toolbar: false{
		display carte type: 3d axes: false background: rgb(50,50,50) toolbar: false{
			 overlay position: { 50#px,50#px} size: { 1 #px, 1 #px } background: # black border: #black rounded: false 
            	{
            	//for each possible type, we draw a square with the corresponding color and we write the name of the type
                
                draw "Rainfall" at: {0, 0} anchor: #top_left  color: #white font: title;
                float y <- 50#px;
                draw rectangle(20#px, 280#px) at: {10#px, y + 130#px} wireframe: true color: #white;
                        		
				loop p over: reverse(rainfall_scale.pairs)
                {
                    draw square(20#px) at: { 10#px, y } color: rgb(p.key, 0.6) ;
                    draw string(p.value) at: { 30#px, y} anchor: #left_center color: # white font: text;
                    y <- y + 20#px;
                }
            }
			
			light #ambient intensity: 128;
			//camera 'default' location: {1254.041,2938.6921,1792.4286} target: {1258.8966,1547.6862,0.0};
			//species basin refresh: false;
			//species building refresh: false;
			//species people;

			//display the pollution grid in 3D using triangulation.
			//mesh cell scale: 9 triangulation: true transparency: 0.4 smooth: 3 above: 0.8 color: #red;
			mesh water_field  color: scale( rainfall_scale) triangulation: true smooth: true;
			
   			species Basin aspect: blueFlow ;			
			//species River aspect: base ;
			species Reservoir aspect: base ;			
		}
	}

}