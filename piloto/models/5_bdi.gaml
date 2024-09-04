/**
* Name: aguamoviendose
* Based on the internal empty template. 
* Author: carol
* Tags: 
*/


model lectura_excel

global {
	float risk_reservoir_rate <- 0.9;
		
   //Shapefile for the river
    file river_shapefile <- file("../includes/rivers.shp");
	file grid_data <- file("../datos/mdt.tif");   
   
	 //Shape of the environment using the dem file
	 geometry shape <- envelope( grid_data );
 
   float step <- 1 #day;
   date starting_date <- date("2020-01-01");
   
   	map<rgb,float> rainfall_scale <- [rgb(0, 0, 0 )::0, rgb(131, 129, 142 )::1,rgb(97, 88, 132 )::5,rgb(52, 117, 142)::10
		,rgb(11, 140, 136)::30,rgb(53, 159, 53)::40,rgb(167, 157, 81)::80,rgb(159, 127, 58)::120
		,rgb(190, 76, 7)::250,rgb(207, 40, 71)::500,rgb(175, 80, 136 )::750,rgb(212, 118, 163)::1000
		,rgb(250, 157, 190)::1500,rgb(220, 220, 220)::5000
	];
	
   //Shapefile for the basins
   file basins_shapefile <- file("../includes/basins.shp");
   file reservoirs_shapefile <- file("../includes/reservoirs.shp");
	  
   init {
		create River from: river_shapefile with: [basin_id::string(read ("basin_id"))];
		create Basin from: basins_shapefile with: [id::string(read ("HYBAS_ID")), next_basin_id::string(read ("NEXT_DOWN")), order::int(read ("ORDER")),is_heather:: bool(int(read("is_heather")))];		
   		create Reservoir from: reservoirs_shapefile with: [id::string(read ("id")),basin_id::string(read ("basin_id")), max_volume::float(read ("max_volume")), min_volume::float(read ("min_volume")), maxoutflow::float(read ("maxoutflow"))];
			
		// Asignar la cuenca correspondiente a cada embalse
        ask Reservoir {
        	myBasin <- one_of (Basin where (each.id = self.basin_id));
        	current_volume <- self.max_volume / 2;        	
        }
        ask River {
        	myBasin <- one_of (Basin where (each.id = self.basin_id));        	
        }	
        
        create Rainfall from:csv_file( "../datos/lluvias/mensual.csv",true) with:
			[rainfall_date::date(get("rainfall_date")),
				value::float(get("mm")), 				
				basin_id:: replace(get("basin_id"), "b", "")
			];	
   }  
   
	reflex water_flow {
		ask Reservoir {
			do entradas_por_salidas;
		}
		ask reverse(Basin sort_by(each.order)) {
			do move_water;
		}			
	}   
    
}

//grid mdt file: grid_data;

species Rainfall {
	date rainfall_date;
	float value;
	string basin_id;
	Basin myBasin;
	
	init {
		myBasin <- one_of (Basin where (each.id = self.basin_id));        	
	}
	
	aspect default {
		draw circle(3) color: color; 
	}
}

/**
 * 
 * Finite State Machine control !!! 
 * 
 * statement enter : set of instructions to be executed before entering a state
 * statement transition : [to: the state to transition to] [when: the condition to trigger the transition]
 * statement exit : set of instructions to be executed after leaving a state
 * 
 */
species Reservoir {
	string id;
	string basin_id;
	float max_volume;
	float min_volume;
	float maxoutflow;
	float ini_volume;
	float current_volume <- 0.0;
	float outflow;
	float inflow;
	Basin myBasin;
	 	
	int priority_of_discharge <- 50;
		 	
	rgb color <- #gray  ;
	
	aspect base {
		draw circle(1000) color: color border: #pink;		
	}
		
	action getInflow {
		if ( myBasin != nil ) {
			inflow <- myBasin.rainfall;
		}
	}
	
	action entradas_por_salidas {
		do getInflow;
write "----" + basin_id;		
		if ( inflow > maxoutflow) {
write "E > S ";
			outflow <- maxoutflow;
			current_volume <- current_volume + (inflow - outflow);			
		} else {
write "E <= S ";			
			outflow <- inflow;
		}
		
		let porcentaje <- (current_volume / max_volume);
		let healthy <-  porcentaje < risk_reservoir_rate; 		
write "Current Volume" + current_volume + "[" + porcentaje + "%]" + ( healthy ? " SEGURO " : " EN RIESGO");		
	}
}

species River  {
	string basin_id;
	Basin myBasin;
	
	rgb color <- #blue ;
	aspect base {
		draw shape color: color ;
	}
}

species Basin  {
	string id;
	string next_basin_id;
	bool is_heather;
	int order;
	
	//lluvia en cada cada intevalo 
    float rainfall <- 0.0; //variable de contorno    
    
    action move_water {
write "Moving Water TO basin " + id;
    	
//    	list<Rainfall> _allmyRainfall  <-  list (Rainfall where ((each.basin_id = self.id)));

		//Lluvia en el intervalo actual   
    	Rainfall myCurrentRainfall  <-  one_of (Rainfall where ((each.basin_id = self.id)
    		and ( each.rainfall_date = current_date )
    	));
    	
    	if (myCurrentRainfall = nil) {
//    		write "   NO TENGO LLUVIA";
    		rainfall <- 0.0;
   		} else {
//   			write "   " + myCurrentRainfall.value;
    		rainfall <- myCurrentRainfall.value;	
    	}
    	
    	//LLuvia que viene de aguas arriba
    	list<Basin> upperBasins  <-  list (Basin where ((each.next_basin_id = self.id)));
    	loop upper_basin over: upperBasins {
    		//si esta o no regulada
    		Reservoir upper_reservoir <- one_of (Reservoir where (each.myBasin = upper_basin));    		
    		if ( upper_reservoir = nil) {
write "   Moving Water FROM basin " + upper_basin.id + " WITH rainfall " + upper_basin.rainfall;    			
    			rainfall <- rainfall + upper_basin.rainfall;		
    		} else {
write "   Moving Water FROM reservoir " + upper_reservoir.id + " WITH outflow " + upper_reservoir.outflow;    			
    			rainfall <- rainfall + upper_reservoir.outflow;
    		}
    	}
    	
    	
write "-- " + id + " [Rainfall: " + myCurrentRainfall.value + ", TOTAL: " + rainfall + "]";
    	
    	color <- get_rainfall_color( rainfall );     
    }
       
    rgb color <- rgb(255, 255, 255 );
	
	//reflex set_basin_color {
    	//color <- get_rainfall_color( rainfall ); 
    //}
	
	aspect base {
		draw shape border: #black color: #white;
	}
	aspect rainfallAspect {
		draw shape border: #white color: color;
	}	
	
	 rgb get_rainfall_color(float r) {
    	list<rgb> colors <- rainfall_scale.keys;
		list<float>thresholds <- rainfall_scale.values;
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



experiment bonito type: gui //autorun: true
{
	//parameter "Shapefile for the rivers:" var: river_shapefile category: "GIS" ;
	parameter "Shapefile for the basins:" var: basins_shapefile category: "GIS" ;
   	parameter "Shapefile for the rivers:" var: river_shapefile category: "GIS" ;
   	
	parameter "Risk percentage for reservoirs: " var: risk_reservoir_rate category: "Reservoir";
	

	
	font text <- font("Arial", 14, #bold);
	font title <- font("Arial", 18, #bold);
	
	output synchronized: true{
		
		monitor "Current date" value: current_date;
					
		//display carte type: 3d axes: false background: rgb(50,50,50) fullscreen: true toolbar: false{
		display carte type: 3d axes: false background: rgb(50,50,50) toolbar: true {
			
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
			//mesh water_field  color: scale( rainfall_scale) triangulation: true smooth: true;
			//mesh water_field  scale: 9 triangulation: true transparency: 0.4 smooth: 3 above: 0.8 color: scale( rainfall_scale);

			species Basin aspect: rainfallAspect;
			species River aspect: base ;
			species Reservoir aspect: base ;
//			species Rainfall;
		}
		
		display Risk_information refresh: every(5#cycles)  type: 2d {
			chart "Reservoir Status" type: histogram background: #lightgray size: {0.5,0.5} position: {0, 0} {
				data "Healthy" value: Reservoir count ((each.current_volume / each.max_volume) < risk_reservoir_rate) color: #blue;
				data "Risk" value: Reservoir count ((each.current_volume / each.max_volume) >= risk_reservoir_rate) color: #blue;
			}
		}
	}

}