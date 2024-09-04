/**
* Name: aguamoviendose
* Based on the internal empty template. 
* Author: carol
* Tags: 
*/


model lectura_excel

global {
   //Shapefile for the river
   file river_shapefile <- file("../includes/rivers.shp");
   file land_cover_file <- file("../datos/cortados/cortado.0.2020.01.tif");
   
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
   
	geometry shape <- envelope(basins_shapefile) + 500;
	  
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
        
        create Rainfall from:csv_file( "../datos/lluvias/mensual.csv",true) with:
			[rainfall_date::date(get("rainfall_date")),
				value::float(get("mm")), 				
				basin_id:: replace(get("basin_id"), "b", "")
			];	
   }  
   
  
   
}

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
    float rainfall <- 0.0; //variable de contorno    
    
    reflex set_water_volume {
write self.id;    	

    	list<Rainfall> _allmyRainfall  <-  list (Rainfall where ((each.basin_id = self.id)));   
      	list<Rainfall> _allNotNilRainfall  <-  list (_allmyRainfall where ((each.rainfall_date != nil )));   
      	list<Rainfall> _allNilRainfall  <-  list (_allmyRainfall where ((each.rainfall_date = nil )));   
    	Rainfall myRainfall  <-  one_of (Rainfall where ((each.basin_id = self.id)
    		and ( each.rainfall_date = current_date )
    	));        	
    	
    	if (myRainfall = nil) {
			rainfall <- 5.0;	
    	} else {
    		rainfall <- myRainfall.value;	
    	}
    	
    }
       
    rgb color <- rgb(255, 255, 255 );
	
	reflex set_basin_color {
    	color <- get_rainfall_color( rainfall ); 
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
			mesh terrain scale: 10 triangulation: true  color: palette([#burlywood, #saddlebrown, #darkgreen, #green]) refresh: false smooth: true;
			
   			species Basin aspect: rainfallAspect;			
			species River aspect: base ;
			species Reservoir aspect: base ;
			species Rainfall;
		}
	}

}